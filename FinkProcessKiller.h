/*
 File: FinkProcessKiller.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 The FinkProcessKiller class provides a method for terminating fink and apt-get
 processes.  The NSTask terminate method doesn't work on these processes because
 they are owned by root, while FinkCommander is owned by the user.  
 
 I have tried several alternatives, and the only method that seems to be at all 
 reliable is to send a SIGKILL signal to the child process and to each of the "grandchildren."
 
 Another alternative that I may try is to write a separate tool that calls killpg()
 for the child process (which seems to set the process group for each of the grandchildren)
 and then run that with sudo or the SecurityFramework.

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

@interface FinkProcessKiller : NSObject {
}

-(void)terminateChildProcesses;

@end
