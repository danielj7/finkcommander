/*
File: FinkConf.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 The FinkConf class serves as a model for the /sw/etc/fink.conf configuration
 file.  Its methods are used by FinkPreferences to modify the file and thus
 configure fink itself.  It sends a notification to FinkController which 
 triggers the launchCommandWithArguments: method to make changes that require 
 root privileges.

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
#import "FinkInstallationInfo.h"

//---------------------------------------------->Global Variables


@interface FinkConf : NSObject 
{
	NSMutableDictionary *finkConfDict;
	NSUserDefaults *defaults;
	NSString *proxyHTTP;
	BOOL finkTreesChanged;
}

//Get settings from the fink.conf file
-(void)readFinkConf;

//Get and set configuration parameters
@property (nonatomic) BOOL useUnstableMain;
@property (nonatomic) BOOL useUnstableCrypto;
@property (nonatomic, readonly) BOOL extendedVerboseOptions;
@property (nonatomic) NSInteger verboseOutput;
@property (nonatomic) BOOL passiveFTP;
@property (nonatomic) BOOL keepBuildDir;
@property (nonatomic) BOOL keepRootDir;
@property (nonatomic, copy) NSString *useHTTPProxy;
@property (nonatomic, copy) NSString *useFTPProxy;
@property (nonatomic, copy) NSString *downloadMethod;
@property (nonatomic, copy) NSString *rootMethod;
@property (nonatomic, copy) NSString *fetchAltDir;
@property (nonatomic, readonly, copy) NSString *distribution;

//Set flag that determines whether fink index
//command should be run
-(void)setFinkTreesChanged:(BOOL)b;

//Begin convulted process of writing changes to fink.conf
-(void)writeToFile;

@end
