/*
File: FinkInstallationInfo.m

 See the header file, FinkController.h, for interface and license information.

*/

#import "FinkInstallationInfo.h"

#define APRIL_TOOLS_VERSION @"2.2.1"
#define MAY_TOOLS_VERSION 	@"2.0.1"

NSString *DEVTOOLS_TEST_PATH = 
		@"/Developer/Applications/Interface Builder.app/Contents/version.plist";

@implementation FinkInstallationInfo

-(NSString *)finkVersion
{
	NSTask *versionTask = [[NSTask alloc] init];
	NSPipe *pipeFromStdout = [NSPipe pipe];
	NSFileHandle *taskStdout = [pipeFromStdout fileHandleForReading];
	NSString *result;
	
	[versionTask setLaunchPath: 
		[[[NSUserDefaults standardUserDefaults] objectForKey: FinkBasePath]
			stringByAppendingPathComponent: @"/bin/fink"]];
	[versionTask setArguments: [NSArray arrayWithObjects: @"--version", nil]];
	[versionTask setStandardOutput: pipeFromStdout];
	[versionTask launch];

	result = [[[NSString alloc] initWithData: [taskStdout readDataToEndOfFile]
								encoding: NSUTF8StringEncoding] autorelease];
	[versionTask release];
	[taskStdout closeFile];
	return result;
}

-(NSString *)macOSXVersion
{
	NSTask *versionTask = [[NSTask alloc] init];
	NSPipe *pipeFromStdout = [NSPipe pipe];
	NSFileHandle *taskStdout = [pipeFromStdout fileHandleForReading];
	NSString *output;
	NSString *line;
	NSString *result = @"Couldn't find Mac OS X Version";
	NSEnumerator *e;
	int loc;

	[versionTask setLaunchPath: @"/usr/bin/sw_vers"];
	[versionTask setStandardOutput: pipeFromStdout];
	[versionTask launch];

	output = [[[NSString alloc] initWithData: [taskStdout readDataToEndOfFile]
								encoding: NSUTF8StringEncoding] autorelease];
	[versionTask release];
	[taskStdout closeFile];
	
	e = [[output componentsSeparatedByString: @"\n"] objectEnumerator];
	while (line = [e nextObject]){
		if ((loc = [line rangeOfString: @"10."].location) != NSNotFound){
			result = [NSString stringWithFormat: @"Mac OS X Version: %@",
							[line substringWithRange: 
								NSMakeRange(loc, [line length] - loc)]];
			result = [result strip];
			break;
		}
	}
	return result;
}

-(NSString *)gccVersion
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSTask *versionTask = [[NSTask alloc] init];
	NSPipe *pipeFromStdout = [NSPipe pipe];
	NSFileHandle *taskStdout = [pipeFromStdout fileHandleForReading];
	NSString *result;

	if (! [manager fileExistsAtPath: @"/usr/bin/cc"]){
		result = @"Developer Tools not installed";
		return result;
	}

	[versionTask setLaunchPath: @"/usr/bin/cc"];
	[versionTask setArguments: [NSArray arrayWithObjects: @"--version", nil]];
	[versionTask setStandardOutput: pipeFromStdout];
	[versionTask launch];

	result = [[[NSString alloc] initWithData: [taskStdout readDataToEndOfFile]
								encoding: NSUTF8StringEncoding] autorelease];
	result = [result strip];
	result = [NSString stringWithFormat: @"gcc version: %@", result];
	[versionTask release];
	[taskStdout closeFile];
	return result;
}

-(NSString *)developerToolsInfo
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *result = @"Unable to determine Developer Tools version";
	NSString *develFormat = @"Developer Tools: %@";
	NSString *version = [[NSDictionary dictionaryWithContentsOfFile: DEVTOOLS_TEST_PATH]
							objectForKey:@"CFBundleShortVersionString"];
	
	if (! [manager fileExistsAtPath: DEVTOOLS_TEST_PATH]) return result;
	
	if ([version isEqualToString: APRIL_TOOLS_VERSION]){
		result = [NSString stringWithFormat: develFormat, @"April 2002"];
	}else if ([version compare: MAY_TOOLS_VERSION] == NSOrderedDescending){
		result = [NSString stringWithFormat: develFormat, @"December 2001"];
	}else{
		result = [NSString stringWithFormat: develFormat, @"Pre-December 2001"];
	}
	return result;
}

-(NSString *)makeVersion
{
	NSTask *whichTask = [[NSTask alloc] init];
	NSTask *versionTask = [[NSTask alloc] init];
	NSPipe *whichPipe = [NSPipe pipe];
	NSPipe *versionPipe = [NSPipe pipe];
	NSFileHandle *whichStdout = [whichPipe fileHandleForReading];
	NSFileHandle *versionStdout = [versionPipe fileHandleForReading];
	NSString *pathToMake;
	NSString *versionString;
	NSString *versionNumber;
	NSScanner *versionScanner;
	NSCharacterSet *versionChars = [NSCharacterSet characterSetWithCharactersInString:
													@"0123456789."];
	NSArray *pathComponents;

	//use which to find the path to make
	[whichTask setLaunchPath: @"/usr/bin/which"];
	[whichTask setArguments: [NSArray arrayWithObjects: @"make", nil]];
	[whichTask setStandardOutput: whichPipe];
	[whichTask launch];
	pathToMake = [[[NSString alloc] initWithData: [whichStdout readDataToEndOfFile]
									encoding: NSUTF8StringEncoding] autorelease];
	[whichTask release];
	[whichStdout closeFile];
	
	if ([pathToMake contains: @"not found"] || [pathToMake contains:@"no make"]){
		return @"Unable to locate \"make.\"";
	}
	//make sure we're looking at the last line of the result
	pathComponents = [pathToMake componentsSeparatedByString:@"\n"];
	pathToMake = [pathComponents count] > 1 ? 
					[pathComponents objectAtIndex: [pathComponents count] - 2] :
					[pathComponents objectAtIndex:0];
	if (DEBUGGING) { NSLog(@"Path to make: %@", pathToMake); }
	//get the result of make -v
	[versionTask setLaunchPath: [pathToMake strip]];
	[versionTask setArguments: [NSArray arrayWithObjects: @"-v", nil]];
	[versionTask setStandardOutput: versionPipe];
	[versionTask launch];
	versionString = [[[NSString alloc] initWithData: [versionStdout readDataToEndOfFile]
										encoding: NSUTF8StringEncoding] autorelease];
	[versionTask release];
	[versionStdout closeFile];
	//parse the result for the version number
	versionScanner = [NSScanner scannerWithString:versionString];
	[versionScanner scanUpToString:@"version " intoString:NULL];
	[versionScanner scanString:@"version " intoString:NULL];
	if (! [versionScanner scanCharactersFromSet:versionChars intoString:&versionNumber]){
		return @"Unable to determine \"make\" version.";
	}
	
	return [NSString stringWithFormat: @"make version: %@", versionNumber];
}

-(NSString *)getInstallationInfo
{
	NSString *finkVersion = [self finkVersion];
	NSString *macOSXVersion = [self macOSXVersion];
	NSString *gccVersion = [self gccVersion];
	NSString *devTools;
	NSString *makeVersion;
	NSString *result;

	if ([gccVersion contains: @"not installed"]){
		result = [NSString stringWithFormat: @"%@%@\n%@\n", 
					finkVersion, macOSXVersion, gccVersion];
	}else{
		devTools = [self developerToolsInfo];
		makeVersion = [self makeVersion];
		result = [NSString stringWithFormat: @"%@%@\n%@\n%@\n%@\n", 
					finkVersion, macOSXVersion, devTools, gccVersion, makeVersion];
	}
	return result;
}

@end
