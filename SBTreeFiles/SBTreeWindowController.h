//FILE OWNER FOR TreeView.nib

#import <Cocoa/Cocoa.h>
#import "SBFileItemTree.h"
#import "SBOutlineView.h"
#import "SBOutlineViewController.h"
#import "SBBrowserView.h"
#import "SBUtilities.h"

@interface SBTreeWindowController: NSWindowController
{
	IBOutlet NSTabView *tabView;
	IBOutlet NSScrollView *outlineScrollView;
    IBOutlet id outlineView;
    IBOutlet NSTextField *msgTextField;
    IBOutlet NSProgressIndicator *loadingIndicator;
	IBOutlet NSBrowser *oldBrowser;
	IBOutlet NSBox *divider;

	SBFileItemTree *tree;
    SBOutlineViewController *oController;
	SBBrowserView *browser;
    SBDateColumnController *mDateColumnController;
    NSMutableArray *fileList;
	NSString  *_sbActiveView;
	BOOL treeBuildingThreadIsFinished;
}

-(id)initWithFileList:(NSMutableArray *)fList;
-(id)initWithFileList:(NSMutableArray *)fList
		   windowName:(NSString *)wName;

-(NSMutableArray *)fileList;
-(void)setFileList:(NSMutableArray *)fList;

-(NSString *)activeView;
-(void)setActiveView:(NSString *)newActiveView;

-(IBAction)switchViews:(id)sender;

-(void)startedLoading;
-(void)finishedLoading:(NSNotification *)n;

@end
