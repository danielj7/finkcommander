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
	minDelete = bufferLimit * 0.10;
	if (minDelete < 10) minDelete = 10;

	NSLog(@"Buffer limit = %d; min delete = %d", bufferLimit, minDelete);
	
	[super setString:aString];
}

-(int)numberOfLinesInString:(NSString *)s
{
	NSArray *slines = [s componentsSeparatedByString:@"\n"];
	int numlines = [slines count];
	
	return numlines - 1;
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
		
		if (lines > bufferLimit) NSLog(@"%d", lines);
		
		overflow = lines - bufferLimit;
		if (overflow > minDelete){
			r = [self rangeOfLinesAtTopOfView:overflow];
			[[self textStorage] deleteCharactersInRange:r];
			lines -= overflow;
		}
	}
	
	[[self textStorage] appendAttributedString:
		[[[NSAttributedString alloc] initWithString: s] autorelease]];
}

@end
