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

*	AuthorizedExecutable (M) -- runs fink commands asynchronously in separate processes using
	Apple's Security Framework for authorization;

*	FinkOutputParser (M) -- parses the output from fink and apt-get commands and
	returns signals indicating what type of action, if any, is appropriate for that output; 
	some signals tell FinkCommander to send a follow-up message for additional 
	information;

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
#import "FinkWarningDialog.h"
#import "AuthorizedExecutable.h"
#import "FinkTableViewController.h"
#import "FinkTextViewController.h"
#import "FinkSplitView.h"
#import "FinkInstallationInfo.h"
#import "FinkOutputParser.h"
#import "FinkUtilities.h"

#define  CMD_REQUIRES_UPDATE(x) ([(x) isEqualToString: @"install"]	|| 				\
							[(x) isEqualToString: @"remove"]		|| 				\
							[(x) isEqualToString: @"index"]			|| 				\
							[(x) contains: @"build"]				|| 				\
							[(x) contains: @"dpkg"]					|| 				\
							[(x) contains: @"update"])

#define TAG_NAME_ARRAY [NSArray arrayWithObjects: 									\
							@"version",           									\
							@"binary",           									\
							@"stable",												\
							@"unstable",											\
							@"status",												\
							@"category",											\
							@"summary",												\
							@"maintainer",											\
							@"installed",											\
							@"name",												\
							nil]

#define NAME_TAG_DICTIONARY [NSDictionary dictionaryWithObjectsAndKeys: 			\
							[NSNumber numberWithInt: VERSION], @"version",          \
							[NSNumber numberWithInt: BINARY], @"binary",            \
							[NSNumber numberWithInt: STABLE], @"stable",            \
							[NSNumber numberWithInt: UNSTABLE], @"unstable",        \
							[NSNumber numberWithInt: STATUS], @"status",            \
							[NSNumber numberWithInt: CATEGORY], @"category",        \
							[NSNumber numberWithInt: SUMMARY], @"summary",          \
							[NSNumber numberWithInt: MAINTAINER], @"maintainer",	\
							[NSNumber numberWithInt: INSTALLED], @"installed",      \
							[NSNumber numberWithInt: NAME], @"name",                \
							nil]

enum {
    VERSION    	= 2000, 
    BINARY     	= 2001,
    STABLE     	= 2002,
    UNSTABLE   	= 2003,
    STATUS     	= 2004,
    CATEGORY   	= 2005,
    SUMMARY    	= 2006,
    MAINTAINER 	= 2007,
    INSTALLED  	= 2008,
	NAME	   	= 2009
};

enum {
	FCWEB 		= 1000,
	FCBUG 		= 1001,
	FINKDOC 	= 1002
};

enum {
	SOURCE_COMMAND,
	BINARY_COMMAND
};

enum {
	FILTER,
	INTERACTION
};

enum {
	DEFAULT,
	USER_CHOICE
};

@interface FinkController : NSObject
{
	//main window outlets
	IBOutlet NSWindow *window;
	IBOutlet id tableView;
	IBOutlet NSScrollView *tableScrollView;
	IBOutlet NSScrollView *outputScrollView;
	IBOutlet id splitView;
	IBOutlet id textView;
	IBOutlet id msgText;
	IBOutlet NSView *progressViewHolder;
	IBOutlet NSView *progressView;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSMenu *viewMenu;
	IBOutlet NSMenu *tableContextMenu;
	
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
	FinkPreferences *preferences;
	FinkPackageInfo *packageInfo;
	FinkWarningDialog *warningDialog;
	FinkOutputParser *parser;
	AuthorizedExecutable *finkTask;
	AuthorizedExecutable *killTask;
	NSUserDefaults *defaults;
	NSToolbar *toolbar;
	NSArray *selectedPackages;
	NSMutableArray *lastParams;
	NSString *lastCommand;
	NSString *launcher;
	BOOL commandIsRunning;
	BOOL userConfirmedQuit;
	BOOL commandTerminated;
	BOOL pendingCommand;
	BOOL toolIsBeingFixed;
}

//Accessors
-(FinkDataController *)packages;
-(NSArray *)selectedPackages;
-(void)setSelectedPackages:(NSArray *)a;
-(NSString *)lastCommand;
-(void)setLastCommand:(NSString *)s;
-(NSMutableArray *)lastParams;
-(void)setLastParams:(NSMutableArray *)a;
-(void)setParser:(FinkOutputParser *)p;

//Helper method used by appendOutput
-(void)scrollToVisible:(NSNumber *)n;

//Menu and Toolbar Action Methods
-(void)checkForLatestVersion:(BOOL)notifyWhenCurrent;
-(IBAction)checkForLatestVersionAction:(id)sender;
-(IBAction)saveOutput:(id)sender;
-(void)didEnd:(NSSavePanel *)sheet
	  returnCode:(int)code
	 contextInfo:(void *)contextInfo;
-(IBAction)runCommand:(id)sender;
-(IBAction)runUpdater:(id)sender;
-(IBAction)forceRemove:(id)sender;
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
// sheet methods for interaction window
-(IBAction)raiseInteractionWindow:(id)sender;
-(IBAction)endInteractionWindow:(id)sender;
-(void)interactionSheetDidEnd:(NSWindow *)sheet
			returnCode:(int)returnCode
			contextInfo:(void *)contextInfo;
// run the command
-(void)runCommandWithParameters:(NSMutableArray *)params;
// AuthorizedExecutable delegate methods
-(void)captureOutput:(NSString *)output forExecutable:(id)ignore;
-(void)executableFinished:(id)ignore withStatus:(NSNumber *)number;

@end
