/* 
 File: FinkController.h 

FinkCommander

Graphical user interface for Fink, a software package management system 
that automates the downloading, patching, compilation and installation of
Unix software on Mac OS X.

The FinkController class allows the graphical user interface to interact with
command-line fink scripts and programs, as well as the data made available 
by the FinkDataController class.

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
#import "FinkDataController.h"
#import "FinkPackage.h"
#import "FinkPreferences.h"
#import "FinkPackageInfo.h"
#import "FinkConf.h"
#import "FinkBasePathUtility.h"
#import "IOTaskWrapper.h"
#import "FinkProcessKiller.h"

#include <math.h>

enum {
	SOURCE_COMMAND,
	BINARY_COMMAND
};

enum {
	FCWEB,
	FCBUG,
	FINKDOC
};

@interface FinkController : NSWindowController <IOTaskWrapperController>
{
	//main window outlets
	IBOutlet NSTableView *tableView;
	IBOutlet NSScrollView *tableScrollView;
	IBOutlet NSScrollView *outputScrollView;
	IBOutlet NSSplitView *splitView;
	IBOutlet NSTextView *textView;
	IBOutlet id msgText;
	IBOutlet NSView *progressViewHolder;
	IBOutlet NSView *progressView;
	IBOutlet NSProgressIndicator *progressIndicator;
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
	NSUserDefaults *defaults;
	FinkDataController *packages;
	NSMutableArray *displayedPackages;
	FinkPreferences *preferences;
	FinkPackageInfo *packageInfo;
	FinkBasePathUtility *utility;
	NSArray *selectedPackages;
	NSString *lastCommand;
	NSString *lastIdentifier;
	NSMutableDictionary *columnState;
	NSImage *reverseSortImage;
	NSImage *normalSortImage;
	BOOL commandIsRunning;
	NSToolbar *toolbar;
	BOOL userChoseToTerminate;
	NSArray *selectedObjectInfo;	

	//Authentication and Process Control
	NSString *password;
	BOOL pendingCommand;
	NSMutableArray *lastParams;
	IOTaskWrapper *finkTask;
}

//Accessors
-(FinkDataController *)packages;
-(NSMutableArray *)displayedPackages;
-(void)setDisplayedPackages:(NSMutableArray *)a;
-(BOOL)pendingCommand;
-(void)setPendingCommand:(BOOL)b;
-(NSArray *)selectedPackages;
-(void)setSelectedPackages:(NSArray *)a;
-(NSString *)lastCommand;
-(void)setLastCommand:(NSString *)s;
-(NSString *)lastIdentifier;
-(void)setLastIdentifier:(NSString *)s;
-(BOOL)commandIsRunning;
-(void)setCommandIsRunning:(BOOL)b;
//Authentication and process control
-(NSString *)password;
-(void)setPassword:(NSString *)s;
-(NSMutableArray *)lastParams;
-(void)setLastParams:(NSMutableArray *)a;
-(NSArray *)selectedObjectInfo;
-(void)setSelectedObjectInfo:(NSArray *)array;
-(NSArray *)selectedPackageArray;

-(void)scrollToVisible:(NSNumber *)n;

//Split view action methods
-(IBAction)collapseOutput:(id)sender;
-(IBAction)expandOutput:(id)sender;

//Menu and Toolbar Action Methods
-(IBAction)saveOutput:(id)sender;
-(IBAction)runCommand:(id)sender;
-(IBAction)runUpdater:(id)sender;
-(IBAction)terminateCommand:(id)sender;
-(IBAction)updateTable:(id)sender;
-(IBAction)showPreferencePanel:(id)sender;
-(IBAction)showPackageInfoPanel:(id)sender;
-(IBAction)showDescription:(id)sender;
//  help menu items
-(IBAction)goToWebSite:(id)sender;

//Toolbar Methods
-(void)setupToolbar;
-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar
	   itemForItemIdentifier:(NSString *)itemIdentifier
   willBeInsertedIntoToolbar:(BOOL)flag;
-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
// reapplies filter if filter popup menu changes 
-(IBAction)refilter:(id)sender;


//Table Methods
//  data source methods
-(int)numberOfRowsInTableView:(NSTableView *)aTableView;
-(id)tableView:(NSTableView *)aTableView 
		objectValueForTableColumn:(NSTableColumn *)aTableColumn
		row:(int)rowIndex;
//  delegate method
-(void)tableView:(NSTableView *)aTableView
		didClickTableColumn:(NSTableColumn *)aTableColumn;
//  helper
-(void)sortTableAtColumn: (NSTableColumn *)aTableColumn 
		inDirection:(NSString *)direction;


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
-(void)runCommandWithParams:(NSMutableArray *)params;

@end
