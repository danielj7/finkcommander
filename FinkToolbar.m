/*
 File: FinkToolbar.m

 See the header file, FinkToolbar.h, for interface and license information.

 */
 
#import "FinkToolbar.h"

@implementation FinkToolbar

#ifndef OSXVER101

-(void)setSizeMode:(NSToolbarSizeMode)sizeMode
{
    id searchView = [[self searchField] superview];
    NSRect fFrame = [[self searchField] frame];
    NSRect vFrame = [searchView frame];

    if (sizeMode == NSToolbarSizeModeRegular){
		[[[self searchButton] cell] setControlSize:NSRegularControlSize];
		[[self searchButton] setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
		[[self searchField] setFrame:NSMakeRect(fFrame.origin.x, 3.0,
										fFrame.size.width, 22.0)];
		[searchView setFrame:NSMakeRect(vFrame.origin.x, vFrame.origin.y, 
										vFrame.size.width, 29.0)]; 
		[[self searchField] setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
    }else{
		[[[self searchButton] cell] setControlSize:NSSmallControlSize];
		[[self searchButton] setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
		[[self searchField] setFrame:NSMakeRect(fFrame.origin.x, 5.0,
										fFrame.size.width, 19.0)];
		[searchView setFrame:NSMakeRect(vFrame.origin.x, vFrame.origin.y,
										vFrame.size.width, 25.0)]; 		
		[[self searchField] setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    }
	[searchView setNeedsDisplay:YES];
    [super setSizeMode:sizeMode];
}

#endif /* ! OSXVER101 */

@end
