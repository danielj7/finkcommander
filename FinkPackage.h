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

enum {
	NOT_FLAGGED,
	IS_FLAGGED
};

#import <Foundation/Foundation.h>
#import "SBString.h"

@interface FinkPackage : NSObject 
{
	//Attributes of a fink package
	NSString *name;
	NSString *status;
	NSString *version;
	NSString *installed;
	NSString *binary;
	NSString *stable;
	NSString *unstable;
	NSString *category;
	NSString *summary;
	NSString *fulldesc;
	NSString *weburl;
	NSString *maintainer;
	NSString *email;
	int flagged;
}

/*
 * Accessors
 */

-(NSString *)name;
-(void)setName:(NSString *)s;

-(NSString *)status;
-(void)setStatus:(NSString *)s;

-(NSString *)version;
-(void)setVersion:(NSString *)s;

-(NSString *)installed;
-(void)setInstalled:(NSString *)s;

-(NSString *)binary;
-(void)setBinary:(NSString *)s;

-(NSString *)stable;
-(void)setStable:(NSString *)s;

-(NSString *)unstable;
-(void)setUnstable:(NSString *)s;

-(NSString *)category;
-(void)setCategory:(NSString *)s;

-(NSString *)summary;
-(void)setSummary:(NSString *)s;

-(NSString *)fulldesc;
-(void)setFulldesc:(NSString *)s;

-(NSString *)weburl;
-(void)setWeburl:(NSString *)s;

-(NSString *)maintainer;
-(void)setMaintainer:(NSString *)s;

-(NSString *)email;
-(void)setEmail:(NSString *)s;

-(int)flagged;
-(void)setFlagged:(int)f;

/*
 * Comparison Methods
 */

//-(NSComparisonResult)xExists:(NSString *)x yExists:(NSString *)y;

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

-(NSComparisonResult)normalCompareByBinary:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByBinary:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByUnstable:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByUnstable:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByMaintainer:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByMaintainer:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByFlagged:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByFlagged:(FinkPackage *)pkg;

/*
 * Querying the Package
 */

-(NSString *)nameWithoutSplitoff;

-(NSString *)pathToPackageInTree:(NSString *)tree
			withExtension:(NSString *)ext;

@end
