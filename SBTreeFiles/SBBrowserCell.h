/*
 File: SBBrowserCell.h

 This is for use in SBOutlineView, rather than SBBrowserMatrix or 
 SBBrowserView as you might expect.  An NSBrowserCell allows the 
 display of an image as well as text and is therefore a convenient means
 of displaying a file's icon and name in the outline view.  However, some
 NSBrowserCell behavior is inappropriate for an outline view and therefore
 requires overriding. 

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


@interface SBBrowserCell : NSBrowserCell {
}

@end
