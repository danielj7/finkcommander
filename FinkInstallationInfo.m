/*
File: FinkInstallationInfo.m

 See the header file, FinkController.h, for interface and license information.

*/

#import "FinkInstallationInfo.h"

//Constants
#define MAY_TOOLS_VERSION  @"2.0.1"
#define DEVTOOLS_TEST_PATH1 @"/Developer/Applications/Project Builder.app/Contents/Resources/English.lproj/DevCDVersion.plist"
#define DEVTOOLS_TEST_PATH2 @"/Developer/Applications/Interface Builder.app/Contents/version.plist"

@implementation FinkInstallationInfo

//------------------------------>init

-(id)init
{
	if (self = [super init]){
		manager = [NSFileManager defaultManager];  //shared instance, no need to retain
	}
	return self;
}

//------------------------------>Helpers for Specific Version Methods

//Scan version output for the version number
-(NSString *)numericVersionFromString:(NSString *)s
{
	NSScanner *versionScanner;
	NSCharacterSet *versionChars = [NSCharacterSet characterSetWithCharactersInString:
		@"0123456789."];
	NSString *result;

	if (! s) return nil;
	versionScanner = [NSScanner scannerWithString:s];
	[versionScanner scanUpToCharactersFromSet:versionChars intoString:NULL];
	if (! [versionScanner scanCharactersFromSet:versionChars intoString:&result]){
		return nil;
	}
	return result;
}

//Run CLI tool to get its version information
-(NSString *)versionOutputForExecutable:(NSString *)path
	usingArgument:(NSString *)arg
{
	NSTask *versionTask = [[NSTask alloc] init];
	NSPipe *pipeFromStdout = [NSPipe pipe];
	NSFileHandle *taskStdout = [pipeFromStdout fileHandleForReading];
	NSString *result;

	if (! [manager fileExistsAtPath:path]){
		return nil;
	}
	
	[versionTask setLaunchPath: path];
	if (arg){
		[versionTask setArguments: [NSArray arrayWithObjects:arg, nil]];
	}
	[versionTask setStandardOutput: pipeFromStdout];
	[versionTask launch];

	NS_DURING
		result = [[[NSString alloc] initWithData:[taskStdout readDataToEndOfFile]
									encoding:NSMacOSRomanStringEncoding] autorelease];
	NS_HANDLER
		//Handle NSFileHandleOperationException
		NSLog(@"Failed to read data stream from %@ %@", path, arg);
		return nil;
	NS_ENDHANDLER

	[versionTask release];
	[taskStdout closeFile];
	return result;
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
	if (! version) return @"Unable to determine fink version\n";
	return version;
}

-(NSString *)macOSXVersion
{
	NSString *result = [self versionOutputForExecutable:@"/usr/bin/sw_vers"
								usingArgument:nil];
	
	result = [self numericVersionFromString:result];
	if (!result) return @"Unable to determine Mac OS X Version";
	return [NSString stringWithFormat: @"Mac OS X version: %@", result];
}

-(NSString *)gccVersion
{
	NSString *result; 
	
	if (! [manager fileExistsAtPath: @"/usr/bin/cc"]){
		return @"Developer Tools not installed";
	}
	
	result = [self versionOutputForExecutable:@"/usr/bin/cc"];
	result = [self numericVersionFromString:result];
	if (!result) return @"Unable to determine gcc version";
	return [NSString stringWithFormat: @"gcc version: %@", result];
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
	Dprintf(@"Make is %@", pathToMake);
	
	result = [self versionOutputForExecutable:pathToMake];
	result = [self numericVersionFromString:result];
	if (!result) return error;
	return [NSString stringWithFormat: @"make version: %@", result];
}

//------------------------------>Developer Tools Info

-(NSString *)developerToolsInfo
{
	NSString *error = @"Unable to determine Developer Tools version";
	NSString *version;

	if ([manager fileExistsAtPath: DEVTOOLS_TEST_PATH1]){
		Dprintf(@"Found file at %@", DEVTOOLS_TEST_PATH1);
		version = [[NSDictionary dictionaryWithContentsOfFile: DEVTOOLS_TEST_PATH1]
							objectForKey:@"DevCDVersion"];
		if (! version  || [version length] < 3) return error;
		version = [version stringByAppendingString:@" or later"];
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

//------------------------------>All The Information Combined

//As a string
-(NSString *)installationInfo
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

//As a signature properly formatted for inclusion in a mailto URL
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
