/*  
 File: FinkDataController.m

See the header file, FinkDataController.h, for interface and license information.

*/

#import "FinkDataController.h"

@implementation FinkDataController

//---------------------------------------------------------->The Ususal

-(id)init
{
	if (self = [super init])
	{
		//should contain user's fink path; possibly by means of 
		//a configuration script on installation
		finkArray = [[NSMutableArray alloc] initWithCapacity: 1300];
	}

	[[NSNotificationCenter defaultCenter] addObserver: self
				selector: @selector(completeUpdate:)
				name: NSFileHandleReadToEndOfFileCompletionNotification
				object: nil];
	return self;
}

-(void)dealloc
{
	[finkArray release];
	[binaryPackages release];
	[start release];
	[super dealloc];
}

// Accessors
-(NSMutableArray *)array
{
	return finkArray;
}

-(void)setBinaryPackages:(NSString *)s
{
	[s retain];
	[binaryPackages release];
	binaryPackages = s;
}

//---------------------------------------------------------->Fink Tools
//
//  Tools for getting and storing information about fink packages in the array.
//
//  update: is the "public" method.  It runs a custom perl script 
//  in an NSTask to obtain a list of all package names and their installation 
//  states and stores the information in FinkPackage instances in finkArray.
//
//	getBinaryList: is a helper method used to fill to determine
//  whether packages in the array are available in binary form.


// Run  apt-cache to get list of packages available for binary install
-(NSString *)getBinaryList
{
	NSTask *listCmd = [[NSTask alloc] init];
	//create pipe and file handle for reading from the task's standard output
	NSPipe *pipeIn  = [NSPipe pipe];
	NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];
	NSString *output;
	NSArray *args = [NSArray arrayWithObjects: @"pkgnames", nil];
	NSArray *lines;
	NSEnumerator *e;
	NSString *line;
	NSMutableArray *pkgLines = [NSMutableArray arrayWithCapacity: 600];

	[listCmd setLaunchPath: [[[NSUserDefaults standardUserDefaults] objectForKey: FinkBasePath]
		stringByAppendingPathComponent: @"/bin/apt-cache"]];
	[listCmd setArguments: args];
	[listCmd setStandardOutput: pipeIn];
	
	[listCmd launch];
	output = [NSString stringWithCString: [[cmdStdout readDataToEndOfFile] bytes]];
	lines = [output componentsSeparatedByString: @"\n"];
	e = [lines reverseObjectEnumerator];
	
	while (line = [e nextObject]){
		[pkgLines addObject: [NSString stringWithFormat: @" %@#", line]];
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
	
	start = [[NSDate date] retain];
	[listCmd launch];

	//run task asynchronously; notification will trigger completeUpdate: method
	[cmdStdout readToEndOfFileInBackgroundAndNotify];
	
	binaryPackages = [[self getBinaryList] retain]; //instance variable released by 
													//completeUpdate
#ifdef DEBUG
	NSLog(@"Completed binary list after %f seconds",
	   -[start timeIntervalSinceNow]);
#endif //DEBUG
}


-(void)completeUpdate:(NSNotification *)n
{
	NSData *d;
	NSString *output; 
	NSMutableArray *temp;
	NSArray *listRecord;
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
	[finkArray removeAllObjects];
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
		//make sure FULL name matches package on binary list
		if ([binaryPackages contains:
			[NSString stringWithFormat: @" %@#", [p name]]]){
			[p setBinary: @"*"];
		}else{
			[p setBinary: @" "];
		}
		[finkArray addObject: p];
		[p release];
	}

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
	NSEnumerator *e = [finkArray objectEnumerator];
	FinkPackage *pkg;

	while (pkg = [e nextObject]){
		if ([[pkg installed] contains: @"t"]){
			count++;
		}
	}
	return count;
}


@end
