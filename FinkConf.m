/*
File: FinkConf.m

 See the header file, FinkConf.h, for interface and license information.

*/

#import "FinkConf.h"

//Global variables used throughout FinkCommander source code to set
//user defaults.
NSString *FinkBasePath = @"FinkBasePath";
NSString *FinkBasePathFound = @"FinkBasePathFound";
NSString *FinkUpdateWithFink = @"FinkUpdateWithFink";
NSString *FinkAlwaysChooseDefaults = @"FinkAlwaysChooseDefaults";
NSString *FinkScrollToSelection = @"FinkScrollToSelection";
NSString *FinkSelectedColumnIdentifier = @"FinkSelectedColumnIdentifier";
NSString *FinkSelectedPopupMenuTitle = @"FinkSelectedPopupMenuTitle";
NSString *FinkHTTPProxyVariable = @"FinkHTTPProxyVariable";
NSString *FinkFTPProxyVariable = @"FinkFTPProxyVariable";
NSString *FinkLookedForProxy = @"FinkLookedForProxy";
NSString *FinkAskForPasswordOnStartup = @"FinkAskForPasswordOnStartup";
NSString *FinkNeverAskForPassword = @"FinkNeverAskForPassword";
NSString *FinkAlwaysScrollToBottom = @"FinkAlwaysScrollToBottom";
NSString *FinkWarnBeforeRunning = @"FinkWarnBeforeRunning";

//Global variables identifying inter-object notifications
NSString *FinkConfChangeIsPending = @"FinkConfChangeIsPending";
NSString *FinkCommandCompleted = @"FinkCommandCompleted";
NSString *FinkPackageArrayIsFinished = @"FinkPackageArrayIsFinished";

//Globals for this file
NSString *PROXY_HTTP = @"ProxyHTTP";
NSString *PROXY_FTP = @"ProxyFTP";

@implementation FinkConf

//--------------------------------------------------->Startup and Shutdown

-(id)init
{
	if (self = [super init]){
		finkConfDict = [[NSMutableDictionary alloc] initWithCapacity: 20];
		defaults = [NSUserDefaults standardUserDefaults];
		
		[self readFinkConf];
		[self setFinkTreesChanged: NO];

		[[NSNotificationCenter defaultCenter] 
			addObserver: self
			selector: @selector(completeFinkConfUpdate:)
			name: FinkCommandCompleted
			object: nil];
	}
	return self;
}

-(void)dealloc
{
	[finkConfDict release];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[super dealloc];
}

-(void)readFinkConf
{
	NSString *fconfString = [NSString stringWithContentsOfFile:
			[[defaults objectForKey: FinkBasePath] stringByAppendingPathComponent: 
				@"/etc/fink.conf"]];
	NSEnumerator *e;
	NSString *line;
	int split;

	e = [[fconfString componentsSeparatedByString: @"\n"] objectEnumerator];
	while(line = [e nextObject]){
		if ([line contains: @":"]){
			split = [line rangeOfString: @":"].location;
			[finkConfDict setObject: [line substringFromIndex: split + 2] // eliminate space 
				forKey: [line substringToIndex: split]];
		}
	}
	[finkConfDict setObject: [NSMutableArray arrayWithArray:
								[[finkConfDict objectForKey: @"Trees"] 
									componentsSeparatedByString: @" "]]
				  forKey: @"Trees"];				
}


//--------------------------------------------------->Fink.conf Accessors

-(BOOL)useUnstableMain
{
	if ([[finkConfDict objectForKey: @"Trees"] 
		indexOfObject: @"unstable/main"] == NSNotFound){
		return NO;
	}
	return YES;
}

-(void)setUseUnstableMain:(BOOL)shouldUseUnstable
{
	if (shouldUseUnstable){
		if ([[finkConfDict objectForKey: @"Trees"]
			indexOfObject: @"unstable/main"] == NSNotFound){
			[[finkConfDict objectForKey: @"Trees"] addObject: @"unstable/main"];
		}
	}else{
		if ([[finkConfDict objectForKey: @"Trees"]
			indexOfObject: @"unstable/main"] != NSNotFound){
			[[finkConfDict objectForKey: @"Trees"] removeObject: @"unstable/main"];
		}
	}
}

-(BOOL)useUnstableCrypto
{
	if ([[finkConfDict objectForKey: @"Trees"]
		indexOfObject: @"unstable/crypto"] == NSNotFound){
		return NO;
	}
	return YES;
}

-(void)setUseUnstableCrypto:(BOOL)shouldUseUnstable
{
	if (shouldUseUnstable){
		if ([[finkConfDict objectForKey: @"Trees"]
			indexOfObject: @"unstable/crypto"] == NSNotFound){
			[[finkConfDict objectForKey: @"Trees"] addObject: @"unstable/crypto"];
		}
	}else{
		if ([[finkConfDict objectForKey: @"Trees"]
			indexOfObject: @"unstable/crypto"] != NSNotFound){
			[[finkConfDict objectForKey: @"Trees"] removeObject: @"unstable/crypto"];
		}
	}
}

-(BOOL)verboseOutput
{
	if ([[finkConfDict objectForKey: @"Verbose"] isEqualToString: @"true"]){
		return YES;
	}
	return NO;
}

-(void)setVerboseOutput:(BOOL)verboseOutput
{
	if (verboseOutput){
		[finkConfDict setObject: @"true" forKey: @"Verbose"];
	}else{
		[finkConfDict setObject: @"false" forKey: @"Verbose"];
	}
}

-(BOOL)passiveFTP
{
	if ([[finkConfDict objectForKey: @"ProxyPassiveFTP"] isEqualToString: @"true"]){
		return YES;
	}
	return NO;
}

-(void)setPassiveFTP:(BOOL)passiveFTP
{
	if (passiveFTP){
		[finkConfDict setObject: @"true" forKey: @"ProxyPassiveFTP"];
	}else{
		[finkConfDict setObject: @"false" forKey: @"ProxyPassiveFTP"];
	}
}

-(NSString *)useHTTPProxy
{
	return [finkConfDict objectForKey: PROXY_HTTP];
}

-(void)setUseHTTPProxy:(NSString *)s
{
	if (s != nil){
		[finkConfDict setObject: s forKey: PROXY_HTTP];
	}else{
		[finkConfDict removeObjectForKey: PROXY_HTTP];
	}
}

-(NSString *)useFTPProxy
{
	return [finkConfDict objectForKey: PROXY_FTP];
}

-(void)setUseFTPProxy:(NSString *)s
{
	if (s != nil){
		[finkConfDict setObject: s forKey: PROXY_FTP];
	}else{
		[finkConfDict removeObjectForKey: PROXY_FTP];
	}
}

-(void)setFinkTreesChanged:(BOOL)b
{
	finkTreesChanged = b;
}


//--------------------------------------------------->Write Changes to Fink.conf

//translate dictionary of fink.conf settings into string for writeToFile method
-(NSString *)stringFromDictionary
{
    NSMutableString *fconfString = [NSMutableString stringWithString:
		@"# Fink configuration, initially created by bootstrap.pl\n"];
	NSEnumerator *e;
    NSString *k;
	NSString *v;
	
	//turn tree list into string
    [finkConfDict setObject: [[finkConfDict objectForKey: @"Trees"] 
								componentsJoinedByString: @" "]
				  forKey: @"Trees"];

	//get string from dictionary of fink.conf values
    e = [finkConfDict keyEnumerator];
    while (k = [e nextObject]){
		v = [finkConfDict objectForKey: k];
		[fconfString appendString: 
		   [NSString stringWithFormat: @"%@: %@\n", k, v]];
    }

	//turn tree list back into an array for additional changes
    [finkConfDict setObject: [[finkConfDict objectForKey: @"Trees"]
								componentsSeparatedByString: @" "]
				  forKey: @"Trees"];

    return fconfString;
}


//starts process of writing changes to fink.conf file by copying existing fink.conf 
//to a backup file
-(void)writeToFile
{
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	NSString *basePath = [defaults objectForKey: FinkBasePath];
	NSString *backupFile = [NSString stringWithFormat: @"%@/etc/fink.conf~", basePath];
	NSMutableArray *backupFinkConfArray = [NSMutableArray arrayWithObjects:
		@"/bin/cp",
		[NSString stringWithFormat: @"%@/etc/fink.conf", basePath],
		backupFile,
		nil];

	[center postNotificationName: FinkConfChangeIsPending
			object: backupFinkConfArray];
}

//completes process of writing changes to fink.conf file;
//performed twice after receiving notifications that previous commands were completed;
//done this way to prevent method calls from overlapping commands running asynchronously
-(void)completeFinkConfUpdate:(NSNotification *)n
{
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	NSString *basePath = [defaults objectForKey: FinkBasePath];

	//if backup performed, write out temp fink.conf file and move to /sw/etc
	if ([[n object] contains: @"cp"]){
		NSString *fconfString = [self stringFromDictionary];
		NSFileManager *manager = [NSFileManager defaultManager];
		NSString *backupFile = [NSString stringWithFormat: @"%@/etc/fink.conf~", basePath];
		NSMutableArray *writeFinkConfArray = [NSMutableArray arrayWithObjects:
			@"/bin/mv",
			@"/private/tmp/fink.conf.tmp",
			[NSString stringWithFormat: @"%@/etc/fink.conf", basePath],
			nil];
		
		//note: NSString write to file method returns boolean YES if successful
		if ([manager fileExistsAtPath: backupFile] &&
			[fconfString writeToFile: @"/private/tmp/fink.conf.tmp" atomically: YES]){

			[center postNotificationName: FinkConfChangeIsPending
								  object: writeFinkConfArray];
		}else{			
			NSRunCriticalAlertPanel(@"Error",
						   @"FinkCommander was unable to write changes to fink.conf.",
						   @"OK", nil, nil);
		}
	//if fink.conf file changed by mv command, call index to make table data reflect
	//new fink.conf settings
	}else if (finkTreesChanged && [[n object] contains: @"mv"]){
		NSMutableArray *indexCommandArray = [NSMutableArray arrayWithObjects:
			@"fink",
			@"index",
			nil];
			
		[self setFinkTreesChanged: NO];

		[center postNotificationName: FinkConfChangeIsPending
				object: indexCommandArray];
	}
}

@end
