/*
 File: SBTreeWindowManager.h

 Creates and destroys package file browser windows.  Creates list of paths
 by running dpkg -L and passes them on to the SBTreeWindowController, which
 then creates an SBFileItemTree.

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
#import "SBTreeWindowController.h"
#import "SBUtilities.h"
#import "FinkGlobals.h"

@interface SBTreeWindowManager : NSObject
{
    NSString *_sbcurrentPackageName;
	NSMutableArray *_sbWindowControllers;
	NSMutableArray *_sbWindowTitles;
}

-(NSString *)currentPackageName;
-(void)setCurrentPackageName:(NSString *)newCurrentPackageName;
-(NSMutableArray *)windowControllers;
-(NSMutableArray *)windowTitles;
-(void)openNewWindowForPackageName:(NSString *)pkgName;
-(void)closingTreeWindowWithController:(id)sender;

@end
