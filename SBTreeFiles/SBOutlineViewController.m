/*
 File SBOutlineViewController.m

 See header file SBOutlineViewController.h for license and interface information.

 */

#import "SBOutlineViewController.h"

@implementation SBOutlineViewController

//----------------------------------------------------------
#pragma mark OBJECT CREATION AND DESTRUCTION
//----------------------------------------------------------

-(id)initWithTree:(SBFileItemTree *)aTree
			 view:(NSOutlineView *)oView
{
	self = [super init];
	if (nil != self){
		NSTableColumn *aColumn;
		NSEnumerator *e; 

		outlineView = oView;  //retained by superview
		tree = [aTree retain];
		e = [[outlineView tableColumns] objectEnumerator];
		[self setPreviousColumnIdentifier:@"filename"];
		
		[outlineView setDelegate:self];
		[outlineView setDataSource:self];
		[outlineView setIntercellSpacing:NSMakeSize(4.0, 2.0)];
		[outlineView setTarget:outlineView];
		[outlineView setDoubleAction:@selector(openSelectedFiles:)];

		while (nil != (aColumn = [e nextObject])){
			[[aColumn headerCell] setTarget:self];
			[[aColumn headerCell] setAction:@selector(sortByColumn:)];
		}
		columnStateDictionary = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
			SBAscendingOrder, @"filename",
			SBAscendingOrder, @"size",
			SBAscendingOrder, @"mdate", nil] retain];
		[outlineView setHighlightedTableColumn:	
			[outlineView tableColumnWithIdentifier:@"filename"]];
	}
	return self;
}

-(void)dealloc
{
	Dprintf(@"Releasing outline view controller");
    [tree release];
	[previousColumnIdentifier release];
    [columnStateDictionary release];

    [super dealloc];
}

//----------------------------------------------------------
#pragma mark ACCESSORS
//----------------------------------------------------------

-(NSString *)previousColumnIdentifier { return previousColumnIdentifier; }

-(void)setPreviousColumnIdentifier:(NSString *)newPreviousColumnIdentifier{
	[newPreviousColumnIdentifier retain];
	[previousColumnIdentifier release];
	previousColumnIdentifier = newPreviousColumnIdentifier;
}

//----------------------------------------------------------
#pragma mark NSOUTLINEVIEW DATA SOURCE METHODS
//----------------------------------------------------------

-(int)outlineView:(NSOutlineView *)outlineView 
	numberOfChildrenOfItem:(id)item 
{
    return (nil == item) ? 1 : [item numberOfChildren];
}

-(BOOL)outlineView:(NSOutlineView *)outlineView 
  isItemExpandable:(id)item 
{
    return (nil == item) ? YES : ([item numberOfChildren] != -1);
}

-(id)outlineView:(NSOutlineView *)outlineView 
		   child:(int)index 
		  ofItem:(id)item 
{
    return (nil == item) ? [tree rootItem] : [item childAtIndex:index];
}

-(id)outlineView:(NSOutlineView *)outlineView 
	objectValueForTableColumn:(NSTableColumn *)tableColumn 
	byItem:(id)item 
{
    NSString *identifier = [tableColumn identifier];
    if ([identifier isEqualToString:@"size"]){
		unsigned long itemSize = (nil == item) 	? 
			[[[tree rootItem] valueForKey:identifier] unsignedLongValue] :
			[[item valueForKey:identifier] unsignedLongValue];
		itemSize = itemSize / 1024 + 1;
		return [NSString stringWithFormat:@"%u KB", itemSize];
    }
    return (nil == item) ? 
		(id)[[tree rootItem] valueForKey:identifier] : 
		(id)[item valueForKey:identifier];
}

//----------------------------------------------------------
#pragma mark NSOUTLINEVIEW DELEGATE METHOD(S)
//----------------------------------------------------------

- (void)outlineView:(NSOutlineView *)outlineView 
	willDisplayCell:(id)cell 
	forTableColumn:(NSTableColumn *)tableColumn 
	item:(id)item
{
	if ([[tableColumn identifier] isEqualToString:@"filename"]){
		NSImage *itemImage = [[NSWorkspace sharedWorkspace] 
			iconForFile:[item path]];
	
		[itemImage setSize:NSMakeSize(16.0, 16.0)];
		[cell setImage:itemImage];
	}
}

//----------------------------------------------------------
#pragma mark DRAG AND DROP
//----------------------------------------------------------

/* 	Create an array of path names for selected items. Copy
	the file list to the pasteboard.  */
-(BOOL)outlineView:(NSOutlineView *)ov 
	writeItems:(NSArray *)items
	toPasteboard:(NSPasteboard *)pboard
{
    NSArray *fileList = [NSArray array];
    SBFileItem *item;
    NSEnumerator *e = [items objectEnumerator];

	while (nil != (item = [e nextObject])){
		fileList = [fileList arrayByAddingObject:[item path]];
	}
	[ov registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
	[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType]
			owner:self];
	[pboard setPropertyList:fileList forType:NSFilenamesPboardType];
	return YES;
}

//----------------------------------------------------------
#pragma mark SORTING METHOD
//----------------------------------------------------------

- (BOOL)outlineView:(NSOutlineView *)theOutlineView
	shouldSelectTableColumn:(NSTableColumn *)tableColumn
{
    NSString *identifier = [tableColumn identifier]; 
    NSString *order;
    NSImage *triangle;
	
    [outlineView setIndicatorImage:nil 
			inTableColumn:[outlineView tableColumnWithIdentifier:[self previousColumnIdentifier]]];

    //If user clicks same column header twice in a row, change sort order
    if ([identifier isEqualToString:[self previousColumnIdentifier]]){
		order = [[columnStateDictionary objectForKey:identifier] isEqualToString:SBAscendingOrder]
			? SBDescendingOrder : SBAscendingOrder;
		//Record new state for next click on this column
		[columnStateDictionary setObject:order forKey:identifier];
		//Otherwise, return sort order to previous state for selected column
    }else{
		order = [columnStateDictionary objectForKey:identifier];
    }
    [self setPreviousColumnIdentifier:identifier];

    //Set appropriate indicator image in clicked column
    triangle = [order isEqualToString:SBAscendingOrder]   		?
		[NSImage imageNamed:@"NSAscendingSortIndicator"]   		:
		[NSImage imageNamed:@"NSDescendingSortIndicator"];
    [outlineView setIndicatorImage:triangle inTableColumn:tableColumn];

    [tree sortTreeByElement:identifier inOrder:order];
    [outlineView reloadItem:[tree rootItem] reloadChildren:YES];
	[outlineView setHighlightedTableColumn:tableColumn];
	return NO;
}

//----------------------------------------------------------
#pragma mark OUTLINE MANIPULATION
//----------------------------------------------------------

// NSOutline collapseItem:collapseChildren: appears not to work
-(void)collapseItemAndChildren:(SBFileItem *)item
{
	if (nil != [item children]){
		SBFileItem *child;
		NSEnumerator *e = [[item children] objectEnumerator];
		while (nil != (child = [e nextObject])){
			[self collapseItemAndChildren:child];
		}
	}
	[outlineView collapseItem:item];
}

@end


