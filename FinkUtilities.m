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
#ifdef DEBUGGING
			NSLog(@"Found basepath %@ using array", path);
#endif
			break;
		}
	}
	if (! [oldBasePath isEqualToString:path]){
		NSLog(@"Fink base path has changed from %@ to %@", oldBasePath, path);
		[defaults setBool:YES forKey:FinkBasePathFound];
	}
}

void fixScript(void)
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *aspath = [NSHomeDirectory() stringByAppendingPathComponent:
						@"Library/Application Support"];
	NSString *fcpath = [aspath stringByAppendingPathComponent: @"FinkCommander"];
	NSString *wpath = [fcpath stringByAppendingPathComponent:@"FinkCommander.pl"];
						
	if (! [manager fileExistsAtPath:aspath]){
		NSLog(@"Creating ~/Library/Application Support directory");
		[manager createDirectoryAtPath:aspath attributes:nil];
	}
	
	if (! [manager fileExistsAtPath:fcpath]){
		NSLog(@"Creating ~/Library/Application Support/FinkCommander directory");
		[manager createDirectoryAtPath:fcpath attributes:nil];
	}
	
	if (! [manager fileExistsAtPath:wpath] || [defaults boolForKey:FinkBasePathFound]){
		NSString *rpath = [[NSBundle mainBundle] pathForResource:@"fpkg_list" ofType:@"pl"];
		NSMutableString *scriptText = [NSMutableString stringWithContentsOfFile:rpath];
		NSString *basePath = [[NSUserDefaults standardUserDefaults] objectForKey:FinkBasePath];
		NSRange rangeOfBASEPATH;
		
		while((rangeOfBASEPATH = [scriptText rangeOfString:@"BASEPATH"]).length > 0){
			[scriptText replaceCharactersInRange:rangeOfBASEPATH withString:basePath];
		}
#ifdef DEBUGGING
		NSLog(@"Script text:\n%@", scriptText);
#endif
		NSLog(@"Writing table update script to %@", wpath);
		[scriptText writeToFile:wpath atomically:YES];
		[defaults setBool:NO forKey:FinkBasePathFound];
	}
}


//------------------------------------------------------------>Fix Preferences

void fixPreferences(void)
{
	NSString *path = [NSHomeDirectory() 
		stringByAppendingPathComponent:@"Library/Preferences/com.sburrious.finkcommander.plist"];
	NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:path];
	
	[prefs removeObjectForKey:FinkViewMenuSelectionStates];
	[prefs removeObjectForKey:FinkTableColumnsArray];
	[prefs removeObjectForKey:@"NSTableView Columns FinkTableView"];

	[prefs writeToFile:path atomically:YES];
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
				@"PERL5LIB", 
				@"ssh",
				@"CVS_RSH",
				NSHomeDirectory(),
				@"HOME",
				nil];

	proxy = [defaults objectForKey:FinkHTTPProxyVariable];
	if ([proxy length] > 0){
		[settings setObject:proxy forKey:@"http_proxy"];
	}else if (! [defaults boolForKey: FinkLookedForProxy]){
		if (proxyEnv = getenv("http_proxy")){
			proxy = [NSString stringWithCString:proxyEnv];
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
												encoding:NSMacOSRomanStringEncoding] autorelease];
#ifdef DEBUGGING
	NSLog(@"ps command output:\n%@", psOutput);
#endif
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
#ifdef DEBUGGING
			NSLog(@"Found line with parent pid %@:\n%@", ppid, line);
#endif
			pidScanner = [NSScanner scannerWithString:line];
			//child pid is first set of decimal digits in line
			[pidScanner scanUpToCharactersFromSet: [NSCharacterSet decimalDigitCharacterSet]
												   intoString: nil];
			[pidScanner scanCharactersFromSet: [NSCharacterSet decimalDigitCharacterSet]
											   intoString:&cpid];
			if ([cpid isEqualToString:ppid]){ 
#ifdef DEBUGGING
				NSLog(@"It's the parent; ignoring");
#endif
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

void terminateChildProcesses()
{
	NSString *ppid = [NSString stringWithFormat: @"%d", getpid()];
	NSString *cpid = childOfProcess(ppid);

	//The sins of the father are visited on his children.
	while (cpid){
	
#ifdef DEBUGGING
		NSLog(@"Calling terminateProcessWithPID: %@", cpid);
#endif
		terminateProcessWithPID(cpid);
		ppid = cpid;
		cpid = childOfProcess(ppid);
	}
}