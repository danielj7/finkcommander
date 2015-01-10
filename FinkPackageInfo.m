/*
 File: FinkPackageInfo.m

 See the header file, FinkPackageInfo.h, for interface and license information.

*/

#import "FinkPackageInfo.h"
#import "SBMutableAttributedString.h"

// Constants used to format text storage 
//medium gray
#define SHORTDESCCOLOR 		\
	[NSColor colorWithCalibratedHue:0.0 saturation:0.0 brightness:0.50 alpha:1.0]
//medium gray
#define VERSIONCOLOR 		\
	[NSColor colorWithCalibratedHue:0.0 saturation:0.0 brightness:0.40 alpha:1.0]
//dark green
#define URLCOLOR 			\
	[NSColor colorWithCalibratedHue:0.33 saturation:1.0 brightness:0.60 alpha:1.0]
//dark blue
#define HEADINGCOLOR 		\
	[NSColor colorWithCalibratedHue:0.67 saturation:1.0 brightness:0.60 alpha:1.0]

#define MAINHEADINGFONT [NSFont boldSystemFontOfSize:[NSFont systemFontSize]+2.0]

//Localized string used twice
#define LS_PACKAGE_INFO NSLocalizedString(@"Package Info", @"Window title")

@interface FinkPackageInfo ()

// FIXME: defaults isn't used
@property (nonatomic, readonly) NSUserDefaults *defaults;

@end

@implementation FinkPackageInfo

-(instancetype)init
{
	self = [super initWithWindowNibName:@"PackageInfo"];
	if (nil != self){
		_defaults = [NSUserDefaults standardUserDefaults];
		[[self window] setTitle:LS_PACKAGE_INFO];
		[self setEmailSig:@""];
		[self setWindowFrameAutosaveName: @"PackageInfo"];
	}
	return self;
}

-(void)awakeFromNib
{
	[self setTextView: [MyTextView myTextViewToReplace:[self textView] in:[self scrollView]]];
	[[[self textView] window] setDelegate:self];
}



//--------------------------------------------------------------->Email Methods

/* Used to set URL attribute for email addresses displayed by Package Inspector and
	in FinkController's emailMaintainer method */
-(NSURL *)mailURLForPackage:(FinkPackage *)pkg withBody:(NSString *)body
{ 
	return [[NSString stringWithFormat: 
						@"mailto:%@?subject=(Fink) %@-%@&body=%@\n\n%@", 
						[pkg email], [pkg name], [pkg version], body, [self emailSig]]
				URLByAddingPercentEscapesToString];
}

//--------------------------------------------------------------->Text Display Methods

/*	Add font attributes to headings and link attributes to urls; remove hard 
	returns within paragraphs to allow soft wrapping; attempt to preserve author's 
	list formatting */
-(NSAttributedString *)formattedDescriptionStringforPackage:(FinkPackage *)p
{
	NSString *s = [p fulldesc];
	NSEnumerator *lineEnumerator = [[s componentsSeparatedByString: @"\n"] objectEnumerator];
	NSArray *fields = @[@"Summary", @"Description",
								@"Usage Notes", @"Web site", @"Maintainer"];
	NSDictionary *urlAttributes = @{NSForegroundColorAttributeName: URLCOLOR,
									NSUnderlineStyleAttributeName: @(NSSingleUnderlineStyle)};
	NSMutableAttributedString *description = 	
			[[NSMutableAttributedString alloc]
					initWithString: @""
						   attributes: @{NSFontAttributeName: [NSFont systemFontOfSize:0]}];
	NSString *line;
	NSString *uri;
	NSRange r;	      //general purpose range variable
	
	[lineEnumerator nextObject];   //discard summary; already included
	//test second line for period or DescDetail
	line = [[lineEnumerator nextObject]  strip];
	if (! line) return description;
	if ([line isEqualToString: @"."]){ 		//change period to 2 newlines
		[description appendString: @"\n\n"];
	}else{									//add newlines before DescDetail
		[description appendString:[NSString stringWithFormat: @"\n\n%@ ", line]];
	}

	while (nil != (line = [lineEnumerator nextObject])){
		//remove linefeed within paragraphs to allow wrapping in text view
		line = [line strip];
		/* 	In fink descriptions, paragraph breaks are signified by a period. 
			At least one package description separates sections by double
			periods. */
		if ([line containsExpression: @"^[.]+$"]){
			if ([[description string] hasSuffix:@"\n"]){
				line = @"\n";
			}else{
				line = @"\n\n";
			}
		//If line begins with punctuation intended as a bullet, put the linefeed back
		}else{
			line = [NSString stringWithFormat: @"%@\n", line];
		}
		[description appendString:line];
	}
	
	//apply attributes to field names
	for (NSString *field in fields){
		r = [[description string] rangeOfString: field];
		if (r.length > 0){
			[description addAttribute: NSForegroundColorAttributeName 
				  value: HEADINGCOLOR 
				  range: r];
		}
	}
	
	//look for web url and if found turn it into an active link
	uri = [p weburl]; 
	if ([uri length] > 0){
		uri = [uri stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\""]];
		[p setWeburl: uri];
		r = [[description string] rangeOfString: uri];
		[description addAttributes: urlAttributes range: r];
		[description addAttribute: NSLinkAttributeName
							value: [NSURL URLWithString: uri]
							range: r];
	}
		
	//look for e-mail url and if found turn it into an active link
	if ([[p email] length] > 0){
		NSURL *murl = [self mailURLForPackage:p withBody:@""];
		r = [[description string] rangeOfString:[p email]];
		[description addAttributes:urlAttributes range:r];
		[description addAttribute:NSLinkAttributeName
				value:murl
				range:r];
	}
	return description;
}

//Add font attributes, spacing and newlines for various versions of package
-(NSAttributedString *)formattedVersionsForPackage:(FinkPackage *)pkg
{
	NSArray *versionNames = @[@"Installed", @"Unstable", @"Stable",
                              @"Binary"];
	NSString *vNumber;
	NSMutableAttributedString *description =
		[[NSMutableAttributedString alloc]
				initWithString: @""
				attributes: @{NSFontAttributeName: [NSFont systemFontOfSize:0]}];
	
	for (NSString *vName in versionNames){
		vNumber = [pkg valueForKey:[vName lowercaseString]];
		if ([vNumber length] < 2) vNumber = @"None";
		if ([vName length] < 8) vNumber = [NSString stringWithFormat: @"\t%@", vNumber];
		[description appendAttributedString:
			[[NSMutableAttributedString alloc]
					initWithString: [NSString stringWithFormat: @"\n%@:", vName]
					attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:0],
									NSForegroundColorAttributeName: HEADINGCOLOR}]];
		[description appendAttributedString:
			[[NSMutableAttributedString alloc]
				initWithString: [NSString stringWithFormat: @"\t%@", vNumber]
					attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:0],
									NSForegroundColorAttributeName: VERSIONCOLOR}]];
	}	
	return description;
}

-(void)displayDescriptions:(NSArray *)packages
{
	NSUInteger i, count = [packages count];
	FinkPackage *pkg;
	NSString *pname;
	NSString *psummary;

	[[[self textView] textStorage] beginEditing];

	[[self textView] setString: @""];
	for (i = 0; i < count; i++){
		pkg = packages[i];
		pname = [NSString stringWithFormat:@"%@\n", [pkg name]];
		psummary = [NSString stringWithFormat:@"%@\n", [pkg summary]];
		[[[self textView] textStorage] appendAttributedString:
			[[NSAttributedString alloc] 
					initWithString: pname
					attributes: @{NSFontAttributeName: MAINHEADINGFONT,
										NSForegroundColorAttributeName: HEADINGCOLOR}]];
		[[[self textView] textStorage] appendAttributedString:
			[[NSAttributedString alloc]
					initWithString: psummary
						attributes: @{NSFontAttributeName: [NSFont systemFontOfSize:0],
										NSForegroundColorAttributeName: SHORTDESCCOLOR}]];
		[[[self textView] textStorage] appendAttributedString:
			[self formattedVersionsForPackage:pkg]];
		[[[self textView] textStorage] appendAttributedString:
			[self formattedDescriptionStringforPackage: pkg]];
		if (i != count - 1){  			//just add one newline after last package
			[[[self textView] textStorage] appendString:@"\n\n\n"];
		}else{
			[[[self textView] textStorage] appendString:@"\n"];
		}
	}
	
	[[[self textView] textStorage] endEditing];
}


//--------------------------------------------------------------->NSWindow Delegate Methods

//Resize window when zoom button clicked
-(NSRect)windowWillUseStandardFrame:(NSWindow *)sender
		 defaultFrame:(NSRect)defaultFrame
{	
	CGFloat windowOffset = [[self window] frame].size.height
							- [[[self textView] superview] frame].size.height;
	CGFloat newHeight = [[self textView] frame].size.height;
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
	if ([[[n object] title] isEqualToString:LS_PACKAGE_INFO]){
		[[self textView] setString: @""];
	}
}

@end
