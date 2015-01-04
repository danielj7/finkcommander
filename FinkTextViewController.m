/*
File: FinkTextViewController.m

 See the header file, FinkTextViewController.h, for interface and license information.

*/

#import "FinkTextViewController.h"

@interface FinkTextViewController ()

@property (nonatomic) NSInteger lines;
@property (nonatomic) NSInteger bufferLimit;
@property (nonatomic) NSInteger minDelete;

@end

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
	[self setLines: 0];
	[self setBufferLimit: [[NSUserDefaults standardUserDefaults] integerForKey:FinkBufferLimit]];
	[self setMinDelete: (NSInteger)([self bufferLimit] * 0.10)];
	if ([self minDelete] < 10) [self setMinDelete: 10];	
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

	if ([self bufferLimit] > 0){
		NSInteger overflow;
			
        [self setLines: [self lines] + [self numberOfLinesInString:s]];
		overflow = [self lines] - [self bufferLimit];
		
		if (overflow > [self minDelete]){
			NSRange r = [self rangeOfLinesAtTopOfView:overflow];			
			[[self textView] replaceCharactersInRange:r withString:@""];
            [self setLines: [self lines] - overflow];
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
