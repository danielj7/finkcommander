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
		basePath = [[NSString alloc] initWithString: @"/sw"];
		finkArray = [[NSMutableArray alloc] initWithCapacity: 1000];
	}
	return self;
}

-(void)dealloc
{
	[basePath release];
	[stablePath release];
	[finkArray release];
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
//  update is the "public" method.  It calls getFinkList, which uses a custom
//  perl script to obtain a list of all package names and their installation states
//  and stores the information in FinkPackage instances in finkArray.


// Run custom perl script to get list of packages with all information needed for
// FinkPackage object, except whether package is available in binary form.
-(NSString *)getSourceList
{
	NSTask *listCmd = [[NSTask alloc] init];
	NSPipe *pipeIn  = [NSPipe pipe];
	NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];
	NSString *output;
	NSArray *args = [NSArray arrayWithObjects:
		[[NSBundle mainBundle] pathForResource: @"fpkg_list" ofType: @"pl"],
		nil];

	[listCmd setLaunchPath: @"/usr/bin/perl"];
	[listCmd setArguments: args];
	[listCmd setStandardOutput: pipeIn];

	[listCmd launch];
	output = [NSString stringWithCString: [[cmdStdout readDataToEndOfFile] bytes]];
	[listCmd release];
    return output;
}

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
	NSDirectoryEnumerator *direnum = [[NSFileManager defaultManager]
        enumeratorAtPath: stableRoot];
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


// Update finkArray to reflect latest package information.
-(void)update
{
	NSMutableArray *temp = [NSMutableArray arrayWithArray:
		[[self getSourceList] componentsSeparatedByString: @"\n----\n"]];
	NSArray *listRecord;
	NSString *pkgList;
	NSEnumerator *e;
	FinkPackage *p;
	NSString *binList = [[self getBinaryList] retain];
	NSString *stableList = [[self getStableList] retain];
	
//	NSLog(@"%@", stableList);
	
	//remove existing data
	[finkArray removeAllObjects];

	//run command to get fink package list; put each line into temp array
	pkgList = [[self getSourceList] retain];
	[temp removeObjectAtIndex: 0];  // "Reading package info . . . etc.

	//parse array elements and store in FinkPackage instances
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
		if ([binList rangeOfString:
			[NSString stringWithFormat: @" %@#", [p name]]].length > 0){
			[p setBinary: @"*"];
		}else{
			[p setBinary: @" "];
		}
		if ([stableList rangeOfString: [NSString stringWithFormat:
			@"%@-%@.info", [p name], [p version]]].length > 0 || 
			[[p category] isEqualToString:@"unknown"]){
			[p setUnstable: @" "];
		}else{
			[p setUnstable: @"*"];
		}
		[p release];
	}

	[binList release];
	[stableList release];
	[pkgList release];
}

@end
