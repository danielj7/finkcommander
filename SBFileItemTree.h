#import <Cocoa/Cocoa.h>
#import "SBFileItem.h"
#import "SBDateColumnController.h"
#import "FinkGlobals.h"

@interface SBFileItemTree: NSWindowController
{
	//Oultine window outlets
	IBOutlet NSOutlineView *outlineView;
	IBOutlet NSTextField *msgTextField;
	IBOutlet NSProgressIndicator *loadingIndicator;
	
	//Instance variables
	SBFileItem *_sbrootItem;
	SBDateColumnController *mDateColumnController;
	NSString *_sbname;
	unsigned long totalSize;
	unsigned long itemCount;
}

/*
Initializers
*/
//If one of the next two is used, the caller must follow up with a bulidTreeFromFileList message.  
-(id)init;
-(id)initWithWindowName:(NSString *)name;
//The designated initializer; automatically builds tree from inlcuded file path array 
-(id)initWithWindowName:(NSString *)name 
	fileArray:(NSMutableArray *)flist;

/*
NSWindow/NSApplication Delegate Methods
*/	 
-(BOOL)windowShouldClose:(id)sender;
-(void)windowWillClose:(NSNotification *)n;
-(void)applicationWillTerminate:(NSNotification *)n;

/*
Accessors
*/
- (SBFileItem *)rootItem;
- (void)setRootItem:(SBFileItem *)newRootItem;

-(NSString *)_sbname;
-(void)_setSbname:(NSString *)newSbname;

/*
Methods used to build the tree
*/
-(void)buildTreeFromFileList:(NSMutableArray *)flist;
-(SBFileItem *)parentOfItem:(SBFileItem *)item;
-(void)addItemToTree:(SBFileItem *)item;

/*
Outline view manipulation
*/
-(void)collapseItemAndChildren:(SBFileItem *)item;

/*
Action(s)
*/
-(IBAction)openSelectedFiles:(id)sender;

@end
