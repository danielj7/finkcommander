
#import "SBTreeManager.h"

@implementation SBTreeManager

-(id)init
{
	if (nil != (self = [super init])){
		_sbLock = [[NSLock alloc] init];
	}
	return self;
}

-(void)dealloc
{
	[_sbcurrentPackageName release];
	[_sbLock release];
	[super dealloc];
}

-(NSString *)_sbcurrentPackageName { return _sbcurrentPackageName; }

-(void)_sbsetCurrentPackageName:(NSString *)newCurrentPackageName
{
	[newCurrentPackageName retain];
	[_sbcurrentPackageName release];
	_sbcurrentPackageName = newCurrentPackageName;
}

-(void)runCommandWithArguments:(NSArray *)args
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSTask *task = [[[NSTask alloc] init] autorelease];
	NSPipe *pipeIn = [NSPipe pipe];
	NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];
	NSData *d;
	NSString *s;
	NSMutableArray *fileList;
	SBFileItemTree *tree;

    [task setLaunchPath:[args objectAtIndex:0]];
    if ([args count] > 1){
		[task setArguments:[args subarrayWithRange:
			NSMakeRange(1, [args count]-1)]];
    }
    [task setStandardOutput:pipeIn];
	[task launch];
	d = [cmdStdout readDataToEndOfFile];
	s = [[[NSString alloc] initWithData:d
						   encoding:NSMacOSRomanStringEncoding] autorelease];
	fileList = [[[s componentsSeparatedByString:@"\n"] mutableCopy] autorelease];
	[fileList removeObjectAtIndex:0]; /* "/." */
		
	if ( [s contains:@"/usr/X11R6"] || [s containsExpression:@"^/Applications"] ){
		[fileList insertObject:@"/" atIndex:0];
	}
	
	[_sbLock lock];
	tree = [[SBFileItemTree alloc] 
				initWithWindowName:[self _sbcurrentPackageName]	
				fileArray:fileList];
	[_sbLock unlock];

	[pool release];
}

-(void)openNewOutlineForPackageName:(NSString *)pkgName
{
	[self _sbsetCurrentPackageName:pkgName];
	[NSThread detachNewThreadSelector:@selector(runCommandWithArguments:)
			  toTarget:self
			  withObject:[NSArray arrayWithObjects: @"/sw/bin/dpkg", @"-L", pkgName, nil]];
}

@end
