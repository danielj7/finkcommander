/*
 File: SBBrowserMatrix.h

 Subclasses NSBrowserMatrix in order to allow drag and drop from
 a browser view.  See also SBBrowserView.h.

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
 
#import <AppKit/AppKit.h>
#import "SBUtilities.h"


@interface SBBrowserMatrix : NSMatrix 
{
}

@property (nonatomic) id myBrowser;

@end
