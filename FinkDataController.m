/*  
File: FinkDataController.m

See the header file, FinkDataController.h, for interface and license information.

*/

#import "FinkDataController.h"

//Globals: placed here to make it easier to change values if fink output changes
NSString *WEBKEY = @"Web site:";
NSString *MAINTAINERKEY = @"Maintainer:";
int URLSTART = 10;
int NAMESTART = 12;
int PACKAGESTART = 9;
int VERSIONSTART = 9;

@implementation FinkDataController

//---------------------------------------------------------->The Usual

-(id)init
{
    if (self = [super init])
	{
		defaults = [NSUserDefaults standardUserDefaults];
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
    [array release];
    [binaryPackages release];
    [start release];
    [super dealloc];
}

// Accessors
-(NSArray *)array
{
    return array;
}

-(void)setArray:(NSArray *)a
{
    [a retain];
    [array release];
    array = a;
}

-(void)setBinaryPackages:(NSDictionary *)d
{
    [d retain];
    [binaryPackages release];
    binaryPackages = d;
}

-(void)setStart:(NSDate *)d
{
    [d retain];
    [start release];
    start = d;
}

//---------------------------------------------------------->Fink Tools
//
//  Tools for getting and storing information about fink packages in the array.
//
//  update: is the "public" method.  It runs a custom perl script 
//  in an NSTask to obtain a list of all package names and their installation 
//  states and stores the information in FinkPackage instances in array.
//  completUpdate: is called by notification after the asynchronous task
//  called by update is competed.
//
//	makeBinaryDictionary is a helper method used to determine
//  the version of packages in the array that are available in binary form.
//
//  A series of methods between update: and completeUpdate: parse the output
//  from the task to derive the package's full description, web url, maintainer name
//  and maintainer email address.

-(NSDictionary *)makeBinaryDictionary
{
    NSTask *listCmd = [[NSTask alloc] init];
    NSPipe *pipeIn  = [NSPipe pipe];
    NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];
	NSData *d;
    NSString *output;
	
	NSMutableDictionary *pkgs = [NSMutableDictionary dictionary];
    NSEnumerator *e, *f;
    NSString *pkginfo, *line;
	NSString *pname = nil, *pversion = nil;

    [listCmd setLaunchPath: 
		[[[NSUserDefaults standardUserDefaults] objectForKey: FinkBasePath]
			stringByAppendingPathComponent: @"/bin/apt-cache"]];
    [listCmd setArguments: [NSArray arrayWithObjects: @"dumpavail", nil]];
    [listCmd setStandardOutput: pipeIn];
    [listCmd launch];
	d = [cmdStdout readDataToEndOfFile];
	[listCmd release];
	output = [[[NSString alloc] initWithData:d encoding:NSMacOSRomanStringEncoding] autorelease];
    e = [[output componentsSeparatedByString: @"\n\n"] objectEnumerator];
	while (nil != (pkginfo = [e nextObject])){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		f = [[pkginfo componentsSeparatedByString: @"\n"] objectEnumerator];
		while (nil != (line = [f nextObject])){
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
			[pkgs setObject:pversion forKey:pname];
		}
		[pool release];
	}
	
	Dprintf(@"Completed binary dictionary after %f seconds", -[start timeIntervalSinceNow]);
	return pkgs;
}

-(void)update
{
    NSPipe *pipeIn  = [NSPipe pipe];
    NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];
    NSArray *args;
	NSTask *finkListCommand = [[[NSTask alloc] init] autorelease];
	args = [NSArray arrayWithObjects:
		[NSHomeDirectory() stringByAppendingPathComponent: 
			@"Library/Application Support/FinkCommander/FinkCommander.pl"], nil];
	[finkListCommand setLaunchPath: @"/usr/bin/perl"];

    [finkListCommand setArguments: args];
    [finkListCommand setStandardOutput: pipeIn];

    [self setStart: [NSDate date]];

    //run task asynchronously; this can take anywhere from a few seconds to a minute
    [finkListCommand launch];
    //the notification this method refers to will trigger the completeUpdate: method
    [cmdStdout readToEndOfFileInBackgroundAndNotify];

    //in the meantime, run the task that obtains the binary package names, which takes only
    //a second or two, synchronously
	[self setBinaryPackages: [self makeBinaryDictionary]];
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

-(NSArray *)parseMaintainerInfoFromString:(NSString *)s
{
    NSString *name;    
    NSString *address;

    int emailstart = [s rangeOfString: @"<"].location;   
    int emailend   = [s rangeOfString: @">"].location;

    if (emailstart == NSNotFound || emailend == NSNotFound){
		return [NSArray arrayWithObjects: @"", @"", nil];
    }	
    name = [s substringWithRange:NSMakeRange(NAMESTART, emailstart - NAMESTART - 1)];
    address = [s substringWithRange:NSMakeRange(emailstart + 1, emailend - emailstart - 1)];
    return [NSArray arrayWithObjects: name, address, nil];
}

-(NSArray *)descriptionComponentsFromString:(NSString *)s
{
    NSString *line;
    NSString *web = @"";
    NSString *maint = @"";
    NSString *email = @"";
    NSArray *lines = [s componentsSeparatedByString: @"\n"];
    NSEnumerator *e = [lines objectEnumerator];

    line = [e nextObject]; //discard--name-version: short desc

    while (nil != (line = [e nextObject])){
		line = [line strip];
		if ([line contains: WEBKEY]){
			web = [self parseWeburlFromString: line];
		}else if ([line contains: MAINTAINERKEY]){
			NSArray *info = [self parseMaintainerInfoFromString: line];
			maint = [info objectAtIndex: 0];
			email = [info objectAtIndex: 1];
		}
    }
    return [NSArray arrayWithObjects: web, maint, email, nil];
}

-(void)completeUpdate:(NSNotification *)n
{
    NSDictionary *info = [n userInfo];
    NSData *d;
    NSString *output; 
    NSMutableArray *temp;
    NSMutableArray *collector = [NSMutableArray array];
    NSArray *listRecord;
    NSArray *components;
    NSEnumerator *e;
    FinkPackage *p;
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *path;
	NSString *bversion;
	
	d = [info objectForKey: NSFileHandleNotificationDataItem];
	output = [[[NSString alloc] initWithData:d
								encoding:NSMacOSRomanStringEncoding] autorelease];

	Dprintf(@"Read to end of file notification sent after %f seconds",
	   -[start timeIntervalSinceNow]);

    temp = [NSMutableArray arrayWithArray:
	       [output componentsSeparatedByString: @"\n----\n"]];
    [temp removeObjectAtIndex: 0];  // "Reading package info . . . "
    e = [temp objectEnumerator];

    while (nil != (listRecord = [[e nextObject] componentsSeparatedByString: @"**\n"])){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		p = [[FinkPackage alloc] init];
		[p setName:[listRecord objectAtIndex: 0]];
		[p setStatus:[listRecord objectAtIndex: 1]];
		[p setVersion:[listRecord objectAtIndex: 2]];
		[p setInstalled:[listRecord objectAtIndex: 3]];
		[p setStable:[listRecord objectAtIndex: 4]];
		[p setUnstable:[listRecord objectAtIndex: 5]];
		[p setCategory:[listRecord objectAtIndex: 6]];
		[p setSummary:[listRecord objectAtIndex: 7]];
		[p setFulldesc:[listRecord objectAtIndex: 8]];

		if ([defaults boolForKey:FinkShowRedundantPackages] &&
			[[p unstable] length] < 2 						&&
			[[p stable] length] > 1){
			path = [self pathToPackage:p inTree:@"unstable" withExtension:@"info"];
			if ([manager fileExistsAtPath:path]){
				[p setUnstable:[p stable]];
			}
		}
		components = [self descriptionComponentsFromString: [p fulldesc]];
		[p setWeburl: [components objectAtIndex: 0]];
		[p setMaintainer: [components objectAtIndex: 1]];
		[p setEmail: [components objectAtIndex: 2]];
		
		bversion = [binaryPackages objectForKey:[p name]];
		bversion = bversion ? bversion : @" ";
		[p setBinary:bversion];

		[collector addObject: p];
		[p release];
		[pool release];
    }
    [self setArray:[NSArray arrayWithArray:collector]]; //make immutable
	[self setBinaryPackages: nil];
	
	Dprintf(@"Fink package array completed after %f seconds",
	   -[start timeIntervalSinceNow]);
	   
    //notify FinkController that table needs to be updated
    [[NSNotificationCenter defaultCenter] postNotificationName: FinkPackageArrayIsFinished
											object: nil];
}

//---------------------------------------------------------->Utilities

-(NSString *)pathToPackage:(FinkPackage *)pkg 
			   inTree:(NSString *)tree
			   withExtension:(NSString *)ext
{
	NSString *version = [tree isEqualToString:@"stable"] ? [pkg unstable] : [pkg stable];
	NSString *name = [pkg name];
	NSString *pathToDists = [[[defaults objectForKey:FinkBasePath]
								stringByAppendingPathComponent: @"/fink/dists"] retain];
	NSString *splitoff;
	NSEnumerator *e = [[NSArray arrayWithObjects:@"-bin", @"-dev", @"-shlibs", nil]
								objectEnumerator];
    NSString *pkgFileName;
    NSArray *components;
	NSRange r;

	while (nil != (splitoff = [e nextObject])){
		r = [name rangeOfString:splitoff];
		if (r.length > 0){
			name = [name substringToIndex:r.location];
			break;
		}
	}
	pkgFileName = [NSString stringWithFormat:@"%@-%@.%@", name, version, ext];

    if ([[pkg category] isEqualToString:@"crypto"]){
		components = [NSArray arrayWithObjects:pathToDists, tree, @"crypto",
			@"finkinfo", pkgFileName, nil];
    }else{
		components = [NSArray arrayWithObjects:pathToDists, tree, @"main",
			@"finkinfo", [pkg category], pkgFileName, nil];
    }

	return [NSString pathWithComponents:components];
}

-(int)installedPackagesCount
{
    int count = 0;
    NSEnumerator *e = [[self array] objectEnumerator];
    FinkPackage *pkg;

    while (nil != (pkg = [e nextObject])){
		if ([[pkg status] contains: @"t"]){
			count++;
		}
    }
    return count;
}

@end

