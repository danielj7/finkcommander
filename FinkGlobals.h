/*
File: FinkGlobals.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 The FinkGlobals files declare and define global variables used throughout the 
 project as keys for user default values and as notification items.
 
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


#import <Foundation/Foundation.h>
#import "SBString.h"

//comment out for release version:
//#define DEBUG

//User Default Items
//  Set by user
extern NSString *FinkBasePath;
extern NSString *FinkBasePathFound;
extern NSString *FinkOutputPath;
extern NSString *FinkUpdateWithFink;
extern NSString *FinkAlwaysChooseDefaults;
extern NSString *FinkScrollToSelection;
extern NSString *FinkHTTPProxyVariable;
extern NSString *FinkFTPProxyVariable;
extern NSString *FinkAskForPasswordOnStartup;
extern NSString *FinkNeverAskForPassword;
extern NSString *FinkAlwaysScrollToBottom;
extern NSString *FinkWarnBeforeRunning;
extern NSString *FinkWarnBeforeRemoving;
extern NSString *FinkPackagesInTitleBar;
extern NSString *FinkAutoExpandOutput;
extern NSString *FinkGiveEmailCredit;
extern NSString *FinkCheckForNewVersion;
//  not yet implemented
extern NSString *FinkLastCheckedForNewVersion;
extern NSString *FinkCheckForNewVersionInterval;
//  Set programmatically
extern NSString *FinkSelectedColumnIdentifier;
extern NSString *FinkSelectedPopupMenuTitle;
extern NSString *FinkOutputViewRatio;
extern NSString *FinkLookedForProxy;
extern NSString *FinkViewMenuSelectionStates;
extern NSString *FinkTableColumnsArray;

//Notification Names
extern NSString *FinkConfChangeIsPending;
extern NSString *FinkCommandCompleted;
extern NSString *FinkPackageArrayIsFinished;
extern NSString *FinkCollapseOutputView;

extern NSString *FinkCreditString;
