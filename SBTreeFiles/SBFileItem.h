/*
 File: SBFileItem.h

 SBFileItems serve as Models for file objects, including directories, in 
 the Mac OS X file system.  Items respond to accessors for several file attributes.
 Directory items respond to a number of messages relating to their "children," i.e. 
 the files and subdirectories contained by the items.  

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

#import <Foundation/Foundation.h>
#import "SBUtilities.h"

@interface SBFileItem: NSObject
{
}

/* 
 *	Item Creation 
 */

-(instancetype)initWithPath:(NSString *)p NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithURL:(NSURL *)url;

/* 
 *	Accessors 
 *	
 *	Most of these are self-explanatory
 *
 */

@property (nonatomic, copy) NSArray *children;

//Full path to the file
@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, copy) NSString *path;

//Name of the file without the path
@property (nonatomic, copy) NSString *filename;

@property (nonatomic) unsigned long size;

/* Not used yet:
-(NSDate *)cdate;
-(void)setCdate:(NSDate *)newCdate;
*/

@property (nonatomic, copy) NSDate *mdate;

/*
 *	Family Ties
 *	
 *	Again, mostly self-explanatory
 *
 */

/* 	Retains the child added, which should therefore
	be released or autoreleased by the caller.  */
-(BOOL)addChild:(SBFileItem *)item;

@property (nonatomic, readonly) NSInteger numberOfChildren;

-(BOOL)hasChild:(SBFileItem *)item;

-(SBFileItem *)childAtIndex:(NSUInteger)n;

-(SBFileItem *)childWithPath:(NSString *)iPath;

-(SBFileItem *)childWithFileName:(NSString *)fname;

@property (nonatomic, readonly, copy) NSString *pathToParent;

@end
