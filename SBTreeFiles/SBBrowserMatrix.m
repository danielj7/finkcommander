/*
 File SBBrowserMatrix.m

 See header file SBBrowserView.h for license and interface information.

 */
 
#import "SBBrowserMatrix.h"

#define USE_MODIFIER 1
 
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
		NSArray *selectedCellCache = [self selectedCells];
		NSCell *clickedCell;
		NSPoint clickPoint = [theEvent locationInWindow];
		int arow, acol;

		clickPoint = [self convertPoint:clickPoint fromView:nil];
		[self getRow:&arow column:&acol forPoint:clickPoint];
		clickedCell = [self cellAtRow:arow column:acol];
		/* 	If user option-clicks in previously selected area, drag 
			selection. */		
		if ([selectedCellCache containsObject:clickedCell]){
			NSEnumerator *e = [selectedCellCache objectEnumerator];
			NSCell *theCell;
			int brow, bcol;
				
			while (nil != (theCell = [e nextObject])){
				[self getRow:&brow column:&bcol ofCell:theCell];
				[self setSelectionFrom:brow to:brow anchor:brow highlight:YES];
			}
		}else{
			[self selectCellAtRow:arow column:acol];
		}
		[myBrowser mouseDown:theEvent];
    }else{
		[super mouseDown:theEvent];
    }
}

#else
/* 	Alternative version used to try to find a way to do drag and drop
	without a modifier key while retaining browser functionality */
-(void)mouseDown:(NSEvent *)theEvent
{
	int row;
	int col;
	BOOL inMatrix;
	NSPoint clickPoint = [theEvent locationInWindow];
	
	clickPoint = [self convertPoint:clickPoint fromView:nil];
	inMatrix = [self getRow:&row column:&col forPoint:clickPoint];
	[self selectCellAtRow:row column:col];
	[myBrowser selectRow:row inColumn:col];
	[myBrowser mouseDown:theEvent];
}

#endif

@end
