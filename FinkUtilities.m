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
	NSString *oldBasePath = [defaults objectForKey:FinkBasePath];
	
	//look in some possible install paths
	e = [[NSArray arrayWithObjects: @"/sw", @"/opt", @"/usr/local", @"/fink", homeDir,
		[homeDir stringByAppendingPathComponent: @"sw"],
        [homeDir stringByAppendingPathComponent: @"fink"],
        @"/opt/fink", @"/opt/sw", @"/usr/local/sw", @"/usr/local/fink",
        @"/usr/sw", @"/usr/fink", nil] objectEnumerator];

	while (path = [e nextObject]){
		if ([manager isReadableFileAtPath:
			[path stringByAppendingPathComponent: @"/etc/fink.conf"]]){
			[defaults setObject:path forKey:FinkBasePath];
			if (DEBUGGING) {NSLog(@"Found basepath %@ using array", path);}
			break;
		}
	}
	if (! [oldBasePath isEqualToString:path]){
		[defaults setBool:YES forKey:FinkBasePathFound];
	}
}

void fixScript(void)
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *home = NSHomeDirectory();
	NSString *wpath = [home stringByAppendingPathComponent:
						@"Library/Application Support/FinkCommander.pl"];
	
	if (! [manager fileExistsAtPath:wpath] || [defaults boolForKey:FinkBasePathFound]){
		NSString *rpath = [[NSBundle mainBundle] pathForResource:@"fpkg_list" ofType:@"pl"];
		NSMutableString *scriptText = [NSMutableString stringWithContentsOfFile:rpath];
		NSString *basePath = [[NSUserDefaults standardUserDefaults] objectForKey:FinkBasePath];
		NSRange rangeOfBASEPATH;

		while((rangeOfBASEPATH = [scriptText rangeOfString: @"BASEPATH"]).length > 0){
			LOGIFDEBUG(@"Replacing BASEPATH");
			[scriptText replaceCharactersInRange:rangeOfBASEPATH withString:basePath];
		}
		NSLog(@"Fixed script:\n%@", scriptText);
		[scriptText writeToFile:wpath atomically:YES];
		[defaults setBool:NO forKey:FinkBasePathFound];
	}
	
}

//------------------------------------------------------------>Environment Defaults
void setInitialEnvironmentVariables(void)
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *settings;
	NSString *basePath = [defaults objectForKey:FinkBasePath];
	NSString *proxy;
	char *proxyEnv;

	settings = 
	[NSMutableDictionary 
		dictionaryWithObjectsAndKeys: 
			[NSString stringWithFormat:
				@"%@/bin:%@/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin", 
				basePath, basePath],
			@"PATH",
			[NSString stringWithFormat: @"%@/lib/perl5", basePath],
			@"PERL5LIB", nil];

	proxy = [defaults objectForKey: FinkHTTPProxyVariable];
	if ([proxy length] > 0){
		[settings setObject:proxy forKey:@"http_proxy"];
	}else if (! [defaults boolForKey: FinkLookedForProxy]){
		if (proxyEnv = getenv("http_proxy")){
			proxy = [NSString stringWithCString: proxyEnv];
			[settings setObject:proxy forKey:@"http_proxy"];
		}
		[defaults setBool:YES forKey:FinkLookedForProxy];
	}
	[defaults setObject:settings forKey:FinkEnvironmentSettings];
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


