/*
 File SBTreeWindowManager.m

 See header file SBTreeWindowManager.h for license and interface information.

 */

#import "SBTreeWindowManager.h"

@implementation SBTreeWindowManager

//----------------------------------------------------------
#pragma mark CREATION AND DESTRUCTION
//----------------------------------------------------------

-(instancetype)init
{
	self = [super init];
	if (nil != self){
		_sbWindowControllers = [[NSMutableArray alloc] init];
		_sbWindowTitles = [[NSMutableArray alloc] init];
	}
	return self;
}


//----------------------------------------------------------
#pragma mark ACCESSORS
//----------------------------------------------------------

-(NSString *)currentPackageName { return _sbcurrentPackageName; }

-(void)setCurrentPackageName:(NSString *)newCurrentPackageName
{
    _sbcurrentPackageName = newCurrentPackageName;
}

-(NSMutableArray *)windowControllers { return _sbWindowControllers; }

-(NSMutableArray *)windowTitles { return _sbWindowTitles; }

//----------------------------------------------------------
#pragma mark CREATING AND DESTROYING SBTREEWINDOWCONTROLLERS
//----------------------------------------------------------

-(NSMutableArray *)fileListFromCommand:(NSArray *)args
{
    NSTask *task = [[NSTask alloc] init];
    NSPipe *pipeIn = [NSPipe pipe];
    NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];
    NSData *d;
    NSString *s;
    NSMutableArray *fileList;

    [task setLaunchPath:args[0]];
    if ([args count] > 1){
		[task setArguments:[args subarrayWithRange:
			NSMakeRange(1, [args count]-1)]];
    }
    [task setStandardOutput:pipeIn];
	[task setEnvironment: [[NSUserDefaults standardUserDefaults] 									objectForKey:FinkEnvironmentSettings]];
    [task launch];
    d = [cmdStdout readDataToEndOfFile];
    s = [[NSString alloc] initWithData:d
							encoding:NSMacOSRomanStringEncoding];
	//dpkg -L didn't work for this package
	if ([s length] < 3) return nil;

    fileList = [[s componentsSeparatedByString:@"\n"] mutableCopy];
    [fileList removeObjectAtIndex:0]; /* "/." */

    if ( [s contains:@"/usr/X11R6"] || [s containsExpression:@"^/Applications"] ){
		[fileList insertObject:@"/" atIndex:0];
    }
	return fileList;
}

-(void)openNewWindowForPackageName:(NSString *)pkgName
{
    NSMutableArray *fileList = [self fileListFromCommand:
			@[@"/sw/bin/dpkg", @"-L", pkgName]];
    SBTreeWindowController *newController;
	NSString *windowTitle = pkgName;
	int windowNumber = 1;
	
	if (nil == fileList){
		NSBeep();
		return;
	}
	
	while ([[self windowTitles] containsObject:windowTitle]){
		windowNumber++;
		windowTitle = [NSString stringWithFormat:@"%@ (%d)", pkgName, windowNumber];
	}
	[[self windowTitles] addObject:windowTitle];			
	
	newController = [[SBTreeWindowController alloc]
							initWithFileList:fileList
							windowName:windowTitle];		//RC == 1
	[[self windowControllers] addObject:newController];		//RC == 2
									                        //RC == 1
}

-(void)closingTreeWindowWithController:(id)sender
{
	[[self windowControllers] removeObject:sender];			//RC == 0
}

@end


