/*
File: FinkPreferences.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 FinkPreferences connects the user's choices in the preferences windows to 
 values stored in the application's NSUserDefaults dictionary or to values
 in the fink.conf file.

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

 Contact the author at sburrious@users.sourceforge.net.

 */

#import <AppKit/AppKit.h>
#import "FinkConf.h"

@interface FinkPreferences : NSWindowController 
{
	//widgets used for general preference settings
	IBOutlet NSMatrix *pathChoiceMatrix;
	IBOutlet NSTextField *basePathTextField;
	IBOutlet NSButton *alwaysChooseDefaultsButton;
	IBOutlet NSButton *askOnStartupButton;
	IBOutlet NSButton *neverAskButton;
	
	//widgets used to alter table behavior
	IBOutlet NSButton *scrollToSelectionButton;
	IBOutlet NSButton *updateWithFinkButton;
	
	//widgets used to alter fink.conf
	IBOutlet NSButton *useUnstableMainButton;
	IBOutlet NSButton *useUnstableCryptoButton;
	IBOutlet NSButton *verboseOutputButton;
	IBOutlet NSButton *passiveFTPButton;
	IBOutlet NSButton *httpProxyButton;
	IBOutlet NSTextField *httpProxyTextField;
	IBOutlet NSButton *ftpProxyButton;
	IBOutlet NSTextField *ftpProxyTextField;
	
	NSUserDefaults *defaults;
	FinkConf *conf;
	
	BOOL pathChoiceChanged;
	BOOL finkConfChanged;
}

-(IBAction)setPreferences:(id)sender;
-(IBAction)cancel:(id)sender;
-(IBAction)setPathChoice:(id)sender;
-(IBAction)setFinkConfChanged:(id)sender;
-(IBAction)setFinkTreesChanged:(id)sender;

@end
