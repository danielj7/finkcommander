/*
 File: SBOutlineView.h

 Subclasses NSOutlineView primariy in order to allow drag and drop from
 the outline view to other applications.  It also includes an action method
 to open files or directories selected in the outline view.  This action
 is connected to First Responsder in order to be accessible from the main
 menu.

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
#import "SBUtilities.h"
#import "SBFileItem.h"
#import "SBBrowserCell.h"

@interface SBOutlineView : NSOutlineView

-(id)initAsSubstituteForOutlineView:(NSOutlineView *)oldView;

-(unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal;

-(IBAction)openSelectedFiles:(id)sender;

@end
