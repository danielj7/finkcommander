/*
File: FinkConf.m

 See the header file, FinkConf.h, for interface and license information.

*/

#import "FinkConf.h"

@interface FinkConf ()
{
    BOOL _finkTreesChanged;
}

@property (nonatomic, readonly) NSMutableDictionary *finkConfDict;
@property (nonatomic, readonly) NSUserDefaults *defaults;
// FIXME: not actually used?
@property (nonatomic, copy) NSString *proxyHTTP;

@end

@implementation FinkConf

//--------------------------------------------------->Startup and Shutdown

-(instancetype)init
{
	if ((self = [super init])){
		_finkConfDict = [[NSMutableDictionary alloc] initWithCapacity: 20];
		_defaults = [NSUserDefaults standardUserDefaults];
		
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
                             [[[self defaults] objectForKey: FinkBasePath]
                              stringByAppendingPathComponent: @"/etc/fink.conf"]
                                                      encoding: NSUTF8StringEncoding
                                                         error: &err];
	NSArray *fconfArray;
	NSUInteger split;

	fconfArray = [fconfString componentsSeparatedByString: @"\n"];
	for (NSString *line in fconfArray){
		if ([line contains: @":"]){
			split = [line rangeOfString: @":"].location;
			[self finkConfDict][[line substringToIndex: split]] = [line substringFromIndex: split + 2];
		}
	}
	[self finkConfDict][@"Trees"] = [NSMutableArray arrayWithArray:
								[[self finkConfDict][@"Trees"] 
									componentsSeparatedByString: @" "]];
}


//--------------------------------------------------->Fink.conf Accessors

/*
 * Unstable
 */

-(BOOL)useUnstableMain
{
	if ([[self finkConfDict][@"Trees"] 
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
		if ([[self finkConfDict][@"Trees"]
				indexOfObject: @"unstable/main"] == NSNotFound){
			[[self finkConfDict][@"Trees"] 
				addObject: @"unstable/main"];
		}
	}else{
		if ([[self finkConfDict][@"Trees"]
			indexOfObject: @"unstable/main"] != NSNotFound){
			[[self finkConfDict][@"Trees"] removeObject:@"unstable/main"];
		}
	}
}

-(BOOL)useUnstableCrypto
{
	if ([[self finkConfDict][@"Trees"]
		indexOfObject: @"unstable/crypto"] == NSNotFound){
		return NO;
	}
	return YES;
}

-(void)setUseUnstableCrypto:(BOOL)shouldUseUnstable
{
	if (shouldUseUnstable){
		if ([[self finkConfDict][@"Trees"]
			indexOfObject: @"unstable/crypto"] == NSNotFound){
			[[self finkConfDict][@"Trees"] 
				addObject: @"unstable/crypto"];
		}
	}else{
		if ([[self finkConfDict][@"Trees"]
			indexOfObject: @"unstable/crypto"] != NSNotFound){
			[[self finkConfDict][@"Trees"] removeObject:@"unstable/crypto"];
		}
	}
}

//Flag whether fink index needs to be run in order to update the table
-(void)setFinkTreesChanged:(BOOL)b
{
	_finkTreesChanged = b;
}

/*
 * Verbosity
 */

//does the user have PM v. 0.10 or later and therefore access to the
//additional verbosity options?
-(BOOL)extendedVerboseOptions
{
	if ([[self defaults] boolForKey:FinkExtendedVerbosity]){
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
			[[self defaults] setBool:YES forKey:FinkExtendedVerbosity];
			return YES;
		}
	}
	return NO;
}

-(NSInteger)verboseOutput
{
	NSString *verbose = [self finkConfDict][@"Verbose"];
	
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
	[self finkConfDict][@"Verbose"] = loquacity;
}

/*
 * Keeping Directories
 */

-(BOOL)keepBuildDir
{
	if ([[self finkConfDict][@"KeepBuildDir"] isEqualToString: @"true"]){
		return YES;
	}
	return NO;
}

-(void)setKeepBuildDir:(BOOL)keep
{
	if (keep){
		[self finkConfDict][@"KeepBuildDir"] = @"true";
	}else{
		[self finkConfDict][@"KeepBuildDir"] = @"false";
	}
}

-(BOOL)keepRootDir
{
	if ([[self finkConfDict][@"KeepRootDir"] isEqualToString: @"true"]){
		return YES;
	}
	return NO;
	
}

-(void)setKeepRootDir:(BOOL)keep
{
	if (keep){
		[self finkConfDict][@"KeepRootDir"] = @"true";
	}else{
		[self finkConfDict][@"KeepRootDir"] = @"false";
	}
	
}

/*
 * Downloads
 */

-(BOOL)passiveFTP
{
	if ([[self finkConfDict][@"ProxyPassiveFTP"] isEqualToString: @"true"]){
		return YES;
	}
	return NO;
}

-(void)setPassiveFTP:(BOOL)passiveFTP
{
	if (passiveFTP){
		[self finkConfDict][@"ProxyPassiveFTP"] = @"true";
	}else{
		[self finkConfDict][@"ProxyPassiveFTP"] = @"false";
	}
}

-(NSString *)useHTTPProxy
{
	NSString *proxy = [self finkConfDict][@"ProxyHTTP"];

	if (proxy != nil){
		return proxy;
	} else {
		return @"";
	}
}

-(void)setUseHTTPProxy:(NSString *)s
{
	if (s != nil){
		[self finkConfDict][@"ProxyHTTP"] = s;
	}else{
		[[self finkConfDict] removeObjectForKey: @"ProxyHTTP"];
	}
}

-(NSString *)useFTPProxy
{
	NSString *proxy = [self finkConfDict][@"ProxyFTP"];

	if (proxy != nil){
		return proxy;
	} else {
		return @"";
	}
}

-(void)setUseFTPProxy:(NSString *)s
{
	if (s != nil){
		[self finkConfDict][@"ProxyFTP"] = s;
	}else{
		[[self finkConfDict] removeObjectForKey: @"ProxyFTP"];
	}
}

-(NSString *)downloadMethod
{
	NSString *method = [self finkConfDict][@"DownloadMethod"];
	if (method != nil){
		return method;
	}
	return @"curl"; //default
}

-(void)setDownloadMethod:(NSString *)s
{
	[self finkConfDict][@"DownloadMethod"] = s;
}

-(NSString *)fetchAltDir
{
	return [self finkConfDict][@"FetchAltDir"];
}

-(void)setFetchAltDir:(NSString *)s
{
	if (s != nil){
		[self finkConfDict][@"FetchAltDir"] = s;
	}else{
		[[self finkConfDict] removeObjectForKey: @"FetchAltDir"];
	}
}

/*
 * Root Authorization Method
 */

-(NSString *)rootMethod
{
	NSString *method = [self finkConfDict][@"RootMethod"];
	if (method != nil){
		return method;
	}
	return @"sudo"; //default
}

-(void)setRootMethod:(NSString *)s
{
	[self finkConfDict][@"RootMethod"] = s;
}

-(NSString *)distribution
{
	NSString *d = [self finkConfDict][@"Distribution"];
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
    [self finkConfDict][@"Trees"] = [[self finkConfDict][@"Trees"] 
								componentsJoinedByString: @" "];

	//get string from dictionary of fink.conf values
    e = [[self finkConfDict] keyEnumerator];
    while ((k = [e nextObject])){
		v = [self finkConfDict][k];
		[fconfString appendString: 
		   [NSString stringWithFormat: @"%@: %@\n", k, v]];
    }

	//turn tree list back into an array for additional changes
    [self finkConfDict][@"Trees"] = [[self finkConfDict][@"Trees"]
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
			[[self defaults] objectForKey: FinkBasePath],
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
	if (_finkTreesChanged){
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		NSString *basePath = [[self defaults] objectForKey: FinkBasePath];
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
