/*
 File:		IOTaskWrapper.m
 
 See the header file, IOTaskWrapper.h, for interface and license information.

*/

#import "IOTaskWrapper.h"

@implementation IOTaskWrapper

-(id)initWithController:(id <IOTaskWrapperController>)cont
{
    if (self = [super init]){

		controller = cont;
		useCustomEnvironment = NO;
		task = [[NSTask alloc] init];
	}
    return self;
}

-(void)dealloc
{
    [self stopProcess];

	[environment release];
    [task release];
    [super dealloc];
}

-(NSTask *)task
{
	return task;
}

-(void)setEnvironmentDictionary:(NSDictionary *)d
{
	[d retain];
	[environment release];
	environment = d;
	useCustomEnvironment = YES;
}

// Start the process via an NSTask.
-(void)startProcessWithArgs: (NSMutableArray *)arguments
{
	[controller processStarted];

    [task setStandardOutput: [NSPipe pipe]];
    [task setStandardError: [task standardOutput]];
	[task setStandardInput: [NSPipe pipe]];	
    [task setLaunchPath: [arguments objectAtIndex: 0]];
	[arguments removeObjectAtIndex: 0];
    [task setArguments: arguments];
	if (useCustomEnvironment){
		[task setEnvironment: environment];
	}

    [[NSNotificationCenter defaultCenter] addObserver:self 
        selector:@selector(getData:) 
        name: NSFileHandleReadCompletionNotification 
        object: [[task standardOutput] fileHandleForReading]];

    [[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];

    // launch the task asynchronously
    [task launch];
}

-(void)stopProcess
{
	//make sure task is really finished before calling processFinishedWithStatus.
	[task waitUntilExit];
	
	//send message to controller object
	[controller processFinishedWithStatus: [task terminationStatus]];
    controller = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
	  name: NSFileHandleReadCompletionNotification 
	  object: [[task standardOutput] fileHandleForReading]];
}

// Get data asynchronously from process's standard output
-(void)getData: (NSNotification *)aNotification
{
    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];

	//if process is still returning data, send it to the controller object
    if ([data length]){
        [controller appendOutput: [[[NSString alloc] initWithData:data encoding:NSMacOSRomanStringEncoding] autorelease]];
    } else {
        [self stopProcess];
    }
    
    //schedule the file handle to go read more data in the background
    [[aNotification object] readInBackgroundAndNotify];
}

// ADDED: Write data to process's standard input
-(void)writeToStdin: (NSString *)s
{
	[[[task standardInput] fileHandleForWriting] writeData:
		[s dataUsingEncoding: NSMacOSRomanStringEncoding]];
}

@end

