/*  
 File: FinkDataController.m

See the header file, FinkDataController.h, for interface and license information.

*/

#import "FinkDataController.h"

@implementation FinkDataController

//---------------------------------------------------------->The Ususal

-(id)init
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (self = [super init])
	{
		//should contain user's fink path; possibly by means of 
		//a configuration script on installation
		finkArray = [[NSMutableArray alloc] initWithCapacity: 1000];
		basePath = [[defaults objectForKey: FinkBasePath] retain];
	}

	[[NSNotificationCenter defaultCenter] addObserver: self
									   selector: @selector(completeUpdate:)
									   name: NSFileHandleReadToEndOfFileCompletionNotification
									   object: nil];
	return self;
}

-(void)dealloc
{
	[basePath release];
//	[stablePath release];
	[finkArray release];
	[binaryPackages release];
	[stablePackages release];
	[start release];
	[super dealloc];
}

// Accessors
-(NSMutableArray *)array
{
	return finkArray;
}

-(NSString *)basePath
{
	return basePath;
}


//---------------------------------------------------------->Fink Tools
//
//  Tools for getting and storing information about fink packages in the array.
//
//  update: is the "public" method.  It runs a custom perl script 
//  in an NSTask to obtain a list of all package names and their installation 
//  states and stores the information in FinkPackage instances in finkArray.
//
//	getBinaryList: and getStableList: are helper methods used to fill to determine
//  whether packages in the array are available in binary form or are unstable.


// Run  apt-cache to get list of packages available for binary install
-(NSString *)getBinaryList
{
	NSTask *listCmd = [[NSTask alloc] init];
	//create pipe and file handle for reading from the task's standard output
	NSPipe *pipeIn  = [NSPipe pipe];
	NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];
	NSString *output;
	NSArray *args = [NSArray arrayWithObjects: @"dump", nil];
	NSArray *lines;
	NSEnumerator *e;
	NSString *line;
	NSMutableArray *pkgLines = [NSMutableArray arrayWithCapacity: 300];

	[listCmd setLaunchPath: [basePath stringByAppendingPathComponent: @"/bin/apt-cache"]];
	[listCmd setArguments: args];
	[listCmd setStandardOutput: pipeIn];
	
	[listCmd launch];
	output = [NSString stringWithCString: [[cmdStdout readDataToEndOfFile] bytes]];
	lines = [output componentsSeparatedByString: @"\n"];
	e = [lines reverseObjectEnumerator];
	
	while (line = [e nextObject]){
		if ([line rangeOfString: @"Package:"].length > 0){
			//add marker to facilitate matching full package names
			[pkgLines addObject: [line stringByAppendingString: @"#"]];
 		}
 	}
 	[listCmd release];
	return [pkgLines componentsJoinedByString: @"\n"];
}


-(NSString *)getStableList
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSMutableString *infoFiles = [NSMutableString stringWithString: @" "];
	NSString *stableRoot = [basePath stringByAppendingPathComponent: @"fink/dists/stable"];
	NSDirectoryEnumerator *direnum = [manager enumeratorAtPath: stableRoot];
	NSString *fname;
	NSString *pname;
	NSString *dirContents;
	BOOL isdir;

	while (fname = [direnum nextObject]){
		pname = [stableRoot stringByAppendingPathComponent: fname];
		if ([manager fileExistsAtPath: pname isDirectory: &isdir] && isdir){
			dirContents = [[manager directoryContentsAtPath: pname] 
			    componentsJoinedByString: @" "];
			if ([dirContents rangeOfString: @".info"].length > 0){
				[infoFiles appendString: dirContents];
			}
		}
	}
	return infoFiles;
}


-(void)update
{
	NSTask *listCmd = [[[NSTask alloc] init] autorelease];
	NSPipe *pipeIn  = [NSPipe pipe];
	NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];
	NSArray *args = [NSArray arrayWithObjects:
		[[NSBundle mainBundle] pathForResource: @"fpkg_list" ofType: @"pl"],
		[NSString stringWithFormat: @"-path=%@", [self basePath]], nil];

	[listCmd setLaunchPath: @"/usr/bin/perl"];
	[listCmd setArguments: args];
	[listCmd setStandardOutput: pipeIn];
	
	start = [[NSDate date] retain];
	[listCmd launch];

	//run task asynchronously; notification will trigger completeUpdate: method
	[cmdStdout readToEndOfFileInBackgroundAndNotify];
	
	binaryPackages = [[self getBinaryList] retain];
	stablePackages = [[self getStableList] retain];
#ifdef DEBUG
	NSLog(@"Completed binary and stable lists after %f seconds",
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

	while (listRecord = [[e nextObject] componentsSeparatedByString: @"\n"]){
		p = [[FinkPackage alloc] init];
		[p setName: [listRecord objectAtIndex: 0]];
		[p setVersion: [listRecord objectAtIndex: 1]];
		[p setInstalled: [listRecord objectAtIndex: 2]];
		[p setCategory: [listRecord objectAtIndex: 3]];
		[p setDescription: [listRecord objectAtIndex: 4]];
		[finkArray addObject: p];
		//make sure FULL name matches package on binary list
		if ([binaryPackages rangeOfString:
			[NSString stringWithFormat: @" %@#", [p name]]].length > 0){
			[p setBinary: @"*"];
		}else{
			[p setBinary: @" "];
		}
		if ([stablePackages rangeOfString: [NSString stringWithFormat:
			@"%@-%@.info", [p name], [p version]]].length > 0 ||
			[[p category] isEqualToString:@"unknown"]){
			[p setUnstable: @" "];
		}else{
			[p setUnstable: @"*"];
		}
		[p release];
	}
#ifdef DEBUG
	NSLog(@"Fink package array completed after %f seconds",
		-[start timeIntervalSinceNow]);
#endif //DEBUG
	//notify FinkController that table needs to be updated
	[[NSNotificationCenter defaultCenter] postNotificationName: @"packageArrayIsFinished"
		object: nil];
	
}

@end
