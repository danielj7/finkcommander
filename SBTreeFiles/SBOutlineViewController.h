
#import <Cocoa/Cocoa.h>
#import "SBFileItemTree.h"
#import "SBFileItem.h"
#import "SBDateColumnController.h"
#import "FinkGlobals.h"

extern NSString *sbAscending;
extern NSString *sbDescending;

@interface SBOutlineViewController: NSObject
{
    NSOutlineView *outlineView;
    SBFileItemTree *tree;
    NSMutableDictionary *columnStateDictionary;
    NSString *previousColumnIdentifier;
}

-(id)initWithTree:(SBFileItemTree *)aTree
			 view:(NSOutlineView *)oView;

-(NSString *)previousColumnIdentifier;

-(void)setPreviousColumnIdentifier:(NSString *)newPreviousColumnIdentifier;
	

/* 
	Outline view data source methods
*/

-(int)outlineView:(NSOutlineView *)outlineView 
		numberOfChildrenOfItem:(id)item;

-(BOOL)outlineView:(NSOutlineView *)outlineView 
		isItemExpandable:(id)item;

-(id)outlineView:(NSOutlineView *)outlineView 
		child:(int)index 
		ofItem:(id)item;

-(id)outlineView:(NSOutlineView *)outlineView 
		objectValueForTableColumn:(NSTableColumn *)tableColumn 
		byItem:(id)item;

/*
	Actions
*/

-(IBAction)openSelectedFiles:(id)sender;

//-(IBAction)sortByColumn:(id)sender;

/*
	Replacement for non-functional NSOutlineView
	collapseItem:collapseChildren:
*/

-(void)collapseItemAndChildren:(SBFileItem *)item;

@end

