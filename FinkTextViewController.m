/*
File: FinkTextViewController.m

 See the header file, FinkTextViewController.h, for interface and license information.

*/

#import "FinkTextViewController.h"

@implementation FinkTextViewController

-(instancetype)initWithView:(NSTextView *)aTextView 
	 forScrollView:(NSScrollView *)aScrollView
{
	if ((self = [super init])){
		[self setTextView:aTextView];
		[self setScrollView:aScrollView];
		[_textView setDelegate:self];
		[_textView setFont:[NSFont userFixedPitchFontOfSize:0.0]];
	}
	return self;
}


-(void)setLimits
{
	lines = 0;
	bufferLimit = [[NSUserDefaults standardUserDefaults] integerForKey:FinkBufferLimit];
	minDelete = (NSInteger)(bufferLimit * 0.10);
	if (minDelete < 10) minDelete = 10;	
}

-(NSUInteger)numberOfLinesInString:(NSString *)s
{
 	return [[s componentsSeparatedByString:@"\n"] count] - 1;
}

-(NSRange)rangeOfLinesAtTopOfView:(NSInteger)numlines
{
	NSString *viewString = [[self textView] string];
	NSInteger i;
	NSInteger test;
	NSInteger lastReturn = 0;
	
	for (i = 0; i < numlines; i++){
		test = 
			[viewString rangeOfString:@"\n"
				options:0
				range:NSMakeRange(lastReturn + 1, 
									[viewString length] - lastReturn - 1)].location;
		if (test == NSNotFound) break;
		lastReturn = test;
	}
	return NSMakeRange(0, lastReturn);
}

-(void)appendString:(NSString *)s
{
	[[[self textView] textStorage] beginEditing];

	if (bufferLimit > 0){
		NSInteger overflow;
			
		lines += [self numberOfLinesInString:s];
		overflow = lines - bufferLimit;
		
		if (overflow > minDelete){
			NSRange r = [self rangeOfLinesAtTopOfView:overflow];			
			[[self textView] replaceCharactersInRange:r withString:@""];
			lines -= overflow;
		}
	}
	[[self textView] replaceCharactersInRange:NSMakeRange([[[self textView] string] length], 0)
		withString:s];
		
	[[[self textView] textStorage] endEditing];
}

-(void)replaceLastLineByString:(NSString *)s
{
	// if the string consists of more lines than it's invalid for dynamic output
	if (([self numberOfLinesInString:s] > 0) || (([[s componentsSeparatedByString:@"\r"] count] - 1) > 1)) {
		return;
	}
	[[[self textView] textStorage] beginEditing];
	[[self textView] replaceCharactersInRange:NSMakeRange([[[self textView] string] length] - [s length], [s length])
		withString:s];
	[[[self textView] textStorage] endEditing];
}

@end
