/* 
 File SBString.m

 See header file SBString.h for license and interface information.

*/

#import "SBString.h"

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
    const char *s = [self UTF8String];
    const char *p = [pat UTF8String];
    int result;

    result = fnmatch(p, s, 0);
    if (result == 0) return YES;
    return NO;
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
