/*
 File: AuthorizedExecutable.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 AuthorizedExecutable uses an NSTask to run the Launcher tool with administrative
 privileges.  It communicates with Launcher, and thus with fink or apt-get subprocesses,
 through pipes and sends the output from the subprocesses to FinkController through 
 delegate methods.

 Created by David Love on Thu Jul 18 2002.
 Copyright (c) 2002 Cashmere Software, Inc.
 Released to Steven J. Burr on August 21, 2002, under the Gnu General Public License.
 
 A few minor modifications to Dave's orginal code have been made.

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
#import <Security/Authorization.h>
#import "FinkGlobals.h"

@class AuthorizedExecutable;
@protocol AuthorizedExecutableDelegate <NSObject>

// Delegates available:
//
// (void)captureOutput:(NSString*)str forExecutable:(AuthorizedExecutable*)exe;
//      - captured whenever data is available on stdout or stderr
//      - the stdout and stderr delegates (below) take precendence over this
//        routine and will effectively filter out any applicable messages.
//        If you provide delegates from both captureStdOut and captureStdErr,
//        this routine will only be called when the log method is directly
//        called by your application.
//
// (void)captureStdOut:(NSString*)str forExecutable:(AuthorizedExecutable*)exe;
//      - called whenever data is available on stdout
//
// (void)captureStdErr:(NSString*)str forExecutable:(AuthorizedExecutable*)exe;
//      - called whenever data is available on stderr
//
// (void)executableFinished:(AuthorizedExecutable*)exe withStatus:(NSNumber*)status;
//      - called when the executable exits

- (void)captureOutput:(NSString*)str forExecutable:(AuthorizedExecutable*)exe;
- (void)executableFinished:(AuthorizedExecutable*)exe withStatus:(NSNumber*)status;

@optional

- (void)captureStdOut:(NSString*)str forExecutable:(AuthorizedExecutable*)exe;
- (void)captureStdErr:(NSString*)str forExecutable:(AuthorizedExecutable*)exe;

@end

@interface AuthorizedExecutable : NSObject
{
}

// The command and arguments you want to run.  This is passed
// directly to NSTask.  The first entry is the command you want
// to run.  Any other entries are the options you want passed
// to the command.  Note that if an option has an associated
// argument (-r foo), they must be specified in the array as
// *two* entries ('-r' and 'foo'), not one.
//
@property (nonatomic, copy) NSMutableArray *arguments;

@property (nonatomic, copy) NSDictionary *environment;
@property (nonatomic, weak) id <AuthorizedExecutableDelegate> delegate;

-(instancetype)initWithExecutable:(NSString*)exe NS_DESIGNATED_INITIALIZER;

-(void)dealloc;

-(BOOL)authorize;
-(BOOL)authorizeWithQuery;
-(BOOL)checkAuthorizationWithFlags:(AuthorizationFlags) flags;

-(BOOL)isAuthorized;
-(void)unAuthorize;

-(BOOL)isExecutable;

-(void)captureStdOut:(NSNotification*)notification;
-(void)captureStdErr:(NSNotification*)notification;
- (BOOL)isRunning;
- (void)log:(NSString*)str;
- (void)logStdOut:(NSString*)str;
- (void)logStdErr:(NSString*)str;
- (void)writeData:(NSData*)data;
- (void)writeToStdin:(NSString*)str;
- (void)start;
- (void)stop;

@end
