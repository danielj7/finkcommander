/* 
 File SBString.m

 See header file SBString.h for license and interface information.

*/

#import "SBString.h"

@implementation NSString ( SBString )

-(NSString *)strip
{
    NSCharacterSet *nonWhitespaceSet = [[NSCharacterSet 
       whitespaceAndNewlineCharacterSet] invertedSet];
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

    return [self substringWithRange: NSMakeRange(start, length)];
}

@end
