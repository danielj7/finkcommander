
#import <Cocoa/Cocoa.h>
#import "SBTreeWindowController.h"
#import "SBUtilities.h"
#import "FinkGlobals.h"

@interface SBTreeWindowManager : NSObject
{
    NSString *_sbcurrentPackageName;
	NSMutableArray *_sbWindows;
}

-(NSString *)currentPackageName;
-(void)setCurrentPackageName:(NSString *)newCurrentPackageName;
-(NSMutableArray *)windows;
-(void)openNewOutlineForPackageName:(NSString *)pkgName;

@end
