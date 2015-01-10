/*
 File: AuthorizedExecutable.m

 Created by David Love on Thu Jul 18 2002.
 Copyright (c) 2002 Cashmere Software, Inc.
 Released to Steven J. Burr on August 21, 2002, under the Gnu General Public License.

 See the header file, AuthorizedExecutable.h for more information on the license.

*/

#import "AuthorizedExecutable.h"
#import "FinkController.h"
#import <Security/AuthorizationTags.h>

@interface AuthorizedExecutable ()
{
    @protected
    AuthorizationRef _authorizationRef;
}

@property (nonatomic, copy) NSString *authExecutable;
@property (nonatomic) BOOL mustBeAuthorized;
@property (nonatomic, readonly) NSMutableString* output;
@property (nonatomic) NSFileHandle *stdinHandle;
@property (nonatomic) NSFileHandle *stdoutHandle;
@property (nonatomic) NSFileHandle *stderrHandle;
@property (nonatomic) NSTask *task;

@end

@implementation AuthorizedExecutable

// This needs to be initialized with the full path to the Launcher
// executable (which should be setuid root).  Note that this is
// different from the executable you want eventually run.  That
// executable will be specified as the first entry in the arguments
// array.
//
- (instancetype)initWithExecutable:(NSString*)exe
{
    if ((self = [super init]))
    {
        NSMutableArray* args = [[NSMutableArray alloc] init];
        _arguments = args;
        _output = [[NSMutableString alloc] init];
        _authExecutable = exe;
        _mustBeAuthorized = NO;
    }
    return self;
}


// self-explanatory
//
-(void)dealloc
{
    [self stop];
    [self setAuthExecutable:nil];
    [self setArguments:nil];
	[self setEnvironment:nil];
}


// Helper routine.  Both authorize and authorizedWithQuery call
// this routine to check the authorization.  They just use different
// flags to determine if the 'authorization dialog' should be 
// displayed.
//
-(BOOL)checkAuthorizationWithFlags:(AuthorizationFlags)flags
{
    AuthorizationRights rights;
    AuthorizationItem items[1];
    OSStatus err = errAuthorizationSuccess;

    if (! [self isExecutable])
    {
        return NO;
    }

    if (_authorizationRef == NULL)
    {
        err = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment,
                                  kAuthorizationFlagDefaults, &_authorizationRef);
     }

    if (err == errAuthorizationSuccess)
    {
        // There should be one item in the AuthorizationItems array for each
        // right you want to acquire.
        // The data in the value and valueLength is dependent on which right you
        // want to acquire.
        // For the right to execute tools as root, kAuthorizationRightExecute,
        // they should hold a pointer to a C string containing the path to
        // the tool you want to execute, and the length of the C string path.
        // There needs to be one item for each tool you want to execute.
		items[0].name = "com.sburrious.finkcommander";
		items[0].value = 0;
		items[0].valueLength = 0;		
        items[0].flags = 0;
        rights.count=1;
        rights.items = items;
        // Since we've specified kAuthorizationFlagExtendRights and
        // haven't specified kAuthorizationFlagInteractionAllowed, if the
        // user isn't currently authorized to execute tools as root,
        // they won't be asked for a password and err will indicate
        // an authorization failure.
        err = AuthorizationCopyRights(_authorizationRef,&rights,
                                      kAuthorizationEmptyEnvironment,
                                      flags, NULL);
    }
    return errAuthorizationSuccess==err;
}


// attempt to authorize the user without displaying the authorization dialog.
//
-(BOOL)authorize
{
    return [self checkAuthorizationWithFlags:kAuthorizationFlagExtendRights];
}


// attempt to authorize the user, displaying the authorization dialog
// if necessary.
//
-(BOOL)authorizeWithQuery
{
    return [self checkAuthorizationWithFlags:kAuthorizationFlagExtendRights| kAuthorizationFlagInteractionAllowed];
}

// Helper routine which converts the current authorizionRef to its
// external form.  The external form will eventually get piped
// to the Launcher.
//
-(BOOL)fillExternalAuthorizationForm:(AuthorizationExternalForm*)extAuth
{
    BOOL result = NO;
    if (_authorizationRef)
    {
        result = errAuthorizationSuccess != AuthorizationMakeExternalForm(_authorizationRef, extAuth);
    }
    return result;
}

// self-explanatory
//
-(BOOL)isAuthorized
{
    return [self authorize];
}

// Determine if the Launcher exists and is executable.
//
-(BOOL)isExecutable
{
    NSString* exe = [self authExecutable];
    return exe != nil && [[NSFileManager defaultManager] isExecutableFileAtPath:exe];
}

// Free any existing authorization.  This sets the user to an unauthorized
// state.
//
-(void)unAuthorize
{
    if (_authorizationRef != NULL)
    {
        AuthorizationFree(_authorizationRef,kAuthorizationFlagDestroyRights);
        _authorizationRef = NULL;
    }
}

// This saves the output of the command in the output string.  A
// delegate should implement captureOutput:forExecutable to receive
// the command's output
-(void)log:(NSString*)str
{
    if ([[self delegate] respondsToSelector:@selector(captureOutput:forExecutable:)])
    {
        [[self delegate] performSelector:@selector(captureOutput:forExecutable:) 
						 withObject:str withObject:self];
    }
    else
    {
        [[self output] replaceCharactersInRange:NSMakeRange([[self output] length], 0) 
				withString:str];
    }
}

// This saves capture the program's stdout and either passes it to a delegate, if assigned,
// or to the log method.
//
-(void)logStdOut:(NSString*)str
{
    if ([[self delegate] respondsToSelector:@selector(captureStdOut:forExecutable:)])
    {
        [[self delegate] performSelector:@selector(captureStdOut:forExecutable:) 
							withObject:str 
							withObject:self];
    }
    else
    {
        [self log:str];
    }
}

// This saves capture the program's stderr and either passes it to a delegate, if assigned,
// or to the log method.
//
-(void)logStdErr:(NSString*)str
{
    if ([[self delegate] respondsToSelector:@selector(captureStdErr:forExecutable:)])
    {
        [[self delegate] performSelector:@selector(captureStdErr:forExecutable:) 
							withObject:str 
							withObject:self];
    }
    else
    {
        [self log:str];
    }
}

-(void)writeData:(NSData*)data
{
    if ([self isRunning])
    {
        [[self stdinHandle] writeData:data];
    }
}

-(void)writeToStdin:(NSString*)str
{
    [self writeData:[str dataUsingEncoding:NSASCIIStringEncoding]];
}

// Internal routines used to capture output asynchronously.
// If a delegate overrides the executableFinished:withStatus method,
// it will be called when the command exits.
//
//  (void)executableFinished:(AuthorizedExecutable*)exe withStatus:(int)status;
//

//Helper method
-(NSString *)stringFromOutputData:(NSData *)data
{
	NSString *outputString;
	
    @try {
		outputString = [[NSString alloc] initWithBytes:[data bytes]
                                                length:[data length]
                                              encoding:NSUTF8StringEncoding];
		return outputString;	
    }
    @catch (NSException __unused *localException) {
		return @"WARNING:  Unable to decode output for display.\n";
    }
}

-(void)captureStdOut:(NSNotification*)notification
{
    NSData *inData = [notification userInfo][NSFileHandleNotificationDataItem];
    if (inData == nil || [inData length] == 0)
    {
        [[self task] waitUntilExit];
        [self stop];
    }
    else
    {
        [self logStdOut:[[NSString alloc] initWithBytes:[inData bytes]
                                                 length:[inData length]
                                               encoding:NSUTF8StringEncoding]];
        [[self stdoutHandle] readInBackgroundAndNotify];
    }
}

// Internal routine used to capture stderr asynchronously.
//
-(void)captureStdErr:(NSNotification*)notification
{
    NSData *inData = [notification userInfo][NSFileHandleNotificationDataItem];
    if (inData != nil && [inData length] != 0)
    {
        [self logStdErr:[[NSString alloc] initWithBytes:[inData bytes]
                                                 length:[inData length]
                                               encoding:NSUTF8StringEncoding]];
        [[self stderrHandle] readInBackgroundAndNotify];
    }
}

// task status
//
- (BOOL)isRunning
{
    return [[self task] isRunning];
}


// Call this to start the command.  If the command is already running,
// this is a no-op.
- (void)start
{
    if (! [[self task] isRunning])
    {
        AuthorizationExternalForm extAuth;
        OSStatus err;
        NSPipe *stdinPipe = nil;
        NSPipe *stdoutPipe = nil;
        //NSPipe *stderrPipe = nil;

        [[self output] setString:@""];

        if (! [self isExecutable])
        {
            [self log:
                NSLocalizedString(@"I can't find the tool I use to run an authorized command. You'll need to reinstall this application\n",@"This warning is issued if the user tries to start this task and the Launcher can't be found or isn't executable")];
			return;
        }

		if ([self mustBeAuthorized] && ! [self isAuthorized])
		{
			[self log:
				NSLocalizedString(@"You must authorize yourself before you can run this command.\n",@"This warning is issued if the user tries to start this task when the mustBeAuthorized flag is set and the user isn't authorized")];
			return;
		}
        err = AuthorizationMakeExternalForm(_authorizationRef, &extAuth);
        if (err != errAuthorizationSuccess)
        {
            [self log:[NSString stringWithFormat:@"TODO: Unknown error in AuthorizationMakeExternalForm: (%d)\n", err]];
            return;
        }

        @try {
            stdoutPipe = [NSPipe pipe];
            stdinPipe = [NSPipe pipe];
            //stderrPipe = [NSPipe pipe];

            [self setStdinHandle: [stdinPipe fileHandleForWriting]];
            [self setStdoutHandle: [stdoutPipe fileHandleForReading]];
            //[self setStderrHandle: [stderrPipe fileHandleForReading]];

            [[NSNotificationCenter defaultCenter] 
						addObserver:self 
						selector:@selector(captureStdOut:)
						name:NSFileHandleReadCompletionNotification
						object:[self stdoutHandle]];
#ifdef UNDEF
            [[NSNotificationCenter defaultCenter] 
						addObserver:self selector:@selector(captureStdErr:)
						name:NSFileHandleReadCompletionNotification
						object:stderrHandle];
#endif
            [[self stdoutHandle] readInBackgroundAndNotify];
            //[[self stderrHandle] readInBackgroundAndNotify];

            [self setTask: [[NSTask alloc] init]];
            [[self task] setStandardOutput:stdoutPipe];
            [[self task] setStandardInput:stdinPipe];
			//my change:
			[[self task] setStandardError:stdoutPipe];
            //[task setStandardError:stderrPipe];

            [[self task] setLaunchPath:[self authExecutable]];
            [[self task] setArguments:[self arguments]];
			[[self task] setEnvironment:[self environment]];
            [[self task] launch];

            [self writeData:[NSData dataWithBytes:&extAuth 
				  length:sizeof(AuthorizationExternalForm)]];

        }
        @catch (NSException __unused *localException) {
            [self log:[NSString stringWithFormat:@"Failed while trying to launch helper program"]];
            [self stop];
        }
    }
}

// This terminates the running process, if necessary, and cleans up 
// any related objects.
//
- (void)stop
{
	NSInteger status;

    if ([self stdoutHandle])
    {
        [[NSNotificationCenter defaultCenter] 
			removeObserver:self
			name:NSFileHandleReadCompletionNotification
			object:[self stdoutHandle]];
    }
    if ([self stderrHandle])
    {
        [[NSNotificationCenter defaultCenter] 
			removeObserver:self
			name:NSFileHandleReadCompletionNotification
			object:[self stderrHandle]];
    }
    if ([[self task] isRunning])
    {
		Dprintf(@"Task terminated");
        [[self task] terminate];
		[[self task] waitUntilExit];
    }
	status = [[self task] terminationStatus];
	[[self stdinHandle] closeFile];
	[[self stdoutHandle] closeFile];
	//[[self stderrHandle] closeFile];
    [self setTask: nil];
    [self setStdoutHandle: nil];
    [self setStdinHandle: nil];
    //[self setStderrHandle: nil];
	if ([[self delegate]
				respondsToSelector:@selector(executableFinished:withStatus:)])
	{
		[[self delegate]
				performSelector:@selector(executableFinished:withStatus:)
					 withObject:self
					 withObject:@(status)];
	}	
}


@end
