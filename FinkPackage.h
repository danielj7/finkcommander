/*  
 File: FinkPackage.h

FinkCommander

Graphical user interface for Fink, a software package management system
that automates the downloading, patching, compilation and installation of
Unix software on Mac OS X.

Each instance of the FinkPackage class stores the attributes of a single
fink package, including its name, version and category.  The class provides
methods for comparing packages by each attribute for use in sorting an array
of packages.

Copyright (C) 2002  Steven J. Burr

This program is free software; you can redistribute it and/or modify
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

Contact the author at sburr@mac.com.

*/

#import <Foundation/Foundation.h>

#define PACKAGE_ATTRIBUTES @"name", @"version", @"installed", @"category", @"description", @"binary", @"unstable"
#define ATTRIBUTE_NUMBER 7

@interface FinkPackage : NSObject 
{
	//Attributes of a fink package
	NSString *name;
	NSString *version;
	NSString *installed;
	NSString *category;
	NSString *description;
	NSString *binary;
	NSString *unstable;
}

-(id)init;

//Instance variable access
-(NSString *)name;
-(void)setName:(NSString *)s;
-(NSString *)version;
-(void)setVersion:(NSString *)s;
-(NSString *)installed;
-(void)setInstalled:(NSString *)s;
-(NSString *)category;
-(void)setCategory:(NSString *)s;
-(NSString *)description;
-(void)setDescription:(NSString *)s;
-(NSString *)binary;
-(void)setBinary:(NSString *)s;
-(NSString *)unstable;
-(void)setUnstable:(NSString *)s;

//Comparison methods
-(NSComparisonResult)normalCompareByName:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByName:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByVersion:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByVersion:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByInstalled:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByInstalled:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByCategory:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByCategory:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByDescription:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByDescription:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByBinary:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByBinary:(FinkPackage *)pkg;

-(NSComparisonResult)normalCompareByUnstable:(FinkPackage *)pkg;
-(NSComparisonResult)reverseCompareByUnstable:(FinkPackage *)pkg;

@end
