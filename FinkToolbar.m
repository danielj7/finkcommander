/*
File: FinkFinkToolbar.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 The sole function of the FinkToolbar class is to override the 
 NSToolbar setSizeMode: method to resize the search view.  NSToolbar will
 undoubtedly include a toolbarSizeModeDidChange: delegate method in
 the future, at which point this class will become unnecessary.

 Copyright (C) 2002  Steven J. Burr

 This program is free software; you may redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

 Contact the author at sburrious@users.sourceforge.net.

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

@end
