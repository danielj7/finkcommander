

#import "SBTreeWindowController.h"

//Constants matching tags in selection matrix
enum {
	SB_BROWSER = 0,
	SB_OUTLINE = 1
};

#define BYTE_FORMAT NSLocalizedString(@"%u items, %.0f b", "Formatter for browser window")
#define KILOBYTE_FORMAT NSLocalizedString(@"%u items, %.2f KB", "Formatter for browser window")
#define MEGABYTE_FORMAT NSLocalizedString(@"%u items, %.2f MB", "Formatter for browser window")

//----------------------------------------------------------
#pragma mark OBJECT CREATION AND DESTRUCTION
//----------------------------------------------------------

@implementation SBTreeWindowController

-(id)initWithFileList:(NSMutableArray *)fList
{
    return [self initWithFileList:fList 
			windowName:@"File Tree Viewer"];
}

-(id)initWithFileList:(NSMutableArray *)fList
		   windowName:(NSString *)wName
{
    self = [super initWithWindowNibName:@"TreeView"];
    if (nil != self){
		
		tree = [[SBFileItemTree alloc] initWithFileArray:fList name:wName];
		[self setFileList:fList];  //Needed in windowDidLoad to build tree
		[[self window] setTitle:wName];
		[[self window] setReleasedWhenClosed:YES];
		[self setActiveView:@"outline"];
		
		Dprintf(@"Registering for notification %@", [[self window] title]);
		[[NSDistributedNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(finishedLoading:)
			name:@"SBTreeCompleteNotification"
			object:[[self window] title]
			suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];

		[[NSNotificationCenter defaultCenter] 
			addObserver:self 
			selector:@selector(applicationWillTerminate:)
			name:NSApplicationWillTerminateNotification
			object:nil];
	}
    return self;
}

/* After the window loads, display it; set the controllers for the outline view and
browser; tell the tree object to build its data structure.  */
-(void)windowDidLoad
{
    NSTableColumn *mdateColumn;
    NSRect browserFrame = [oldBrowser frame];
	NSView *browserSuperview = [oldBrowser superview];
	
    [self startedLoading];
    [self showWindow:self];
		
	/* Set up the custom outline view */
	outlineView = [SBOutlineView substituteForOutlineView:outlineView];
	[outlineScrollView setDocumentView:outlineView];
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
    [outlineView setIndicatorImage:
		[NSImage imageNamed:@"NSAscendingSortIndicator"]
						inTableColumn:[outlineView 
							tableColumnWithIdentifier:@"filename"]];

	/* Substitute SBBrowserView with drag and drop for nib version */
    browser = [[SBBrowserView alloc] initWithFrame:browserFrame];
	[browser setAutoresizingMask:[oldBrowser autoresizingMask]];
	[browser setMaxVisibleColumns:[oldBrowser maxVisibleColumns]];
	[oldBrowser removeFromSuperview];
	[browserSuperview addSubview:browser];
    [browser release];
    [browser setTree:tree];
	
	/*Building the file tree can take some time; run in a separate
	thread to avoid tying up the rest of the app*/
    treeBuildingThreadIsFinished = NO;
    [NSThread detachNewThreadSelector:@selector(buildTreeFromFileList:)
			  toTarget:tree
			  withObject:[self fileList]];
}

-(BOOL)windowShouldClose:(id)sender
{
    /*	The following is needed to release all items in a tree.  NSOutline
	apparently retains an item when its parent is expanded and doesn't
	release it until the parent is collapsed.  */
	if (! treeBuildingThreadIsFinished){
		NSBeep();
		return NO;
	}
    [oController collapseItemAndChildren:[tree rootItem]];
    return YES;
}

-(void)windowWillClose:(NSNotification *)n
{
    //We have no more need for the data structure
    [[tree rootItem] setChildren:nil];

}

-(void)applicationWillTerminate:(NSNotification *)n
{
    [[self window] performClose:self];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [oController release];
	[browser release];
    [fileList release];
    [tree release];
}

//----------------------------------------------------------
#pragma mark ACCESSORS
//----------------------------------------------------------

-(NSMutableArray *)fileList { return fileList; }

-(void)setFileList:(NSMutableArray *)fList
{
    [fList retain];
    [fileList release];
    fileList = fList;
}

-(NSString *)activeView { return _sbActiveView; }

-(void)setActiveView:(NSString *)newActiveView
{
	[newActiveView retain];
	[_sbActiveView release];
	_sbActiveView = newActiveView;
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

-(void)startedLoading
{
    [loadingIndicator setUsesThreadedAnimation:YES];
    [loadingIndicator startAnimation:self];
}


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
#pragma mark DELEGATE METHODS
//----------------------------------------------------------

//Resize window vertically but not horizontally when zoom button is clicked.
-(NSRect)windowWillUseStandardFrame:(NSWindow *)sender
		defaultFrame:(NSRect)defaultFrame
{
	float currentHeight = [sender frame].size.height;
	float newHeight;     
	float woffset; 
	//	NSRect scrollViewFrame;
	NSRect transformFrame;
	
	if ([[self activeView] isEqualToString:@"browser"]){
		return defaultFrame;
	}
	
	transformFrame = [NSWindow contentRectForFrameRect:[sender frame] styleMask:[sender styleMask]];
	woffset = currentHeight - [[outlineView superview] frame].size.height;
	newHeight = [outlineView frame].size.height;
	
	if (newHeight >= transformFrame.size.height){
		newHeight += woffset;
	}else{
		newHeight -= woffset;
	}
	
	transformFrame.origin.y += transformFrame.size.height;
	transformFrame.origin.y -= newHeight;
	transformFrame.size.height = newHeight;
	
	transformFrame = [NSWindow frameRectForContentRect:transformFrame styleMask:[sender styleMask]];

    if (transformFrame.size.height > defaultFrame.size.height){
		transformFrame.size.height = defaultFrame.size.height;
		transformFrame.origin.y = defaultFrame.origin.y;
    }else if (transformFrame.origin.y < defaultFrame.origin.y){
		transformFrame.origin.y = defaultFrame.origin.y;
    }
    return transformFrame;
}

@end
