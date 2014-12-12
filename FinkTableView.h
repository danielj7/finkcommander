/*
File: FinkTableView.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 FinkTableView, a subclass of NSTableView, includes methods
 for adding and removing columns from FinkCommander's table view, for sorting
 the table view when the user clicks the table header cells and for returning
 an array of the FinkPackage objects selected in the table.

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


@interface FinkTableView: NSTableView <NSTableViewDelegate,NSTableViewDataSource>
{
	NSUserDefaults *defaults;

	NSMutableDictionary *columnState;
}

//----------------------------------------------->Accessors
@property (nonatomic, copy) NSString *lastIdentifier;
@property (nonatomic, copy) NSArray *displayedPackages;
@property (nonatomic, copy) NSArray *selectedObjectInfo;
@property (nonatomic, readonly, copy) NSImage *normalSortImage;
@property (nonatomic, readonly, copy) NSImage *reverseSortImage;
@property (nonatomic, readonly, copy) NSArray *selectedPackageArray;

//----------------------------------------------->Column Manipulation
-(NSTableColumn *)makeColumnWithName:(NSString *)identifier;
-(void)addColumnWithName:(NSString *)identifier;
-(void)removeColumnWithName:(NSString *)identifier;

//----------------------------------------------->Actions
-(IBAction)openPackageFiles:(id)sender;

//----------------------------------------------->Sorting Methods
-(void)storeSelectedObjectInfo;
-(void)scrollToSelectedObject;
-(void)sortTableAtColumn:(NSTableColumn *)aTableColumn 
		inDirection:(NSString *)direction;
-(void)resortTableAfterFilter;

@end


