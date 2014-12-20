/*
 File: SBBrowserView.h

 SBBrowserView serves primarily as the delegate for a browser object.  
 It implements the lazy form of the NSBrowser delegate methods to 
 populate the browser with file names and icons.  It also subclasses
 NSBrowser in order to allow drag and drop behavior similar to Finder's.

 Copyright (C) 2002, 2003  Steven J. Burr

 This program is free software; you may redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 */


#import <Cocoa/Cocoa.h>
#import "SBFileItemTree.h"
#import "SBFileItem.h"
#import "SBBrowserMatrix.h"
#import "SBUtilities.h"

@interface SBBrowserView: NSBrowser <NSBrowserDelegate, NSDraggingSource>
{
    SBFileItemTree *tree;
}

/*
 * Accessors
 */
 
@property (nonatomic, strong) SBFileItemTree *tree;

/*
 *	Browser delegate methods
 */

-(NSInteger)browser:(NSBrowser *)sender
		numberOfRowsInColumn:(NSInteger)column;

-(void)browser:(NSBrowser *)sender 
		willDisplayCell:(id)cell 
		atRow:(int)row 
		column:(int)column;

@end
