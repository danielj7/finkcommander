
#import <Cocoa/Cocoa.h>
#import "SBFileItemTree.h"
#import "FinkGlobals.h"


@interface SBTreeManager : NSObject 
{
	NSString *_sbcurrentPackageName;
	NSLock *_sbLock;
}

-(NSString *)_sbcurrentPackageName;
-(void)_sbsetCurrentPackageName:(NSString *)newCurrentPackageName;
-(void)openNewOutlineForPackageName:(NSString *)pkgName;

@end
