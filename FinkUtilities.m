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
		NSLog(@"Writing table update script to %@", wpath);
		[scriptText writeToFile:wpath atomically:YES];
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

