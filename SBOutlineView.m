
#import "SBOutlineView.h"

#define SB_COLUMNS [NSDictionary dictionaryWithObjectsAndKeys:	\
	@"Name", @"filename",										\
	@"Size", @"size",											\
	@"Modified", @"mdate",										\
	nil]

@implementation SBOutlineView

//----------------------------------------------------------
#pragma mark CREATION
//----------------------------------------------------------

//Helper
-(NSMutableArray *)tableColumnsForFrame:(NSRect)frame
{
	NSArray *columnKeys = [SB_COLUMNS allKeys];
	NSMutableArray *columnArray = [NSMutableArray array];
	NSEnumerator *e;
	NSString *identifier;
	float nameWidth = frame.size.width / 2.0;
	float sizeWidth = nameWidth / 4.0;
	float mdateWidth = frame.size.width - nameWidth - sizeWidth;
	columnKeys = [columnKeys
            sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	e = [columnKeys objectEnumerator];
	while (nil != (identifier = [e nextObject])){
		NSTableColumn *newColumn = [[[NSTableColumn alloc]
										initWithIdentifier:identifier]
			autorelease];
		NSString *title = NSLocalizedStringFromTable([SB_COLUMNS
                                    objectForKey:identifier],
											   @"Programmatic", nil);
		[[newColumn headerCell] setStringValue:title];
		[newColumn setEditable:NO];
		if ([identifier isEqualToString:@"size"]){
			[newColumn setWidth:sizeWidth];
			[[newColumn headerCell] setAlignment:NSRightTextAlignment];
			[[newColumn dataCell] setAlignment:NSRightTextAlignment];
		}else{
			if ([identifier isEqualToString:@"filename"]){
				[newColumn setWidth:nameWidth];
				[self setOutlineTableColumn:newColumn];
			}else{
				[newColumn setWidth:mdateWidth];
			}
			[[newColumn headerCell] setAlignment:NSLeftTextAlignment];
			[[newColumn dataCell] setAlignment:NSLeftTextAlignment];
		}
		[columnArray addObject:newColumn];
	}
	return columnArray;
}
	
+(id)substituteForOutlineView:(NSOutlineView *)oldView
{
	SBOutlineView *newView = [[[SBOutlineView alloc] 
								initWithFrame:[oldView frame]] autorelease];
	NSEnumerator *e = [[newView tableColumnsForFrame:[oldView frame]] 
							objectEnumerator];
	NSTableColumn *column;
	
	while (nil != (column = [e nextObject])){
		[newView addTableColumn:column];
	}
	[newView moveColumn:2 toColumn:1];

	[newView setAutoresizingMask:[oldView autoresizingMask]];
	[newView setAutosaveTableColumns:[oldView autosaveTableColumns]];
	[newView setAllowsMultipleSelection:[oldView allowsMultipleSelection]];
	[newView setAllowsColumnSelection:[oldView allowsColumnSelection]];
	[newView setAllowsColumnReordering:[oldView allowsColumnReordering]];
	[newView setAllowsColumnResizing :[oldView allowsColumnReordering]];
	[newView setAutoresizesOutlineColumn:NO];
	[newView setVerticalMotionCanBeginDrag:NO];
	
	return newView;
}

//----------------------------------------------------------
#pragma mark DRAG AND DROP
//----------------------------------------------------------
//Allow dragging items outside outline view
-(unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    return NSDragOperationCopy;
}

- (NSImage *)dragImageForRows:(NSArray *)dragRows
			event:(NSEvent *)dragEvent
			dragImageOffset:(NSPointPointer)dragImageOffset
{
	SBFileItem *dragItem = [self itemAtRow:[[dragRows lastObject] intValue]];
	NSImage *dragImage = [[NSWorkspace sharedWorkspace]
							iconForFile:[dragItem path]];
	
	return dragImage;
}

//----------------------------------------------------------
#pragma mark ACTION(S)
//----------------------------------------------------------

-(IBAction)openSelectedFiles:(id)sender
{
    NSEnumerator *e = [self selectedRowEnumerator];
    NSNumber *rownum;
    NSString *ipath;
    BOOL successful;
    NSMutableArray *inaccessiblePathsArray = [NSMutableArray array];

    while (nil != (rownum = [e nextObject])){
		ipath = [[self itemAtRow:[rownum intValue]] path];
		successful = openFileAtPath(ipath);
		if (! successful){
			[inaccessiblePathsArray addObject:ipath];
		}
    }
    alertProblemPaths(inaccessiblePathsArray);
}

@end
