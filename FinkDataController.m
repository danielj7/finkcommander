/*  
File: FinkDataController.m

See the header file, FinkDataController.h, for interface and license information.

*/

//If you use UTF-8 encoding to encode data objects obtained by running shell commands
//in a subprocess, as suggested by Apple's Moriarity example your code will break 
//on Jaguar.  Jaguar uses bash as the default shell for ....  Bash does not support UTF-8 encoding.

#import "FinkDataController.h"

//#define TESTING

#ifdef DEBUGGING
#define BUFFERLEN 512
#endif //DEBUGGING

//Globals: placed here to make it easier to change values if fink output changes
NSString *WEBKEY = @"Web site:";
NSString *MAINTAINERKEY = @"Maintainer:";
int URLSTART = 10;
int NAMESTART = 12;

@implementation FinkDataController

//---------------------------------------------------------->The Ususal

-(id)init
{
    if (self = [super init])
	{
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
-(NSMutableArray *)array
{
    return array;
}

-(void)setArray:(NSMutableArray *)a
{
    [a retain];
    [array release];
    array = a;
}

-(void)setBinaryPackages:(NSString *)s
{
    [s retain];
    [binaryPackages release];
    binaryPackages = s;
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
//	getBinaryList: is a helper method used to fill to determine
//  whether packages in the array are available in binary form.
//
//  A series of methods between update: and completeUpdate: parse the output
//  from the task to derive the package's full description, web url, maintainer name
//  and maintainer email address.

-(NSString *)getBinaryList
{
    NSTask *listCmd = [[NSTask alloc] init];
    //create pipe and file handle for reading from the task's standard output
    NSPipe *pipeIn  = [NSPipe pipe];
    NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];
    NSString *output;
    NSEnumerator *e;
    NSString *line;
    NSMutableArray *pkgLines = [NSMutableArray array];

    [listCmd setLaunchPath: 
		[[[NSUserDefaults standardUserDefaults] objectForKey: FinkBasePath]
		stringByAppendingPathComponent: @"/bin/apt-cache"]];
    [listCmd setArguments: [NSArray arrayWithObjects: @"dumpavail", nil]];
    [listCmd setStandardOutput: pipeIn];

    [listCmd launch];
    output = [NSString stringWithCString: [[cmdStdout readDataToEndOfFile] bytes]];
    e = [[output componentsSeparatedByString: @"\n"] reverseObjectEnumerator];

    while (line = [e nextObject]){
		if ([line contains:@"Package:"]){
			line = [line substringWithRange: NSMakeRange(9, [line length] - 9)];
			[pkgLines addObject: [NSString stringWithFormat: @" %@#", line]];
		}
    }
    [listCmd release];
    return [pkgLines componentsJoinedByString: @"\n"];
}

-(void)update
{
    NSTask *listCmd = [[[NSTask alloc] init] autorelease];
    NSPipe *pipeIn  = [NSPipe pipe];
    NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];

    NSArray *args;

#ifdef TESTING
	args = [NSArray arrayWithObjects: @"-c", @"/usr/bin/perl",
		[NSHomeDirectory() stringByAppendingPathComponent: 
			@"Library/Application Support/FinkCommander.pl"], nil];
    [listCmd setLaunchPath: @"/sw/bin/bash"];
#else
	args = [NSArray arrayWithObjects:
		[NSHomeDirectory() stringByAppendingPathComponent: 
			@"Library/Application Support/FinkCommander.pl"], nil];
	[listCmd setLaunchPath: @"/usr/bin/perl"];
#endif

    [listCmd setArguments: args];
    [listCmd setStandardOutput: pipeIn];

    [self setStart: [NSDate date]];

    //run task asynchronously; this can take anywhere from a few seconds to a minute
    [listCmd launch];
    //the notification this method refers to will trigger the completeUpdate: method
    [cmdStdout readToEndOfFileInBackgroundAndNotify];

    //in the meantime, run the task that obtains the binary package names, which takes only
    //a second or two, synchronously
    [self setBinaryPackages: [self getBinaryList]];

    if (DEBUGGING) {
		int slen, rlen;
		NSLog(@"User's shell: %s", getenv("SHELL"));
		NSLog(@"Default C string encoding: %d", [NSString defaultCStringEncoding]);
		NSLog(@"Completed binary list after %f seconds", 
		-[start timeIntervalSinceNow]);
		if (binaryPackages){
			slen = [binaryPackages length];
			rlen = slen > BUFFERLEN ? BUFFERLEN : slen;
			NSLog(@"Binary package string (up to 240 chars):\n%@", 
		 [binaryPackages substringWithRange:NSMakeRange(0, BUFFERLEN-1)]);
		}
    }
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

-(NSArray *)getDescriptionComponentsFromString:(NSString *)s
{
    NSString *line;
    NSString *web = @"";
    NSString *maint = @"";
    NSString *email = @"";
    NSArray *lines = [s componentsSeparatedByString: @"\n"];
    NSEnumerator *e = [lines objectEnumerator];

    line = [e nextObject]; //discard--name-version: short desc

    while (line = [e nextObject]){
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

    d = [info objectForKey: NSFileHandleNotificationDataItem];

	output = [[[NSString alloc] initWithData: d
								encoding: NSUTF8StringEncoding] autorelease];

    if (DEBUGGING) {
		NSLog(@"Read to end of file notification sent after %f seconds",
		-[start timeIntervalSinceNow]);
		NSLog(@"User info keys from notification:\n%@", [info allKeys]);
		if (d) {
			char buffer[BUFFERLEN];
			[d getBytes:buffer length:BUFFERLEN-1]; //BUFFERLEN should be OK, but just to be safe
			NSLog(@"Data in buffer from notification (up to 240 chars):\n%s", buffer);
		}else{
			NSLog(@"Notification data buffer was empty");
		}
		if (output) {
			int olen = [output length];
			int rlen = olen > 240 ? 240 : olen;
			NSLog(@"Output string from data buffer:\n%@", [output substringWithRange:NSMakeRange(0, rlen)]);
		}else{
			NSLog(@"Output string from data buffer was empty");
		}
    }	

    temp = [NSMutableArray arrayWithArray:
	       [output componentsSeparatedByString: @"\n----\n"]];

    if (DEBUGGING && temp) {NSLog(@"Length of array from output string = %d", [temp count]);}

    [temp removeObjectAtIndex: 0];  // "Reading package info . . . "
    e = [temp objectEnumerator];

    while (listRecord = [[e nextObject] componentsSeparatedByString: @"**\n"]){
		p = [[FinkPackage alloc] init];
		[p setName: [listRecord objectAtIndex: 0]];
		[p setVersion: [listRecord objectAtIndex: 1]];
		[p setInstalled: [listRecord objectAtIndex: 2]];
		[p setCategory: [listRecord objectAtIndex: 3]];
		[p setDescription: [listRecord objectAtIndex: 4]];
		if ([[listRecord objectAtIndex: 5] isEqualToString: @"stable"]){
			[p setUnstable: @" "];
		}else{
			[p setUnstable: @"*"];
		}
		[p setFulldesc: [listRecord objectAtIndex: 6]];
		components = [self getDescriptionComponentsFromString: [p fulldesc]];
		[p setWeburl: [components objectAtIndex: 0]];
		[p setMaintainer: [components objectAtIndex: 1]];
		[p setEmail: [components objectAtIndex: 2]];
		//make sure FULL name matches package on binary list
		if ([binaryPackages contains:
			[NSString stringWithFormat: @" %@#", [p name]]]){
			[p setBinary: @"*"];
		}else{
			[p setBinary: @" "];
		}
		[collector addObject: p];
		[p release];
    }
    [self setArray: collector];

    if (DEBUGGING){
		NSLog(@"Fink package array completed after %f seconds",
		-[start timeIntervalSinceNow]);
    }

    //notify FinkController that table needs to be updated
    [[NSNotificationCenter defaultCenter] postNotificationName: FinkPackageArrayIsFinished
											object: nil];
}

-(void)updateManuallyWithCommand:(NSString *)cmd packages:(NSArray *)pkgs
{
    FinkPackage *pkg;
    NSEnumerator *e = [pkgs objectEnumerator];

    if ([cmd isEqualToString: @"install"]){
		while (pkg = [e nextObject]){
			[pkg setInstalled: @"current"];
		}
    }else if ([cmd isEqualToString: @"remove"]){
		while (pkg = [e nextObject]){
			[pkg setInstalled: @"archived"];
		}
    }else if ([cmd isEqualToString: @"update-all"]){
		e = [[self array] objectEnumerator];
		while (pkg = [e nextObject]){
			if ([[pkg installed] isEqualToString: @"outdated"]){
				[pkg setInstalled: @"current"];
			}
		}
    }
}

-(int)installedPackagesCount
{
    int count = 0;
    NSEnumerator *e = [[self array] objectEnumerator];
    FinkPackage *pkg;

    while (pkg = [e nextObject]){
		if ([[pkg installed] contains: @"t"]){
			count++;
		}
    }
    return count;
}


@end

