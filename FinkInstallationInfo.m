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

-(NSString *)getFinkVersion
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
	return result;
}

-(NSString *)getMacOSXVersion
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

-(NSString *)getGCCVersion
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
	return result;
}

-(NSString *)getDeveloperToolsInfo
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

-(NSString *)getInstallationInfo
{
	NSString *finkVersion = [self getFinkVersion];
	NSString *macOSXVersion = [self getMacOSXVersion];
	NSString *gccVersion = [self getGCCVersion];
	NSString *devTools;
	NSString *result;

	if ([gccVersion contains: @"Developer"]){
		result = [NSString stringWithFormat: @"%@%@\n%@\n", 
			finkVersion, macOSXVersion, gccVersion];
	}else{
		devTools = [self getDeveloperToolsInfo];
		result = [NSString stringWithFormat: @"%@%@\n%@\n%@\n", 
			finkVersion, macOSXVersion, devTools, gccVersion];
	}
	return result;
}

@end
