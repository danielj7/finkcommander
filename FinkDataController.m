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

@implementation FinkDataController

//---------------------------------------------------------->The Ususal

-(id)init
{
	if (self = [super init])
	{
		//should contain user's fink path; possibly by means of 
		//a configuration script on installation

	[[NSNotificationCenter defaultCenter] addObserver: self
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

	[listCmd setLaunchPath: [[[NSUserDefaults standardUserDefaults] objectForKey: FinkBasePath]
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
	NSArray *args = [NSArray arrayWithObjects:
		[[NSBundle mainBundle] pathForResource: @"fpkg_list" ofType: @"pl"], nil];

	[listCmd setLaunchPath: @"/usr/bin/perl"];
	[listCmd setArguments: args];
	[listCmd setStandardOutput: pipeIn];
	
	[self setStart: [NSDate date]];
	[listCmd launch];

	//run task asynchronously; notification will trigger completeUpdate: method
	[cmdStdout readToEndOfFileInBackgroundAndNotify];
	
	[self setBinaryPackages: [self getBinaryList]];
	
	 NSLog(@"Binary list:\n%@", binaryPackages); 
	
#ifdef DEBUG
	NSLog(@"Completed binary list after %f seconds",
	   -[start timeIntervalSinceNow]);
#endif //DEBUG
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
	name = [s substringWithRange: NSMakeRange(NAMESTART, emailstart - NAMESTART - 1)];
	address = [s substringWithRange:
			NSMakeRange(emailstart + 1, emailend - emailstart - 1)];
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
	NSData *d;
	NSString *output; 
	NSMutableArray *temp;
	NSMutableArray *collector = [NSMutableArray array];
	NSArray *listRecord;
	NSArray *components;
	NSEnumerator *e;
	FinkPackage *p;

#ifdef DEBUG	
	NSLog(@"Read to end of file notification sent after %f seconds",
	       -[start timeIntervalSinceNow]);
#endif

	d = [[n userInfo] objectForKey: NSFileHandleNotificationDataItem];
	output = [[[NSString alloc] initWithData: d
								encoding: NSUTF8StringEncoding] autorelease];
	temp = [NSMutableArray arrayWithArray:
		    [output componentsSeparatedByString: @"\n----\n"]];
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

#ifdef DEBUG
	NSLog(@"Fink package array completed after %f seconds",
		-[start timeIntervalSinceNow]);
#endif //DEBUG

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
			[pkg setInstalled: @" "];
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
