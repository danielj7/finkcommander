/*
File: FinkConf.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 The FinkConf class serves as a model for the /sw/etc/fink.conf configuration
 file.  Its methods are used by FinkPreferences to modify the file and thus
 configure fink itself.  It sends a notification to FinkController which 
 triggers the runCommandWithParams: method to make changes that require 
 root privileges.

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
-(BOOL)useUnstableMain;
-(void)setUseUnstableMain:(BOOL)shouldUseUnstable;
-(BOOL)useUnstableCrypto;
-(void)setUseUnstableCrypto:(BOOL)shouldUseUnstable;
-(BOOL)extendedVerboseOptions;
-(int)verboseOutput;
-(void)setVerboseOutput:(int)verboseOutput;
-(BOOL)passiveFTP;
-(void)setPassiveFTP:(BOOL)passiveFTP;
-(BOOL)keepBuildDir;
-(void)setKeepBuildDir:(BOOL)passiveFTP;
-(BOOL)keepRootDir;
-(void)setKeepRootDir:(BOOL)passiveFTP;
-(NSString *)useHTTPProxy;
-(void)setUseHTTPProxy:(NSString *)s;
-(NSString *)useFTPProxy;
-(void)setUseFTPProxy:(NSString *)s;
-(NSString *)downloadMethod;
-(void)setDownloadMethod:(NSString *)s;
-(NSString *)rootMethod;
-(void)setRootMethod:(NSString *)s;
-(NSString *)fetchAltDir;
-(void)setFetchAltDir:(NSString *)s;

//Set flag that determines whether fink index
//command should be run
-(void)setFinkTreesChanged:(BOOL)b;

//Begin convulted process of writing changes to fink.conf
-(void)writeToFile;

@end
