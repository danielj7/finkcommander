/*
 File: SBDateColumn.h

 Observes NSTableViewColumnDidResizeNotifications in order to adjust the date
 format for its column in a manner similar to Finder.

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
#import "SBUtilities.h"

@interface SBDateColumnController: NSObject
{
}

-(instancetype)initWithColumn:(NSTableColumn *)myColumn;

-(instancetype)initWithColumn:(NSTableColumn *)myColumn
		 shortTitle:(NSString *)stitle;
	/*" The designated initializer "*/
-(instancetype)initWithColumn:(NSTableColumn *)myColumn
		 shortTitle:(NSString *)stitle 
		  longTitle:(NSString *)ltitle NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) NSTableColumn *column;

@property (nonatomic, copy) NSString *shortTitle;

@property (nonatomic, copy) NSString *longTitle;

-(void)adjustColumnAndHeaderDisplay:(NSNotification *)n;

@end
