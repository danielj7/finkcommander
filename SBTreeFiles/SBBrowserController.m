
#import "SBBrowserController.h"

@implementation SBBrowserController

-(id)initWithTree:(SBFileItemTree *)aTree
		  browser:(NSBrowser *)aBrowser
{
	self = [super init];
	if (nil != self){
		browser = aBrowser;
		tree = aTree;
		[browser setDelegate:self];
		[browser setTarget:self];
		[browser setDoubleAction:@selector(openSelectedFiles:)];
	}
	return self;
}

//Helper
-(SBFileItem *)selectedItemInColumn:(int)column
{
    NSMutableArray *pathArray = [NSMutableArray array];

    for (; column >= 0; column--){
		[pathArray insertObject:[[browser selectedCellInColumn:column] stringValue]
					 atIndex:0];	   
    }
    [pathArray insertObject:[[tree rootItem] path] atIndex:0];

    return [tree itemInTreeWithPathArray:pathArray];
}

//Delegate Methods

-(int)browser:(NSBrowser *)sender 
	numberOfRowsInColumn:(int)column
{
    SBFileItem *item;
    if (0 == column){
		return [[tree rootItem] numberOfChildren];
    }
    item = [self selectedItemInColumn:column-1];
    if (nil == item){
		return -1;
    }
    return [item numberOfChildren];
}

-(void)browser:(NSBrowser *)sender 
		willDisplayCell:(id)cell 
		atRow:(int)row 
		column:(int)column
{
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    SBFileItem *item;
    NSImage *itemImage;
    if (0 == column){
		item = [[tree rootItem] childAtIndex:row];
    }
    item = [[self selectedItemInColumn:column-1] childAtIndex:row];
    [cell setLeaf:(nil == [item children])];
    [cell setStringValue:[item filename]];
    itemImage = [ws iconForFile:[item path]];
    //    [itemImage setSize:NSMakeSize(24.0, 24.0)];
    [cell setImage:itemImage];
}

@end
