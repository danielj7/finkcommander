/*
 File: FinkWarningDialog.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 FinkWarningDialog is the controller for a view (Dialogs.nib) that allows
 the user to turn off a warning by clicking a check box type button.

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

enum {
    REMOVE,
    TERMINATE
};

@interface FinkWarningDialog : NSWindowController 
{
	IBOutlet NSButton *removeWarningButton;
	IBOutlet NSTextField *warningMessageField;
	IBOutlet NSButton *confirmButton;
	IBOutlet NSButton *cancelButton;
	
	NSMutableArray *arguments;
	NSUserDefaults *defaults;
	int command;
}

-(NSMutableArray *)arguments;
-(void)setArguments:(NSMutableArray *)newArguments;

-(void)showRemoveWarningForArguments:(NSMutableArray *)args;
-(void)showTerminateWarning;

-(IBAction)confirmAction:(id)sender;
-(IBAction)cancelAction:(id)sender;

@end
