/*  
File: FinkData.m

See the header file, FinkData.h, for interface and license information.

*/

#import "FinkData.h"

//Constants: placed here to make it easier to change values if fink output changes
#define WEBKEY @"Web site:"
#define MAINTAINERKEY @"Maintainer:"
#define URLSTART 10
#define NAMESTART 12
#define PACKAGESTART 9
#define VERSIONSTART 9

@interface FinkData ()
@property (nonatomic) NSArray *array;
@property (nonatomic) NSDictionary *binaryPackages;
@property (nonatomic) NSDate *start;
@property (nonatomic) NSUserDefaults *defaults;
@end

@implementation FinkData

//---------------------------------------------------------->The Usual

+(FinkData *)sharedData
{
    static FinkData *mySharedData = nil;
    if (nil == mySharedData){
        mySharedData = [[FinkData alloc] init];
    }
    return mySharedData;
}

-(instancetype)init
{
    if ((self = [super init]))
	{
		[self setDefaults: [NSUserDefaults standardUserDefaults]];
		[[NSNotificationCenter defaultCenter] 
			addObserver: self
			selector: @selector(completeUpdate:)
			name: NSFileHandleReadToEndOfFileCompletionNotification
			object: nil];
	}
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

//---------------------------------------------------------->Fink Tools
/*
 Tools for getting and storing information about fink packages in the
 packageArray.

 updateBinaryPackageDictionary: is a helper method used to determine
 the version of packages in the array that are available in binary form.

 update: is the "public" method.  It runs a custom perl script in an
 NSTask to obtain a list of all package names and their installation
 states and stores the information in FinkPackage instances in
 packageArray.  completUpdate: is called by notification after the
 asynchronous task called by update is competed.

 A series of methods between update: and completeUpdate: parse the
 output  from the task to derive the package's full description, web
 url, maintainer name and maintainer email address.
 */

-(NSDictionary *)makeBinaryDictionary
{
    NSTask *listCmd = [[NSTask alloc] init];
    NSPipe *pipeIn  = [NSPipe pipe];
    NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];
	NSData *d;
    NSString *output;
	
	NSMutableDictionary *pkgs = [NSMutableDictionary dictionary];
    NSArray *e, *f;
	NSString *pname = nil, *pversion = nil;

    [listCmd setLaunchPath: 
		[[[NSUserDefaults standardUserDefaults] objectForKey: FinkBasePath]
			stringByAppendingPathComponent: @"/bin/apt-cache"]];
    [listCmd setArguments: @[@"dumpavail"]];
    [listCmd setStandardOutput: pipeIn];
    [listCmd launch];
	d = [cmdStdout readDataToEndOfFile];
	output = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    e = [output componentsSeparatedByString: @"\n\n"];
	for (NSString *pkginfo in e){
		@autoreleasepool {
			f = [pkginfo componentsSeparatedByString: @"\n"];
			for (NSString *line in f){
				if ([line contains:@"Package:"]){
					pname = [line substringWithRange: 
									NSMakeRange(PACKAGESTART, [line length] - PACKAGESTART)];
					continue;
				}
				if ([line contains:@"Version:"]){
					pversion = [line substringWithRange:
										NSMakeRange(VERSIONSTART, [line length] - VERSIONSTART)];
					break;
				}
			}
			if (pname && pversion){
				pkgs[pname] = pversion;
			}
		}
	}
	
	Dprintf(@"Completed binary dictionary after %f seconds", -[[self start] timeIntervalSinceNow]);
	return pkgs;
}

-(void)update
{
    NSPipe *pipeIn  = [NSPipe pipe];
    NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];
    NSArray *args;
	NSTask *finkListCommand = [[NSTask alloc] init];

	args = @[[NSHomeDirectory() stringByAppendingPathComponent: 
			@"Library/Application Support/FinkCommander/FinkCommander.pl"]];

	[finkListCommand setLaunchPath:[[self defaults] objectForKey:FinkPerlPath]];
	[finkListCommand setArguments:args];
	[finkListCommand setEnvironment:[[self defaults] objectForKey:FinkEnvironmentSettings]];
    [finkListCommand setStandardOutput:pipeIn];

    [self setStart:[NSDate date]];

    //Run task asynchronously; this can take anywhere from a few seconds to a minute
    [finkListCommand launch];
    //The notification this method refers to will trigger the completeUpdate: method
    [cmdStdout readToEndOfFileInBackgroundAndNotify];

    /*	In the meantime, run the task that obtains the binary package names, which takes only
    	a second or two, synchronously */
	[self setBinaryPackages:[self makeBinaryDictionary]];
}

-(NSString *)parseWeburlFromString:(NSString *)s
{
    NSRange r;
    if ([s length] <= URLSTART){
		return @"";
    }
    r = NSMakeRange(URLSTART, [s length] - URLSTART);
    return [s substringWithRange: r];
}

-(void)getMaintainerName:(NSString **)name
	emailAddress:(NSString **)address
	fromDescription:(NSString *)s
{
	NSInteger emailstart = [s rangeOfString: @"<"].location;
	NSInteger emailend   = [s rangeOfString: @">"].location;
	if (emailstart == NSNotFound || emailend == NSNotFound){
			*name = @"";
			*address = @"";
			return;
		}
	if (emailstart - NAMESTART - 1 >= 0){
		*name = [s substringWithRange:
			NSMakeRange(NAMESTART, emailstart - NAMESTART - 1)];
	} else {
		*name = @"";
	}
	*address = [s substringWithRange:
		NSMakeRange(emailstart + 1, emailend - emailstart - 1)];
}

-(NSArray *)descriptionComponentsFromString:(NSString *)s
{
    NSString *line;
    NSString *web = @"";
    NSString *maint = @"";
    NSString *email = @"";
    NSArray *lines = [s componentsSeparatedByString: @"\n"];
    NSEnumerator *e = [lines objectEnumerator];

    [e nextObject]; //discard--name-version: short desc

    while (nil != (line = [e nextObject])){
		line = [line strip];
		if ([line contains: WEBKEY]){
			web = [self parseWeburlFromString: line];
		}else if ([line contains: MAINTAINERKEY]){
            [self getMaintainerName:&maint
					emailAddress:&email
					fromDescription:line];
		}
    }
    return @[web, maint, email];
}

-(void)completeUpdate:(NSNotification *)n
{
    NSDictionary *info = [n userInfo];
    NSData *d;
    NSString *output; 
    NSMutableArray *outputComponents;
    NSMutableArray *collector = [NSMutableArray array];
    NSArray *packageComponents;
    NSArray *descriptionComponents;
    NSEnumerator *e;
    FinkPackage *p;
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *path;
	NSString *bversion;
	NSArray *flagArray = [[self defaults] objectForKey:FinkFlaggedColumns];
	BOOL showRedundantPackages = [[self defaults] boolForKey:FinkShowRedundantPackages];
	
	d = info[NSFileHandleNotificationDataItem];
	output = [[NSString alloc] initWithData:d
								encoding:NSUTF8StringEncoding];

	Dprintf(@"Read to end of file notification sent after %f seconds",
	   -[[self start] timeIntervalSinceNow]);


    outputComponents = [NSMutableArray arrayWithArray:
	       [output componentsSeparatedByString: @"\n----\n"]];
    [outputComponents removeObjectAtIndex: 0];  // "Reading package info . . . "
    e = [outputComponents objectEnumerator];

    while (nil != (packageComponents = [[e nextObject] componentsSeparatedByString: @"**\n"])){
		/* 	Without a separate autorelease pool for this loop,
			FinkCommander's memory usage increases by several megabytes
			while the updating process is taking place.  */
		@autoreleasepool {
		p = [[FinkPackage alloc] init];
		[p setName:packageComponents[0]];
		[p setStatus:packageComponents[1]];
		[p setVersion:packageComponents[2]];
		[p setInstalled:packageComponents[3]];
		[p setStable:packageComponents[4]];
		[p setUnstable:packageComponents[5]];
		[p setLocal:packageComponents[6]];
		[p setCategory:packageComponents[7]];
		[p setFilename:packageComponents[8]];
		[p setSummary:packageComponents[9]];
		[p setFulldesc:packageComponents[10]];
		
		/* 	Many package have identical versions in the stable and
			unstable branches. If unstable is listed first in
			fink.conf, the package will be identified as unstable by
			Fink::PkgVersion::get_tree() and therefore by
			FinkCommander.pl.  This block fixes that problem by finding
			these packages and identifying them as stable only or as
			stable and unstable, depending on the user's
			preferences. */
		if ([[p stable] length] < 2 && [[p unstable] length] > 1){
			path = [p pathToPackageInTree:@"stable" 
						withExtension:@"info"
						version:[p unstable]];
			if ([manager fileExistsAtPath:path]){
				[p setStable:[p unstable]];
				if (! showRedundantPackages){
					[p setUnstable:@" "];
				}
			}
		}
		if (showRedundantPackages 		&& 
			[[p unstable] length] < 2 	&& 
			[[p stable] length] > 1){
			path = [p pathToPackageInTree:@"unstable" 
						withExtension:@"info"
						version:[p stable]];
			if ([manager fileExistsAtPath:path]){
				[p setUnstable:[p stable]];
			}
		}
		descriptionComponents = [self descriptionComponentsFromString:[p fulldesc]];
		[p setWeburl: descriptionComponents[0]];
		[p setMaintainer: descriptionComponents[1]];
		[p setEmail: descriptionComponents[2]];
		
		bversion = [self binaryPackages][[p name]];
		bversion = bversion ? bversion : @" ";
		[p setBinary:bversion];
		
		if ([flagArray containsObject:[p name]]){
			[p setFlagged:IS_FLAGGED];
		}else{
			[p setFlagged:NOT_FLAGGED];
		}

		[collector addObject: p];
		}
    }
    [self setArray:[NSArray arrayWithArray:collector]]; //make immutable
	[self setBinaryPackages: nil];
	
	Dprintf(@"Fink package array completed after %f seconds",
	   -[[self start] timeIntervalSinceNow]);
	   
    //notify FinkController that table needs to be updated
    [[NSNotificationCenter defaultCenter] postNotificationName: FinkPackageArrayIsFinished
											object: nil];
}

//---------------------------------------------------------->Utilities

-(NSInteger)installedPackagesCount
{
    NSInteger count = 0;

    for (FinkPackage *pkg in [self array]){
		if ([[pkg status] contains: @"t"]){
			count++;
		}
    }
    return count;
}

@end

