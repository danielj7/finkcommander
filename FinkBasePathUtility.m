//
//  FinkBasePathUtility.m
//  FinkCommander
//
//  Created by Steven Burr on Wed Mar 20 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "FinkBasePathUtility.h"

@implementation FinkBasePathUtility

-(id)init
{
	self = [super init];
	return self;
}

-(void)dealloc
{
	[super dealloc];
}

-(void)findFinkBasePath
{
	NSEnumerator *e;
	NSString *path;
	NSFileManager *manager = [NSFileManager defaultManager];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL pathFound = NO;

	//variables used by NSTask
	NSTask *findTask;
	NSPipe *pipeIn;
	NSFileHandle *cmdStdout;
	NSArray *args;
	NSRange range;
	NSString *whichPath;

	e = [[NSArray arrayWithObjects: @"/sw", @"/usr/local", @"/usr/X11R6",
		@"/usr", nil] objectEnumerator];

	//look in some possible install paths
	while (path = [e nextObject]){
		if ([manager isReadableFileAtPath:
			[path stringByAppendingPathComponent: @"/etc/fink.conf"]]){
			[defaults setObject: path forKey: FinkBasePath];
			[defaults setBool: YES forKey: FinkBasePathFound];
			pathFound = YES;
			
#ifdef DEBUG
			NSLog(@"Found basepath %@ using array", path);
#endif //DEBUG

			break;
		}
	}

	//if that doesn't work, try the which command
	if (!pathFound){
		findTask = [[[NSTask alloc] init] autorelease];
		pipeIn  = [NSPipe pipe];
		cmdStdout = [pipeIn fileHandleForReading];
		args = [NSArray arrayWithObjects: @"fink", @"|", @"tail", @"-n1",
			nil];

		[findTask setLaunchPath: @"/usr/bin/which"];
		[findTask setArguments: args];
		[findTask setStandardOutput: pipeIn];
		[findTask launch];
		whichPath = [[[NSString alloc] initWithData: [cmdStdout readDataToEndOfFile]
															 encoding: NSUTF8StringEncoding] autorelease];
		//get the stuff before /bin/fink
		range = [whichPath rangeOfString: @"/bin/fink"];
		path = [whichPath substringWithRange: NSMakeRange(0, range.location)];
		if([manager isReadableFileAtPath:
			[path stringByAppendingPathComponent: @"/etc/fink.conf"]]){
			[defaults setObject: path forKey: FinkBasePath];
			[defaults setBool: YES forKey: FinkBasePathFound];
			
#ifdef DEBUG			
			NSLog(@"Found basepath %@ using call to which command", path);
#endif //DEBUG
			
		}
	}
}

-(void)fixScript
{
	NSString *pathToScript = [[NSBundle mainBundle] pathForResource:
							 @"fpkg_list" ofType: @"pl"];
	NSMutableString *scriptText = [NSMutableString stringWithContentsOfFile: pathToScript];
	NSString *basePath = [[NSUserDefaults standardUserDefaults]
	                     objectForKey: FinkBasePath];
	NSFileHandle *scriptFile = [NSFileHandle fileHandleForWritingAtPath: pathToScript];
	NSRange rangeOfBASEPATH;

	while((rangeOfBASEPATH = [scriptText rangeOfString: @"BASEPATH"]).length > 0){
		[scriptText replaceCharactersInRange: rangeOfBASEPATH withString: basePath];
	}
	
	[scriptFile truncateFileAtOffset: 0];
	[scriptFile writeData: [scriptText dataUsingEncoding: NSUTF8StringEncoding]];
	[scriptFile closeFile];  // probably not necessary
}

@end
