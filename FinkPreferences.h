/*
File: FinkPreferences.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 FinkPreferences connects the user's choices in the preferences windows to 
 values stored in the application's NSUserDefaults dictionary or to values
 in the fink.conf file.

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
#import "FinkConf.h"
#import "FinkGlobals.h"
#import "FinkUtilities.h"

@interface FinkPreferences : NSWindowController
{
}

@property (nonatomic, weak) IBOutlet NSTabView *tabView;

//widgets used for general preference settings
@property (nonatomic, weak) IBOutlet NSMatrix *pathChoiceMatrix;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *basePathTextField;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *outputPathTextField;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *scrollBackLimitTextField;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *perlPathTextField;
@property (nonatomic, weak) IBOutlet NSButton *scrollBackLimitButton;
@property (nonatomic, weak) IBOutlet NSButton *outputPathButton;
@property (nonatomic, weak) IBOutlet NSButton *perlPathButton;
@property (nonatomic, weak) IBOutlet NSButton *alwaysChooseDefaultsButton;
@property (nonatomic, weak) IBOutlet NSButton *scrollToBottomButton;
@property (nonatomic, weak) IBOutlet NSButton *warnBeforeRemovingButton;
@property (nonatomic, weak) IBOutlet NSButton *warnBeforeTerminatingButton;
@property (nonatomic, weak) IBOutlet NSButton *showPackagesInTitleButton;
@property (nonatomic, weak) IBOutlet NSButton *autoExpandOutputButton;
@property (nonatomic, weak) IBOutlet NSButton *giveEmailCreditButton;
@property (nonatomic, weak) IBOutlet NSButton *showRedundantPackagesButton;
@property (nonatomic, weak) IBOutlet NSButton *automaticallyCheckUpdatesButton;

//widgets used for environment settings
@property (nonatomic, weak) IBOutlet NSTableView *environmentTableView;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *nameTextField;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *valueTextField;
@property (nonatomic, weak) IBOutlet NSButton *addEnvironmentSettingButton;
@property (nonatomic, weak) IBOutlet NSButton *deleteEnvironmentSettingButton;

//widgets used to alter table behavior
@property (nonatomic, weak) IBOutlet NSButton *scrollToSelectionButton;
@property (nonatomic, weak) IBOutlet NSButton *allowRegexFilterButton;

//widgets used to alter fink.conf
@property (nonatomic, weak) IBOutlet NSButton *useUnstableMainButton;
@property (nonatomic, weak) IBOutlet NSButton *useUnstableCryptoButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *verboseOutputPopupButton;
@property (nonatomic, weak) IBOutlet NSButton *passiveFTPButton;
@property (nonatomic, weak) IBOutlet NSButton *keepBuildDirectoryButton;
@property (nonatomic, weak) IBOutlet NSButton *keepRootDirectoryButton;
@property (nonatomic, weak) IBOutlet NSButton *httpProxyButton;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *httpProxyTextField;
@property (nonatomic, weak) IBOutlet NSButton *ftpProxyButton;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *ftpProxyTextField;
@property (nonatomic, weak) IBOutlet NSButton *fetchAltDirButton;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *fetchAltDirTextField;
@property (nonatomic, weak) IBOutlet NSMatrix *downloadMethodMatrix;
@property (nonatomic, weak) IBOutlet NSMatrix *rootMethodMatrix;
@property (nonatomic, weak) IBOutlet NSImageView *titleBarImageView;

//widgets used for software update
@property (nonatomic, weak) IBOutlet NSButton *checkNowButton;

//main button actions ("Apply", "OK", "Cancel")
-(IBAction)setPreferences:(id)sender;
-(IBAction)setAndClose:(id)sender;
-(IBAction)cancel:(id)sender;

//environment setting buttons
-(IBAction)addEnvironmentSetting:(id)sender;
-(IBAction)removeEnvironmentSettings:(id)sender;
-(IBAction)restoreEnvironmentSettings:(id)sender;

//choose directory for text fields ("Browse" button action)
-(IBAction)selectDirectory:(id)sender;

//record whether certain preference items have changed
-(IBAction)setPathChoiceChanged:(id)sender;
-(IBAction)setAutoExpandChanged:(id)sender;
-(IBAction)setFinkConfChanged:(id)sender;
-(IBAction)setFinkTreesChanged:(id)sender;

//set title bar image to reflect user's choice
-(IBAction)setTitleBarImage:(id)sender;

//software update buttons
-(IBAction)checkNow:(id)sender;

@end
