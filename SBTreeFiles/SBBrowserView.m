/*
 File SBBrowserView.m

 See header file SBBrowserView.h for license and interface information.

*/
 
#import "SBBrowserView.h"

@implementation SBBrowserView

//----------------------------------------------------------
#pragma mark - OBJECT CREATION AND DESTRUCTION
//----------------------------------------------------------

-(instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (nil != self){
		[self setMatrixClass:[SBBrowserMatrix class]];
		[self setDelegate:self];
		[self setTarget:self];
		[self setDoubleAction:@selector(openSelectedFiles:)];
		[self setAllowsMultipleSelection:YES];
		[self setAllowsBranchSelection:NO];
		[self setReusesColumns:YES];
		[self setHasHorizontalScroller:YES];
		[self setTitled:NO];
	}
    return self;
}

-(void)dealloc
{
	Dprintf(@"Deallocating browser view");
}

//----------------------------------------------------------
#pragma mark - BROWSER DELEGATE METHODS
//----------------------------------------------------------

/* 	Let the browser know how many rows should be displayed for the
	next column so it knows how many times to send the next delegate
	message. */
-(NSInteger)browser:(NSBrowser *)sender
		numberOfRowsInColumn:(NSInteger)column
{
	NSBrowserCell *parentCell;
    SBFileItem *item;
	
    if (0 == column){ //We're at the root
		return 1;
	} 

	parentCell = [self selectedCellInColumn:column-1];
	item = [parentCell representedObject];
	//[self setTitle:[item path] ofColumn:column];
    return [item numberOfChildren];
}

-(void)browser:(NSBrowser *)sender 
		willDisplayCell:(id)cell
		atRow:(NSInteger)row
		column:(NSInteger)column
{
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    SBFileItem *item;
    NSImage *itemImage;
    NSBrowserCell *parentCell;

    if (0 == column){
		/* Put the root item in column 0. */
		item = [[self tree] rootItem];
    }else{
		/* 	The representedObject of the selected item in the parent column
			is the SBFileItem ancestor of the objects that will be represented
			in the child (i.e. new) column. */
		parentCell = [self selectedCellInColumn:column-1];
		item = (SBFileItem *)[[parentCell representedObject] childAtIndex:row];
    }
    //Cell should be a leaf rather than branch if represented object has no children
    [cell setLeaf:(nil == [item children])];
    /* 	Set the represented object for the new cell being displayed to the SBFileItem 
		derived above, so that the item's attributes can be accessed by this method when 
		the cell is selected.  */
    [cell setRepresentedObject:item];
    [cell setStringValue:[item filename]];
    //Set the image for the item to an appropriately sized version of the file icon
    itemImage = [ws iconForFile:[item path]];
    [itemImage setSize:NSMakeSize(16.0, 16.0)];
    [cell setImage:itemImage];
}

//----------------------------------------------------------
#pragma mark - ACTION METHOD(S)
//----------------------------------------------------------

-(IBAction)openSelectedFiles:(id)sender
{
    NSString *ipath;
    BOOL successful;
    NSMutableArray *inaccessiblePathsArray = [NSMutableArray array];

    for (NSBrowserCell *bCell in [self selectedCells]){
		ipath = [[bCell representedObject] path];  //SBFileItem represented in cell
		successful = openFileAtPath(ipath);
		if (! successful)[inaccessiblePathsArray addObject:ipath];
    }
    alertProblemPaths(inaccessiblePathsArray);
}

//----------------------------------------------------------
#pragma mark - VALIDATION
//----------------------------------------------------------

-(BOOL)validateItem:(id)theItem
{
	SEL itemAction = [theItem action];

    if (nil == [self selectedCell]){
		if (itemAction == @selector(openSelectedFiles:)){
			return NO;
		}
	}
	return YES;
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    return [self validateItem:menuItem];
}


//----------------------------------------------------------
#pragma mark - FILE DRAG AND DROP
//----------------------------------------------------------

//Allows drag and drop from the browser to other apps (including finder)
- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    switch (context) {
        case NSDraggingContextOutsideApplication:
            return NSDragOperationCopy;
            
        case NSDraggingContextWithinApplication:
        default:
            return NSDragOperationNone;
    }
}

-(BOOL)browser:(NSBrowser *)browser writeRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)column toPasteboard:(NSPasteboard *)pasteboard
{
    NSMutableArray *itemList = [[NSMutableArray alloc] init];
    SBFileItem *file;

    for (NSBrowserCell *theCell in [self selectedCells]){
        file = [theCell representedObject];
        [itemList addObject:[file URL]];
    }
    
    [pasteboard writeObjects:(NSArray*)itemList];
    return YES;
}

@end

