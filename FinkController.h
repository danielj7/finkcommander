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

* 	FinkDataController (MC) -- gathers and updates information on the user's fink
	installation in the form of an array of FinkPackage objects (M);

*	IOTaskWrapper (M) -- runs fink commands asynchronously in separate processes;

*	FinkOutputParser (M) -- parses the output from fink and apt-get commands and
	returns signals indicating what type of action, if any, is appropriate for that output; 
	will in a future release include signals that tell FinkCommander to send a follow-up
	message for additional instructions;

*	FinkTableViewController (VC) and FinkTextViewController (VC) -- control
	the primary user interface elements;
	
*	a FinkPreferences object (C) -- provides an interface for both the FinkCommander user
	interface system and for changing the fink.conf file (represented by
	the FinkConf object (M)); instantiates and communicates with user interface elements 
	defined in Preferences.nib;
	
*	FinkPackageInfo (C) -- obtains and formats information from FinkPackage
	objects for display in the Package Inspector (V); along with FinkController uses
	a FinkInstallationInfo object (M) to format emails sent to package maintainers; 
	instantiates and communicates with user interface elements defined in 
	PackageInfo.nib (V).

FinkController also creates the FinkCommander toolbar and registers the "factory defaults" 
for preferences set by FinkPreferences or programmatically.  The settings for each are 
read from the files Toolbar.plist and UserDefaults.plist, respectively.

Global variables, which are used solely to allow compiler checking for misspellings of 
defaults and notification identifiers, are declared in FinkGlobals.h.  Functions that 
do not fit well in the existing object model for FinkController are defined in 
FinkUtilities.m. 

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
#import "FinkDataController.h"
#import "FinkPackage.h"
#import "FinkPreferences.h"
#import "FinkPackageInfo.h"
#import "IOTaskWrapper.h"
#import "FinkTableViewController.h"
#import "FinkTextViewController.h"
#import "FinkInstallationInfo.h"
#import "FinkOutputParser.h"
#import "FinkUtilities.h"

enum {
	SOURCE_COMMAND,
	BINARY_COMMAND
};

enum {
	FCWEB = 1000,
	FCBUG = 1001,
	FINKDOC = 1002
};

enum {
	FILTER,
	INTERACTION
};

enum {
	DEFAULT,
	USER_CHOICE
};

@interface FinkController : NSWindowController <IOTaskWrapperController>
{
	//main window outlets
	IBOutlet id tableView;
	IBOutlet NSScrollView *tableScrollView;
	IBOutlet NSScrollView *outputScrollView;
	IBOutlet NSSplitView *splitView;
	IBOutlet id textView;
	IBOutlet id msgText;
	IBOutlet NSView *progressViewHolder;
	IBOutlet NSView *progressView;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSMenu *viewMenu;
	IBOutlet NSMenu *tableContextMenu;
	
	//password entry window outlets
	IBOutlet NSWindow *pwdWindow;
	IBOutlet NSSecureTextField *pwdField;
	
	//interaction window outlets
	IBOutlet NSWindow *interactionWindow;
	IBOutlet NSMatrix *interactionMatrix;
	IBOutlet NSTextField *interactionField;
	
	//search view outlets
	IBOutlet id searchView;
	IBOutlet NSPopUpButton *searchPopUpButton;
	IBOutlet NSTextField *searchTextField;

	//general instance variables

	FinkDataController *packages;
	
	NSUserDefaults *defaults;
	
	FinkPreferences *preferences;
	FinkPackageInfo *packageInfo;
	FinkOutputParser *parser;
	NSArray *selectedPackages;
	NSString *lastCommand;
	BOOL commandIsRunning;
	NSToolbar *toolbar;
	BOOL userChoseToTerminate;
	NSTimer *timer;

	NSString *password;
	BOOL pendingCommand;
	BOOL passwordError;
	NSMutableArray *lastParams;
	IOTaskWrapper *finkTask;
}

//Accessors
-(FinkDataController *)packages;

-(NSArray *)selectedPackages;
-(void)setSelectedPackages:(NSArray *)a;
-(NSString *)lastCommand;
-(void)setLastCommand:(NSString *)s;
-(void)setPassword:(NSString *)s;
-(NSMutableArray *)lastParams;
-(void)setLastParams:(NSMutableArray *)a;
-(void)setParser:(FinkOutputParser *)p;

-(void)scrollToVisible:(NSNumber *)n;

//Split view action methods
-(IBAction)collapseOutput:(id)sender;
-(IBAction)expandOutput:(id)sender;

//Menu and Toolbar Action Methods
-(IBAction)checkForLatestVersionAction:(id)sender;
-(IBAction)saveOutput:(id)sender;
-(void)didEnd:(NSSavePanel *)sheet
	  returnCode:(int)code
	 contextInfo:(void *)contextInfo;
-(IBAction)runCommand:(id)sender;
-(IBAction)runUpdater:(id)sender;
-(IBAction)terminateCommand:(id)sender;
-(IBAction)updateTable:(id)sender;
-(IBAction)showPreferencePanel:(id)sender;
-(IBAction)showPackageInfoPanel:(id)sender;
-(IBAction)showDescription:(id)sender;
//  help menu items
-(IBAction)goToWebsite:(id)sender;
-(IBAction)emailMaintainer:(id)sender;
-(IBAction)chooseTableColumn:(id)sender;

//Toolbar Methods
-(void)setupToolbar;
-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar
	   itemForItemIdentifier:(NSString *)itemIdentifier
   willBeInsertedIntoToolbar:(BOOL)flag;
-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
// reapplies filter if filter popup menu changes 
-(IBAction)refilter:(id)sender;

//Process Control Methods
// sheet methods for password window
-(IBAction)raisePwdWindow:(id)sender;
-(IBAction)endPwdWindow:(id)sender;
-(void)sheetDidEnd:(NSWindow *)sheet
		   returnCode:(int)returnCode
		  contextInfo:(void *)contextInfo;
// sheet methods for interaction window
-(IBAction)raiseInteractionWindow:(id)sender;
-(IBAction)endInteractionWindow:(id)sender;
-(void)interactionSheetDidEnd:(NSWindow *)sheet
			returnCode:(int)returnCode
			contextInfo:(void *)contextInfo;
// run the command
-(void)runCommandWithParameters:(NSMutableArray *)params;

@end
