/*
 File: FinkPackageInfo.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 FinkPackageInfo enables the Package Info window to display information on packages 
 selected in the main window's table and to provide links to package websites and maintainer
 email addresses.  It uses the GPL'd MyTextView class created by Hoshi Takanori to display the 
 familiar "hand" cursor over links.

 Copyright (C) 2002, 2003  Steven J. Burr

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

#import <Cocoa/Cocoa.h>
#import "FinkGlobals.h"
#import "FinkPackage.h"
#import "MyTextView.h"
#include <math.h>

@interface FinkPackageInfo : NSWindowController <NSWindowDelegate>
{
}

@property (nonatomic, unsafe_unretained) IBOutlet NSTextView *textView;
@property (nonatomic, weak) IBOutlet NSScrollView *scrollView;

@property (nonatomic, copy) NSString *emailSig;

-(void)displayDescriptions:(NSArray *)packages;

-(NSURL *)mailURLForPackage:(FinkPackage *)pkg withBody:(NSString *)body;

@end
