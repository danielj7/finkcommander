/*
 File: SBTreeWindowController.h



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

@interface SBTreeWindowController: NSWindowController
{
	IBOutlet NSTabView *tabView;
	IBOutlet NSScrollView *outlineScrollView;
    IBOutlet id outlineView;
    IBOutlet NSTextField *msgTextField;
    IBOutlet NSProgressIndicator *loadingIndicator;
	IBOutlet NSBrowser *oldBrowser;
	IBOutlet NSBox *divider;

	SBFileItemTree *tree;
    SBOutlineViewController *oController;
	SBBrowserView *browser;
    SBDateColumnController *mDateColumnController;
    NSMutableArray *fileList;
	NSString  *_sbActiveView;
	BOOL treeBuildingThreadIsFinished;
}

-(id)initWithFileList:(NSMutableArray *)fList;
-(id)initWithFileList:(NSMutableArray *)fList
		   windowName:(NSString *)wName;

-(NSMutableArray *)fileList;
-(void)setFileList:(NSMutableArray *)fList;

-(NSString *)activeView;
-(void)setActiveView:(NSString *)newActiveView;

-(IBAction)switchViews:(id)sender;

-(void)startedLoading;
-(void)finishedLoading:(NSNotification *)n;

@end
