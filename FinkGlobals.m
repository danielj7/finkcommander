//
//  FinkGlobals.m
//  FinkCommander
//
//  Created by Steven Burr on Wed Jun 19 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "FinkGlobals.h"

//Global variables used throughout FinkCommander source code to set
//user defaults.
NSString *FinkBasePath = @"FinkBasePath";
NSString *FinkBasePathFound = @"FinkBasePathFound";
NSString *FinkOutputPath = @"FinkOutputPath";
NSString *FinkUpdateWithFink = @"FinkUpdateWithFink";
NSString *FinkAlwaysChooseDefaults = @"FinkAlwaysChooseDefaults";
NSString *FinkScrollToSelection = @"FinkScrollToSelection";
NSString *FinkSelectedColumnIdentifier = @"FinkSelectedColumnIdentifier";
NSString *FinkSelectedPopupMenuTitle = @"FinkSelectedPopupMenuTitle";
NSString *FinkHTTPProxyVariable = @"FinkHTTPProxyVariable";
NSString *FinkFTPProxyVariable = @"FinkFTPProxyVariable";
NSString *FinkLookedForProxy = @"FinkLookedForProxy";
NSString *FinkAskForPasswordOnStartup = @"FinkAskForPasswordOnStartup";
NSString *FinkNeverAskForPassword = @"FinkNeverAskForPassword";
NSString *FinkAlwaysScrollToBottom = @"FinkAlwaysScrollToBottom";
NSString *FinkWarnBeforeRunning = @"FinkWarnBeforeRunning";
NSString *FinkWarnBeforeRemoving = @"FinkWarnBeforeRemoving";
NSString *FinkPackagesInTitleBar = @"FinkPackagesInTitleBar";
NSString *FinkOutputViewRatio = @"FinkOutputViewRatio";
NSString *FinkAutoExpandOutput = @"FinkAutoExpandOutput";

//Global variables identifying notifications
NSString *FinkConfChangeIsPending = @"FinkConfChangeIsPending";
NSString *FinkCommandCompleted = @"FinkCommandCompleted";
NSString *FinkPackageArrayIsFinished = @"FinkPackageArrayIsFinished";
NSString *FinkCollapseOutputView = @"FinkCollapseOutputView";
