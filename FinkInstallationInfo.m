/*
File: FinkInstallationInfo.m

 See the header file, FinkController.h, for interface and license information.

*/

#import "FinkInstallationInfo.h"

#define MAY_TOOLS_VERSION 	@"2.0.1"

NSString *DEVTOOLS_TEST_PATH1 = 
	@"/Developer/Applications/Project Builder.app/Contents/Resources/English.lproj/DevCDVersion.plist";

NSString *DEVTOOLS_TEST_PATH2 = 
		@"/Developer/Applications/Interface Builder.app/Contents/version.plist";

@implementation FinkInstallationInfo

-(NSString *)finkVersion
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSTask *versionTask = [[NSTask alloc] init];
	NSPipe *pipeFromStdout = [NSPipe pipe];
	NSFileHandle *taskStdout = [pipeFromStdout fileHandleForReading];
	NSString *pathToFink = [[[NSUserDefaults standardUserDefaults] objectForKey: FinkBasePath]
			stringByAppendingPathComponent: @"/bin/fink"];
	NSString *result = @"Unable to determine fink version";
	if (! [manager fileExistsAtPath:pathToFink]){
		return result;
	}
	[versionTask setLaunchPath: pathToFink];
	[versionTask setArguments: [NSArray arrayWithObjects: @"--version", nil]];
	[versionTask setStandardOutput: pipeFromStdout];
	[versionTask launch];
	result = [[[NSString alloc] initWithData:[taskStdout readDataToEndOfFile]
								encoding:NSMacOSRomanStringEncoding] autorelease];
	[versionTask release];
	[taskStdout closeFile];
	return result;
}

-(NSString *)macOSXVersion
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSTask *versionTask = [[NSTask alloc] init];
	NSPipe *pipeFromStdout = [NSPipe pipe];
	NSFileHandle *taskStdout = [pipeFromStdout fileHandleForReading];
	NSString *output;
	NSString *line;
	NSString *result = @"Could not find Mac OS X Version";
	NSEnumerator *e;
	int loc;
	
	if (! [manager fileExistsAtPath:@"/usr/bin/sw_vers"]){
		return result;
	}
	[versionTask setLaunchPath: @"/usr/bin/sw_vers"];
	[versionTask setStandardOutput: pipeFromStdout];
	[versionTask launch];

	output = [[[NSString alloc] initWithData: [taskStdout readDataToEndOfFile]
								encoding: NSMacOSRomanStringEncoding] autorelease];
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
	NSScanner *versionScanner;
	NSCharacterSet *versionChars = [NSCharacterSet characterSetWithCharactersInString:
		@"0123456789."];
	

	if (! [manager fileExistsAtPath: @"/usr/bin/cc"]){
		return @"Developer Tools not installed";
	}
	[versionTask setLaunchPath: @"/usr/bin/cc"];
	[versionTask setArguments: [NSArray arrayWithObjects: @"--version", nil]];
	[versionTask setStandardOutput: pipeFromStdout];
	[versionTask launch];

	result = [[[NSString alloc] initWithData: [taskStdout readDataToEndOfFile]
								encoding: NSMacOSRomanStringEncoding] autorelease];
	[versionTask release];
	[taskStdout closeFile];

	versionScanner = [NSScanner scannerWithString:result];
	if (! [versionScanner scanUpToCharactersFromSet:versionChars intoString:NULL]){
		return @"Unable to determine gcc version";
	}
	[versionScanner scanCharactersFromSet:versionChars intoString:&result];
	result = [NSString stringWithFormat: @"gcc version: %@", result];
	return result;
}

-(NSString *)developerToolsInfo
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *error = @"Unable to determine Developer Tools version";
	NSString *version;
	
	if ([manager fileExistsAtPath: DEVTOOLS_TEST_PATH1]){
		Dprintf(@"Found file at %@", DEVTOOLS_TEST_PATH1);
		version = [[NSDictionary dictionaryWithContentsOfFile: DEVTOOLS_TEST_PATH1]
							objectForKey:@"DevCDVersion"];
		if (! version  || [version length] < 3) return error;
		return version;
	}
	if ([manager fileExistsAtPath: DEVTOOLS_TEST_PATH2]){
		Dprintf(@"Found file at %@", DEVTOOLS_TEST_PATH2);
		version = [[NSDictionary dictionaryWithContentsOfFile: DEVTOOLS_TEST_PATH2]
							objectForKey:@"CFBundleShortVersionString"];
		if (! version  || [version length] < 3) return error;  //should at least be x.x
		if ([version compare:MAY_TOOLS_VERSION] == NSOrderedDescending){  // > May 2001
			return @"December 2001 Developer Tools";
		}
		return @"Pre-December 2001 Developer Tools";
	}
	Dprintf(@"Failed to find file specifying Developer Tools version");
	return error;
}

-(NSString *)makeVersion
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSTask *whichTask = [[NSTask alloc] init];
	NSTask *versionTask = [[NSTask alloc] init];
	NSPipe *whichPipe = [NSPipe pipe];
	NSPipe *versionPipe = [NSPipe pipe];
	NSFileHandle *whichStdout = [whichPipe fileHandleForReading];
	NSFileHandle *versionStdout = [versionPipe fileHandleForReading];
	NSString *pathToMake;
	NSString *versionString;
	NSString *versionNumber;
	NSString *error = @"Unable to locate \"make\"";
	NSScanner *versionScanner;
	NSCharacterSet *versionChars = [NSCharacterSet characterSetWithCharactersInString:
													@"0123456789."];
	NSArray *pathComponents;

	if (! [manager fileExistsAtPath:@"/usr/bin/which"]){
		return error;
	}
	
	//use which to find the path to make
	[whichTask setCurrentDirectoryPath:@"/" ];
	[whichTask setLaunchPath: @"/usr/bin/which"];
	[whichTask setArguments: [NSArray arrayWithObjects: @"make", nil]];
	[whichTask setStandardOutput: whichPipe];
	[whichTask launch];
	pathToMake = [[[NSString alloc] initWithData:[whichStdout readDataToEndOfFile]
									encoding:NSMacOSRomanStringEncoding] autorelease];
	[whichTask release];
	[whichStdout closeFile];
	
	if ([pathToMake contains: @"not found"] || [pathToMake contains:@"no make"]){
		return error;
	}
	//if the wdPath is at the start, remove it - some unicode char is first
	if ([[pathToMake substringFromIndex:1] hasPrefix:[NSString stringWithFormat:@"]2;/"]]){
		pathComponents = [pathToMake componentsSeparatedByString: @"]2;/"];
		//there is another unicode character after the wdPath, so just move the index fwd one more
		pathToMake = [[pathComponents objectAtIndex:1] substringFromIndex:1];
	}
	//make sure we're looking at the last line of the result
	pathComponents = [pathToMake componentsSeparatedByString:@"\n"];
	pathToMake = [pathComponents count] > 1 								? 
				 [pathComponents objectAtIndex: [pathComponents count] - 2] :
				 [pathComponents objectAtIndex:0];
	pathToMake = [pathToMake strip];
	if (! [manager fileExistsAtPath:pathToMake]){
		return error;
	}
	//get the result of make -v
	[versionTask setLaunchPath: [pathToMake strip]];
	[versionTask setArguments: [NSArray arrayWithObjects: @"-v", nil]];
	[versionTask setStandardOutput: versionPipe];
	[versionTask launch];
	versionString = [[[NSString alloc] initWithData: [versionStdout readDataToEndOfFile]
										encoding: NSMacOSRomanStringEncoding] autorelease];
	[versionTask release];
	[versionStdout closeFile];
	//parse the result for the version number
	versionScanner = [NSScanner scannerWithString:versionString];
	[versionScanner scanUpToCharactersFromSet:versionChars intoString:NULL];
	if (! [versionScanner scanCharactersFromSet:versionChars intoString:&versionNumber]){
		return error;
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
