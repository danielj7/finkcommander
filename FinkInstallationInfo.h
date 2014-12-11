/*
File: FinkInstallationInfo.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 FinkInstallationInfo models the state of the user's fink installation and
 development tools.  The information it provides is used primarily to create
 the email sig for reports to package maintainers.

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
#import "FinkGlobals.h"
#import "FinkUtilities.h"

@interface FinkInstallationInfo : NSObject 
{
	NSFileManager *manager;
}

+(FinkInstallationInfo *)sharedInfo;

@property (nonatomic, readonly, copy) NSString *finkVersion;

//Returns a string with the versions of fink, Mac OS X, gcc, make, and Dev Tools
//installed on the user's system
@property (nonatomic, readonly, copy) NSString *installationInfo;

@property (nonatomic, readonly, copy) NSString *formattedEmailSig;

@end
