/*
 File: SBTreeWindowController.h

 Creates the custom views and controllers, as well as the SBFileItemTree,
 for a particular package file browser window.  

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
#import "SBOutlineView.h"
#import "SBOutlineViewController.h"
#import "SBBrowserView.h"
#import "SBUtilities.h"

@interface SBTreeWindowController: NSObject
{
	IBOutlet NSWindow *sbTreeWindow;
	IBOutlet NSTabView *tabView;
	IBOutlet NSScrollView *outlineScrollView;
    IBOutlet id outlineView;
    IBOutlet NSTextField *msgTextField;
    IBOutlet NSProgressIndicator *loadingIndicator;
	IBOutlet NSBrowser *oldBrowser;

	SBFileItemTree *sbTree;
    SBOutlineViewController *oController;
	SBBrowserView *sbBrowser;
    SBDateColumnController *mDateColumnController;
    NSMutableArray *fileList;
	NSString  *_sbActiveView;
	BOOL treeBuildingThreadIsFinished;
}

-(id)initWithFileList:(NSMutableArray *)fList;
-(id)initWithFileList:(NSMutableArray *)fList
		   windowName:(NSString *)wName;

-(IBAction)switchViews:(id)sender;

@end
