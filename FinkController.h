/* 
File: FinkController.h

FinkCommander

Graphical user interface for Fink, a software package management system 
that automates the downloading, patching, compilation and installation of
Unix software on Mac OS X.

FinkController is the hub of the FinkCommander object system.  It instantiates and
communicates with:

* 	user interface elements created in Interface Builder and located in the 
	MainMenu.nib file (V).

* 	FinkData (M) -- gathers and updates information on the user's fink
	installation in the form of an array of FinkPackage objects (M);

*	AuthorizedExecutable (M) -- runs fink commands asynchronously in separate processes using
	Apple's Security Framework for authorization;

*	FinkOutputParser (M) -- parses the output from fink and apt-get commands and
	returns signals indicating what type of action, if any, is appropriate for that output; 
	some signals tell FinkController to send a follow-up message for additional 
	information;

*	FinkTableView (VC) and FinkTextViewController (C) -- control
	the primary user interface elements; FinkTableView is a subclass
	of NSTableView in order to customize drag and drop behavior;
	
*	a FinkPreferences object (C) -- provides an interface for both the FinkCommander user
	interface system and for changing the fink.conf file (represented by
	the FinkConf object (M)); instantiates and communicates with user interface elements 
	defined in Preferences.nib (V);
	
*	FinkPackageInfo (C) -- obtains and formats information from FinkPackage
	objects for display in the Package Inspector (V); along with FinkController uses
	a FinkInstallationInfo object (M) to format emails sent to package maintainers; 
	instantiates and communicates with user interface elements defined in 
	PackageInfo.nib (V) and in MyTextView (V).
	
*	an SBTreeWindowManager (C) object -- handles the creation and destruction of 
	package file browser windows.  The objects created by SBTreeWindowManager have a 
	different prefix and are in a separate subdirectory and Project Builder group 
	(SBTreeFiles), because I thought they might prove useful in other projects. 

FinkController also creates the FinkCommander toolbar and registers the "factory defaults" 
for preferences set by FinkPreferences or programmatically.  The settings for each are 
read from the files Toolbar.plist and UserDefaults.plist, respectively.  A FinkToolbar subclass
of NSToolbar is included solely to enable resizing of the custom filter view when
the toolbar is resized.  There is currently no delegate method for this.

Global variables, which are used solely to allow compiler checking for misspellings of 
defaults and notification identifiers, are declared in FinkGlobals.h.  Functions that 
do not fit well in the existing object model for FinkController are defined in 
FinkUtilities.m.

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
#include <regex.h>

#import "FinkGlobals.h"
#import "FinkData.h"
#import "FinkPackage.h"
#import "FinkPreferences.h"
#import "FinkPackageInfo.h"
#import "FinkWarningDialog.h"
#import "AuthorizedExecutable.h"
#import "FinkTableView.h"
#import "FinkTextViewController.h"
#import "FinkSplitView.h"
#import "FinkToolbar.h"
#import "FinkInstallationInfo.h"
#import "FinkOutputParser.h"
#import "FinkUtilities.h"
#import "SBTreeWindowManager.h"
#import "SBMutableAttributedString.h"

@interface FinkController : NSObject <NSFileManagerDelegate, NSToolbarDelegate, NSTextFieldDelegate, AuthorizedExecutableDelegate>
{
}

#pragma mark - Main window outlets
// Top level outlets should be strong, all else weak.
// NSTextView can't be weak, however, and has to be unsafe_unretained.
@property (nonatomic, strong) IBOutlet NSWindow *window;
@property (nonatomic, weak) IBOutlet FinkTableView *tableView;
@property (nonatomic, weak) IBOutlet id tableViewController;
@property (nonatomic, weak) IBOutlet NSScrollView *tableScrollView;
@property (nonatomic, weak) IBOutlet NSScrollView *outputScrollView;
@property (nonatomic, weak) IBOutlet FinkSplitView *splitView;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextView *textView;
@property (nonatomic, weak) IBOutlet NSCell *msgText;
@property (nonatomic, weak) IBOutlet NSView *progressViewHolder;
@property (nonatomic, weak) IBOutlet NSView *progressView;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, weak) IBOutlet NSMenu *columnsMenu;
@property (nonatomic, weak) IBOutlet NSMenuItem *collapseExpandMenuItem;
@property (nonatomic, weak) IBOutlet NSMenu *tableContextMenu;
@property (nonatomic, weak) IBOutlet NSMenu *windowMenu;

#pragma mark - Interaction window outlets
@property (nonatomic, strong) IBOutlet NSWindow *interactionWindow;
@property (nonatomic, weak) IBOutlet NSMatrix *interactionMatrix;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *interactionField;

#pragma mark - Search view outlets
@property (nonatomic, weak) IBOutlet NSView *searchView;
@property (nonatomic, unsafe_unretained) IBOutlet NSSearchField *searchTextField;

#pragma mark - Other objects
@property (nonatomic) NSUserDefaults *defaults;
@property (nonatomic, copy) NSString *launcher;

#pragma mark - Flags
@property (nonatomic, getter=isCommandRunning) BOOL commandRunning;
@property (nonatomic, getter=isCommandTerminated) BOOL commandTerminated;
@property (nonatomic, getter=isPendingCommand) BOOL pendingCommand;
@property (nonatomic, getter=isToolBeingFixed) BOOL toolBeingFixed;
@property (nonatomic, getter=isOutputDynamic) BOOL outputDynamic;

@property (nonatomic) NSInteger searchTag;

#pragma mark - Accessors
@property (nonatomic) FinkPreferences *preferences;
@property (nonatomic) FinkPackageInfo *packageInfo;
@property (nonatomic) FinkInstallationInfo *installationInfo;
@property (nonatomic) FinkWarningDialog *warningDialog;
@property (nonatomic) FinkTextViewController *textViewController;
@property (nonatomic) FinkToolbar *toolbar;
@property (nonatomic) AuthorizedExecutable *finkTask;
@property (nonatomic) AuthorizedExecutable *killTask;
@property (nonatomic) SBTreeWindowManager *treeManager;
@property (nonatomic, readonly) FinkData *packages;
@property (nonatomic, copy) NSString *lastCommand;
@property (nonatomic) FinkOutputParser *parser;

#pragma mark - Menu and Toolbar Action Methods
-(void)checkForLatestVersion:(BOOL)notifyWhenCurrent;
-(IBAction)showPreferencePanel:(id)sender;
-(IBAction)updateTable:(id)sender;
-(IBAction)saveOutput:(id)sender;
-(IBAction)showDescription:(id)sender;
-(IBAction)terminateCommand:(id)sender;
-(IBAction)showPackageInfoPanel:(id)sender;
-(IBAction)goToWebsite:(id)sender;
-(IBAction)sendPositiveFeedback:(id)sender;
-(IBAction)sendNegativeFeedback:(id)sender;
-(IBAction)chooseTableColumn:(id)sender;
-(IBAction)sortByPackageElement:(id)sender;
-(IBAction)toggleFlags:(id)sender;
-(IBAction)openDocumentation:(id)sender;
-(IBAction)openPackageFileViewer:(id)sender;
-(IBAction)bringBackMainWindow:(id)sender;
-(IBAction)openHelpInWebBrowser:(id)sender;
-(IBAction)showAboutWindow:(id)sender;
-(void)treeWindowWillClose:(id)sender;

#pragma mark - Toolbar Methods
-(void)setupToolbar;
-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar
	itemForItemIdentifier:(NSString *)itemIdentifier
	willBeInsertedIntoToolbar:(BOOL)flag;
-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
-(IBAction)refilter:(id)sender;

#pragma mark - Process Control Methods
//  sheet methods for interaction window
-(IBAction)raiseInteractionWindow:(id)sender;
-(IBAction)endInteractionWindow:(id)sender;
-(void)interactionSheetDidEnd:(NSWindow *)sheet
			returnCode:(NSInteger)returnCode
			contextInfo:(void *)contextInfo;
//  running the command
-(IBAction)runPackageSpecificCommand:(id)sender;
-(IBAction)runNonSpecificCommand:(id)sender;
-(IBAction)runForceRemove:(id)sender;
#ifndef OSXVER101
-(IBAction)runPackageSpecificCommandInTerminal:(id)sender;
-(IBAction)runNonSpecificCommandInTerminal:(id)sender;
#endif

#pragma mark - AuthorizedExecutable delegate methods
-(void)scrollToVisible:(NSNumber *)n;  //helper method used by captureOutput
-(void)captureOutput:(NSString *)output forExecutable:(id)ignore;
-(void)executableFinished:(id)ignore withStatus:(NSNumber *)number;

@end
