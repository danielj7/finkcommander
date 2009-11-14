/*
File: FinkUtilities.m

 See the header file, FinkUtilities.h, for interface and license information.

*/

#import "FinkUtilities.h"


//------------------------------------------------------------>Path Functions

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

	while (nil != (path = [e nextObject])){
		if ([manager isReadableFileAtPath:
			[path stringByAppendingPathComponent: @"/etc/fink.conf"]]){
			[defaults setObject:path forKey:FinkBasePath];
			Dprintf(@"Found basepath %@ using array", path);
			break;
		}
	}
	if (! [oldBasePath isEqualToString:path]){
		NSLog(@"Fink base path has changed from %@ to %@", oldBasePath, path);
		[defaults setBool:YES forKey:FinkBasePathFound];
	}
}

void findPerlPath(void)
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *pathToPerl = [defaults objectForKey:FinkPerlPath];
	
	if (nil == pathToPerl){
		NSArray *possiblePaths = [NSArray arrayWithObjects: 
									@"/usr/local/bin/perl", 
									@"/opt/bin/perl", 
									@"/opt/local/bin/perl", 
									[NSHomeDirectory() 
										stringByAppendingPathComponent:@"bin/perl"], 
									nil];
		NSEnumerator *binPathEnumerator = [possiblePaths objectEnumerator];
		while (nil != (pathToPerl = [binPathEnumerator nextObject])){
			if ([manager isExecutableFileAtPath:pathToPerl]){
				[defaults setObject:pathToPerl forKey:FinkPerlPath];
				Dprintf(@"Found perl at %@", pathToPerl);
				return;
			}
		}
		NSLog(@"Failed to find executable perl path; setting to /usr/bin/perl as default");
		[defaults setObject:@"/usr/bin/perl" forKey:FinkPerlPath];
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
	//Update the FinkCommander.pl every time for now - till we version it
	if(1){
	// 	if (! [manager fileExistsAtPath:wpath] || [defaults boolForKey:FinkBasePathFound]){
		NSString *rpath = [[NSBundle mainBundle] pathForResource:@"fpkg_list" ofType:@"pl"];
		NSMutableString *scriptText = [NSMutableString stringWithContentsOfFile:rpath];
		NSString *basePath = [[NSUserDefaults standardUserDefaults] objectForKey:FinkBasePath];
		NSRange rangeOfBASEPATH;
		
		while((rangeOfBASEPATH = [scriptText rangeOfString:@"BASEPATH"]).length > 0){
			[scriptText replaceCharactersInRange:rangeOfBASEPATH withString:basePath];
		}
//		NSLog(@"Writing table update script to %@", wpath);
		[scriptText writeToFile:wpath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
		[defaults setBool:NO forKey:FinkBasePathFound];
	}
}


//------------------------------------------------------------>Fix Preferences
//delete table preferences before running 0.4.0 for the first time
void fixPreferences(void)
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *userArray = [defaults objectForKey:FinkUsersArray];
	
	[defaults removeObjectForKey:FinkViewMenuSelectionStates];
	[defaults removeObjectForKey:FinkTableColumnsArray];
	[defaults removeObjectForKey:@"NSTableView Columns FinkTableView"];
	[defaults removeObjectForKey:FinkSelectedColumnIdentifier];
	userArray = [userArray arrayByAddingObject:NSUserName()];
	[defaults setObject:userArray forKey:FinkUsersArray];
	[defaults setBool:YES forKey:FinkBasePathFound];
	fixScript();
}


//------------------------------------------------------------>Environment Defaults
void setInitialEnvironmentVariables(void)
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *settings;
	NSString *basePath = [defaults objectForKey:FinkBasePath];
	NSString *terminal;

	if (! (terminal = [[[NSProcessInfo processInfo] environment] valueForKey: @"TERM_PROGRAM"])){
		terminal = @"Apple_Terminal";
	}

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
				terminal,
				@"TERM_PROGRAM",
				@"C",
				@"LC_ALL",
				nil];
	
	[defaults setObject:settings forKey:FinkEnvironmentSettings];
}

