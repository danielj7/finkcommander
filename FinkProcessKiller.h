/*
 File: FinkProcessKiller.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 The FinkProcessKiller class provides a method for terminating fink and apt-get
 processes.  The NSTask terminate method doesn't work on these processes because
 they are owned by root, while FinkCommander is owned by the user. 

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

#import <Foundation/Foundation.h>
#import "SBString.h"
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

@interface FinkProcessKiller : NSObject {
}

-(void)terminateChildProcesses;

@end
