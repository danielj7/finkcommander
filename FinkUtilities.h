/*
File: FinkUtilities.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 This file prototypes utility functions used by the FinkController object to 
 discover the base path for the user's fink installation and to terminate
 processes.

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
#import "SBString.h"

#include <unistd.h>
#include <sys/types.h>
#include <signal.h>

void findFinkBasePath(void);
void fixScript(void);
void setInitialEnvironmentVariables(void);

void fixPreferences(void);

void terminateChildProcesses(NSString *password);

BOOL addEnvironmentVariable(NSString *key, NSString *value);
NSDictionary *environmentSettingWithName(NSString *name);
BOOL removeEnvironmentVariable(NSDictionary *setting);


