/*
 File: FinkProcessKiller.m

 See the header file, FinkProcessKiller.h, for interface and license information.

 */
#import "FinkProcessKiller.h"

@implementation FinkProcessKiller

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
	psOutput = [[[NSString alloc] initWithData: [cmdStdout readDataToEndOfFile]
								encoding:NSUTF8StringEncoding] autorelease];

	return psOutput;
}

-(NSString *)childOfProcess:(NSString *)ppid
{
	NSString *psOutput = [self ps];
	NSEnumerator *e = [[psOutput componentsSeparatedByString:@"\n"] objectEnumerator];
	NSString *line;
	NSString *cpid = nil;
	NSScanner *pidScanner;
	
	while (line = [e nextObject]){
		if ([line contains: ppid]){
#ifdef DEBUG
			NSLog(@"Found line with pid %@:\n%@", ppid, line);
#endif //DEBUG
			pidScanner = [NSScanner scannerWithString:line];
			//child pid is first set of decimal digits in line
			[pidScanner scanUpToCharactersFromSet: [NSCharacterSet decimalDigitCharacterSet]
							intoString: nil];
			[pidScanner scanCharactersFromSet: [NSCharacterSet decimalDigitCharacterSet]
							intoString:&cpid];
			if ([cpid isEqualToString:ppid]){
				cpid = nil;
				continue;
			}
			break;
		}
	}
	return cpid;
}

-(void)terminateProcessWithPID:(NSString *)pid
{
		[NSTask launchedTaskWithLaunchPath: @"/usr/bin/sudo"
			arguments: [NSArray arrayWithObjects: @"-S", @"kill", @"-KILL", pid, nil]];
}

-(void)terminateChildProcesses
{
	NSString *ppid = [NSString stringWithFormat: @"%d", getpid()];
	NSString *cpid = [self childOfProcess: ppid];
	
	//find FC's child and terminate it
	//then recursively find child of child and terminate it 
	//until all descendants have been terminated
	while (cpid){
#ifdef DEBUG
		NSLog(@"Calling terminateProcessWithPID: %@", cpid);
#endif //DEBUG
		[self terminateProcessWithPID: cpid];
		ppid = cpid;
		cpid = [self childOfProcess: ppid];
	}
}

@end
