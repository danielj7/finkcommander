
#import <Cocoa/Cocoa.h>
#import "SBUtilities.h"
#import "SBFileItem.h"
#import "SBBrowserCell.h"

@interface SBOutlineView : NSOutlineView

+(SBOutlineView *)substituteForOutlineView:(NSOutlineView *)oldView;

-(unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal;

-(IBAction)openSelectedFiles:(id)sender;

@end
