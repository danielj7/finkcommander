

#import <Cocoa/Cocoa.h>
#import "SBFileItemTree.h"
#import "SBFileItem.h"
#import "SBBrowserMatrix.h"
#import "SBUtilities.h"

@interface SBBrowserView: NSBrowser
{
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
