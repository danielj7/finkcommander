/*
File: FinkTextViewController.m

 See the header file, FinkTextViewController.h, for interface and license information.

*/

#import "FinkTextViewController.h"

@implementation FinkTextViewController

//override parent method
-(void)setString:(NSString *)aString
{
	lines = 0;
	bufferLimit = [[NSUserDefaults standardUserDefaults] integerForKey:FinkBufferLimit];
	[super setString:aString];
}

-(int)numberOfLinesInString:(NSString *)s
{
	NSScanner *lineScanner = [NSScanner scannerWithString:s];
	NSCharacterSet *returnSet = [NSCharacterSet characterSetWithCharactersInString: @"\n"];
	int numlines = 0;
	
	while (! [lineScanner isAtEnd]){
		[lineScanner scanUpToCharactersFromSet:returnSet intoString:NULL];
		[lineScanner scanString:@"\n" intoString:NULL];
		numlines++;
	}
	return numlines;
}

-(NSRange)rangeOfLinesAtTopOfView:(int)numlines
{
	NSString *viewString = [self string];
	int i, test;
	int lastReturn = 0;
	
	for (i = 0; i < numlines; i++){
		test = [viewString rangeOfString:@"\n"
					options:0
					range:NSMakeRange(lastReturn + 1, [viewString length] - lastReturn - 1)].location;
		if (test == NSNotFound) break;
		lastReturn = test;
	}
	return NSMakeRange(0, lastReturn);
}


-(void)appendString:(NSString *)s
{
	if (bufferLimit > 0){
		int overflow;
		NSRange r;
			
		lines += [self numberOfLinesInString:s];
		overflow = lines - bufferLimit;
		if (overflow > 10){
			r = [self rangeOfLinesAtTopOfView:overflow];		
			[[self textStorage] deleteCharactersInRange:r];
			lines = 0;
		}
	}
	
	[[self textStorage] appendAttributedString:
		[[[NSAttributedString alloc] initWithString: s] autorelease]];
}

@end
