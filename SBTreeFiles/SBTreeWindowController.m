

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
		
		Dprintf(@"In SBTWC, received file list:\n%@", fList);

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
	NSTableColumn *mdateColumn = [outlineView tableColumnWithIdentifier:@"mdate"];
    [self startedLoading];
	[self showWindow:self];
	
    oController = [[SBOutlineViewController alloc] initWithTree:tree
										view:outlineView];

	mDateColumnController = 
			[[SBDateColumnController alloc]
					initWithColumn:mdateColumn
					shortTitle:@"Modified"
					longTitle:@"Date Modified"];
	

#ifdef UNDEF
    bController = [[SBBrowserController alloc] initWithTree:tree
												browser:browser];
#endif

    //Building the file tree can take some time
    [NSThread detachNewThreadSelector:@selector(buildTreeFromFileList:)
								toTarget:tree
							  withObject:[self fileList]];
}

-(BOOL)windowShouldClose:(id)sender
{
    /*	The following is needed to release all items in a tree.  NSOutline
	apparently retains an item when its parent is expanded and doesn't
	release it until the parent is collapsed.  */
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
//  [bController release];
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

#ifdef UNDEF
//----------------------------------------------------------
#pragma mark ACTIONS
//----------------------------------------------------------

-(IBAction)switchViews:(id)sender
{
    [tabView selectTabViewItemAtIndex:[sender tag]];
}
#endif

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

    if (nil == [tree rootItem]){
		[msgTextField setStringValue:@"Error:  No such package installed"];
    }else{
		[msgTextField setStringValue:
			[NSString stringWithFormat:@"Total size: %u KB; file count: %u",
				[tree totalSize] / 1024 + 1, [tree itemCount]]];
    }
    [outlineView reloadItem:[tree rootItem] reloadChildren:YES];
	[loadingIndicator stopAnimation:self];
    [loadingIndicator removeFromSuperview];

}

@end
