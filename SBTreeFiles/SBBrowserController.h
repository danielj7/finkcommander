

#import <Cocoa/Cocoa.h>
#import "SBFileItemTree.h"
#import "SBFileItem.h"

@interface SBBrowserController: NSObject
{
    NSBrowser *browser;
    SBFileItemTree *tree;
}

-(id)initWithTree:(SBFileItemTree *)aTree
		  browser:(NSBrowser *)aBrowser;

/*
	Browser delegate methods
*/

-(int)browser:(NSBrowser *)sender 
		numberOfRowsInColumn:(int)column;

-(void)browser:(NSBrowser *)sender 
		willDisplayCell:(id)cell 
		atRow:(int)row 
		column:(int)column;

@end
