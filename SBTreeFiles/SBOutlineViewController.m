
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
		NSEnumerator *e = [[outlineView tableColumns] objectEnumerator];

		outlineView = oView; //Retained when nib opens
		tree = [aTree retain];
		[self setPreviousColumnIdentifier:@"filename"];
		
		[outlineView setDelegate:self];
		[outlineView setDataSource:self];
		[outlineView setTarget:self];
		[outlineView setDoubleAction:@selector(openSelectedFiles:)];


		while (nil != (aColumn = [e nextObject])){
			[[aColumn headerCell] setTarget:self];
			[[aColumn headerCell] setAction:@selector(sortByColumn:)];
		}

		columnStateDictionary = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
			SBAscendingOrder, @"filename",
			SBAscendingOrder, @"size",
			SBAscendingOrder, @"mdate", nil] retain];
	}
	return self;
}

-(void)dealloc
{
    [tree release];
	[previousColumnIdentifier release];
    [columnStateDictionary release];

    [super dealloc];
}

-(NSString *)previousColumnIdentifier { return previousColumnIdentifier; }

-(void)setPreviousColumnIdentifier:(NSString *)newPreviousColumnIdentifier{
	[newPreviousColumnIdentifier retain];
	[previousColumnIdentifier release];
	previousColumnIdentifier = newPreviousColumnIdentifier;
}

//----------------------------------------------------------
#pragma mark NSOUTLINE DATA SOURCE METHODS
//----------------------------------------------------------

//TRY CHANGING RETURN VALUE FOR ITEM == NIL TO ROOTITEM CHILDREN

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
		unsigned long itemSize = (nil == item) ? 
		[[[tree rootItem] valueForKey:identifier] unsignedLongValue]:
		[[item valueForKey:identifier] unsignedLongValue];
		itemSize = itemSize / 1024 + 1;
		return [NSString stringWithFormat:@"%u KB", itemSize];
    }
    return (nil == item) ? 
		(id)[[tree rootItem] valueForKey:identifier] : 
		(id)[item valueForKey:identifier];
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
	return NO;
}

//----------------------------------------------------------
#pragma mark ACTION(S)
//----------------------------------------------------------

-(IBAction)openSelectedFiles:(id)sender
{
    NSEnumerator *e = [outlineView selectedRowEnumerator];
    NSNumber *rownum;
    SBFileItem *item;
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSString *stnddpath;
    BOOL successful;
    NSMutableArray *problemFiles = [NSMutableArray array];

    while (nil != (rownum = [e nextObject])){
		item = [outlineView itemAtRow:[rownum intValue]];
		if (nil != [item children]) continue;  //skip directories
		stnddpath = [item path];  //now standardized when item created
		if ([stnddpath hasSuffix:@".html"]){
			NSURL *fileURL = [NSURL fileURLWithPath:stnddpath];
			successful = [ws openURL:fileURL];
		}else{
			//TBD:  Allow user to specify preferred application
			successful = [ws openFile:stnddpath withApplication:@"TextEdit"];
		}
		if (! successful){
			[problemFiles addObject:stnddpath];
		}
    }
    if ([problemFiles count] > 0){
		NSRunAlertPanel(@"Error",
				  @"The following could not be opened:\n\n%@",
				  @"OK", nil, nil, 
				  [problemFiles componentsJoinedByString:@" "]);
    }
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


