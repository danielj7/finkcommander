
#import "SBOutlineView.h"
#import "SBFileItem.h"

#define SB_COLUMNS [NSDictionary dictionaryWithObjectsAndKeys:	\
	@"Name", @"filename",										\
	@"Size", @"size",											\
	@"Modified", @"mdate",										\
	nil]

@implementation SBOutlineView

-(NSMutableArray *)tableColumnsForFrame:(NSRect)frame
{
	NSArray *columnKeys = [SB_COLUMNS allKeys];
	NSMutableArray *columnArray = [NSMutableArray array];
	NSEnumerator *e;
	NSString *identifier;
	float nameWidth = frame.size.width / 2.0;
	float otherWidth = nameWidth / ([[SB_COLUMNS allKeys] count]);
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
			[[newColumn headerCell] setAlignment:NSRightTextAlignment];
			[[newColumn dataCell] setAlignment:NSRightTextAlignment];
		}else{
			[[newColumn headerCell] setAlignment:NSLeftTextAlignment];
			[[newColumn dataCell] setAlignment:NSLeftTextAlignment];
		}
		if ([identifier isEqualToString:@"filename"]){
			[newColumn setWidth:nameWidth];
			[self setOutlineTableColumn:newColumn];
		}else{
			[newColumn setWidth:otherWidth];
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
	
	return newView;
}

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

@end
