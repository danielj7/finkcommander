/*
 File: FinkPackageInfo.m

 See the header file, FinkPackageInfo.h, for interface and license information.

 */

#import "FinkPackageInfo.h"

//dark green
#define URLCOLOR [NSColor colorWithDeviceCyan:1.0 magenta:0.0 yellow:1.0 black:0.4 alpha:1.0]
//dark blue
#define HEADINGCOLOR [NSColor colorWithDeviceCyan:1.0 magenta:1.0 yellow:0.0 black:0.3 alpha:1.0]


@implementation FinkPackageInfo

-(id)init
{
	self = [super initWithWindowNibName: @"PackageInfo"];
	defaults = [NSUserDefaults standardUserDefaults];

	[self setWindowFrameAutosaveName: @"PackageInfo"];

	return self;
}

-(void)awakeFromNib
{
	textView = [MyTextView myTextViewToReplace: textView in: scrollView];
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
						forPackage:(FinkPackage *)p
{
	NSEnumerator *e = [[s componentsSeparatedByString: @"\n"] objectEnumerator];
	NSEnumerator *f = [[NSArray arrayWithObjects: @"Summary", @"Description",
								@"Usage Notes", @"Web site", @"Maintainer", nil] 
							objectEnumerator];
	NSDictionary *urlAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									URLCOLOR, NSForegroundColorAttributeName,
									[NSNumber numberWithInt: NSSingleUnderlineStyle],
											NSUnderlineStyleAttributeName,
									nil];
	NSString *line;
	NSString *field;
	NSRange r;	      //general purpose range variable
	
	//start attributed string with colon, which will follow name and version,
	//then newline and formatted Desc field
	NSMutableAttributedString *desc = [[[NSMutableAttributedString alloc]
				initWithString: [NSString stringWithFormat: @":\n%@", 
									[e nextObject]] //Desc
				attributes: [NSDictionary dictionaryWithObjectsAndKeys:
					[NSFont systemFontOfSize: 0], NSFontAttributeName,
					[NSColor darkGrayColor], NSForegroundColorAttributeName,
					nil]] autorelease];

	//test second line for period or DescDetail
	line = [[e nextObject]  strip];
	if ([line isEqualToString: @"."]){ 		//change period to 2 newlines
		[desc appendAttributedString:
			[[[NSMutableAttributedString alloc] initWithString: @"\n\n"] autorelease]];
	}else{									//add newlines before DescDetail
		[desc appendAttributedString:
			[[[NSMutableAttributedString alloc]
					initWithString: [NSString stringWithFormat: @"\n\n%@ ", line]]
			autorelease]];
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

	//apply attributes to field names
	while (field = [f nextObject]){
		r = [[desc string] rangeOfString: field];
		if (r.length > 0){
			[desc addAttribute: NSForegroundColorAttributeName 
				  value: [NSColor darkGrayColor] 
				  range: r];
		}
	}
	
	//look for web url and if found turn it into an active link
	if ([[p weburl] length] > 0){
		r = [[desc string] rangeOfString: [p weburl]];
		[desc addAttributes: urlAttributes range: r];
		[desc addAttribute: NSLinkAttributeName
							value: [NSURL URLWithString: [p weburl]]
							range: r];
	}
		
	//look for e-mail url and if found turn it into an active link
	if ([[p email] length] > 0){
		NSString *mailurl = [NSString stringWithFormat: @"mailto:%@", [p email]];	
		
		r = [[desc string] rangeOfString: [p email]];
		[desc addAttributes: urlAttributes range: r];
		[desc addAttribute: NSLinkAttributeName
							value: [NSURL URLWithString: mailurl]
							range: r];
	}
	return desc;
}

-(void)displayDescriptions:(NSArray *)packages
{
	NSEnumerator *e = [packages objectEnumerator];
	FinkPackage *pkg;
	NSString *nameVersion;

	[textView setString: @""];

	while (pkg = [e nextObject]){
		nameVersion = ([[pkg version] length] > 1) ? 
			[NSString stringWithFormat: @"%@ v. %@", [pkg name], [pkg version]] : [pkg name];
		[[textView textStorage] appendAttributedString:
			[[[NSAttributedString alloc] 
					initWithString: nameVersion
					attributes: [NSDictionary dictionaryWithObjectsAndKeys: 
						[NSFont boldSystemFontOfSize: 0], NSFontAttributeName,
						HEADINGCOLOR, NSForegroundColorAttributeName,
						nil]] autorelease]];
		[[textView textStorage] appendAttributedString:
			[self formatDescriptionString: [pkg fulldesc] forPackage: pkg]];
		[[textView textStorage] appendAttributedString:
			[[[NSMutableAttributedString alloc] initWithString: @"\n"] autorelease]];
	}
}

@end
