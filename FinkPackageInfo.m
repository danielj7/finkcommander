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

-(BOOL)isHeading:(NSString *)s
{
    return ([s contains: @"Usage Notes:"]	||
			[s contains: @"Web site:"] 		||
			[s contains: @"Maintainer:"]);
}

//adds font attributes to headings, link attributes to urls and removes hard
//returns within paragraphs to allow soft wrapping
-(NSAttributedString *)formatDescriptionString:(NSString *)s
{
	NSEnumerator *e = [[s componentsSeparatedByString: @"\n"] objectEnumerator];
	NSEnumerator *f = [[NSArray arrayWithObjects: @"Summary", @"Description",
								@"Usage Notes", @"Web site", @"Maintainer", nil] 
							objectEnumerator];
	NSString *line;
	NSString *field;
	NSRange r;
	
	//start attributed string colon and Desc field (which FC calls Summary)
	NSMutableAttributedString *desc = [[[NSMutableAttributedString alloc]
				initWithString: [NSString stringWithFormat: @":\n%@", 
									[e nextObject]] //Desc
				attributes: [NSDictionary dictionaryWithObjectsAndKeys:
					[NSFont systemFontOfSize: 0], NSFontAttributeName,
					[NSColor grayColor], NSForegroundColorAttributeName,
					nil]] autorelease];

	//test second line for DescDetail; if present, provide field name; if period add newlines
	line = [[e nextObject]  strip];
	if (! [line isEqualToString: @"."]){
		[desc appendAttributedString:
			[[[NSMutableAttributedString alloc]
					initWithString: [NSString stringWithFormat: @"\n\n%@ ", line]]
			autorelease]];
	}else{
		[desc appendAttributedString:
			[[[NSMutableAttributedString alloc] initWithString: @"\n\n"] autorelease]];
	}
	
	//remove line endings from within paragraphs; substitute line endings for periods
	while (line = [e nextObject]){ 
		line = [line strip];
		if ([line isEqualToString: @"."]){
			[desc appendAttributedString:
				[[[NSMutableAttributedString alloc] initWithString: @"\n\n"] autorelease]];
				continue;
		}
		[desc appendAttributedString:
				[[[NSMutableAttributedString alloc] 
					initWithString: [NSString stringWithFormat: @"%@ ", line]] autorelease]];
	}
	[desc appendAttributedString:
		[[[NSMutableAttributedString alloc] initWithString: @"\n\n"] autorelease]];

	//apply bold face to field names
	while (field = [f nextObject]){
		r = [[desc string] rangeOfString: field];
		if (r.length > 0){
			[desc addAttribute: NSForegroundColorAttributeName 
				  value: [NSColor grayColor] 
				  range: r];
		}
	}
	
	return desc;
}

-(void)displayDescriptions:(NSArray *)packages
{
	NSEnumerator *e = [packages objectEnumerator];
	FinkPackage *pkg;

	[textView setString: @""];

	while (pkg = [e nextObject]){
		[[textView textStorage] appendAttributedString:
			[[[NSAttributedString alloc] 
					initWithString:
						[NSString stringWithFormat: @"%@ v. %@", [pkg name], [pkg version]]
					attributes: [NSDictionary dictionaryWithObjectsAndKeys: 
						 [NSFont boldSystemFontOfSize: 0], NSFontAttributeName,
						 [NSNumber numberWithInt: NSSingleUnderlineStyle], NSUnderlineStyleAttributeName, 
						 [NSColor blueColor], NSForegroundColorAttributeName,
						nil]] autorelease]];	
		
		[[textView textStorage] appendAttributedString:
			[self formatDescriptionString: [pkg fulldesc]]];
		[[textView textStorage] appendAttributedString:
			[[[NSMutableAttributedString alloc] initWithString: @"\n"] autorelease]];
	}
}

@end
