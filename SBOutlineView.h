
#import <Cocoa/Cocoa.h>
#import "SBUtilities.h"

@interface SBOutlineView : NSOutlineView

+(SBOutlineView *)substituteForOutlineView:(NSOutlineView *)oldView;

-(unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal;

@end
