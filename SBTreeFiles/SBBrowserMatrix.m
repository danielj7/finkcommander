
#import "SBBrowserMatrix.h"

#define USE_MODIFIER

@implementation SBBrowserMatrix

-(void)setMyBrowser:(id)newBrowser
{
    myBrowser = newBrowser;  //Don't retain parent object!
}

#ifdef USE_MODIFIER

-(void)mouseDown:(NSEvent *)theEvent
{
    int flags = [theEvent modifierFlags];
	
    if (flags & NSAlternateKeyMask){
		[myBrowser mouseDown:theEvent];
    }else{
		[super mouseDown:theEvent];
    }
}
#else

-(void)mouseDown:(NSEvent *)theEvent
{
	int row;
	int col;
	BOOL inMatrix;
	NSPoint clickPoint = [theEvent locationInWindow];
	NSBrowserCell *selectedCell;
	
	clickPoint = [self convertPoint:clickPoint fromView:nil];
	inMatrix = [self getRow:&row column:&col forPoint:clickPoint];
	NSLog(@"Click received in row %d, column %d of matrix", row, col);
	[self selectCellAtRow:row column:col];
	selectedCell = [self selectedCell];
	[selectedCell set];
	[myBrowser mouseDown:theEvent];
}

#endif

@end
