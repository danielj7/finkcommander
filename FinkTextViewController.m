/*
File: FinkTextViewController.m

 See the header file, FinkTextViewController.h, for interface and license information.

*/

#import "FinkTextViewController.h"

@implementation FinkTextViewController

-(id)initWithView:(NSTextView *)aTextView 
	 forScrollView:(NSScrollView *)aScrollView
{
	if (self = [super init]){
		[self setTextView:aTextView];
		[self setScrollView:aScrollView];
		[textView setDelegate:self];
	}
	return self;
}

-(void)dealloc
{
	[textView release];
	[scrollView release];
	
	[super dealloc];
}

- (NSTextView *)textView { return textView; }

- (void)setTextView:(NSTextView *)newTextView 
{
	[newTextView retain];
	[textView release];
	textView = newTextView;
}

- (NSScrollView *)scrollView { return scrollView; }

- (void)setScrollView:(NSScrollView *)newScrollView
{
	[newScrollView retain];
	[scrollView release];
	scrollView = newScrollView;
}

-(void)setLimits
{
	lines = 0;
	bufferLimit = [[NSUserDefaults standardUserDefaults] integerForKey:FinkBufferLimit];
	minDelete = bufferLimit * 0.10;
	if (minDelete < 10) minDelete = 10;	
}

-(int)numberOfLinesInString:(NSString *)s
{
 	return [[s componentsSeparatedByString:@"\n"] count] - 1;
}

-(NSRange)rangeOfLinesAtTopOfView:(int)numlines
{
	NSString *viewString = [textView string];
	int i, test;
	int lastReturn = 0;
	
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
	[[textView textStorage] beginEditing];

	if (bufferLimit > 0){
		int overflow;
			
		lines += [self numberOfLinesInString:s];
		overflow = lines - bufferLimit;
		
		if (overflow > minDelete){
			NSRange r = [self rangeOfLinesAtTopOfView:overflow];			
			[textView replaceCharactersInRange:r withString:@""];
			lines -= overflow;
		}
	}
	[textView replaceCharactersInRange:NSMakeRange([[textView string] length], 0)
		withString:s];
		
	[[textView textStorage] endEditing];
}


@end
