

#import "SBMutableAttributedString.h"


@implementation NSMutableAttributedString ( SBMutableAttributedString )

-(void)appendString:(NSString *)s
{
	[self replaceCharactersInRange: NSMakeRange([self length], 0)
		withString:s];
}

@end
