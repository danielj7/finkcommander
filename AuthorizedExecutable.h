//
//  AuthorizedExecutable.h
//  NMapFE
//
//  Created by David Love on Thu Jul 18 2002.
//  Copyright (c) 2002 Cashmere Software, Inc. All rights reserved.
//  $Id$
//

#import <Foundation/Foundation.h>
#import <Security/Authorization.h>
#import "FinkGlobals.h"

@interface AuthorizedExecutable : NSObject {

    AuthorizationRef authorizationRef;
    NSMutableArray* arguments;
	NSDictionary* environment;
    NSString* authExecutable;
    id delegate;
    bool mustBeAuthorized;
    NSMutableString* output;
    NSFileHandle *stdinHandle;
    NSFileHandle *stdoutHandle;
    NSFileHandle *stderrHandle;
    NSTask *task;
}

-(id)initWithExecutable:(NSString*)exe;

-(void)dealloc;

-(bool)authorize;
-(bool)authorizeWithQuery;
-(bool)checkAuthorizationWithFlags:(AuthorizationFlags) flags;

-(bool)isAuthorized;
-(bool)mustBeAuthorized;
-(void)setMustBeAuthorized:(bool)b;
-(void)unAuthorize;

-(NSString*)authExecutable;
-(void)setAuthExecutable:(NSString*)exe;
-(bool)isExecutable;
-(NSDictionary *)environment;
-(void)setEnvironment:(NSDictionary *)env;
- (NSMutableArray*)arguments;
-(void)setArguments:(NSMutableArray*)args;

-(void)captureStdOut:(NSNotification*)notification;
-(void)captureStdErr:(NSNotification*)notification;
- (bool)isRunning;
- (void)log:(NSString*)str;
- (void)logStdOut:(NSString*)str;
- (void)logStdErr:(NSString*)str;
- (void)writeData:(NSData*)data;
- (void)writeToStdin:(NSString*)str;
- (void)start;
- (void)stop;

- (id)delegate;
- (void)setDelegate:(id)dgate;

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
// (void)executableFinished:(AuthorizedExecutable*)exe withStatus:(int)status;
//      - called when the executable exits
@end
