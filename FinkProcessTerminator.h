/*
File: FinkProcessTerminator.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 The FinkProcessTerminator class creates an object that seeks out and destroys
 subprocesses created by FinkController to run fink and apt-get commands.  
 It runs in a separate thread to avoid the dreaded (but in Jaguar quite pretty) 
 spinning beach ball and to allow use of the main interface while the terminator
 goes on its mission.

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



#import <Foundation/Foundation.h>
#import "FinkGlobals.h"
#include <unistd.h>
#include <sys/types.h>
#include <signal.h>

@interface FinkProcessTerminator : NSObject {
}

-(void)terminateChildProcesses:(NSString *)password;

@end
