//
//  FinkGlobals.m
//  FinkCommander
//
//  Created by Steven Burr on Wed Jun 19 2002.
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
NSString *FinkHTTPProxyVariable = @"FinkHTTPProxyVariable";
NSString *FinkFTPProxyVariable = @"FinkFTPProxyVariable";
NSString *FinkAskForPasswordOnStartup = @"FinkAskForPasswordOnStartup";
NSString *FinkNeverAskForPassword = @"FinkNeverAskForPassword";
NSString *FinkAlwaysScrollToBottom = @"FinkAlwaysScrollToBottom";
NSString *FinkWarnBeforeRunning = @"FinkWarnBeforeRunning";
NSString *FinkWarnBeforeRemoving = @"FinkWarnBeforeRemoving";
NSString *FinkPackagesInTitleBar = @"FinkPackagesInTitleBar";
NSString *FinkAutoExpandOutput = @"FinkAutoExpandOutput";
NSString *FinkGiveEmailCredit = @"FinkGiveEmailCredit";

NSString *FinkSelectedColumnIdentifier = @"FinkSelectedColumnIdentifier";
NSString *FinkSelectedPopupMenuTitle = @"FinkSelectedPopupMenuTitle";
NSString *FinkLookedForProxy = @"FinkLookedForProxy";
NSString *FinkOutputViewRatio = @"FinkOutputViewRatio";

//Global variables identifying notifications
NSString *FinkConfChangeIsPending = @"FinkConfChangeIsPending";
NSString *FinkCommandCompleted = @"FinkCommandCompleted";
NSString *FinkPackageArrayIsFinished = @"FinkPackageArrayIsFinished";
NSString *FinkCollapseOutputView = @"FinkCollapseOutputView";

NSString *FinkCreditString = @"&body=%0A%0A--%0AFeedback%20courtesy%20%20of%20FinkCommander";