/*
 File SBBrowserMatrix.m

 See header file SBBrowserView.h for license and interface information.

 */
 
#import "SBBrowserMatrix.h"
 
@implementation SBBrowserMatrix

-(void)setMyBrowser:(id)newBrowser
{
    myBrowser = newBrowser;  //Don't retain parent object!
}

-(void)mouseDown:(NSEvent *)theEvent
{	
	NSEventModifierFlags eventMask = [theEvent modifierFlags];
	if (eventMask & (NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask)){
		[super mouseDown:theEvent];
		return;
	}
	/* 	After mouse down, if the next event is mouse up, then perform the normal
		NSBrowserMatrix behavior.  I.e. select the cell receiving the click and if
		the cell is a branch, send the delegate methods to populate the next column.
		If the next event is mouse dragged, then drag the clicked item, plus any 
		other items that had previously been part of the same selection. */
	theEvent = [[self window] nextEventMatchingMask:
				NSLeftMouseUpMask | NSLeftMouseDraggedMask];
	if ([theEvent type] == NSLeftMouseDragged){
		NSArray *selectedCellCache = [self selectedCells];
		NSCell *clickedCell;
		NSPoint clickPoint = [theEvent locationInWindow];
		NSInteger arow, acol;

		clickPoint = [self convertPoint:clickPoint fromView:nil];
		[self getRow:&arow column:&acol forPoint:clickPoint];
		clickedCell = [self cellAtRow:arow column:acol];
		// 	If user clicks in previously selected area, drag selection.
		if ([selectedCellCache containsObject:clickedCell]){
			NSInteger brow, bcol;

			for (NSCell *theCell in selectedCellCache){
				[self getRow:&brow column:&bcol ofCell:theCell];
				[self setSelectionFrom:brow to:brow anchor:brow highlight:YES];
			}
		// O/w select new cell and drag that
		}else{
			[self selectCellAtRow:arow column:acol];
		}		
		[myBrowser mouseDragged:theEvent];
	}else{
		[super mouseDown:theEvent];
	}
}

@end
