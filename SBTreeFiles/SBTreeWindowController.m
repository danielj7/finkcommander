

#import "SBTreeWindowController.h"

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
		[self setActiveView:@"browser"];
		
		[[NSNotificationCenter defaultCenter] 
		addObserver:self 
		selector:@selector(applicationWillTerminate:)
			name:NSApplicationWillTerminateNotification
		  object:nil];

		// Register for notification that the file tree data structure is complete
		[[NSDistributedNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(finishedLoading:)
			name:@"SBTreeCompleteNotification"
			object:wName
			suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
    }
    return self;
}

/* After the window loads, display it; set the controllers for the outline view and
browser; tell the tree object to build its data structure.  */
-(void)windowDidLoad
{
    NSTableColumn *mdateColumn;
    NSSize browserSize = [oldBrowser bounds].size;
    NSRect browserFrame = NSMakeRect(0, 0, browserSize.width, browserSize.height);
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
	mdateColumn = [outlineView
					 tableColumnWithIdentifier:@"mdate"];
    mDateColumnController =
		[[SBDateColumnController alloc]
		initWithColumn:mdateColumn
		 shortTitle:@"Modified"
		  longTitle:@"Date Modified"];
    [outlineView setIndicatorImage:
		[NSImage imageNamed:@"NSAscendingSortIndicator"]
						inTableColumn:[outlineView tableColumnWithIdentifier:@"filename"]];

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
    [tabView selectTabViewItemWithIdentifier:[sender title]];
    [self setActiveView:[sender title]];
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
	Dprintf(@"Received SBTreeCompleteNotification");
	treeBuildingThreadIsFinished = YES;
    if (nil == [tree rootItem]){
		[msgTextField setStringValue:@"Error:  No such package installed"];
    }else{
		[msgTextField setStringValue:
			[NSString stringWithFormat:@"Total size: %u KB; file count: %u",
				[tree totalSize] / 1024 + 1, [tree itemCount]]];
    }
    [outlineView reloadItem:[tree rootItem] reloadChildren:YES];
	[browser reloadColumn:0];
	[loadingIndicator stopAnimation:self];
    [loadingIndicator removeFromSuperview];

}

//----------------------------------------------------------
#pragma mark DELEGATE METHODS
//----------------------------------------------------------

- (void)tabView:(NSTabView *)theTabView 
	didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [self setActiveView:[tabViewItem identifier]];
	Dprintf(@"Selected tab view item %@", [self activeView]);
}

//Resize window vertically but not horizontally when zoom button is clicked.
-(NSRect)windowWillUseStandardFrame:(NSWindow *)sender
		defaultFrame:(NSRect)defaultFrame
{
	NSView *theView;
	float newHeight;     
	float woffset; 
	//	NSRect scrollViewFrame;
	NSRect transformFrame;
	
	if ([[self activeView] isEqualToString:@"outline"]){
		theView = outlineView;
	}else{
		return defaultFrame;
	}
	//	scrollViewFrame = [[[theView superview] superview] frame];
	woffset = [sender frame].size.height - [[theView superview] frame].size.height;
	newHeight = [theView frame].size.height;
	transformFrame = [NSWindow contentRectForFrameRect:[sender frame]
						styleMask:[sender styleMask]];
	

	if (newHeight > transformFrame.size.height) { newHeight += woffset; }

	transformFrame.origin.y += transformFrame.size.height;
	transformFrame.origin.y -= newHeight;
	transformFrame.size.height = newHeight;
	
	transformFrame = [NSWindow frameRectForContentRect:transformFrame
						styleMask:[sender styleMask]];

    if (transformFrame.size.height > defaultFrame.size.height){
		transformFrame.size.height = defaultFrame.size.height;
		transformFrame.origin.y = defaultFrame.origin.y;
    }else if (transformFrame.origin.y < defaultFrame.origin.y){
		transformFrame.origin.y = defaultFrame.origin.y;
    }
    return transformFrame;
}

@end
