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
{
	NSEnumerator *e = [[s componentsSeparatedByString: @"\n"] objectEnumerator];
	NSEnumerator *f = [[NSArray arrayWithObjects: @"Summary", @"Description",
								@"Usage Notes", @"Web site", @"Maintainer", nil] 
							objectEnumerator];
	NSDictionary *urlAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSColor colorWithDeviceCyan:1.0 magenta:0.0 yellow:1.0
										black:0.4 alpha:1.0], 			//dark green
										NSForegroundColorAttributeName,
									[NSNumber numberWithInt: NSSingleUnderlineStyle],
											NSUnderlineStyleAttributeName,
									nil];
	NSString *line;
	NSString *field;
	NSString *url;
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
	r = [[desc string] rangeOfString: @"Web site: "];
	if (r.length > 0){
		int start = r.location + r.length;
		int len;
		
		r = [[desc string] rangeOfString: @"\n" options: 0 
							range: NSMakeRange(start, [[desc string] length] - start - 1)];
		len = r.location - start - 1;

		r =  NSMakeRange(start, len);
		url = [[desc string] substringWithRange: r];
		if (url){  	//url will be nil if web site URL is malformed
			[desc addAttributes: urlAttributes range: r];
			[desc addAttribute: NSLinkAttributeName
					value: [NSURL URLWithString: url]
					range: r];
		}
}
	
	//look for e-mail url and if found turn it into an active link
	r = [[desc string] rangeOfString: @"Maintainer: "];
	if (r.length > 0){
		int fnend = r.location + r.length; 	//end of field name
		int start;							//start of mail url
		int len;							//length of mail url
		
		//look for angle bracket marking beginning of email address after Maintainer: field
		r = [[desc string] rangeOfString: @"<" options: 0 
							range: NSMakeRange(fnend, [[desc string] length] - fnend - 1)];
		start = r.length > 0 ? r.location + 1 : 0;  	//0 == start of mail address not found
		//look for angle bracket marking end of email address after start
		r = [[desc string] rangeOfString: @">" options: 0
							range: NSMakeRange(start, [[desc string] length] - start - 1)];
		len = r.length > 0 ? r.location - start : 0;  //0 == end of mail address not found

		//if start and end found, apply link attributes
		if (start > 0 && len > 0){
			r = NSMakeRange(start, len);
			url = [NSString stringWithFormat: @"mailto:%@",
						[[desc string] substringWithRange: r]];
			if (url){
				[desc addAttributes: urlAttributes range: r];
				[desc addAttribute: NSLinkAttributeName
							value: [NSURL URLWithString: url]
							range: r];
			}
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
						[NSColor colorWithDeviceCyan:1.0 magenta:1.0 yellow:0.0 black:0.3 alpha:1.0],				//dark blue
								NSForegroundColorAttributeName,  
						nil]] autorelease]];	
		
		[[textView textStorage] appendAttributedString:
			[self formatDescriptionString: [pkg fulldesc]]];
		[[textView textStorage] appendAttributedString:
			[[[NSMutableAttributedString alloc] initWithString: @"\n"] autorelease]];
	}
}

@end
