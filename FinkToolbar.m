/*
 File: FinkToolbar.m

 See the header file, FinkToolbar.h, for interface and license information.

 */
 
#import "FinkToolbar.h"

@implementation FinkToolbar

-(NSButton *)searchButton {
    return searchButton;
}

-(void)setSearchButton:(NSButton *)newSearchButton{
	[newSearchButton retain];
	[searchButton release];
	searchButton = newSearchButton;
}

-(NSTextField *)searchField {
    return searchField;
}

-(void)setSearchField:(NSTextField *)newSearchField{
	[newSearchField retain];
	[searchField release];
	searchField = newSearchField;
}

#ifndef OSXVER101

-(void)setSizeMode:(NSToolbarSizeMode)sizeMode
{
    id searchView = [searchField superview];
    NSRect fFrame = [searchField frame];
    NSRect vFrame = [searchView frame];

    if (sizeMode == NSToolbarSizeModeRegular){
		[[searchButton cell] setControlSize:NSRegularControlSize];
		[searchButton setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
		[searchField setFrame:NSMakeRect(fFrame.origin.x, 3.0, 
										fFrame.size.width, 22.0)];
		[searchView setFrame:NSMakeRect(vFrame.origin.x, vFrame.origin.y, 
										vFrame.size.width, 29.0)]; 
		[searchField setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
    }else{
		[[searchButton cell] setControlSize:NSSmallControlSize];
		[searchButton setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
		[searchField setFrame:NSMakeRect(fFrame.origin.x, 5.0,
										fFrame.size.width, 19.0)];
		[searchView setFrame:NSMakeRect(vFrame.origin.x, vFrame.origin.y,
										vFrame.size.width, 25.0)]; 		
		[searchField setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    }
	[searchView setNeedsDisplay:YES];
    [super setSizeMode:sizeMode];
}

#endif /* ! OSXVER101 */

@end
