
#import <Cocoa/Cocoa.h>
#import "SBTreeWindowController.h"
#import "FinkGlobals.h"

@interface SBTreeWindowManager : NSObject
{
    NSString *_sbcurrentPackageName;
}

-(NSString *)currentPackageName;
-(void)setCurrentPackageName:(NSString *)newCurrentPackageName;
-(void)openNewOutlineForPackageName:(NSString *)pkgName;

@end
