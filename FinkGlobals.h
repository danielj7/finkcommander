//
//  FinkGlobals.h
//  FinkCommander
//
//  Created by Steven Burr on Wed Jun 19 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBString.h"

// comment out for release version:
#define DEBUG

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
//  Set programmatically
extern NSString *FinkSelectedColumnIdentifier;
extern NSString *FinkSelectedPopupMenuTitle;
extern NSString *FinkOutputViewRatio;
extern NSString *FinkLookedForProxy;

//Notification Names
extern NSString *FinkConfChangeIsPending;
extern NSString *FinkCommandCompleted;
extern NSString *FinkPackageArrayIsFinished;
extern NSString *FinkCollapseOutputView;
