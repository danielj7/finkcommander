/*
 File SBTreeWindowManager.m

 See header file SBTreeWindowManager.h for license and interface information.

 */

#import "SBTreeWindowManager.h"

@implementation SBTreeWindowManager

-(id)init
{
	self = [super init];
	if (nil != self){
		_sbWindowControllers = [[NSMutableArray alloc] init];
		_sbWindowTitles = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)dealloc
{
    [_sbcurrentPackageName release];
	[_sbWindowControllers release];
	[_sbWindowTitles release];
	
    [super dealloc];
}

-(NSString *)currentPackageName { return _sbcurrentPackageName; }

-(void)setCurrentPackageName:(NSString *)newCurrentPackageName
{
    [newCurrentPackageName retain];
    [_sbcurrentPackageName release];
    _sbcurrentPackageName = newCurrentPackageName;
}

-(NSMutableArray *)windowControllers { return _sbWindowControllers; }

-(NSMutableArray *)windowTitles { return _sbWindowTitles; }

-(NSMutableArray *)fileListFromCommand:(NSArray *)args
{
    NSTask *task = [[NSTask alloc] init];
    NSPipe *pipeIn = [NSPipe pipe];
    NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];
    NSData *d;
    NSString *s;
    NSMutableArray *fileList;

    [task setLaunchPath:[args objectAtIndex:0]];
    if ([args count] > 1){
		[task setArguments:[args subarrayWithRange:
			NSMakeRange(1, [args count]-1)]];
    }
    [task setStandardOutput:pipeIn];
	[task setEnvironment: [[NSUserDefaults standardUserDefaults] 									objectForKey:FinkEnvironmentSettings]];
    [task launch];
    d = [cmdStdout readDataToEndOfFile];
	[task release];
    s = [[[NSString alloc] initWithData:d
							encoding:NSMacOSRomanStringEncoding] autorelease];
    fileList = [[[s componentsSeparatedByString:@"\n"] mutableCopy] autorelease];
    [fileList removeObjectAtIndex:0]; /* "/." */

    if ( [s contains:@"/usr/X11R6"] || [s containsExpression:@"^/Applications"] ){
		[fileList insertObject:@"/" atIndex:0];
    }
	return fileList;
}

-(void)openNewWindowForPackageName:(NSString *)pkgName
{
    NSMutableArray *fileList = [self fileListFromCommand:
			[NSArray arrayWithObjects: @"/sw/bin/dpkg", @"-L", pkgName, nil]];
    SBTreeWindowController *newController;
	NSString *windowTitle = pkgName;
	int windowNumber = 1;
	
	while ([[self windowTitles] containsObject:windowTitle]){
		windowNumber++;
		windowTitle = [NSString stringWithFormat:@"%@ (%d)", pkgName, windowNumber];
	}
	[[self windowTitles] addObject:windowTitle];			
	
	newController = [[SBTreeWindowController alloc]
							initWithFileList:fileList
							windowName:windowTitle];		//RC == 1
	[[self windowControllers] addObject:newController];		//RC == 2
	[newController release];								//RC == 1
}

-(void)closingTreeWindowWithController:(id)sender
{
	Dprintf(@"Retain count of %@ before removed from array: %d",
		 sender, [sender retainCount]);

	[[self windowControllers] removeObject:sender];			//RC == 0
}

@end


