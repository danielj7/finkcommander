/*
File: FinkConf.m

 See the header file, FinkConf.h, for interface and license information.

*/

#import "FinkConf.h"

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
	while(nil != (line = [e nextObject])){
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

/*
 * Unstable
 */

-(BOOL)useUnstableMain
{
	if ([[finkConfDict objectForKey: @"Trees"] 
			indexOfObject: @"unstable/main"] == NSNotFound){
		return NO;
	}
	return YES;
}

//This is called after setUseUnstableCrypto in FinkPreferences
//so inserting at index 0 will insure unstable/main comes first
-(void)setUseUnstableMain:(BOOL)shouldUseUnstable
{
	if (shouldUseUnstable){
		if ([[finkConfDict objectForKey: @"Trees"]
				indexOfObject: @"unstable/main"] == NSNotFound){
			[[finkConfDict objectForKey: @"Trees"] 
				addObject: @"unstable/main"];
		}
	}else{
		if ([[finkConfDict objectForKey: @"Trees"]
			indexOfObject: @"unstable/main"] != NSNotFound){
			[[finkConfDict objectForKey:@"Trees"] removeObject:@"unstable/main"];
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
			[[finkConfDict objectForKey: @"Trees"] 
				addObject: @"unstable/crypto"];
		}
	}else{
		if ([[finkConfDict objectForKey: @"Trees"]
			indexOfObject: @"unstable/crypto"] != NSNotFound){
			[[finkConfDict objectForKey:@"Trees"] removeObject:@"unstable/crypto"];
		}
	}
}

//Flag whether fink index needs to be run in order to update the table
-(void)setFinkTreesChanged:(BOOL)b
{
	finkTreesChanged = b;
}

/*
 * Verbosity
 */

//does the user have PM v. 0.10 or later and therefore access to the
//additional verbosity options?
-(BOOL)extendedVerboseOptions
{
	if ([defaults boolForKey:FinkExtendedVerbosity]){
		return YES;
	}else{
		FinkInstallationInfo *info = [[[FinkInstallationInfo alloc] init] autorelease];
		NSString *fversion = [info finkVersion];
		NSString *pmversion = [[fversion componentsSeparatedByString:@"\n"] objectAtIndex:0];
		NSScanner *vscan = [NSScanner scannerWithString:pmversion];
		int vnum;

		[vscan scanUpToString:@"0." intoString:nil];
		[vscan scanString:@"0." intoString:nil];
		[vscan scanInt:&vnum];
		if (vnum > 9){
			[defaults setBool:YES forKey:FinkExtendedVerbosity];
			return YES;
		}
	}
	return NO;
}

-(int)verboseOutput
{
	NSString *verbose = [finkConfDict objectForKey:@"Verbose"];
	
	if ([self extendedVerboseOptions]){
		return [verbose intValue];
	}
	if ([verbose isEqualToString:@"true"]){
		return 1;
	}
	return 0;
}

-(void)setVerboseOutput:(int)verboseOutput
{
	NSString *loquacity;
	
	if ([self extendedVerboseOptions]){
		loquacity = [NSString stringWithFormat:@"%d", verboseOutput];
	}else if (verboseOutput){
		loquacity = @"true";
	}else{
		loquacity = @"false";
	}
	[finkConfDict setObject:loquacity forKey:@"Verbose"];
}

/*
 * Keeping Directories
 */

-(BOOL)keepBuildDir
{
	if ([[finkConfDict objectForKey: @"KeepBuildDir"] isEqualToString: @"true"]){
		return YES;
	}
	return NO;
}

-(void)setKeepBuildDir:(BOOL)keep
{
	if (keep){
		[finkConfDict setObject: @"true" forKey: @"KeepBuildDir"];
	}else{
		[finkConfDict setObject: @"false" forKey: @"KeepBuildDir"];
	}
}

-(BOOL)keepRootDir
{
	if ([[finkConfDict objectForKey: @"KeepRootDir"] isEqualToString: @"true"]){
		return YES;
	}
	return NO;
	
}

-(void)setKeepRootDir:(BOOL)keep
{
	if (keep){
		[finkConfDict setObject: @"true" forKey: @"KeepRootDir"];
	}else{
		[finkConfDict setObject: @"false" forKey: @"KeepRootDir"];
	}
	
}

/*
 * Downloads
 */

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
	return [finkConfDict objectForKey: @"ProxyHTTP"];
}

-(void)setUseHTTPProxy:(NSString *)s
{
	if (s != nil){
		[finkConfDict setObject: s forKey: @"ProxyHTTP"];
	}else{
		[finkConfDict removeObjectForKey: @"ProxyHTTP"];
	}
}

-(NSString *)useFTPProxy
{
	return [finkConfDict objectForKey: @"ProxyFTP"];
}

-(void)setUseFTPProxy:(NSString *)s
{
	if (s != nil){
		[finkConfDict setObject:s forKey: @"ProxyFTP"];
	}else{
		[finkConfDict removeObjectForKey: @"ProxyFTP"];
	}
}

-(NSString *)downloadMethod
{
	NSString *method = [finkConfDict objectForKey: @"DownloadMethod"];
	if (method != nil){
		return method;
	}
	return @"curl"; //default
}

-(void)setDownloadMethod:(NSString *)s
{
	[finkConfDict setObject:s forKey: @"DownloadMethod"];
}

-(NSString *)fetchAltDir
{
	return [finkConfDict objectForKey: @"FetchAltDir"];
}

-(void)setFetchAltDir:(NSString *)s
{
	if (s != nil){
		[finkConfDict setObject:s forKey: @"FetchAltDir"];
	}else{
		[finkConfDict removeObjectForKey: @"FetchAltDir"];
	}
}

/*
 * Root Authorization Method
 */

-(NSString *)rootMethod
{
	NSString *method = [finkConfDict objectForKey: @"RootMethod"];
	if (method != nil){
		return method;
	}
	return @"sudo"; //default
}

-(void)setRootMethod:(NSString *)s
{
	[finkConfDict setObject:s forKey: @"RootMethod"];
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

//Notifies FinkController to run authorized task to write changes to fink.conf
-(void)writeToFile
{
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	NSString *fconfString = [self stringFromDictionary];
	NSString *tempFile = @"/private/tmp/fink.conf.tmp";
	NSMutableArray *writeFinkConfArray = 
		[NSMutableArray arrayWithObjects:
			@"--write_fconf",
			[defaults objectForKey: FinkBasePath],
			nil];
	NSDictionary *d = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:YES]
									forKey:FinkRunProgressIndicator];
	BOOL success;
	
	
	success = [fconfString writeToFile:tempFile atomically:YES];
	if (! success){
		NSRunCriticalAlertPanel(NSLocalizedString(@"Error", nil),
				NSLocalizedString(@"FinkCommander was unable to write changes to fink.conf.", nil),
				NSLocalizedString(@"OK", nil), nil, nil);
	}
	[center postNotificationName:FinkRunCommandNotification
			object:writeFinkConfArray 
			userInfo:d];
}

//Notifies FinkController to run fink index if necessary to update table info
-(void)completeFinkConfUpdate:(NSNotification *)n
{
	if (finkTreesChanged){
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		NSString *basePath = [defaults objectForKey: FinkBasePath];
		NSDictionary *d = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:YES]
										forKey:FinkRunProgressIndicator];
		NSMutableArray *indexCommandArray =
			[NSMutableArray arrayWithObjects:
				[basePath stringByAppendingPathComponent:@"/bin/fink"],
				@"index",
				nil];

		[self setFinkTreesChanged: NO];
		[center postNotificationName:FinkRunCommandNotification
				object:indexCommandArray
				userInfo:d];
	}
}

@end
