/*  
 File: FinkPackage.h

FinkCommander

Graphical user interface for Fink, a software package management system
that automates the downloading, patching, compilation and installation of
Unix software on Mac OS X.

Each instance of the FinkPackage class models the attributes of a single
fink package, including its name, version and category.  The class provides
methods for comparing packages by each attribute for use in sorting an array
of packages.

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

#import <Foundation/Foundation.h>
#import "SBString.h"

typedef NS_ENUM(NSInteger, FinkFlaggedType){
    NOT_FLAGGED,
    IS_FLAGGED
};

@interface FinkPackage : NSObject 
{
}

/*
 * Accessors
 */

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *status;

@property (nonatomic, copy) NSString *version;

@property (nonatomic, copy) NSString *installed;

@property (nonatomic, copy) NSString *binary;

@property (nonatomic, copy) NSString *stable;

@property (nonatomic, copy) NSString *unstable;

@property (nonatomic, copy) NSString *local;

@property (nonatomic, copy) NSString *category;

@property (nonatomic, copy) NSString *filename;

@property (nonatomic, copy) NSString *summary;

@property (nonatomic, copy) NSString *fulldesc;

@property (nonatomic, copy) NSString *weburl;

@property (nonatomic, copy) NSString *maintainer;

@property (nonatomic, copy) NSString *email;

@property (nonatomic) FinkFlaggedType flagged;

/*
 * Comparison Methods
 */

-(NSComparisonResult)normalCompareByName:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByName:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByVersion:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByVersion:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByInstalled:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByInstalled:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByBinary:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByBinary:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByStable:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByStable:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByUnstable:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByUnstable:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByStatus:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByStatus:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByCategory:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByCategory:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareBySummary:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareBySummary:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByLocal:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByLocal:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByMaintainer:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByMaintainer:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByFlagged:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByFlagged:(FinkPackage *)pkg;

/*
 * Querying the Package
 */

//Package name without -dev, -shlibs or -bin
-(NSString *)nameWithoutSplitoff:(BOOL *)changed;

//Check to see if path exists for a particular version
-(NSString *)pathToPackageInTree:(NSString *)tree
				withExtension:(NSString *)ext
				version:(NSString *)fversion;

//Find path without knowing version number
-(NSString *)pathToPackageInTree:(NSString *)tree
				withExtension:(NSString *)ext;

@end
