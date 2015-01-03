/*
File: FinkConf.m

 See the header file, FinkConf.h, for interface and license information.

*/

#import "FinkConf.h"

@implementation FinkConf

//--------------------------------------------------->Startup and Shutdown

-(instancetype)init
{
	if ((self = [super init])){
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
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

-(void)readFinkConf
{
    // TODO: check if an error occurred reading fink.conf.
    NSError *err;
    // fink.conf should be plain ASCII but use UTF8 since it's a superset.
    NSString *fconfString = [NSString stringWithContentsOfFile:
                             [[defaults objectForKey: FinkBasePath]
                              stringByAppendingPathComponent: @"/etc/fink.conf"]
                                                      encoding: NSUTF8StringEncoding
                                                         error: &err];
	NSArray *fconfArray;
	NSUInteger split;

	fconfArray = [fconfString componentsSeparatedByString: @"\n"];
	for (NSString *line in fconfArray){
		if ([line contains: @":"]){
			split = [line rangeOfString: @":"].location;
			finkConfDict[[line substringToIndex: split]] = [line substringFromIndex: split + 2];
		}
	}
	finkConfDict[@"Trees"] = [NSMutableArray arrayWithArray:
								[finkConfDict[@"Trees"] 
									componentsSeparatedByString: @" "]];
}


//--------------------------------------------------->Fink.conf Accessors

/*
 * Unstable
 */

-(BOOL)useUnstableMain
{
	if ([finkConfDict[@"Trees"] 
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
		if ([finkConfDict[@"Trees"]
				indexOfObject: @"unstable/main"] == NSNotFound){
			[finkConfDict[@"Trees"] 
				addObject: @"unstable/main"];
		}
	}else{
		if ([finkConfDict[@"Trees"]
			indexOfObject: @"unstable/main"] != NSNotFound){
			[finkConfDict[@"Trees"] removeObject:@"unstable/main"];
		}
	}
}

-(BOOL)useUnstableCrypto
{
	if ([finkConfDict[@"Trees"]
		indexOfObject: @"unstable/crypto"] == NSNotFound){
		return NO;
	}
	return YES;
}

-(void)setUseUnstableCrypto:(BOOL)shouldUseUnstable
{
	if (shouldUseUnstable){
		if ([finkConfDict[@"Trees"]
			indexOfObject: @"unstable/crypto"] == NSNotFound){
			[finkConfDict[@"Trees"] 
				addObject: @"unstable/crypto"];
		}
	}else{
		if ([finkConfDict[@"Trees"]
			indexOfObject: @"unstable/crypto"] != NSNotFound){
			[finkConfDict[@"Trees"] removeObject:@"unstable/crypto"];
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
		NSString *fversion = [[FinkInstallationInfo sharedInfo] finkVersion];
		NSString *pmversion = [fversion componentsSeparatedByString:@"\n"][0];
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

-(NSInteger)verboseOutput
{
	NSString *verbose = finkConfDict[@"Verbose"];
	
	if ([self extendedVerboseOptions]){
		return [verbose intValue];
	}
	if ([verbose isEqualToString:@"true"]){
		return 1;
	}
	return 0;
}

-(void)setVerboseOutput:(NSInteger)verboseOutput
{
	NSString *loquacity;
	
	if ([self extendedVerboseOptions]){
		loquacity = [NSString stringWithFormat:@"%ld", (long)verboseOutput];
	}else if (verboseOutput){
		loquacity = @"true";
	}else{
		loquacity = @"false";
	}
	finkConfDict[@"Verbose"] = loquacity;
}

/*
 * Keeping Directories
 */

-(BOOL)keepBuildDir
{
	if ([finkConfDict[@"KeepBuildDir"] isEqualToString: @"true"]){
		return YES;
	}
	return NO;
}

-(void)setKeepBuildDir:(BOOL)keep
{
	if (keep){
		finkConfDict[@"KeepBuildDir"] = @"true";
	}else{
		finkConfDict[@"KeepBuildDir"] = @"false";
	}
}

-(BOOL)keepRootDir
{
	if ([finkConfDict[@"KeepRootDir"] isEqualToString: @"true"]){
		return YES;
	}
	return NO;
	
}

-(void)setKeepRootDir:(BOOL)keep
{
	if (keep){
		finkConfDict[@"KeepRootDir"] = @"true";
	}else{
		finkConfDict[@"KeepRootDir"] = @"false";
	}
	
}

/*
 * Downloads
 */

-(BOOL)passiveFTP
{
	if ([finkConfDict[@"ProxyPassiveFTP"] isEqualToString: @"true"]){
		return YES;
	}
	return NO;
}

-(void)setPassiveFTP:(BOOL)passiveFTP
{
	if (passiveFTP){
		finkConfDict[@"ProxyPassiveFTP"] = @"true";
	}else{
		finkConfDict[@"ProxyPassiveFTP"] = @"false";
	}
}

-(NSString *)useHTTPProxy
{
	NSString *proxy = finkConfDict[@"ProxyHTTP"];

	if (proxy != nil){
		return proxy;
	} else {
		return @"";
	}
}

-(void)setUseHTTPProxy:(NSString *)s
{
	if (s != nil){
		finkConfDict[@"ProxyHTTP"] = s;
	}else{
		[finkConfDict removeObjectForKey: @"ProxyHTTP"];
	}
}

-(NSString *)useFTPProxy
{
	NSString *proxy = finkConfDict[@"ProxyFTP"];

	if (proxy != nil){
		return proxy;
	} else {
		return @"";
	}
}

-(void)setUseFTPProxy:(NSString *)s
{
	if (s != nil){
		finkConfDict[@"ProxyFTP"] = s;
	}else{
		[finkConfDict removeObjectForKey: @"ProxyFTP"];
	}
}

-(NSString *)downloadMethod
{
	NSString *method = finkConfDict[@"DownloadMethod"];
	if (method != nil){
		return method;
	}
	return @"curl"; //default
}

-(void)setDownloadMethod:(NSString *)s
{
	finkConfDict[@"DownloadMethod"] = s;
}

-(NSString *)fetchAltDir
{
	return finkConfDict[@"FetchAltDir"];
}

-(void)setFetchAltDir:(NSString *)s
{
	if (s != nil){
		finkConfDict[@"FetchAltDir"] = s;
	}else{
		[finkConfDict removeObjectForKey: @"FetchAltDir"];
	}
}

/*
 * Root Authorization Method
 */

-(NSString *)rootMethod
{
	NSString *method = finkConfDict[@"RootMethod"];
	if (method != nil){
		return method;
	}
	return @"sudo"; //default
}

-(void)setRootMethod:(NSString *)s
{
	finkConfDict[@"RootMethod"] = s;
}

-(NSString *)distribution
{
	NSString *d = finkConfDict[@"Distribution"];
	if (d != nil) {
		return d;
	}
	return @"";
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
    finkConfDict[@"Trees"] = [finkConfDict[@"Trees"] 
								componentsJoinedByString: @" "];

	//get string from dictionary of fink.conf values
    e = [finkConfDict keyEnumerator];
    while ((k = [e nextObject])){
		v = finkConfDict[k];
		[fconfString appendString: 
		   [NSString stringWithFormat: @"%@: %@\n", k, v]];
    }

	//turn tree list back into an array for additional changes
    finkConfDict[@"Trees"] = [finkConfDict[@"Trees"]
								componentsSeparatedByString: @" "];
	
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
	NSDictionary *d = @{FinkRunProgressIndicator: [NSNumber numberWithInt:YES]};
	BOOL success;
	
	success = [fconfString writeToFile:tempFile atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	if (! success){
		NSRunCriticalAlertPanel(LS_ERROR,
				NSLocalizedString(@"FinkCommander was unable to write changes to fink.conf.", 
								  @"Alert panel message"),
				LS_OK, nil, nil);
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
		NSDictionary *d = @{FinkRunProgressIndicator: [NSNumber numberWithInt:YES]};
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
