/*
 File SBOutlineView.m

 See header file SBOutlineView.h for license and interface information.

 */
 
#import "SBOutlineView.h"

#define SB_COLUMNS [NSDictionary dictionaryWithObjectsAndKeys:	\
	@"Name", @"filename",										\
	@"Size", @"size",											\
	@"Modified", @"mdate",										\
	nil]
	
#define MAX_DATE_WIDTH 280
#define MAX_SIZE_WIDTH 80

@interface SBOutlineView ()

// These initializers are private and should never be called.
// They must be overridden, however, since they're designated
// initializers of the super class.

- (instancetype)initWithFrame:(NSRect)frameRect;
- (instancetype)initWithCoder:(NSCoder *)coder;

@end

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
	CGFloat nameWidth = frame.size.width / 2.0;
	CGFloat sizeWidth = nameWidth / 4.0;
	CGFloat mdateWidth = frame.size.width - nameWidth - sizeWidth;
	
	columnKeys = [columnKeys
            sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	e = [columnKeys objectEnumerator];
	while (nil != (identifier = [e nextObject])){
		NSTableColumn *newColumn = [[NSTableColumn alloc]
										initWithIdentifier:identifier];
		NSString *title = SB_COLUMNS[identifier];
		title = [[NSBundle mainBundle] localizedStringForKey:title
										value:title
										table:@"Programmatic"];
		[[newColumn headerCell] setStringValue:title];
		[newColumn setEditable:NO];
		if ([identifier isEqualToString:@"size"]){
			[newColumn setWidth:sizeWidth];
			[newColumn setMaxWidth:MAX_SIZE_WIDTH];
			[[newColumn headerCell] setAlignment:NSRightTextAlignment];
			[[newColumn dataCell] setAlignment:NSRightTextAlignment];
		}else{
			if ([identifier isEqualToString:@"filename"]){
				NSBrowserCell *fileNameCell = [[SBBrowserCell alloc] init];
				[newColumn setDataCell:fileNameCell];
				[newColumn setWidth:nameWidth];
				[self setOutlineTableColumn:newColumn];
			}else{
				[newColumn setWidth:mdateWidth];
				[newColumn setMaxWidth:MAX_DATE_WIDTH];
			}
			[[newColumn headerCell] setAlignment:NSLeftTextAlignment];
			[[newColumn dataCell] setAlignment:NSLeftTextAlignment];
		}
		[columnArray addObject:newColumn];
	}
	return columnArray;
}

-(instancetype)initAsSubstituteForOutlineView:(NSOutlineView *)oldView
{
	self = [super initWithFrame:[oldView frame]];
	if (self != nil){
		NSEnumerator *e = [[self tableColumnsForFrame:[oldView frame]]
			objectEnumerator];
		NSTableColumn *column;

		while (nil != (column = [e nextObject])){
			[self addTableColumn:column];
		}
		[self moveColumn:2 toColumn:1];
		[self setAutoresizingMask:[oldView autoresizingMask]];
		[self setAutosaveTableColumns:[oldView autosaveTableColumns]];
		[self setAllowsMultipleSelection:[oldView allowsMultipleSelection]];
		[self setAllowsColumnSelection:[oldView allowsColumnSelection]];
		[self setAllowsColumnReordering:[oldView allowsColumnReordering]];
		[self setAllowsColumnResizing :[oldView allowsColumnReordering]];
		[self setAutoresizesOutlineColumn:NO];
		[self setColumnAutoresizingStyle:NSTableViewNoColumnAutoresizing];
		[self setVerticalMotionCanBeginDrag:NO];
	}
	return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [self initAsSubstituteForOutlineView:[[NSOutlineView alloc] initWithFrame:frameRect]];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [self initAsSubstituteForOutlineView:[[NSOutlineView alloc] initWithCoder:coder]];
    return self;
}

//----------------------------------------------------------
#pragma mark ACTION(S)
//----------------------------------------------------------

-(IBAction)openSelectedFiles:(id)sender
{
    NSMutableArray *inaccessiblePathsArray = [NSMutableArray array];

    [[self selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        BOOL successful;
        NSString *ipath = [[self itemAtRow:idx] path];
        
        successful = openFileAtPath(ipath);
        if (! successful){
            [inaccessiblePathsArray addObject:ipath];
        }
    }];
    alertProblemPaths(inaccessiblePathsArray);
}

//----------------------------------------------------------
#pragma mark VALIDATION
//----------------------------------------------------------

-(BOOL)validateItem:(id)theItem
{
	SEL itemAction = [theItem action];

    if ([self selectedRow] == -1){
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

@end
