/*
 File:		IOTaskWrapper.m
 
 See the header file, IOTaskWrapper.h, for interface and license information.

 */

#import "IOTaskWrapper.h"

@implementation IOTaskWrapper

-(id)initWithController:(id <IOTaskWrapperController>)cont
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *basePath = [defaults objectForKey: FinkBasePath];
	NSString *proxy;
	char *proxyEnv;
	
    if (self = [super init]){
		
		controller = cont;
		binPath = [[NSString alloc] initWithString: [basePath
						  stringByAppendingPathComponent: @"/bin"]];
		environment = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
			[NSString stringWithFormat:
			    @"/%@:/%@/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:",
				binPath, basePath],
			@"PATH",
			[NSString stringWithFormat: @"%@/lib/perl5", basePath],
			@"PERL5LIB",
			nil];

		proxy = [defaults objectForKey: FinkHTTPProxyVariable];
		if ([proxy length] > 0){
			[environment setObject: proxy forKey: @"http_proxy"];
		}else if (! [defaults boolForKey: FinkLookedForProxy]){
			NSLog(@"Looking for http_proxy environment variable");
			if (proxyEnv = getenv("http_proxy")){
				proxy = [NSString stringWithCString: proxyEnv];
				NSLog(@"Found http_proxy variable: %@", proxy);
				[environment setObject: proxy  forKey: @"http_proxy"];
				[defaults setObject: proxy forKey: FinkHTTPProxyVariable];
			}else {
				NSLog(@"Proxy environment variable not found");
			}
			[defaults setBool: YES forKey: FinkLookedForProxy];
		}
		task = [[NSTask alloc] init];
	}
    return self;
}

-(void)dealloc
{
    [self stopProcess];

	[environment release];
	[password release];
    [task release];
    [super dealloc];
}

-(NSTask *)task
{
	return task;
}

// Start the process via an NSTask.
-(void)startProcessWithArgs: (NSMutableArray *)arguments
{
	[controller processStarted];

    [task setStandardOutput: [NSPipe pipe]];
    [task setStandardError: [task standardOutput]];
	[task setStandardInput: [NSPipe pipe]];	
    [task setLaunchPath: @"/usr/bin/sudo"];

	[arguments insertObject: @"-S" atIndex: 0];
	if ([[arguments objectAtIndex: 1] isEqualToString: @"fink"] &&
	    [[NSUserDefaults standardUserDefaults] boolForKey: FinkAlwaysChooseDefaults]){
		[arguments insertObject: @"-y" atIndex: 2];
	}
    [task setArguments: arguments];
	[task setEnvironment: environment];

    [[NSNotificationCenter defaultCenter] addObserver:self 
        selector:@selector(getData:) 
        name: NSFileHandleReadCompletionNotification 
        object: [[task standardOutput] fileHandleForReading]];


    [[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];
#ifdef DEBUG
	NSLog(@"Environment set to %@", [task environment]);
#endif

    // launch the task asynchronously
    [task launch];
}


-(void)stopProcess
{
	// Make sure task is really finished before calling processFinishedWithStatus.
	// Otherwise sending terminationStatus message to task will raise error.
	// Experimented with terminate and interrupt methods; didn't work in this context
	while ([task isRunning]){
		continue;
	}
	
	[controller processFinishedWithStatus: [task terminationStatus]];    
    controller = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
	  name: NSFileHandleReadCompletionNotification object: [[task standardOutput] fileHandleForReading]];
    
    // Probably superfluous given change made above
    //[task terminate];
}

// Get data asynchronously from process's standard output
-(void)getData: (NSNotification *)aNotification
{
    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];

    if ([data length]){
        [controller appendOutput: [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
    } else {
        [self stopProcess];
    }
    
    // need to schedule the file handle go read more data in the background again.
    [[aNotification object] readInBackgroundAndNotify];
}

// ADDED: Write data to process's standard input
-(void)writeToStdin: (NSString *)s
{
	[[[task standardInput] fileHandleForWriting] writeData:
		[NSData dataWithData: [s dataUsingEncoding: NSUTF8StringEncoding]]];
}

@end

