/* 
 File SBString.m

 See header file SBString.h for license and interface information.

*/

#import "SBString.h"

#define MAXBUF 256

@implementation NSString ( SBString )

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
	char s[[self length]+1];
	char p[[self length]+1];
    int result;
	
	strcpy(s, [self UTF8String]);
	strcpy(p, [pat UTF8String]);
	
    result = fnmatch(p, s, 0);
    if (result == 0) return YES;
    return NO;
}

-(BOOL)containsExpression:(NSString *)pat
{
    regex_t expr;
	char s[[self length]+1];
	char p[[self length]+1];
	char errmsg[MAXBUF];
	int comperr;
    int result;

	strcpy(s, [self UTF8String]);
	strcpy(p, [pat UTF8String]);

	comperr = regcomp(&expr, p, REG_EXTENDED | REG_NOSUB);
	if (comperr){
		regerror(comperr, &expr, errmsg, MAXBUF);
		NSLog(@"Error compiling regular expression:\n%s", errmsg);
		return NO;
	}
	result  = regexec(&expr, s, 0, NULL, 0);
	if (result != 0 && result != REG_NOMATCH){
		regerror(result, &expr, errmsg, MAXBUF);
		NSLog(@"Error executing regular expression:\n%s", errmsg);
		return NO;
	}
	regfree(&expr);
	return result == 0;
}

-(NSRange)rangeOfExpression:(NSString *)pat
{
	return [self rangeOfExpression:pat 
			inRange:NSMakeRange(0, [pat length])];
}

-(NSRange)rangeOfExpression:(NSString *)pat
		inRange:(NSRange)range
{
	NSRange r = NSMakeRange(NSNotFound, 0);
	NSString *searchString = [self substringWithRange:range];
	regex_t expr;
	regmatch_t matches[1];
    size_t nmatch = 1;
	char s[[self length]+1];
	char p[[self length]+1];
	char errmsg[MAXBUF];
	int comperr;
    int result;
	
	strcpy(s, [searchString UTF8String]);
	strcpy(p, [pat UTF8String]);
	
	comperr = regcomp(&expr, p, REG_EXTENDED);
	if (comperr){
		regerror(comperr, &expr, errmsg, MAXBUF);
		NSLog(@"Error compiling regular expression:\n%s", errmsg);
		return r;
	}
	result  = regexec(&expr, s, nmatch, matches, 0);
	if (result != 0){
		if(result != REG_NOMATCH){
			regerror(result, &expr, errmsg, MAXBUF);
			NSLog(@"Error executing regular expression:\n%s", errmsg);
		}
		return r;
	}
	//Add location of substring searhced to determine location within string
	r.location = matches[0].rm_so + range.location;  
	r.length = matches[0].rm_eo - matches[0].rm_so;
	
	regfree(&expr);
	return r;
}

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

@end
