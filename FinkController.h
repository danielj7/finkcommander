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

Contact the author at sburr@mac.com.


*/

#import <Cocoa/Cocoa.h>
#import "FinkDataController.h"
#import "FinkPackage.h"
#import "FinkPreferences.h"
#import "FinkBasePathUtility.h"
#import "IOTaskWrapper.h"
#include <unistd.h>

@interface FinkController : NSWindowController <IOTaskWrapperController>
{
	//main window outlets
	IBOutlet id mainWindow;
	IBOutlet id tableView;
	IBOutlet id textView;
	IBOutlet id msgText;
	
	//password entry window outlets
	IBOutlet NSWindow *pwdWindow;
	IBOutlet NSSecureTextField *pwdField;

	FinkDataController *packages;
	FinkPreferences *preferences;
	FinkBasePathUtility *utility;
	NSString *lastIdentifier;
	NSMutableDictionary *columnState;
	NSImage *reverseSortImage;
	NSImage *normalSortImage;
	BOOL updatingTable;

//MOVE	
	NSString *binPath;
	NSString *password;
	NSString *lastCommand;
	NSMutableArray *lastParams;
	BOOL pendingCommand;
	NSDictionary *environment;
	IOTaskWrapper *finkTask;
//ENDMOVE
}

//Accessors
-(FinkDataController *)packages;

//MOVE
-(NSString *)binPath;
-(NSString *)password;
-(void)setPassword:(NSString *)s;
-(NSMutableArray *)lastParams;
-(void)setLastParams:(NSArray *)a;
-(BOOL)pendingCommand;
-(void)setPendingCommand:(BOOL)b;
//ENDMOVE

-(NSString *)lastCommand;
-(void)setLastCommand:(NSString *)s;
-(NSString *)lastIdentifier;
-(void)setLastIdentifier:(NSString *)s;
-(BOOL)updatingTable;
-(void)setUpdatingTable:(BOOL)b;

//Action and sheet methods
-(IBAction)raisePwdWindow:(id)sender;
-(IBAction)endPwdWindow:(id)sender;
-(void)sheetDidEnd:(NSWindow *)sheet
	   returnCode:(int)returnCode
	   contextInfo:(void *)contextInfo;

-(IBAction)runCommand:(id)sender;
-(IBAction)runUpdater:(id)sender;
-(IBAction)updateTable:(id)sender;

-(IBAction)showPreferencePanel:(id)sender;

//Data source methods
-(int)numberOfRowsInTableView:(NSTableView *)aTableView;
-(id)tableView:(NSTableView *)aTableView 
		objectValueForTableColumn:(NSTableColumn *)aTableColumn
		row:(int)rowIndex;

//Delegates
-(void)tableView:(NSTableView *)aTableView
        mouseDownInHeaderOfTableColumn:(NSTableColumn *)aTableColumn;

//MOVE
//Process control
-(void)runCommandWithParams:(NSArray *)params;
//ENDMOVE

@end
