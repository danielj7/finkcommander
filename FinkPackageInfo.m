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
	[[textView window] setDelegate: self];
}


//--------------------------------------------------------------->Email Methods

-(void)setEmailSig:(NSString *)s
{
	[s retain];
	[emailSig release];
	emailSig = s;
}

-(NSString *)formattedEmailSig
{
	NSMutableArray *m = [NSMutableArray array];
	NSEnumerator *e;
	NSString *line;
	NSString *sig;

	if ([defaults boolForKey: FinkGiveEmailCredit]){
		sig = [NSString stringWithFormat:
			@"--\n%@Feedback Courtesy of FinkCommander\n", emailSig];
	}else{
		sig = [NSString stringWithFormat: @"--\n%@", emailSig];
	}
	e = [[sig componentsSeparatedByString: @"\n"] objectEnumerator];
	while (line = [e nextObject]){
		line = [[line componentsSeparatedByString: @" "] componentsJoinedByString: @"%20"];
		[m addObject: line];
	}
	sig = [m componentsJoinedByString: @"%0A"];
	sig = [ @"&body=%0A%0A" stringByAppendingString: sig];
	return sig;
}

//probb more consistent with MVC to move this back to FinkController
-(void)sendEmailForPackage:(FinkPackage *)pkg
{
	NSMutableString *url = [NSMutableString
			stringWithFormat: @"mailto:%@?subject=%@%@", [pkg email], [pkg name],
		[self formattedEmailSig]];

	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: url]];
}

//--------------------------------------------------------------->Text Display Methods


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
	NSMutableAttributedString *desc = 
		[[[NSMutableAttributedString alloc]
				initWithString: [NSString stringWithFormat: @":\n%@", 
									[e nextObject]] //Desc
				attributes: [NSDictionary dictionaryWithObjectsAndKeys:
					[NSFont systemFontOfSize: 0], NSFontAttributeName,
					[NSColor darkGrayColor], NSForegroundColorAttributeName,
					nil]] autorelease];

	//test second line for period or DescDetail
	line = [[e nextObject]  strip];
	if (! line) return desc;
	if ([line isEqualToString: @"."]){ 		//change period to 2 newlines
		[desc appendAttributedString:
			[[[NSMutableAttributedString alloc] initWithString: @"\n\n"] autorelease]];
	}else{									//add newlines before DescDetail
		[desc appendAttributedString:
			[[[NSMutableAttributedString alloc]
					initWithString: [NSString stringWithFormat: @"\n\n%@ ", line]]
			autorelease]];
	}

	while (line = [e nextObject]){
		//remove linefeed within paragraphs to allow wrapping in text view
		line = [line strip];
		//in fink descriptions, paragraph breaks are signified by a period
		if ([line isEqualToString: @"."]){
			if ([[desc string] hasSuffix:@"\n"]){
				line = @"\n";
			}else{
				line = @"\n\n";
			}
		//if line begins with punctuation intended as a bullet, put the linefeed back
		}else if ([line hasPrefix:@"-"] || [line hasPrefix:@"*"] || [line hasPrefix:@"o "]){
			line = [NSString stringWithFormat: @"%@\n", line];
			if (! [[desc string] hasSuffix: @"\n"]){
				line = [NSString stringWithFormat: @"\n%@", line];
			}
		}else{
			line = [NSString stringWithFormat: @"%@ ", line]; 
		}
		[desc appendAttributedString:
			[[[NSMutableAttributedString alloc] initWithString: line] autorelease]];
	}
	
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
		NSMutableString *mailurl = [NSMutableString 
			stringWithFormat: @"mailto:%@?subject=%@%@", [p email], [p name],
				[self formattedEmailSig]];
		
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
	int i, count = [packages count];
	FinkPackage *pkg;
	NSString *nameVersion;

	[textView setString: @""];

	for (i = 0; i < count; i++){
		pkg = [packages objectAtIndex: i];
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
		if (i != count - 1){  			//don't add newlines after last package
			[[textView textStorage] appendAttributedString:
				[[[NSMutableAttributedString alloc] initWithString: @"\n\n"] autorelease]];
		}
	}
}


//--------------------------------------------------------------->NSWindow Delegate Methods

//Resize window when zoom button clicked
-(NSRect)windowWillUseStandardFrame:(NSWindow *)sender
		 defaultFrame:(NSRect)defaultFrame
{	
	float windowOffset = [[self window] frame].size.height 
							- [[textView superview] frame].size.height;
	float newHeight = [textView frame].size.height;	
	NSRect stdFrame = 
		[NSWindow contentRectForFrameRect:[sender frame] 
							 styleMask:[sender styleMask]];

	if (newHeight > stdFrame.size.height) {newHeight += windowOffset;}
							 
	stdFrame.origin.y += stdFrame.size.height;
	stdFrame.origin.y -= newHeight;
	stdFrame.size.height = newHeight;

	stdFrame = 
		[NSWindow frameRectForContentRect:stdFrame 
							 styleMask:[sender styleMask]];
							 
	//if new height would exceed default frame height,
	//zoom vertically and horizontally
	if (stdFrame.size.height > defaultFrame.size.height){
		stdFrame = defaultFrame;
	//otherwise zoom vertically just enough to accomodate new height
	}else if (stdFrame.origin.y < defaultFrame.origin.y){
		stdFrame.origin.y = defaultFrame.origin.y;
	}

	return stdFrame;
}

//Prevent last selection from appearing when panel reopens
-(void)windowWillClose:(NSNotification *)n
{
	[textView setString: @""];  
}

@end
