
#import <Foundation/Foundation.h>
#import "SBFileItem.h"
#import "FinkGlobals.h"

@interface SBFileItemTree: NSObject
{
    SBFileItem *_sbrootItem;
    NSString *sbName;
    NSLock *sbLock;

    unsigned long totalSize;
    unsigned long itemCount;
}

-(id)initWithFileArray:(NSMutableArray *)flist
				  name:(NSString *)aName;

-(unsigned long)totalSize;
-(unsigned long)itemCount;

- (SBFileItem *)rootItem;
- (void)setRootItem:(SBFileItem *)newRootItem;

-(NSString *)name;
-(void)setName:(NSString *)newName;

-(void)buildTreeFromFileList:(NSMutableArray *)flist;
-(SBFileItem *)itemInTreeWithPathArray:(NSArray *)parray;
-(SBFileItem *)itemInTreeWithPath:(NSString *)path;

@end

