

#import "SBTreeWindowManager.h"

@implementation SBTreeWindowManager

-(id)init
{
	self = [super init];
	if (nil != self){
		_sbWindows = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)dealloc
{
    [_sbcurrentPackageName release];
	[_sbWindows release];
    [super dealloc];
}

-(NSString *)currentPackageName { return _sbcurrentPackageName; }

-(void)setCurrentPackageName:(NSString *)newCurrentPackageName
{
    [newCurrentPackageName retain];
    [_sbcurrentPackageName release];
    _sbcurrentPackageName = newCurrentPackageName;
}

-(NSMutableArray *)windows { return _sbWindows; }

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
	//Dprintf(@"In SBTWM, return value from dpkg -L:\n%@", s);
    fileList = [[[s componentsSeparatedByString:@"\n"] mutableCopy] autorelease];
    [fileList removeObjectAtIndex:0]; /* "/." */

    if ( [s contains:@"/usr/X11R6"] || [s containsExpression:@"^/Applications"] ){
		[fileList insertObject:@"/" atIndex:0];
    }
	return fileList;
}

-(void)openNewOutlineForPackageName:(NSString *)pkgName
{
    NSMutableArray *fileList = [self fileListFromCommand:
			[NSArray arrayWithObjects: @"/sw/bin/dpkg", @"-L", pkgName, nil]];
    SBTreeWindowController *tcontroller;
	NSString *windowTitle = pkgName;
	int windowNumber = 1;
		
	while ([[self windows] containsObject:pkgName]){
		windowNumber++;
		if (windowNumber > 1){
			windowTitle = [NSString stringWithFormat:@"%@ (%d)", pkgName, windowNumber];
		}		
	}
	[[self windows] addObject:pkgName];
		
	tcontroller = [[SBTreeWindowController alloc]
							initWithFileList:fileList
							windowName:windowTitle];
    [tcontroller showWindow:self];
}

@end


