/*
 File: SBTreeWindowController.h

 Serves as the window controller for a particular package file browser window
 and creates the following model objects, custom views and controllers:
 
 *	An SBFileItemTree (M), a tree-structured collection of SBFileItems (M);
	
 *	An SBOutlineViewController (C), which connects the SBFileItemTree to the
	custom SBOutlineView;
	
 *  An SBBrowserView (V/C), which uses delegate methods to display the SBFileItem
	tree in a browser view and customizes the view's behavior with the help of
	an SBBrowserMatrix (V);
 
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
}

@property (nonatomic, strong) IBOutlet NSWindow *sbTreeWindow;
@property (nonatomic, weak) IBOutlet NSTabView *tabView;
@property (nonatomic, weak) IBOutlet NSScrollView *outlineScrollView;
@property (nonatomic, weak) IBOutlet id outlineView;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *msgTextField;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *loadingIndicator;
@property (nonatomic, weak) IBOutlet NSBrowser *oldBrowser;

-(instancetype)initWithFileList:(NSMutableArray *)fList;
-(instancetype)initWithFileList:(NSMutableArray *)fList
		   windowName:(NSString *)wName NS_DESIGNATED_INITIALIZER;

-(IBAction)switchViews:(id)sender;

@end
