/* 
 File SBString.m

 See header file SBString.h for license and interface information.

*/

#import "SBString.h"

#define MAXBUF 2048

@implementation NSString ( SBString )

//================================================================================
#pragma mark STRING AND SHELL PATTERN MATCHING METHODS
//================================================================================

-(BOOL)contains:(NSString *)s
{
    if ([self rangeOfString: s].length > 0) return YES;
    return NO;
}

-(BOOL)containsCI:(NSString *)s
{
   if ([self rangeOfString:s options:NSCaseInsensitiveSearch].length > 0) 
       return YES;
    return NO;
}

-(BOOL)containsPattern:(NSString *)pat
{
	int result;
		
    result = fnmatch([pat UTF8String], [self UTF8String], 0);
    if (result == 0) return YES;
	return NO;
}

//================================================================================
#pragma mark REGULAR EXPRESSION MATCHING METHODS
//================================================================================

/*
 *  Expression = NSString
 */

-(BOOL)containsExpression:(NSString *)pat
{
	return [self rangeOfExpression:pat].length > 0;
}

-(NSRange)rangeOfExpression:(NSString *)pat
{
	return [self rangeOfExpression:pat 
			inRange:NSMakeRange(0, [self length])];
}

-(NSRange)rangeOfExpression:(NSString *)pat
		inRange:(NSRange)range
{
	NSRange r = NSMakeRange(NSNotFound, 0);
	regex_t expr;
	int comperr;
	
	comperr = compiledExpressionFromString(pat, &expr);
	if (comperr) return r;
	
	r = [self rangeOfCompiledExpression:&expr
			inRange:range];
	regfree(&expr);
	return r;
}

/*
 *  Expression = Compiled Regular Expression
 */
 
-(BOOL)containsCompiledExpression:(regex_t *)re
{
	return [self rangeOfCompiledExpression:re].length > 0;
}

-(NSRange)rangeOfCompiledExpression:(regex_t *)re
{
	return [self rangeOfCompiledExpression:re
			inRange:NSMakeRange(0, [self length])];
}

-(NSRange)rangeOfCompiledExpression:(regex_t *)re
	inRange:(NSRange)range
{
	NSRange r = NSMakeRange(NSNotFound, 0);
	NSString *searchString = [self substringWithRange:range];
	regmatch_t matches[1];
	size_t nmatch = 1;
	char errmsg[MAXBUF];
	int result;
	
	result = regexec(re, [searchString UTF8String], nmatch, matches, 0);
	if (result != 0){
		if(result != REG_NOMATCH){
			regerror(result, re, errmsg, MAXBUF);
			NSLog(@"Error executing regular expression:\n%s", errmsg);
		}
		return r;
	}
	//Add location of substring searhced to determine location within string
	r.location = matches[0].rm_so + range.location;
	r.length = matches[0].rm_eo - matches[0].rm_so;
	return r;
}

//================================================================================
#pragma mark OTHER STRING METHODS
//================================================================================

-(NSString *)strip
{
    NSCharacterSet *nonWhitespaceSet = 
			[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
    int start;
    int length;
	//find start of nonwhitespace chars in string
    start = [self rangeOfCharacterFromSet:nonWhitespaceSet].location;
	if (start == NSNotFound){
		return self;
	}
	//find last nonwhitespace char; use it to calculate length
	//of substring between beginning and ending whitespace
	length = [self rangeOfCharacterFromSet: nonWhitespaceSet
					options: NSBackwardsSearch].location - start + 1;
	//use start and length to calculate range
	//return string in that range
	return [self substringWithRange: NSMakeRange(start, length)];
}

-(NSURL *)URLByAddingPercentEscapesToString
{
	NSString *urlString;
	urlString = [(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self,
					NULL, NULL, CFStringConvertNSStringEncodingToEncoding(NSASCIIStringEncoding))
				autorelease];
	return [NSURL URLWithString:urlString];
}

@end


int compiledExpressionFromString(NSString *string, regex_t *expr)
{
	char errmsg[MAXBUF];
	int comperr;
	
	comperr = regcomp(expr, [string UTF8String], REG_EXTENDED);
	if (comperr){
		regerror(comperr, expr, errmsg, MAXBUF);
		NSLog(@"Error compiling regular expression:\n%s", errmsg);
	}
	return comperr;
}




