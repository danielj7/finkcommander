
#import "SBBrowserView.h"

@implementation SBBrowserView

//----------------------------------------------------------
#pragma mark OBJECT CREATION AND DESTRUCTION
//----------------------------------------------------------

-(id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (nil != self){
		[self setDelegate:self];
		[self setTarget:self];
		[self setDoubleAction:@selector(openSelectedFiles:)];
		[self setAllowsMultipleSelection:YES];
		[self setAllowsBranchSelection:NO];
		[self setMatrixClass:[SBBrowserMatrix class]];
		[self setReusesColumns:YES];
		[self setHasHorizontalScroller:YES];
    }
    return self;
}

//----------------------------------------------------------
#pragma mark ACCESSORS
//----------------------------------------------------------

-(SBFileItemTree *)tree
{
    return tree;
}

-(void)setTree:(SBFileItemTree *)newTree
{
    [newTree retain];
    [tree release];
    tree = newTree;
	[self setTitle:[[tree rootItem] path] ofColumn:0];
}

//----------------------------------------------------------
#pragma mark BROWSER DELEGATE METHODS
//----------------------------------------------------------

/* Let the browser know how many rows should be displayed for the
next column so it knows how many times to send the next delegate
message. */
-(int)browser:(NSBrowser *)sender
		numberOfRowsInColumn:(int)column
{
	NSBrowserCell *parentCell;
    SBFileItem *item;
	
    if (0 == column) return [[tree rootItem] numberOfChildren];

	parentCell = [self selectedCellInColumn:column-1];
	item = [parentCell representedObject];
	[self setTitle:[item path] ofColumn:column];
    return [item numberOfChildren];
}

-(void)browser:(NSBrowser *)sender 
		willDisplayCell:(id)cell
		atRow:(int)row
		column:(int)column
{
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    SBFileItem *item;
    NSImage *itemImage;
    NSBrowserCell *parentCell;

    if (0 == column){
		/* Fill the first column (index 0) with the children of the root item. */
		item = [[tree rootItem] childAtIndex:row];
    }else{
		/* The representedObject of the selected item in the parent column
		is the SBFileItem ancestor of the objects that will be represented
		in the child (i.e. new) column. */
		parentCell = [self selectedCellInColumn:column-1];
		item = [[parentCell representedObject] childAtIndex:row];
    }
    //Cell should be a leaf rather than branch if represented object has no children
    [cell setLeaf:(nil == [item children])];
    /* Set the represented object for the current cell to the SBFileItem derived
		above, so that its attributes can be accessed by SBBrowserView methods.  */
    [cell setRepresentedObject:item];
    [cell setStringValue:[item filename]];
    //Set the image for the item to an appropriately sized version of the file icon
    itemImage = [ws iconForFile:[item path]];
    [itemImage setSize:NSMakeSize(16.0, 16.0)];
    [cell setImage:itemImage];
}

//ALTERNATIVE DELEGATE METHOD TO DISPLAY MORE DETAIL ABOUT AN
//ITEM IN THE LAST COLUMN
#ifdef UNDEF
-(void)browser:(NSBrowser *)sender 
    willDisplayCell:(id)cell
		 atRow:(int)row
		column:(int)column
{
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    SBFileItem *pitem;
    SBFileItem *citem = nil;
    NSImage *itemImage;
    NSBrowserCell *parentCell;

    if (0 == column){
		/* Fill the first column (index 0) with the children of the root item. */
		item = [[tree rootItem] childAtIndex:row];
    }else{
		/* The representedObject of the selected item in the parent column
		is the SBFileItem ancestor of the objects that will be represented
		in the child column. */
		parentCell = [self selectedCellInColumn:column-1];
		pitem = [parentCell representedObject];
		if (nil != [pitem children]){
			citem = [pitem childAtIndex:row];
		}
    }
    if (nil == citem){
		/* The pitem is a leaf on the tree.  Display its attributes in next
		column over as in the finder column view. */
		//ADJUST CELL DISPLAY HERE
		[cell setLeaf:YES];
		[cell setStringValue:[pitem description]]; //TEMPORARY
    }else{
		[cell setLeaf:NO];
		[cell setStringValue:[citem filename]];
		[cell setRepresentedObject:citem];
    }

    //Set the image for the item to an appropriately sized version of the file icon
    itemImage = [ws iconForFile:[citem path]];
    [itemImage setSize:NSMakeSize(16.0, 16.0)];
    [cell setImage:itemImage];
}
#endif

//----------------------------------------------------------
#pragma mark ACTION METHOD(S)
//----------------------------------------------------------

-(IBAction)openSelectedFiles:(id)sender
{
    NSEnumerator *e = [[self selectedCells] objectEnumerator];
    NSBrowserCell *bCell;
    NSString *ipath;
    BOOL successful;
    NSMutableArray *inaccessiblePathsArray = [NSMutableArray array];

    while (nil != (bCell = [e nextObject])){
		ipath = [[bCell representedObject] path];  //SBFileItem represented in cell
		Dprintf(@"Path to selection = %@", ipath);
		successful = openFileAtPath(ipath);
		if (! successful)[inaccessiblePathsArray addObject:ipath];
    }
    alertProblemPaths(inaccessiblePathsArray);
}

//----------------------------------------------------------
#pragma mark FILE DRAG AND DROP
//----------------------------------------------------------

-(unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    return NSDragOperationCopy; 
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    NSImage *dragImage;
	NSSize imageSize;
    NSPoint dragPosition;
    NSArray *fileList = [NSArray array];
	NSBrowserCell *theCell;
    SBFileItem *item;
    NSEnumerator *cellEnum = [[self selectedCells] objectEnumerator];

	while (nil != (theCell = [cellEnum nextObject])){
		item = [theCell representedObject];
		fileList = [fileList arrayByAddingObject:[item path]];
	}

	[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType]
			owner:self];
	[pboard setPropertyList:fileList forType:NSFilenamesPboardType];
	
	dragImage = [[NSWorkspace sharedWorkspace]
			iconForFile:[fileList objectAtIndex:0]];
	dragPosition = [self convertPoint:[theEvent locationInWindow]
											fromView:nil];
	imageSize = [dragImage size];
	dragPosition.x -= imageSize.width/2.0;
	dragPosition.y -= imageSize.height/2.0;
	[self dragImage:dragImage
		  at:dragPosition
		  offset:NSZeroSize
		  event:theEvent
		  pasteboard:pboard
		  source:self
		  slideBack:YES];
}

@end

