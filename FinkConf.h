/*
File: FinkConf.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 The FinkConf class serves as a model for the /sw/etc/fink.conf configuration
 file.  Its methods are used by FinkPreferences to modify the file and thus
 configure fink itself.

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

 Contact the author at sburrious@users.sourceforge.net.

 */

#import <Foundation/Foundation.h>

//---------------------------------------------->Global Variables
// eliminate for release version:
//#define DEBUG

//User Default Items
extern NSString *FinkBasePath;
extern NSString *FinkBasePathFound;
extern NSString *FinkUpdateWithFink;
extern NSString *FinkAlwaysChooseDefaults;
extern NSString *FinkScrollToSelection;
extern NSString *FinkSelectedColumnIdentifier;
extern NSString *FinkSelectedPopupMenuTitle;
extern NSString *FinkHTTPProxyVariable;
extern NSString *FinkLookedForProxy;


@interface FinkConf : NSObject 
{
	NSMutableDictionary *finkConfDict;
	NSUserDefaults *defaults;
	
}

-(void)readFinkConf;
-(BOOL)useUnstableMain;
-(void)setUseUnstableMain:(BOOL)shouldUseUnstable;
-(BOOL)useUnstableCrypto;
-(void)setUseUnstableCrypto:(BOOL)shouldUseUnstable;
-(BOOL)verboseOutput;
-(void)setVerboseOutput:(BOOL)verboseOutput;



-(void)writeToFile;

@end
