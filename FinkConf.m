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
NSString *FinkLookedForProxy = @"FinkLookedForProxy";


@implementation FinkConf

-(id)init
{
	defaults = [NSUserDefaults standardUserDefaults];

	if (self = [super init]){
		finkConfDict = [[NSMutableDictionary alloc] initWithCapacity: 15];
		[self readFinkConf];
	}
	return self;
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
		if ([line rangeOfString: @":"].length > 0){
			split = [line rangeOfString: @":"].location;
			[finkConfDict setObject: [line substringFromIndex: split + 2] // eliminate space 
				forKey: [line substringToIndex: split]];
		}
	}
	[finkConfDict setObject: 
						[NSMutableArray arrayWithArray:
							[[finkConfDict objectForKey: @"Trees"] 
								componentsSeparatedByString: @" "]]
				  forKey: @"Trees"];				
}

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


-(NSString *)stringFromDictionary
{
    NSMutableString *fconfString = [NSMutableString stringWithString:
		@"# Fink configuration, initially created by bootstrap.pl\n"];
	NSEnumerator *e;
    NSString *k;

    [finkConfDict setObject: [[finkConfDict objectForKey: @"Trees"] 
								componentsJoinedByString: @" "]
				  forKey: @"Trees"];

    e = [finkConfDict keyEnumerator];
    while (k = [e nextObject]){
		[fconfString appendString: 
		   [NSString stringWithFormat:
				@"%@: %@\n", k, [finkConfDict objectForKey: k]]];
    }

    [finkConfDict setObject: [[finkConfDict objectForKey: @"Trees"]
								componentsSeparatedByString: @" "]
				  forKey: @"Trees"];

    return fconfString;
}

-(void)writeToFile
{
    NSString *fconfString = [self stringFromDictionary];
	NSLog(@"New configuration: %@", fconfString);

#ifdef UNDEF
	//NEED TO ADD PIPES TO STDOUT & STDIN TO DETECT REQUEST FOR AND WRITE PASSWORD
	//OR USE IOTASKWRAPPER
    NSTask *backupTask = [[NSTask alloc] init];
    NSTask *writeTask = [[NSTask alloc] init];
    NSString *basePath = [defaults objectForKey: FinkBasePath];
    int error;

    // Back up existing fink.conf; check for successful completion
    [backupTask setLaunchPath: @"/usr/bin/sudo"];
    [backupTask setArguments: 
		[NSArray arrayWithObjects: @"-S",
			@"/bin/cp", 
			[NSString stringWithFormat: @"%@/etc/fink.conf", basePath],
			[NSString stringWithFormat: @"%@/etc/fink.conf.bak", basePath],
			nil]];
    [backupTask launch];
    while ([backupTask isRunning]){
		continue;
    }
    error = [backupTask terminationStatus];
    [backupTask release];
    if (error){
		NSRunCriticalAlertPanel(@"Error", 
			@"FinkCommander was unable to create a backup for fink.conf.\nFink.conf has not been altered.",
			@"OK", nil, nil);
		return;
    }

    // Write new settings to file; check again
    [writeTask setLaunchPath: @"/usr/bin/sudo"];
    [writeTask setArguments:
		[NSArray arrayWithObjects: @"-S", @"/bin/echo", 
			[NSString stringWithFormat: @"%@>%@/etc/fink.conf", 
				fconfString, basePath],
			nil]];
    [writeTask launch];
    while ([writeTask isRunning]){
		continue;
    }
    error = [writeTask terminationStatus];
    [writeTask release];
    if (error){
       	NSRunCriticalAlertPanel(@"Error", 
				@"FinkCommander was unable to write changes to fink.conf.",
				@"OK", nil, nil);
    }
	
#endif //UNDEF

}

@end
