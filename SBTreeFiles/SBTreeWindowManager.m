

#import "SBTreeWindowManager.h"

@implementation SBTreeWindowManager

-(void)dealloc
{
    [_sbcurrentPackageName release];
    [super dealloc];
}

-(NSString *)currentPackageName { return _sbcurrentPackageName; }

-(void)setCurrentPackageName:(NSString *)newCurrentPackageName
{
    [newCurrentPackageName retain];
    [_sbcurrentPackageName release];
    _sbcurrentPackageName = newCurrentPackageName;
}

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
	Dprintf(@"In SBTWM, return value from dpkg -L:\n%@", s);
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
		
	tcontroller = [[SBTreeWindowController alloc]
								initWithFileList:fileList
								windowName:pkgName];
 
	//ADD DOCUMENT MANAGEMENT ARRAY
    //MAKE SURE EACH DOCUMENT HAS UNIQUE NAME
    //E.G. "autocutsel 2" IF ALREADY AN AUTOCUTSEL WINDOW OPEN

    [tcontroller showWindow:self];
}

@end


