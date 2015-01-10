/*
 File: SBOutlineViewController.h

 Delegate and data source for the outline view.  Implements methods to 
 display the items in the SBFileItemTree created by the parent 
 SBTreeWindowController.

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
#import "SBOutlineView.h"
#import "SBFileItemTree.h"
#import "SBFileItem.h"
#import "SBDateColumnController.h"
#import "SBUtilities.h"

extern NSString *sbAscending;
extern NSString *sbDescending;

@interface SBOutlineViewController: NSObject <NSOutlineViewDelegate,NSOutlineViewDataSource>
{
}

-(instancetype)initWithTree:(SBFileItemTree *)aTree
			 view:(NSOutlineView *)oView NS_DESIGNATED_INITIALIZER;

	

/* 
	Outline view data source methods
*/

-(NSInteger)outlineView:(NSOutlineView *)outlineView
		numberOfChildrenOfItem:(id)item;

-(BOOL)outlineView:(NSOutlineView *)outlineView 
		isItemExpandable:(id)item;

-(id)outlineView:(NSOutlineView *)outlineView 
		child:(NSInteger)index
		ofItem:(id)item;

-(id)outlineView:(NSOutlineView *)outlineView 
		objectValueForTableColumn:(NSTableColumn *)tableColumn 
		byItem:(id)item;

//-(IBAction)sortByColumn:(id)sender;

/*
	Replacement for non-functional NSOutlineView
	collapseItem:collapseChildren:
*/

-(void)collapseItemAndChildren:(SBFileItem *)item;

@end

