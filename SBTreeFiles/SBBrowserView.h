

#import <Cocoa/Cocoa.h>
#import "SBFileItemTree.h"
#import "SBFileItem.h"
#import "SBBrowserMatrix.h"

@interface SBBrowserView: NSBrowser
{
    NSBrowser *browser;
    SBFileItemTree *tree;
}

/*
 * Accessors
 */
 
-(SBFileItemTree *)tree;
-(void)setTree:(SBFileItemTree *)newTree;

/*
 *	Browser delegate methods
 */

-(int)browser:(NSBrowser *)sender 
		numberOfRowsInColumn:(int)column;

-(void)browser:(NSBrowser *)sender 
		willDisplayCell:(id)cell 
		atRow:(int)row 
		column:(int)column;

@end
