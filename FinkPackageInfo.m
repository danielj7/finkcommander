/*
 File: FinkPackageInfo.m

 See the header file, FinkPackageInfo.h, for interface and license information.

 */

#import "FinkPackageInfo.h"


@implementation FinkPackageInfo

-(id)init
{
	self = [super initWithWindowNibName: @"PackageInfo"];
	defaults = [NSUserDefaults standardUserDefaults];

	[self setWindowFrameAutosaveName: @"PackageInfo"];

	return self;
}

-(void)displayDescriptions:(NSArray *)packages
{
	NSEnumerator *e = [packages objectEnumerator];
	FinkPackage *pkg;
	int i = 0;
	NSString *full = nil;
	NSString *divider = @"------------------------\n";

	[textView setString: @""];

	while (pkg = [e nextObject]){
		full = [NSString stringWithFormat: @"%@-%@:   %@\n",
			[pkg name],
			[pkg version],
			[pkg fulldesc]];
		if (i > 0){
			[[textView textStorage] appendAttributedString:
				[[[NSAttributedString alloc] initWithString: divider] autorelease]];
		}
		[[textView textStorage] appendAttributedString:
			[[[NSAttributedString alloc] initWithString: full] autorelease]];
		i++;
	}
}

@end
