/*
File: FinkInstallationInfo.m

 See the header file, FinkController.h, for interface and license information.

*/

#import "FinkInstallationInfo.h"

//Constants
#define MAY_TOOLS_VERSION  @"2.0.1"
#define DEVTOOLS_TEST_PATH @"/Applications/Xcode.app/Contents/version.plist"
#define DEVTOOLS_TEST_PATH0 @"/Developer/Applications/Xcode.app/Contents/version.plist"
#define DEVTOOLS_TEST_PATH1 @"/Developer/Applications/Project Builder.app/Contents/Resources/English.lproj/DevCDVersion.plist"
#define DEVTOOLS_TEST_PATH2 @"/Developer/Applications/Interface Builder.app/Contents/version.plist"

@implementation FinkInstallationInfo

//------------------------------>init

+(FinkInstallationInfo *)sharedInfo
{
	static FinkInstallationInfo *myInfo = nil;
	
	if (nil == myInfo){
		myInfo = [[FinkInstallationInfo alloc] init];
	}
	return myInfo;
}

-(instancetype)init
{
	if ((self = [super init])){
		manager = [NSFileManager defaultManager];  //shared instance, no need to retain
	}
	return self;
}

//------------------------------>Helpers for Specific Version Methods

//Scan version output for the version number and extra version information
-(NSArray *)versionInformationFromString:(NSString *)s
{
	NSScanner *versionScanner;
	NSCharacterSet *versionChars = [NSCharacterSet characterSetWithCharactersInString:
		@"0123456789."];
	NSCharacterSet *endOfLine = [NSCharacterSet characterSetWithCharactersInString:
		@"\n\r"];
	NSString *version;
	NSString *extraInformation;
	NSString *start = @"(GCC) ";

	if (! s) return nil;
	versionScanner = [NSScanner scannerWithString:s];
	[versionScanner scanUpToString:start intoString:nil];
	if (! [versionScanner scanString:start intoString:nil]){
		[versionScanner setScanLocation:0];
		[versionScanner scanUpToCharactersFromSet:versionChars intoString:nil];
	}
	if (! [versionScanner scanCharactersFromSet:versionChars intoString:&version]){
		return nil;
	}
	[versionScanner scanUpToCharactersFromSet:endOfLine intoString:&extraInformation];
	return @[version, extraInformation];
}

//Run CLI tool to get its version information
-(NSString *)versionOutputForExecutable:(NSString *)path usingArguments:(NSArray *)args
{
	NSTask *versionTask = [[NSTask alloc] init];
	NSPipe *pipeFromStdout = [NSPipe pipe];
	NSFileHandle *taskStdout = [pipeFromStdout fileHandleForReading];
	NSString *result;

	if (! [manager fileExistsAtPath:path]){
		return nil;
	}
	
	[versionTask setLaunchPath: path];
	if (args) {
		[versionTask setArguments: args];
	}
	[versionTask setStandardOutput: pipeFromStdout];
	[versionTask setEnvironment:[[NSUserDefaults standardUserDefaults]
		objectForKey:FinkEnvironmentSettings]];
	[versionTask launch];

    @try {
		result = [[NSString alloc] initWithData:[taskStdout readDataToEndOfFile]
									encoding:NSUTF8StringEncoding];
    }
    @catch (NSException __unused *localException) {
		//Handle NSFileHandleOperationException
	//		NSLog(@"Failed to read data stream from %@ %@", path, args);
		NSLog(@"Failed to read data stream from %@", path);
		return nil;
    }

	[taskStdout closeFile];
	return result;
}

-(NSString *)versionOutputForExecutable:(NSString *)path
						  usingArgument:(NSString *) arg
{
	return [self versionOutputForExecutable:path usingArguments:[NSArray arrayWithObjects:arg, nil]];
}

-(NSString *)versionOutputForExecutable:(NSString *)path
{
	return [self versionOutputForExecutable:path usingArgument:@"--version"];
}

//------------------------------>Specific Version Methods

-(NSString *)finkVersion
{
	NSString *pathToFink = [[[NSUserDefaults standardUserDefaults] objectForKey: FinkBasePath]
			stringByAppendingPathComponent: @"/bin/fink"];
	NSString *version = [self versionOutputForExecutable:pathToFink];
	NSArray *version_lines;
	
	if (! version) return @"Unable to determine fink version\n";
	
	version_lines = [version componentsSeparatedByString:@"\n"];
	if ([version_lines count] >= 2 &&
		[version_lines[0] containsCI:@"version"] &&
		[version_lines[1] containsCI:@"version"]){
		version = [NSString stringWithFormat:@"%@\n%@\n", 
					version_lines[0], 
					version_lines[1]];
	}else{
		version = @"Unable to determine fink version; the format changed again!\n"; 
	}
	return version;
}

-(NSString *)macOSXVersion
{
	NSString *sysVerPlistPath = @"/System/Library/CoreServices/SystemVersion.plist";
	NSDictionary *sysVerPlistDict;
	NSString *sysVerString;
	
	/*
	 *	Try to get the version number from SystemVersion.plist file
	 */
	sysVerPlistDict = [NSDictionary dictionaryWithContentsOfFile:sysVerPlistPath];
	/* 	dictionaryWithContentsOfFile returns nil for file error or if file is not validly
		formatted plist */
	if (nil != sysVerPlistDict){
		sysVerString = sysVerPlistDict[@"ProductVersion"];
		if (nil != sysVerString){
			return [NSString stringWithFormat: @"Mac OS X version: %@", sysVerString];
		}
	}
	
	/* 
	 * If that doesn't work, try sw_vers
	 */
	sysVerString = [self versionOutputForExecutable:@"/usr/bin/sw_vers"
								usingArgument:nil];
	if (nil != sysVerString){
		sysVerString = [self versionInformationFromString:sysVerString][0];
		if (nil != sysVerString){
			return [NSString stringWithFormat: @"Mac OS X version: %@", sysVerString];
		}
	}
	
	return @"Unable to determine Mac OS X version";
}

-(NSString *)gccVersion
{
NSString *error = @"Unable to determine compiler version";
NSArray *versInfo;
NSString *result;
NSString *extraInformation;

if (! [manager fileExistsAtPath: @"/usr/bin/cc"]){
return @"Developer Tools not installed";
}

result = [self versionOutputForExecutable:@"/usr/bin/cc"];
if (nil == result) return error;

versInfo = [self versionInformationFromString:result];
result = versInfo[0];
extraInformation = versInfo[1];
if (nil == result) return error;
return [NSString stringWithFormat: @"Compiler version: %@ %@", result, extraInformation];
}

-(NSString *)makeVersion
{
	NSString *finkMakePath = [[[NSUserDefaults standardUserDefaults] 
		objectForKey:FinkBasePath] stringByAppendingPathComponent:@"bin/make"];
	NSString *pathToMake;
	NSString *error = @"Unable to determine make version";
	NSString *result;

	if ([manager fileExistsAtPath:finkMakePath]){
		pathToMake = finkMakePath;
	}else if ([manager fileExistsAtPath:@"/usr/local/bin/make"]){
		pathToMake = @"/usr/local/bin/make";
	}else if ([manager fileExistsAtPath:@"/usr/bin/make"]){
		pathToMake = @"/usr/bin/make";
	}else{
		return error;
	}
	
	result = [self versionOutputForExecutable:pathToMake];
	if (nil == result) return error;
	result = [self versionInformationFromString:result][0];
	if (nil == result) return error;
	return [NSString stringWithFormat: @"make version: %@", result];
}

//------------------------------>Developer Tools Info

-(NSString *)developerToolsInfo
{
	NSString *error = @"Unable to determine Developer Tools version";
	NSString *version;

    if ([manager fileExistsAtPath: DEVTOOLS_TEST_PATH]){
        Dprintf(@"Found file at %@", DEVTOOLS_TEST_PATH);
        version = [NSDictionary dictionaryWithContentsOfFile: DEVTOOLS_TEST_PATH][@"CFBundleShortVersionString"];
        if (! version  || [version length] < 3) return error;
        version = [@"Xcode version: " stringByAppendingString:version];
        return version;
    }
    else if ([manager fileExistsAtPath: DEVTOOLS_TEST_PATH0]){
		Dprintf(@"Found file at %@", DEVTOOLS_TEST_PATH0);
		version = [NSDictionary dictionaryWithContentsOfFile: DEVTOOLS_TEST_PATH0][@"CFBundleShortVersionString"];
		if (! version  || [version length] < 3) return error;
		version = [@"Xcode version: " stringByAppendingString:version];
		return version;
	}
	else if ([manager fileExistsAtPath: DEVTOOLS_TEST_PATH1]){
		Dprintf(@"Found file at %@", DEVTOOLS_TEST_PATH1);
		version = [NSDictionary dictionaryWithContentsOfFile: DEVTOOLS_TEST_PATH1][@"DevCDVersion"];
		if (! version  || [version length] < 3) return error;
		version = [version stringByAppendingString:@" or later"];
		return version;
	}
	else if ([manager fileExistsAtPath: DEVTOOLS_TEST_PATH2]){
		Dprintf(@"Found file at %@", DEVTOOLS_TEST_PATH2);
		version = [NSDictionary dictionaryWithContentsOfFile: DEVTOOLS_TEST_PATH2][@"CFBundleShortVersionString"];
		if (! version  || [version length] < 3) return error;  //should at least be x.x
		if ([version compare:MAY_TOOLS_VERSION] == NSOrderedDescending){  // > May 2001
			return @"December 2001 Developer Tools";
		}
		return @"Pre-December 2001 Developer Tools";
	}
	Dprintf(@"Failed to find file specifying Developer Tools version");
	return error;
}

-(NSString *)distribution
{
	NSString *finkConf = [[[NSUserDefaults standardUserDefaults] objectForKey: FinkBasePath]
							stringByAppendingPathComponent: @"/etc/fink.conf"];
	NSString *version = [self versionOutputForExecutable:@"/usr/bin/grep"
										  usingArguments:@[@"^Distribution:", finkConf]];
	
	if (! version) return @"Unable to determine the distribution field\n";
	return version;
}

-(NSString *)trees
{
	NSString *finkConf = [[[NSUserDefaults standardUserDefaults] objectForKey: FinkBasePath]
						  stringByAppendingPathComponent: @"/etc/fink.conf"];
	NSString *version = [self versionOutputForExecutable:@"/usr/bin/grep"
										  usingArguments:@[@"^Trees:", finkConf]];
	
	if (! version) return @"Unable to determine the trees field\n";
	return version;
}



//------------------------------>All The Information Combined

//As a string
-(NSString *)installationInfo
{
	NSString *finkVersion = [self finkVersion];
	NSString *macOSXVersion = [self macOSXVersion];
	NSString *gccVersion = [self gccVersion];
	NSString *devTools;
	NSString *makeVersion;
	NSString *distribution = [self distribution];
	NSString *trees = [self trees];
	NSString *result;

	if ([gccVersion contains: @"not installed"]){
		result = [NSString stringWithFormat: @"%@%@\n%@\n%@%@", 
					finkVersion, macOSXVersion, gccVersion, distribution, trees];
	}else{
		devTools = [self developerToolsInfo];
		makeVersion = [self makeVersion];
		result = [NSString stringWithFormat: @"%@%@\n%@\n%@\n%@\n%@%@", 
					finkVersion, macOSXVersion, devTools, gccVersion, makeVersion, distribution, trees];
	}
	return result;
}

//As an email signature
-(NSString *)formattedEmailSig
{
	NSString *emailSig = [self installationInfo];
	NSString *sig;

	//create body portion of mail URL
	//set sig format as ordinary string
	if ([[NSUserDefaults standardUserDefaults] boolForKey: FinkGiveEmailCredit]){
		sig = [NSString stringWithFormat:
			@"--\n%@Feedback Courtesy of FinkCommander\n", emailSig];
	}else{
		sig = [NSString stringWithFormat: @"--\n%@", emailSig];
	}
	return sig;
}

@end
