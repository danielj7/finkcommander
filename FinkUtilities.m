/*
File: FinkUtilities.m

 See the header file, FinkUtilities.h, for interface and license information.

*/

#import "FinkUtilities.h"

//------------------------------------------------------------>Base Path Functions

void findFinkBasePath(void)
{
	NSEnumerator *e;
	NSString *path;
    NSString *homeDir = NSHomeDirectory();
	NSFileManager *manager = [NSFileManager defaultManager];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL pathFound = NO;

	//variables used by NSTask
	NSTask *findTask;
	NSPipe *pipeIn;
	NSFileHandle *cmdStdout;
	NSArray *args;
	NSRange range;
	NSString *whichPath;

	//look in some possible install paths
	e = [[NSArray arrayWithObjects: @"/sw", @"/opt", @"/usr/local", @"/fink", homeDir,
		[homeDir stringByAppendingPathComponent: @"sw"],
        [homeDir stringByAppendingPathComponent: @"fink"],
        @"/opt/fink", @"/opt/sw", @"/usr/local/sw", @"/usr/local/fink",
        @"/usr/sw", @"/usr/fink", nil] objectEnumerator];

	while (path = [e nextObject]){
		if ([manager isReadableFileAtPath:
			[path stringByAppendingPathComponent: @"/etc/fink.conf"]]){
			[defaults setObject: path forKey: FinkBasePath];
			[defaults setBool: YES forKey: FinkBasePathFound];
			pathFound = YES;
			if (DEBUGGING) {NSLog(@"Found basepath %@ using array", path);}
			break;
		}
	}
	//if that doesn't work, try the which command
	if (!pathFound){
		findTask = [[[NSTask alloc] init] autorelease];
		pipeIn  = [NSPipe pipe];
		cmdStdout = [pipeIn fileHandleForReading];
		args = [NSArray arrayWithObjects: @"fink", @"|", @"tail", @"-n1",
			nil];

		[findTask setLaunchPath: @"/usr/bin/which"];
		[findTask setArguments: args];
		[findTask setStandardOutput: pipeIn];
		[findTask launch];
		whichPath = [[[NSString alloc] initWithData: [cmdStdout readDataToEndOfFile]
																encoding: NSUTF8StringEncoding] autorelease];
		//get the stuff before /bin/fink
		range = [whichPath rangeOfString: @"/bin/fink"];
        if (range.length > 0){
            path = [whichPath substringWithRange: NSMakeRange(0, range.location)];
            if([manager isReadableFileAtPath:
                [path stringByAppendingPathComponent: @"/etc/fink.conf"]]){
                [defaults setObject: path forKey: FinkBasePath];
                [defaults setBool: YES forKey: FinkBasePathFound];
            }
		}
	}
}

void fixScript(void)
{
	NSString *pathToScript = [[NSBundle mainBundle] pathForResource:@"fpkg_list" ofType: @"pl"];
	NSMutableString *scriptText = [NSMutableString stringWithContentsOfFile: pathToScript];
	NSString *basePath = [[NSUserDefaults standardUserDefaults] objectForKey: FinkBasePath];
	NSRange rangeOfBASEPATH;

	while((rangeOfBASEPATH = [scriptText rangeOfString: @"BASEPATH"]).length > 0){
		LOGIFDEBUG(@"Replacing BASEPATH with path to fink");
		[scriptText replaceCharactersInRange: rangeOfBASEPATH withString: basePath];
	}

	[scriptText writeToFile:pathToScript atomically:YES];
}

//------------------------------------------------------------>Process Termination
NSString *ps(void)
{
	NSTask *ps = [[[NSTask alloc] init] autorelease];
	NSPipe *pipeIn = [NSPipe pipe];
	NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];
	NSString *psOutput;

	[ps setLaunchPath: @"/bin/ps"];
	[ps setArguments: [NSArray arrayWithObjects: @"-acjx", nil]];
	[ps setStandardOutput: pipeIn];
	[ps launch];
	psOutput = [[[NSString alloc] initWithData: 
									[cmdStdout readDataToEndOfFile] 
												encoding:NSUTF8StringEncoding] autorelease];

	return psOutput;
}

NSString *childOfProcess(NSString *ppid)
{
	NSString *psOutput = ps();
	NSEnumerator *e = [[psOutput componentsSeparatedByString:@"\n"] objectEnumerator];
	NSString *line;
	NSString *cpid = nil;
	NSScanner *pidScanner;

	while (line = [e nextObject]){
		if ([line contains: ppid]){
			if (DEBUGGING) {NSLog(@"Found line with pid %@:\n%@", ppid, line);}
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

void terminateProcessWithPID(NSString *pid)
{
	[NSTask launchedTaskWithLaunchPath: @"/usr/bin/sudo"
			arguments: [NSArray arrayWithObjects: @"-S", @"kill", @"-KILL", pid, nil]];
}

void terminateChildProcesses(void)
{
	NSString *ppid = [NSString stringWithFormat: @"%d", getpid()];
	NSString *cpid = childOfProcess(ppid);

	//The sins of the father are visited on his children.
	while (cpid){
		if (DEBUGGING) {NSLog(@"Calling terminateProcessWithPID: %@", cpid);}
		terminateProcessWithPID(cpid);
		ppid = cpid;
		cpid = childOfProcess(ppid);
	}
}
