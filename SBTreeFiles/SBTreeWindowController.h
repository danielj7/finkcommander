//FILE OWNER FOR TreeView.nib

#import <Cocoa/Cocoa.h>
#import "SBFileItemTree.h"
#import "SBOutlineViewController.h"
#import "FinkGlobals.h"
#import "SBBrowserController.h"

@interface SBTreeWindowController: NSWindowController
{
	IBOutlet NSTabView *tabView;
    IBOutlet NSOutlineView *outlineView;
	IBOutlet NSBrowser *browser;
    IBOutlet NSTextField *msgTextField;
    IBOutlet NSProgressIndicator *loadingIndicator;

    SBFileItemTree *tree;
    SBOutlineViewController *oController;
	SBBrowserController *bController;
    SBDateColumnController *mDateColumnController;
    NSMutableArray *fileList;
	BOOL treeBuildingThreadIsFinished;
}

-(id)initWithFileList:(NSMutableArray *)fList;
-(id)initWithFileList:(NSMutableArray *)fList
		   windowName:(NSString *)wName;

-(NSMutableArray *)fileList;
-(void)setFileList:(NSMutableArray *)fList;

//-(IBAction)switchViews:(id)sender;

-(void)startedLoading;
-(void)finishedLoading:(NSNotification *)n;

@end
