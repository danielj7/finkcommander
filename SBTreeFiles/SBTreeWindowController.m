/*
 File SBTreeWindowController.m

 See header file SBTreeWindowController.h for license and interface information.

 */

#import "SBTreeWindowController.h"
#import "FinkController.h"

//Constants matching tags in selection matrix
typedef NS_ENUM(NSInteger, FinkTreeViewType) {
	SB_BROWSER = 0,
	SB_OUTLINE = 1
};

//Other constants

#define MEGABYTE	   1048576.0
#define KILOBYTE		  1024.0

#define THREE_COLUMN_WIDTH 525.0
#define FOUR_COLUMN_WIDTH  700.0
#define FIVE_COLUMN_WIDTH  875.0

#define CLICK_THROUGH_GAP    5.0

//Localized strings

#define BYTE_FORMAT NSLocalizedStringFromTable(@"%u items, %.0f b", @"SBTree", 		\
											   "Formatter for browser window")
#define KILOBYTE_FORMAT NSLocalizedStringFromTable(@"%u items, %.1f KB", @"SBTree", \
												   "Formatter for browser window")
#define MEGABYTE_FORMAT NSLocalizedStringFromTable(@"%u items, %.1f MB", @"SBTree", \
												   "Formatter for browser window")

@interface SBTreeWindowController ()

@property (nonatomic) SBFileItemTree *sbTree;
@property (nonatomic) SBOutlineViewController *oController;
@property (nonatomic) SBBrowserView *sbBrowser;
@property (nonatomic) SBDateColumnController *mDateColumnController;
// FIXME: not used
@property (nonatomic, copy) NSMutableArray *fileList;
// FIXME: not used
@property (nonatomic, copy) NSString *activeView;
@property (nonatomic, getter=isTreeBuildingThreadFinished) BOOL treeBuildingThreadFinished;

@end

@implementation SBTreeWindowController

//----------------------------------------------------------
#pragma mark - ACCESSORS
//----------------------------------------------------------

-(NSWindow *)window { return [self sbTreeWindow]; }

//----------------------------------------------------------
#pragma mark - OBJECT CREATION
//----------------------------------------------------------

/*	Helper for designated initializer.  Replaces NSOutlineView and NSBrowser
	created in nib file with custom objects.  Sets up SBDateColumnController and
	SBOutlineViewController objects.  */
-(void)setupViews
{
    NSTableColumn *mdateColumn;
    NSRect browserFrame = [[self oldBrowser] frame];
	NSView *browserSuperview = [[self oldBrowser] superview];

	/* Set up the custom outline view */
	[self setOutlineView: [[SBOutlineView alloc] 
					initAsSubstituteForOutlineView:[self outlineView]]];  //RC == 1
	[[self outlineScrollView] setDocumentView:[self outlineView]];              //RC == 2
	   									                          //RC == 1
	[[self outlineView] sizeLastColumnToFit];

	/* Set up the outline view controller */
    [self setOController: [[SBOutlineViewController alloc] initWithTree:[self sbTree]
													view:[self outlineView]]];

	/* Set up the controller for the date column */
	mdateColumn = [[self outlineView] tableColumnWithIdentifier:@"mdate"];
    [self setMDateColumnController:
		[[SBDateColumnController alloc]
		initWithColumn:mdateColumn
			shortTitle:@"Modified"
			longTitle:@"Date Modified"]];
    [[self outlineView] setIndicatorImage: [NSImage imageNamed:@"NSAscendingSortIndicator"]
				inTableColumn:[[self outlineView] tableColumnWithIdentifier:@"filename"]];

	/* Substitute SBBrowserView with drag and drop for nib version */
    [self setSbBrowser: [[SBBrowserView alloc] initWithFrame:browserFrame]];
	[[self sbBrowser] setAutoresizingMask:[[self oldBrowser] autoresizingMask]];
	[[self sbBrowser] setMaxVisibleColumns:[[self oldBrowser] maxVisibleColumns]];
	[[self oldBrowser] removeFromSuperview];
	[browserSuperview addSubview:[self sbBrowser]];
    [[self sbBrowser] setTree:[self sbTree]];
	
	[[self loadingIndicator] setStyle:NSProgressIndicatorSpinningStyle];
	[[self loadingIndicator] setDisplayedWhenStopped:NO];
}

-(instancetype)initWithFileList:(NSMutableArray *)fList
{
    return [self initWithFileList:fList 
			windowName:@"File Tree Viewer"];
}

/*	Designated initializer */
-(instancetype)initWithFileList:(NSMutableArray *)fList
		   windowName:(NSString *)wName
{
    self = [super init];
    if (nil != self){
	
		_sbTree = [[SBFileItemTree alloc] initWithFileArray:fList name:wName];
		/*	Building the file tree can take some time; run in a separate
			thread to avoid tying up the rest of the app */
		_treeBuildingThreadFinished = NO;
		[NSThread detachNewThreadSelector:@selector(buildTreeFromFileList:)
									toTarget:_sbTree
								  withObject:fList];		

		[[NSBundle mainBundle] loadNibNamed:@"TreeView" owner:self topLevelObjects:nil];
		
		Dprintf(@"Window name should be: %@", wName);

		[[self window] setTitle:wName];
		[[self window] setReleasedWhenClosed:YES];
		[self setupViews];

		[[self window] makeKeyAndOrderFront:self];
		
		[[self loadingIndicator] setUsesThreadedAnimation:YES];
		[[self loadingIndicator] startAnimation:self];
		[self setActiveView:@"outline"];

		[[NSDistributedNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(finishedLoading:)
			name:@"SBTreeCompleteNotification"
			object:[[self window] title]
			suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
	}
    return self;
}

//----------------------------------------------------------
#pragma mark - OBJECT DESTRUCTION
//----------------------------------------------------------

-(BOOL)windowShouldClose:(id)sender
{
	if (! [self isTreeBuildingThreadFinished]){
		NSBeep();
		return NO;
	}
    [[self oController] collapseItemAndChildren:[[self sbTree] rootItem]];
    return YES;
}

-(void)windowWillClose:(NSNotification *)n
{
	[NSApp sendAction:@selector(treeWindowWillClose:) to:nil from:self];
}

-(void)dealloc
{
	Dprintf(@"Deallocating controller for window %@", [[self window] title]);

    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	
	[self setActiveView:nil];
	
}

//----------------------------------------------------------
#pragma mark - ACTIONS
//----------------------------------------------------------

-(IBAction)switchViews:(id)sender
{	
	FinkTreeViewType selection = [[sender selectedCell] tag];
	NSString *identifier;
	switch (selection){
		case SB_BROWSER:
			identifier = @"browser";
			break;

        case SB_OUTLINE:
		default:
			identifier = @"outline";
			break;
	}
	[[self tabView] selectTabViewItemWithIdentifier:identifier];
    [self setActiveView:identifier];
}

//----------------------------------------------------------
#pragma mark - UI UPDATING
//----------------------------------------------------------

-(void)finishedLoading:(NSNotification *)n
{
	[self setTreeBuildingThreadFinished: YES];
    if (nil == [[self sbTree] rootItem]){
		[[self msgTextField] setStringValue:@"Error:  No such package installed"];
    }else{
		double size = (float)[[self sbTree] totalSize];
		NSString *formatString = BYTE_FORMAT;
		if (size > MEGABYTE){
			size /= MEGABYTE;
			formatString = MEGABYTE_FORMAT;
		}else if (size > KILOBYTE){
			size /= KILOBYTE;
			formatString = KILOBYTE_FORMAT;
		}
		[[self msgTextField] setStringValue:
			[NSString stringWithFormat:formatString,
				[[self sbTree] itemCount], size]];
    }
    [[self outlineView] reloadItem:[[self sbTree] rootItem] reloadChildren:YES];
	[[self sbBrowser] reloadColumn:0];
	[[self loadingIndicator] stopAnimation:self];
    //[loadingIndicator removeFromSuperview];
}

//----------------------------------------------------------
#pragma mark - NSWINDOW DELEGATE METHODS
//----------------------------------------------------------

-(void)windowDidResize:(NSNotification *)aNotification
{
	double newWidth = [[aNotification object] frame].size.width;
	if (newWidth >= FIVE_COLUMN_WIDTH){
		[[self sbBrowser] setMaxVisibleColumns:5];
	}else if (newWidth >= FOUR_COLUMN_WIDTH){
		[[self sbBrowser] setMaxVisibleColumns:4];
	}else if (newWidth >= THREE_COLUMN_WIDTH){
		[[self sbBrowser] setMaxVisibleColumns:3];
	}else{
		[[self sbBrowser] setMaxVisibleColumns:2];
	}
	[[self outlineView] sizeLastColumnToFit];
}

/* 	Resize window vertically but not horizontally when zoom button is clicked in 
	outline view, and vice-versa in browser view. */
-(NSRect)windowWillUseStandardFrame:(NSWindow *)sender
		defaultFrame:(NSRect)defaultFrame
{
	if ([[self activeView] isEqualToString:@"browser"]){
		defaultFrame.size.height = [sender frame].size.height;
		defaultFrame.origin.y = [sender frame].origin.y;
	}else{
		defaultFrame.size.height = defaultFrame.size.height - CLICK_THROUGH_GAP;
		defaultFrame.origin.y = defaultFrame.origin.y + CLICK_THROUGH_GAP;
		defaultFrame.size.width = [sender frame].size.width;
		defaultFrame.origin.x = [sender frame].origin.x;
	}
	return defaultFrame;
}

@end
