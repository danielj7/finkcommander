/*
 File SBTreeWindowController.m

 See header file SBTreeWindowController.h for license and interface information.

 */

#import "SBTreeWindowController.h"

//Constants matching tags in selection matrix
enum {
	SB_BROWSER = 0,
	SB_OUTLINE = 1
};

#define BYTE_FORMAT NSLocalizedString(@"%u items, %.0f b", "Formatter for browser window")
#define KILOBYTE_FORMAT NSLocalizedString(@"%u items, %.1f KB", "Formatter for browser window")
#define MEGABYTE_FORMAT NSLocalizedString(@"%u items, %.1f MB", "Formatter for browser window")

@implementation SBTreeWindowController

//----------------------------------------------------------
#pragma mark ACCESSORS
//----------------------------------------------------------

-(NSString *)activeView { return _sbActiveView; }

-(void)setActiveView:(NSString *)newActiveView
{
	[newActiveView retain];
	[_sbActiveView release];
	_sbActiveView = newActiveView;
}

-(NSWindow *)window { return sbTreeWindow; }

//----------------------------------------------------------
#pragma mark OBJECT CREATION
//----------------------------------------------------------

/*	Helper for designated initializer.  Replaces NSOutlineView and NSBrowser
	created in nib file with custom objects.  Sets up SBDateColumnController and
	SBOutlineViewController objects.  */
-(void)setupViews
{
    NSTableColumn *mdateColumn;
    NSRect browserFrame = [oldBrowser frame];
	NSView *browserSuperview = [oldBrowser superview];

	/* Set up the custom outline view */
	outlineView = [[SBOutlineView alloc] 
					initAsSubstituteForOutlineView:outlineView];  //RC == 1
	[outlineScrollView setDocumentView:outlineView];              //RC == 2
	[outlineView release];   									  //RC == 1
	[outlineView sizeLastColumnToFit];

	/* Set up the outline view controller */
    oController = [[SBOutlineViewController alloc] initWithTree:tree
													view:outlineView];

	/* Set up the controller for the date column */
	mdateColumn = [outlineView tableColumnWithIdentifier:@"mdate"];
    mDateColumnController =
		[[SBDateColumnController alloc]
		initWithColumn:mdateColumn
			shortTitle:@"Modified"
			longTitle:@"Date Modified"];
    [outlineView setIndicatorImage: [NSImage imageNamed:@"NSAscendingSortIndicator"]
				inTableColumn:[outlineView tableColumnWithIdentifier:@"filename"]];

	/* Substitute SBBrowserView with drag and drop for nib version */
    browser = [[SBBrowserView alloc] initWithFrame:browserFrame];
	[browser setAutoresizingMask:[oldBrowser autoresizingMask]];
	[browser setMaxVisibleColumns:[oldBrowser maxVisibleColumns]];
	[oldBrowser removeFromSuperview];
	[browserSuperview addSubview:browser];
    [browser release];
    [browser setTree:tree];
}

-(id)initWithFileList:(NSMutableArray *)fList
{
    return [self initWithFileList:fList 
			windowName:@"File Tree Viewer"];
}

/*	Designated initializer */
-(id)initWithFileList:(NSMutableArray *)fList
		   windowName:(NSString *)wName
{
    self = [super init];
    if (nil != self){
	
		tree = [[SBFileItemTree alloc] initWithFileArray:fList name:wName];
		/*	Building the file tree can take some time; run in a separate
			thread to avoid tying up the rest of the app */
		treeBuildingThreadIsFinished = NO;
		[NSThread detachNewThreadSelector:@selector(buildTreeFromFileList:)
									toTarget:tree
								  withObject:fList];		

		[NSBundle loadNibNamed:@"TreeView" owner:self];

		[[self window] setTitle:wName];
		[[self window] setReleasedWhenClosed:YES];
		[self setupViews];

		[[self window] makeKeyAndOrderFront:self];
		
		[loadingIndicator setUsesThreadedAnimation:YES];
		[loadingIndicator startAnimation:self];
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
#pragma mark OBJECT DESTRUCTION
//----------------------------------------------------------

-(BOOL)windowShouldClose:(id)sender
{
	if (! treeBuildingThreadIsFinished){
		NSBeep();
		return NO;
	}
	/*	The following is needed to release all items in a tree.  NSOutline
		apparently retains an item when its parent is expanded and doesn't
		release it until the parent is collapsed.  */	
    [oController collapseItemAndChildren:[tree rootItem]];
    return YES;
}

-(void)windowWillClose:(NSNotification *)n
{
	[NSApp sendAction:@selector(treeWindowWillClose:) to:nil from:self];
	//[[tree rootItem] setChildren:nil];
}

/* 	This is not getting called, even when releasedWhenClosed is set to YES */
-(void)dealloc
{
	Dprintf(@"Deallocating controller for window %@", [[self window] title]);

    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	
	[self setActiveView:nil];
	[mDateColumnController release];
	[oController release];
	[tree release];
	
	[super dealloc];
}

//----------------------------------------------------------
#pragma mark ACTIONS
//----------------------------------------------------------

-(IBAction)switchViews:(id)sender
{	
	int selection = [[sender selectedCell] tag];
	NSString *identifier;
	switch (selection){
		case SB_BROWSER:
			identifier = @"browser";
			break;
		case SB_OUTLINE:
			identifier = @"outline";
			break;
		default:
			break;
	}
	[tabView selectTabViewItemWithIdentifier:identifier];
    [self setActiveView:identifier];
}

//----------------------------------------------------------
#pragma mark UI UPDATING
//----------------------------------------------------------

-(void)finishedLoading:(NSNotification *)n
{
	treeBuildingThreadIsFinished = YES;
    if (nil == [tree rootItem]){
		[msgTextField setStringValue:@"Error:  No such package installed"];
    }else{
		double size = (float)[tree totalSize];
		NSString *formatString = BYTE_FORMAT;
		if (size > 1048576.0){
			size /= 1048576.0;
			formatString = MEGABYTE_FORMAT;
		}else if (size > 1024.0){
			size /= 1024.0;
			formatString = KILOBYTE_FORMAT;
		}
		[msgTextField setStringValue:
			[NSString stringWithFormat:formatString,
				[tree itemCount], size]];
    }
    [outlineView reloadItem:[tree rootItem] reloadChildren:YES];
	[browser reloadColumn:0];
	[loadingIndicator stopAnimation:self];
    [loadingIndicator removeFromSuperview];
}

//----------------------------------------------------------
#pragma mark NSWINDOW DELEGATE METHODS
//----------------------------------------------------------

-(void)windowDidResize:(NSNotification *)aNotification
{
	double newWidth = [[aNotification object] frame].size.width;
	if (newWidth >= 800.0){
		[browser setMaxVisibleColumns:5];
	}else if (newWidth >= 600.0){
		[browser setMaxVisibleColumns:4];
	}else if (newWidth >= 400.0){
		[browser setMaxVisibleColumns:3];
	}else{
		[browser setMaxVisibleColumns:2];
	}
	[outlineView sizeLastColumnToFit];
}

#ifdef UNDEF
//Resize window vertically but not horizontally when zoom button is clicked.
-(NSRect)windowWillUseStandardFrame:(NSWindow *)sender
		defaultFrame:(NSRect)defaultFrame
{

	if ([[self activeView] isEqualToString:@"browser"]){
		return defaultFrame;
	}else{
		float windowOffset = [[self window] frame].size.height
			- [[outlineView superview] frame].size.height;
		float newHeight = [outlineView frame].size.height;
		NSRect stdFrame =
			[NSWindow contentRectForFrameRect:[sender frame]
					  styleMask:[sender styleMask]];

		if (newHeight > stdFrame.size.height) {newHeight += windowOffset;}

		stdFrame.origin.y += stdFrame.size.height;
		stdFrame.origin.y -= newHeight;
		stdFrame.size.height = newHeight;

		stdFrame =
			[NSWindow frameRectForContentRect:stdFrame
					  styleMask:[sender styleMask]];

		//if new height would exceed default frame height,
		//zoom vertically and horizontally
		if (stdFrame.size.height > defaultFrame.size.height){
			stdFrame = defaultFrame;
			//otherwise zoom vertically just enough to accomodate new height
		}else if (stdFrame.origin.y < defaultFrame.origin.y){
			stdFrame.origin.y = defaultFrame.origin.y;
		}
		return stdFrame;
	}
}
#endif

@end
