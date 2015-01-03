/*
File: FinkTableView.m

See the header file, FinkTableView.h, for interface and license information.
*/

#import "FinkTableView.h"

//----------------------------------------------------------
#pragma mark - MACROS AND CONSTANTS
//----------------------------------------------------------

//Column widths
#define MAX_FLAG_WIDTH 30.0
#define MAX_STATUS_WIDTH 90.0
#define MAX_CATEGORY_WIDTH 90.0
// #define MAX_NAME_WIDTH 200.0
#define MAX_VERSION_WIDTH 130.0

#define IS_VERSION_IDENTIFIER(id) 							\
	[(id) isEqualToString:@"version"]	||					\
	[(id) isEqualToString:@"stable"]	||					\
	[(id) isEqualToString:@"unstable"]	||					\
	[(id) isEqualToString:@"binary"]	||					\
	[(id) isEqualToString:@"installed"]

//Tags for "File:Open .info" and "File:Open .patch" items in MainMenu.nib
typedef NS_ENUM(NSInteger, FinkFileType) {
    FINKINFO =  101,
    FINKPATCH = 102
};

@interface FinkTableView ()

@property (nonatomic) NSUserDefaults *defaults;
@property (nonatomic) NSMutableDictionary *columnState;

@end

@implementation FinkTableView

//----------------------------------------------------------
#pragma mark - CREATION AND DESTRUCTION
//----------------------------------------------------------

-(instancetype)initWithFrame:(NSRect)rect
{
	_defaults = [NSUserDefaults standardUserDefaults];

	if ((self = [super initWithFrame: rect])){
		for (NSString *identifier in [_defaults objectForKey:FinkTableColumnsArray]){
			[self addTableColumn:[self makeColumnWithName:identifier]];
		}
		[self setDelegate: self];
		[self setDataSource: self];
		[self setAutosaveName: @"FinkTableView"];
		[self setAutosaveTableColumns: YES];
		[self setAllowsMultipleSelection: YES];
		[self setAllowsColumnSelection: NO];
		[self setVerticalMotionCanBeginDrag:NO];
		[self setTarget:self];
		[self setDoubleAction:@selector(openPackageFiles:)];
		[self setUsesAlternatingRowBackgroundColors:YES];

		[self setLastIdentifier: [_defaults objectForKey: FinkSelectedColumnIdentifier]];
		_reverseSortImage = [NSImage imageNamed: @"reverse"];
		_normalSortImage = [NSImage imageNamed: @"normal"];
		// dictionary used to record whether table columns are sorted in normal or reverse order
		_columnState = [[_defaults objectForKey:FinkColumnStateDictionary] mutableCopy];
	}
	return self;
}


//----------------------------------------------------------
#pragma mark - ACCESSORS
//----------------------------------------------------------

-(NSArray *)selectedPackageArray
{
	NSMutableArray *pkgArray = [NSMutableArray arrayWithCapacity: 5];

    [[self selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        [pkgArray addObject:
         [self displayedPackages][idx]];
    }];
	return pkgArray;
}

//----------------------------------------------------------
#pragma mark - ACTION
//----------------------------------------------------------

/* Open the info or patch file or both for selected packages. */
-(IBAction)openPackageFiles:(id)sender
{
    //Accumulates paths for files that could not be opened
    NSMutableArray *problemPaths = [NSMutableArray array];
    NSString *path, *tree;
    NSInteger senderTag = [sender tag];
    //YES if user double-clicked the package name in the table
	BOOL shouldOpenBoth = senderTag != FINKINFO && senderTag != FINKPATCH;
    BOOL fileWasOpened;

	Dprintf(@"Sender tag in openPackageFiles: %d", senderTag);

    for (FinkPackage *pkg in [self selectedPackageArray]){
		if ([[pkg unstable] length] > 1) {
			tree = @"unstable";
		} else {
			if ([[pkg stable] length] > 1) {
				tree = @"stable";
			} else {
				tree = @"local";
			}
		}
		if (senderTag == FINKPATCH){
			path = [pkg pathToPackageInTree:tree withExtension:@"patch"];
		}else{
			path = [pkg pathToPackageInTree:tree withExtension:@"info"];
		}
		fileWasOpened = openFileAtPath(path);
		if (! fileWasOpened) [problemPaths addObject:path];
		if (shouldOpenBoth){
			path = [pkg pathToPackageInTree:tree withExtension:@"patch"];
			/* 	We won't check the return value here.  Some packages
				don't have patch files.  Letting the user know when the
				info file could not be opened is sufficient if the user
				chose to open both by double-clicking.  */
			openFileAtPath(path);
		}
    }
    alertProblemPaths(problemPaths);
}

//----------------------------------------------------------
#pragma mark - VALIDATION
//----------------------------------------------------------

-(BOOL)validateItem:(id)theItem
{
	SEL itemAction = [theItem action];
	
    if ([self selectedRow] == -1){
		if (itemAction == @selector(openPackageFiles:) 	||
			itemAction == @selector(copy:)){
			return NO;
		}
	}
	return YES;
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    return [self validateItem: menuItem];
}

//----------------------------------------------------------
#pragma mark - COPY
//----------------------------------------------------------

/* 	Copy the single selected row from the table.  The elements
	are separated by tabs, as text, as well as tabular text 
	(NSTabularTextPboardType). */

-(void)copySelectedRows
{
	NSMutableString	*theData = [NSMutableString string];
	NSPasteboard *pb = [NSPasteboard generalPasteboard];

	// Write the header values
    for (NSTableColumn *theColumn in [self tableColumns]){
		[theData appendString:[theColumn identifier]];
		[theData appendString:@"\t"];
	}
	[theData appendString:@"\n"];

    [[self selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        for (NSTableColumn *theColumn in [self tableColumns]){
            id columnValue = [self tableView:self objectValueForTableColumn:theColumn
                                         row:idx];
            NSString *columnString = @"";
            if ([columnValue isKindOfClass:[NSImage class]] && nil != columnValue){
                columnString = @"YES";
            }else if (nil != columnValue){
                columnString = [columnValue description];
            }else{
                columnString = @"NO";
            }
            [theData appendFormat:@"%@\t", columnString];
        }
        // delete the last tab.
        if ([theData length]){
            [theData deleteCharactersInRange:NSMakeRange([theData length] - 1, 1)];
        }
        [theData appendString:@"\n"];
    }];

	[pb declareTypes: @[NSTabularTextPboardType, 
		NSStringPboardType] owner:nil];
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

//----------------------------------------------------------
#pragma mark - FILE DRAG AND DROP
//----------------------------------------------------------

-(BOOL)tableView:(NSTableView *)tview
	writeRowsWithIndexes:(NSIndexSet *)rows
	toPasteboard:(NSPasteboard *)pboard
{
	NSArray * __block fileList = @[];
	NSFileManager *manager = [NSFileManager defaultManager];

	[rows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
		FinkPackage *pkg = [self displayedPackages][idx];
        NSString *tree;
        NSString *path;
		if ([[pkg unstable] length] > 1){
			tree = @"unstable";
		}else{
			tree = @"stable";
		}
		path = [pkg pathToPackageInTree:tree
					withExtension:@"patch"];
		if ([manager fileExistsAtPath:path]){
			fileList = [fileList arrayByAddingObject:path];
		}
		path = [pkg pathToPackageInTree:tree
					withExtension:@"info"];
		if ([manager fileExistsAtPath:path]){
			fileList = [fileList arrayByAddingObject:path];
		}		
    }];
	[tview registerForDraggedTypes:@[NSFilenamesPboardType]];
	[pboard declareTypes:@[NSFilenamesPboardType]
								  owner:self];
	[pboard setPropertyList:fileList forType:NSFilenamesPboardType];
	return YES;
}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent *)dragEvent offset:(NSPointPointer)dragImageOffset
{
    NSImage *dragImage = [NSImage imageNamed:@"info"];
    
    dragImageOffset->y += [dragImage size].height / 3.5;
    
    return dragImage;
    
}

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

//----------------------------------------------------------
#pragma mark - COLUMN MANIPULATION
//----------------------------------------------------------

-(NSTableColumn *)makeColumnWithName:(NSString *)identifier
{
	NSTableColumn *newColumn = 
		[[NSTableColumn alloc] initWithIdentifier:identifier];
	NSString *title = [[NSBundle mainBundle] localizedStringForKey:identifier
											 value:identifier
											 table:@"Programmatic"];

	if ([identifier isEqualToString:@"flagged"]){
		NSImageCell *dataCell = [[NSImageCell alloc] initImageCell:nil];
		[newColumn setDataCell:dataCell];
		[[newColumn headerCell] setImage:[NSImage imageNamed:@"header_flag"]];
		[newColumn setMaxWidth:MAX_FLAG_WIDTH];
	}else{
		NSCell *dataCell = [[NSCell alloc] initTextCell:@""];
		[newColumn setDataCell:dataCell];
		[[newColumn headerCell] setStringValue: title];
		[[newColumn headerCell] setAlignment: NSLeftTextAlignment];
		if ([identifier isEqualToString:@"status"]){
			[newColumn setMaxWidth:MAX_STATUS_WIDTH];
		}else if ([identifier isEqualToString:@"category"]){
			[newColumn setMaxWidth:MAX_CATEGORY_WIDTH];
		}else if (IS_VERSION_IDENTIFIER(identifier)){
			[newColumn setMaxWidth:MAX_VERSION_WIDTH];
		}
	}
	//Allow double click to open .info file
	if ([identifier isEqualToString:@"name"]){
		[newColumn setEditable:NO];
	}else{
		[newColumn setEditable:YES];
	}
	return newColumn;
}

//Sent by View menu action method
-(void)addColumnWithName:(NSString *)identifier
{
	NSArray *columnNames = [[self defaults] objectForKey: FinkTableColumnsArray];
	NSTableColumn *newColumn = [self makeColumnWithName: identifier];
	NSTableColumn *lastColumn = [[self tableColumns] lastObject];
	NSRect oldFrame = [[self window] frame];
	NSRect newFrame = NSMakeRect(oldFrame.origin.x, oldFrame.origin.y,
		oldFrame.size.width + 2, oldFrame.size.height);
		
	[newColumn setWidth: MIN([newColumn maxWidth], [lastColumn width] *0.5)];
	[lastColumn setWidth: MIN([lastColumn maxWidth], 
							  [lastColumn width] - [newColumn width])];

	[self addTableColumn: newColumn];
	[[self window] setFrame:newFrame display:YES];
	[self sizeLastColumnToFit];

	columnNames = [columnNames arrayByAddingObject: identifier];
	[[self defaults] setObject: columnNames forKey: FinkTableColumnsArray];
}

-(void)removeColumnWithName:(NSString *)identifier
{	
	NSArray *columns = [[self defaults] objectForKey: FinkTableColumnsArray];
	NSMutableArray *reducedColumns = [columns mutableCopy];
	
	[self removeTableColumn: [self tableColumnWithIdentifier: identifier]];
	[self sizeLastColumnToFit];
	[reducedColumns removeObject: identifier];
	columns = reducedColumns;
	[[self defaults] setObject:columns forKey:FinkTableColumnsArray];
}

//----------------------------------------------------------
#pragma mark - DATA SOURCE METHODS
//----------------------------------------------------------

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[self displayedPackages] count];
}

-(id)tableView:(NSTableView *)aTableView
	objectValueForTableColumn:(NSTableColumn *)aTableColumn
	row:(NSInteger)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	FinkPackage *package = [self displayedPackages][rowIndex];
	if ([identifier isEqualToString:@"status"]){
		NSString *pkgStatus = [package status];
		return [[NSBundle mainBundle] localizedStringForKey:pkgStatus
									  value:pkgStatus
									  table:@"Programmatic"];
	}
	if ([identifier isEqualToString:@"flagged"]){
		int flag = [[package valueForKey:identifier] intValue];
		if (flag == 1) return [NSImage imageNamed:@"flag"];
		return nil;
	}
	return [package valueForKey:identifier];
}

//----------------------------------------------------------
#pragma mark - SORTING
//----------------------------------------------------------

/* 	The following two methods are used to scroll back to the previously selected row
	after the table is sorted.  It works almost the same way Mail does, except
	that only the latest selection is preserved.  For the filter, sorting and
	scrolling methods to work together, information on the selected object must
	be stored and then the rows must be deselected before the filter is applied
	and before the table is sorted. */

//Store information needed to scroll back to selection after filter/sort
-(void)storeSelectedObjectInfo
{
	FinkPackage *selectedObject;
    NSInteger selectionIndex = [self selectedRow];
	NSInteger topRowIndex =  [self rowAtPoint:
		[[self superview] bounds].origin];
	NSInteger offset = selectionIndex - topRowIndex;

	if (selectionIndex >= 0){
		selectedObject = [self displayedPackages][selectionIndex];
		[self setSelectedObjectInfo:
			@[selectedObject,
				@(offset)]];
		[self deselectAll: nil];
	}else{
		[self setSelectedObjectInfo: nil];
	}
}

//Scroll back to selection after sort
-(void)scrollToSelectedObject
{
	if ([self selectedObjectInfo]){
		FinkPackage *selectedObject = [self selectedObjectInfo][0];
		NSInteger selection = [[self displayedPackages] indexOfObject: selectedObject];

		if (selection != NSNotFound){
			int offset = [[self selectedObjectInfo][1] intValue];
			NSPoint offsetRowOrigin = [self rectOfRow: selection - offset].origin;
			id contentView = [self superview];
			id tableScrollView = [contentView superview];
			NSPoint target = [contentView constrainScrollPoint: offsetRowOrigin];

			[contentView scrollToPoint: target];
			[tableScrollView reflectScrolledClipView: contentView];
            [self selectRowIndexes:[NSIndexSet indexSetWithIndex:selection] byExtendingSelection:NO];
		}
	}
}

//Basic sorting method
-(void)sortTableAtColumn:(NSTableColumn *)aTableColumn inDirection:(NSString *)direction
{
	NSString *columnName = [aTableColumn identifier];
	NSArray *newArray;
	
	if (!columnName){
		NSLog(@"Unable to sort; no identifier for table column: %@", aTableColumn);
		[self reloadData];
		return;
	}
	
	newArray = [[self displayedPackages] sortedArrayUsingSelector:
					NSSelectorFromString([NSString stringWithFormat: @"%@CompareBy%@:", direction,
			[columnName capitalizedString]])]; // e.g. reverseCompareByName:
	[self setDisplayedPackages:newArray];
	[self reloadData];
}

//Sent by delegate method for filter text view in FinkController
-(void)resortTableAfterFilter
{
	NSTableColumn *lastColumn = [self tableColumnWithIdentifier:
		[self lastIdentifier]];
	NSString *direction = [self columnState][[self lastIdentifier]];

	[self sortTableAtColumn: lastColumn inDirection: direction];
}


//----------------------------------------------------------
#pragma mark - DELEGATE METHODS
//----------------------------------------------------------

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
		direction = [[self columnState][identifier] isEqualToString: @"normal"]
						? @"reverse" : @"normal";
		//record new state for next click on this column
		[self columnState][identifier] = direction;
		[[self defaults] setObject:[[self columnState] copy]
				  forKey:FinkColumnStateDictionary];
		// otherwise, return sort order to previous state for selected column
	}else{
		direction = [self columnState][identifier];
	}

	// record currently selected column's identifier for next call to method
	// and for future sessions
	[self setLastIdentifier: identifier];
	[[self defaults] setObject: identifier forKey: FinkSelectedColumnIdentifier];

	// reset visual indicators
	if ([direction isEqualToString: @"reverse"]){
		[self setIndicatorImage: [self reverseSortImage]
							 inTableColumn: aTableColumn];
	}else{
		[self setIndicatorImage: [self normalSortImage]
							 inTableColumn: aTableColumn];
	}
	[self setHighlightedTableColumn: aTableColumn];

	// sort the table contents
	if ([[self defaults] boolForKey: FinkScrollToSelection]){
		[self storeSelectedObjectInfo];
	}
	[self sortTableAtColumn: aTableColumn inDirection: direction];
	if ([[self defaults] boolForKey: FinkScrollToSelection]){
		[self scrollToSelectedObject];
	}
}

-(BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	NSString *pname = [[self displayedPackages][rowIndex] name];
	if ([pname contains:@"tcsh"] 				|| 
		[pname contains:@"term-readkey-pm"]){
		NSBeginAlertSheet(LS_WARNING,
					LS_OK,
					nil, nil,
					[self window], self, NULL,	NULL, nil,
					[NSString stringWithFormat:NSLocalizedString(@"FinkCommander is unable to install %@ from source.  Please install the binary or use the Source:Run in Terminal menu command to install %@.", @"Alert sheet message"), pname, pname],
					nil);
	}
	return YES;
}

-(BOOL)textShouldBeginEditing:(NSText *)textObject
{
	return NO;
}

@end
 