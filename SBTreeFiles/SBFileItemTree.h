/*
 File: SBFileItemTree.h

 An SBFileItemTree models a directory tree for selected files in
 the file system.  Given a list of file paths, the buildTreeFromFileList
 method immediately creates a complete tree data structure consisting of
 SBFileItems representing each of the paths.  A lazy method would reduce
 memory consumption but would slow down the display.  
 
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
#import "SBFileItem.h"
#import "SBUtilities.h"

extern NSString *SBAscendingOrder;
extern NSString *SBDescendingOrder;

//Functions used by both SBBrowserView and SBOutlineViewController
extern BOOL openFileAtPath(NSString *);
extern void alertProblemPaths(NSArray *);

@interface SBFileItemTree: NSObject
{
    SBFileItem *_sbrootItem;
    NSString *_sbName;
    NSLock *sbLock;

    unsigned long totalSize;
    unsigned long itemCount;
}

/*
 *	Initialization
 */
-(instancetype)initWithFileArray:(NSMutableArray *)flist
				  name:(NSString *)aName NS_DESIGNATED_INITIALIZER;

/*
 *	Accessors
 */

// Total size in bytes of all files in the tree
@property (nonatomic, readonly) unsigned long totalSize;
//Total number of file items (excluding directories)
@property (nonatomic, readonly) unsigned long itemCount;

// Top level directory
@property (nonatomic, strong) SBFileItem *rootItem;

/*	String used to identify a tree in a Distributed Objects
	notification (see below).  The string should be unique within an 
	application to make sure notification receivers correctly
	identify the tree object.  */
@property (nonatomic, copy) NSString *name;


/*
 *	Building the Tree
 *
 *	Designed to run in a separate thread.  Posts an
 *	"SBTreeCompleteNotification" on completion with the tree's
 *	name as the object.
 */

-(void)buildTreeFromFileList:(NSMutableArray *)flist;


/*
 *	Sorting the Tree
 *
 * 	The arguments should be an SBFileItem attribute (filename, size, mdate) and
 *	either @"ascending" or @"descending".
 */

-(void)sortTreeByElement:(NSString *)element
    inOrder:(NSString *)order;

@end

