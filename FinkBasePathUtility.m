/*
File: FinkBasePathUtility.m

 See the header file, FinkBasePathUtility.h, for interface and license information.
*/

#import "FinkBasePathUtility.h"

@implementation FinkBasePathUtility

-(void)findFinkBasePath
{
	NSEnumerator *e;
	NSString *path;
    NSString *homeDir = NSHomeDirectory();
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
    
	//look in some possible install paths
	e = [[NSArray arrayWithObjects: @"/sw", @"/usr/local", @"/fink", homeDir,
		[homeDir stringByAppendingPathComponent: @"sw"],
        [homeDir stringByAppendingPathComponent: @"fink"],
        @"/usr/local/sw", @"/usr/local/fink",
        @"/usr/sw", @"/usr/fink", nil] objectEnumerator];

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
        if (range.length > 0){
            path = [whichPath substringWithRange: NSMakeRange(0, range.location)];
            if([manager isReadableFileAtPath:
                [path stringByAppendingPathComponent: @"/etc/fink.conf"]]){
                [defaults setObject: path forKey: FinkBasePath];
                [defaults setBool: YES forKey: FinkBasePathFound];
            }
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
	[scriptFile closeFile];
}

@end
