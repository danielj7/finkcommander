
#import "FinkToolbar.h"

@implementation FinkToolbar

-(id)delegate
{
	return [super delegate];
}

-(void)setSizeMode:(NSToolbarSizeMode)sizeMode
{
    id searchButton = [[self delegate] searchPopUpButton];
    id searchField = [[self delegate] searchTextField];
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

@end
