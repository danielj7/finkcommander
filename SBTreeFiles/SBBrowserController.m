
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
		return 0;
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
    }else{
		item = [[self selectedItemInColumn:column-1] childAtIndex:row];
	}
    [cell setLeaf:(nil == [item children])];
    [cell setStringValue:[item filename]];
    itemImage = [ws iconForFile:[item path]];
    [itemImage setSize:NSMakeSize(16.0, 16.0)];
    [cell setImage:itemImage];
}

//Action method

-(IBAction)openSelectedFiles:(id)sender
{
    NSEnumerator *e = [[browser selectedCells] objectEnumerator];
	NSBrowserCell *bCell;
	NSFileManager *mgr = [NSFileManager defaultManager];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSString *path, *stnddpath;
    BOOL isDir, successful;
    NSMutableArray *problemFiles = [NSMutableArray array];

    while (nil != (bCell = [e nextObject])){
		path = [browser pathToColumn:[browser lastColumn]]; //up to but not including last
		path = [path stringByAppendingPathComponent:[bCell stringValue]];
		path = [[[tree rootItem] path] stringByAppendingPathComponent:path];
		Dprintf(@"Path to selection = %@", path);
		stnddpath = [path stringByStandardizingPath];
		//skip directories
		[mgr fileExistsAtPath:stnddpath isDirectory:&isDir];
		if (isDir) continue;
		if ([stnddpath hasSuffix:@".html"] || [stnddpath hasSuffix:@".htm"]){
			NSURL *fileURL = [NSURL fileURLWithPath:stnddpath];
			successful = [ws openURL:fileURL];
		}else{
			successful = [ws openFile:stnddpath];
			if (! successful){
				successful = [ws openFile:stnddpath withApplication:@"TextEdit"];
			}
		}
		if (! successful){
			[problemFiles addObject:stnddpath];
		}
    }
    if ([problemFiles count] > 0){
		NSRunAlertPanel(@"Error",
				  @"The following could not be opened:\n\n%@",
				  @"OK", nil, nil,
				  [problemFiles componentsJoinedByString:@" "]);
    }
}

@end
