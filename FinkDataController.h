/*  
 File: FinkDataController.h

FinkCommander

Graphical user interface for Fink, a software package management system
that automates the downloading, patching, compilation and installation of
Unix software on Mac OS X.

The FinkDataController class obtains information about installed and available fink 
packages and stores the information in an array of FinkPackage instances.

Copyright (C) 2002  Steven J. Burr

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
#import "SBString.h"

@interface FinkDataController : NSObject
{
	NSUserDefaults *defaults;
	NSTask *finkListCommand;
	NSMutableArray *array;
	NSDictionary *binaryPackages;
	NSString *pathToDists;
	NSDate *start;
}

//Accessors
-(NSMutableArray *)array;
-(void)setArray:(NSMutableArray *)a;
-(void)setStart:(NSDate *)d;

//Update array to reflect latest package information.
-(void)update;
-(void)updateManuallyWithCommand:(NSString *)cmd packages:(NSArray *)pkgs;
-(int)installedPackagesCount;

@end
