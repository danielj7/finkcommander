/*
File: FinkTableViewController.m

See the header file, FinkTableViewController.h, for interface and license information.
*/

#import "FinkTableViewController.h"

@implementation FinkTableViewController

-(id)initWithFrame:(NSRect)rect
{
	defaults = [NSUserDefaults standardUserDefaults];

	if (self = [super initWithFrame: rect]){
		NSString *identifier;
		NSString *attribute;
		NSEnumerator *e = [[defaults objectForKey:FinkTableColumnsArray] objectEnumerator];
		NSEnumerator *f = [[defaults objectForKey:FinkPackageAttributes] objectEnumerator];

		while (identifier = [e nextObject]){
			[self addTableColumn:[self makeColumnWithName:identifier]];
		}
		[self setDelegate: self];
		[self setDataSource: self];
		[self setAutosaveName: @"FinkTableView"];
		[self setAutosaveTableColumns: YES];
		[self setAllowsMultipleSelection: YES];
		[self setAllowsColumnSelection: NO];

		[self setLastIdentifier: [defaults objectForKey: FinkSelectedColumnIdentifier]];
		reverseSortImage = [[NSImage imageNamed: @"reverse"] retain];
		normalSortImage = [[NSImage imageNamed: @"normal"] retain];
		// dictionary used to record whether table columns are sorted in normal or reverse order
		columnState = [[NSMutableDictionary alloc] init];
		while (attribute = [f nextObject]){
			[columnState setObject:@"normal" forKey:attribute];
		}
	}
	return self;
}

-(void)dealloc
{
	[displayedPackages release];
	[lastIdentifier release];
	[columnState release];
	[reverseSortImage release];
	[normalSortImage release];
	[selectedObjectInfo release];	
	[super dealloc];
}

//----------------------------------------------->Accessors
-(NSString *)lastIdentifier {return lastIdentifier;}
-(void)setLastIdentifier:(NSString *)s
{
	[s retain];
	[lastIdentifier release];
	lastIdentifier = s;
}

-(NSMutableArray *)displayedPackages {return displayedPackages;}
-(void)setDisplayedPackages:(NSMutableArray *)a
{
	[a retain];
	[displayedPackages release];
	displayedPackages = a;
}

-(NSArray *)selectedObjectInfo
{
    return selectedObjectInfo;
}

-(void)setSelectedObjectInfo:(NSArray *)array
{
    [array retain];
    [selectedObjectInfo release];
    selectedObjectInfo = array;
}

-(NSImage *)normalSortImage {return normalSortImage;}
-(NSImage *)reverseSortImage {return reverseSortImage;}

//not really an accessor
-(NSArray *)selectedPackageArray
{
	NSEnumerator *e = [self selectedRowEnumerator];
	NSNumber *anIndex;
	NSMutableArray *pkgArray = [NSMutableArray arrayWithCapacity: 5];

	while (anIndex = [e nextObject]){
		[pkgArray addObject:
			[[self displayedPackages] objectAtIndex: [anIndex intValue]]];
	}
	return pkgArray;
}

//----------------------------------------------->Copy

/*"        Copy the single selected row from the table.  The elements
are separated by tabs, as text, as well as tabular text (NSTabularTextPboardType).
"*/

-(void)copySelectedRows
{
	NSEnumerator *colEnum = [[self tableColumns] objectEnumerator];
	NSEnumerator *rowEnum = [self selectedRowEnumerator];
	NSMutableString	*theData = [NSMutableString string];
	NSNumber *theRowNum;
	NSTableColumn *theColumn;
	NSPasteboard *pb = [NSPasteboard generalPasteboard];

	// Write the header values
	while (nil != (theColumn = [colEnum nextObject])){
		[theData appendString:[theColumn identifier]];
		[theData appendString:@"\t"];
	}
	[theData appendString:@"\n"];

	while (nil != (theRowNum = [rowEnum nextObject])){
		colEnum = [[self tableColumns] objectEnumerator];

		while (nil != (theColumn = [colEnum nextObject])){
			id columnValue = [self tableView:self objectValueForTableColumn:theColumn
									row:[theRowNum intValue] ];
			NSString *columnString = @"";
			if (columnValue){
				columnString = [columnValue description];
			}
			[theData appendFormat:@"%@\t", columnString];
		}
		// delete the last tab.
		if ([theData length]){
			[theData deleteCharactersInRange:NSMakeRange([theData length] - 1, 1)];
		}
		[theData appendString:@"\n"];
	}

	[pb declareTypes: [NSArray arrayWithObjects:NSTabularTextPboardType, NSStringPboardType, nil]
						   owner:nil];
	[pb setString:[NSString stringWithString:theData]
			 forType:NSStringPboardType];
	[pb setString:[NSString stringWithString:theData]
			 forType:NSTabularTextPboardType];
}

-(IBAction)copy:(id)sender
{
	if ([self selectedRow] != -1){
		[self copySelectedRows];
	}
}

//not working!
-(BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	if ([menuItem action] == @selector(copy:) && [self selectedRow] == -1){
		return NO;
	}
	return YES;
}

//----------------------------------------------->Column Manipulation

-(NSTableColumn *)makeColumnWithName:(NSString *)identifier
{
	NSTableColumn *newColumn= 
		[[[NSTableColumn alloc] initWithIdentifier:identifier] autorelease];
	NSString *title = NSLocalizedString(identifier, nil);

	[[newColumn headerCell] setStringValue: title];
	[[newColumn headerCell] setAlignment: NSLeftTextAlignment];
	[newColumn setEditable:YES];
	return newColumn;
}

//called by View menu action method
-(void)addColumnWithName:(NSString *)identifier
{
	NSArray *columnNames = [defaults objectForKey: FinkTableColumnsArray];
	NSTableColumn *newColumn = [self makeColumnWithName: identifier];
	NSTableColumn *lastColumn = [[self tableColumns] lastObject];
	NSRect oldFrame = [[self window] frame];
	NSRect newFrame = NSMakeRect(oldFrame.origin.x, oldFrame.origin.y,
		oldFrame.size.width + 2, oldFrame.size.height);
	
	[lastColumn setWidth: [lastColumn width] * 0.5];
	[newColumn setWidth: [lastColumn width] * 0.5];	
	[self addTableColumn: newColumn];
	[[self window] setFrame:newFrame display:YES];
	[self sizeLastColumnToFit];

	columnNames = [columnNames arrayByAddingObject: identifier];
	[defaults setObject: columnNames forKey: FinkTableColumnsArray];
}

-(void)removeColumnWithName:(NSString *)identifier
{	
	NSArray *columns = [defaults objectForKey: FinkTableColumnsArray];
	NSMutableArray *reducedColumns = [[columns mutableCopy] autorelease];
	
	[self removeTableColumn: [self tableColumnWithIdentifier: identifier]];
	[self sizeLastColumnToFit];
	[reducedColumns removeObject: identifier];
	columns = reducedColumns;
	[defaults setObject:columns forKey:FinkTableColumnsArray];
}

//----------------------------------------------->Data Source Methods

-(int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[self displayedPackages] count];
}

-(id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
						  row:(int)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	FinkPackage *package = [[self displayedPackages] objectAtIndex: rowIndex];
	if ([identifier isEqualToString:@"status"]){
		return NSLocalizedString([package valueForKey: identifier], nil);
	}
	return [package valueForKey: identifier];
}

//------------------------------------------------->Sorting Methods

//The following two methods are used to scroll back to the previously selected row
//after the table is sorted.  It works almost the same way Mail does, except
//that only the latest selection is preserved.  For the filter, sorting and
//scrolling methods to work together, information on the selected object must
//be stored and then the rows must be deselected before the filter is applied
//and before the table is sorted.

//store information needed to scroll back to selection after filter/sort
-(void)storeSelectedObjectInfo
{
	FinkPackage *selectedObject;
    int selectionIndex = [self selectedRow];
	int topRowIndex =  [self rowAtPoint:
		[[self superview] bounds].origin];
	int offset = selectionIndex - topRowIndex;

	if (selectionIndex >= 0){
		selectedObject = [[self displayedPackages]
							objectAtIndex: selectionIndex];
		[self setSelectedObjectInfo:
			[NSArray arrayWithObjects:
				selectedObject,
				[NSNumber numberWithInt: offset],
				nil]];
		[self deselectAll: nil];
	}else{
		[self setSelectedObjectInfo: nil];
	}
}

//scroll back to selection after sort
-(void)scrollToSelectedObject
{
	if ([self selectedObjectInfo]){
		FinkPackage *selectedObject = [[self selectedObjectInfo] objectAtIndex: 0];
		int selection = [[self displayedPackages] indexOfObject: selectedObject];

		if (selection != NSNotFound){
			int offset = [[[self selectedObjectInfo] objectAtIndex: 1] intValue];
			NSPoint offsetRowOrigin = [self rectOfRow: selection - offset].origin;
			id contentView = [self superview];
			id tableScrollView = [contentView superview];
			NSPoint target = [contentView constrainScrollPoint: offsetRowOrigin];

			[contentView scrollToPoint: target];
			[tableScrollView reflectScrolledClipView: contentView];
			[self selectRow: selection byExtendingSelection: NO];
		}
	}
}

//basic sorting method
-(void)sortTableAtColumn:(NSTableColumn *)aTableColumn inDirection:(NSString *)direction
{
//	[[[self dataSource] displayedPackages] sortUsingSelector:
	[[self displayedPackages] sortUsingSelector:
		NSSelectorFromString([NSString stringWithFormat: @"%@CompareBy%@:", direction,
			[[aTableColumn identifier] capitalizedString]])]; // e.g. reverseCompareByName:
	[self reloadData];
}

//called by delegate method for filter text view in FinkController
-(void)resortTableAfterFilter
{
	NSTableColumn *lastColumn = [self tableColumnWithIdentifier:
		[self lastIdentifier]];
	NSString *direction = [columnState objectForKey: [self lastIdentifier]];

	[self sortTableAtColumn: lastColumn inDirection: direction];
}


//------------------------------------------------->Delegate Methods

-(void)tableView:(NSTableView *)aTableView
	didClickTableColumn:(NSTableColumn *)aTableColumn
{
	NSString *identifier = [aTableColumn identifier];
	NSTableColumn *lastColumn = [self tableColumnWithIdentifier:
		[self lastIdentifier]];
	NSString *direction;

	// remove sort direction indicator from last selected column
	[self setIndicatorImage: nil inTableColumn: lastColumn];

	// if user clicks same column header twice in a row, change sort order
	if ([aTableColumn isEqualTo: lastColumn]){
		direction = [[columnState objectForKey: identifier] isEqualToString: @"normal"]
						? @"reverse" : @"normal";
		//record new state for next click on this column
		[columnState setObject: direction forKey: identifier];
		// otherwise, return sort order to previous state for selected column
	}else{
		direction = [columnState objectForKey: identifier];
	}

	// record currently selected column's identifier for next call to method
	// and for future sessions
	[self setLastIdentifier: identifier];
	[defaults setObject: identifier forKey: FinkSelectedColumnIdentifier];

	// reset visual indicators
	if ([direction isEqualToString: @"reverse"]){
		[self setIndicatorImage: reverseSortImage
							 inTableColumn: aTableColumn];
	}else{
		[self setIndicatorImage: normalSortImage
							 inTableColumn: aTableColumn];
	}
	[self setHighlightedTableColumn: aTableColumn];

	//sort the table contents
	if ([defaults boolForKey: FinkScrollToSelection]){
		[self storeSelectedObjectInfo];
	}
	[self sortTableAtColumn: aTableColumn inDirection: direction];
	if ([defaults boolForKey: FinkScrollToSelection]){
		[self scrollToSelectedObject];
	}
}

-(BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	NSString *pname = [[[self displayedPackages] objectAtIndex: rowIndex] name];
	if ([pname contains:@"tcsh"]){
		NSBeginAlertSheet(NSLocalizedString(@"Sorry", nil),
					NSLocalizedString(@"OK", nil),
					nil,	nil,
					[self window], self, NULL,	NULL, nil,
					NSLocalizedString(@"UnableToInstallTcsh", nil),
					nil);
		return NO;
	}

	if ([pname contains:@"term-readkey-pm"]){
		NSBeginAlertSheet(NSLocalizedString(@"Caution", nil),
					NSLocalizedString(@"OK", nil),
					nil, nil,
					[self window], self, NULL,	NULL, nil,
					NSLocalizedString(@"UnableToInstallTerm-Readkey", nil),
					nil);
		return YES;
	}
	return YES;
}

//allows selection of table cells for copying, unlike setting the column to be non-editable
-(BOOL)textShouldBeginEditing:(NSText *)textObject
{
	return NO;
}

@end
 