/*
File: FinkProcessTerminator.m

 See the header file, FinkDataController.h, for interface and license information.

 */


#import "FinkProcessTerminator.h"

@implementation FinkProcessTerminator

//Just like its command-line counterpart
-(NSString *)ps
{
	NSTask *ps = [[[NSTask alloc] init] autorelease];
	NSPipe *pipeIn = [NSPipe pipe];
	NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];
	NSString *psOutput;

	[ps setLaunchPath: @"/bin/ps"];
	[ps setArguments: [NSArray arrayWithObjects: @"-acjx", nil]];
	[ps setStandardOutput: pipeIn];
	[ps launch];
	psOutput = [[[NSString alloc] initWithData:[cmdStdout readDataToEndOfFile]
								  encoding:NSMacOSRomanStringEncoding]
				autorelease];
	return psOutput;
}

//Get the group id for the subprocesses (== id for top subprocess)
-(NSString *)processGroupID:(NSString *)ppid
{
	NSString *psOutput = [self ps];
	NSEnumerator *e = [[psOutput componentsSeparatedByString:@"\n"] objectEnumerator];
	NSEnumerator *e1;
	NSString *line;
	NSString *element;
	NSString *pgid = nil;

	while (line = [e nextObject]){
		if ([line contains: ppid] 				&&
			([[line strip] hasSuffix:@"perl"]	||
			 [[line strip] hasSuffix:@"apt-get"])){
			e1 = [[[line strip] componentsSeparatedByString:@" "] objectEnumerator];
			Dprintf(@"Looking for group id in:\n  %@", line);
			while (element = [e1 nextObject]){
				if ([element containsPattern:@"*[0-9]*"]){
					pgid = element;
					break;
				}
			}
			break;
		}
	}
	return pgid;
}

//Get the id of the next subprocess in the group
-(NSString *)processInGroup:(NSString *)pgid
{
	NSString *psOutput = [self ps];
	NSEnumerator *e = [[psOutput componentsSeparatedByString:@"\n"] objectEnumerator];
	NSString *line;
	NSString *cpid = nil;
	NSScanner *pidScanner;

	while (line = [e nextObject]){
		if ([line contains: pgid] && ![[line strip] hasSuffix:@"ps"]){
			Dprintf(@"Found line with pgid %@:\n  %@", pgid, line);
			pidScanner = [NSScanner scannerWithString:line];
			//child pid is first set of decimal digits in line
			[pidScanner scanUpToCharactersFromSet: [NSCharacterSet decimalDigitCharacterSet]
												intoString: nil];
			[pidScanner scanCharactersFromSet: [NSCharacterSet decimalDigitCharacterSet]
											intoString:&cpid];
			break;
		}
	}
	return cpid;
}

//Give the first call to sudo kill the chance to write the password to stdin if necessary
-(void)terminateFirstProcess:(NSString *)pid usingPassword:(NSString *)password
{
	NSTask *term = [[[NSTask alloc] init] autorelease];
	NSPipe *pipeIn = [NSPipe pipe];
	NSPipe *pipeOut = [NSPipe pipe];
	NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];
	NSFileHandle *cmdStdin = [pipeOut fileHandleForWriting];
	NSData *termData;
	NSString *termOutput;

	[term setLaunchPath: @"/usr/bin/sudo"];
	[term setArguments: [NSArray arrayWithObjects: @"-S", @"kill", @"-KILL", pid, nil]];
	[term setStandardOutput: pipeIn];
	[term setStandardError: [term standardOutput]];
	[term setStandardInput: pipeOut];
	[term launch];

	termData = [cmdStdout availableData];
	while ([termData length] > 0 ){
		termOutput = [[[NSString alloc] initWithData:termData
										encoding:NSMacOSRomanStringEncoding] 
						autorelease];
		if ([termOutput contains:@"Password"]){
			[cmdStdin writeData:[password dataUsingEncoding:NSMacOSRomanStringEncoding]];
			break;
		}
		termData = [cmdStdout availableData];
	}
}

//No pipes needed in subsequent kills
-(void)terminateOtherProcess:(NSString *)pid
{
	NSTask *term = [[[NSTask alloc] init] autorelease];

	[term setLaunchPath: @"/usr/bin/sudo"];
	[term setArguments: [NSArray arrayWithObjects: @"-S", @"kill", @"-KILL", pid, nil]];
	[term launch];
	[term waitUntilExit];
}

-(void)terminateChildProcesses:(NSString *)password
{
	NSAutoreleasePool *threadPool = [[NSAutoreleasePool alloc] init];
	NSString *ppid = [NSString stringWithFormat: @"%d", getpid()];
	NSString *pgid = [self processGroupID:ppid];
	NSString *cpid;

	if (!pgid) return;
	[self terminateFirstProcess:pgid usingPassword:password];
	cpid = [self processInGroup:pgid];
	while (cpid){
		NSLog(@"Terminating process with pid: %@", cpid);
		[self terminateOtherProcess:cpid];
		cpid = [self processInGroup:pgid];
	}
	//Before I added a delay here, FC kept crashing because of an uncaught
	//SIGTRAP signal. I made a WAG that this had something to do with the fact
	//that the last kill process was printing an error message ("no such process")
	//to stdout after the thread terminated; so I tried giving the thread
	//some arbitrary amount of extra time. A call to sleep(1) seemed to do the trick, but
	//I decided to go with the NSThread method and more time to be safe.
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];
	[threadPool release];
}

@end
