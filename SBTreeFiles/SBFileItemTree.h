
#import <Cocoa/Cocoa.h>
#import "SBFileItem.h"
#import "FinkGlobals.h"

extern NSString *SBAscendingOrder;
extern NSString *SBDescendingOrder;

//Functions used by both SBBrowserView and SBOutlineViewController
extern BOOL openFileAtPath(NSString *);
extern void alertProblemPaths(NSArray *);

@interface SBFileItemTree: NSObject
{
    SBFileItem *_sbrootItem;
    NSString *sbName;
    NSLock *sbLock;

    unsigned long totalSize;
    unsigned long itemCount;
}

/*
	Initialization
*/
-(id)initWithFileArray:(NSMutableArray *)flist
				  name:(NSString *)aName;

/*
	Accessors
*/

-(unsigned long)totalSize;
-(unsigned long)itemCount;

- (SBFileItem *)rootItem;
- (void)setRootItem:(SBFileItem *)newRootItem;

-(NSString *)name;
-(void)setName:(NSString *)newName;

/*
	Tree Building
*/
-(void)buildTreeFromFileList:(NSMutableArray *)flist;


/*
	Sorting the Tree
*/

-(void)sortTreeByElement:(NSString *)element
    inOrder:(NSString *)order;

@end

