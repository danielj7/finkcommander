/*
 File:		IOTaskWrapper.m
 
 See the header file, IOTaskWrapper.h, for interface and license information.

 */

#import "IOTaskWrapper.h"

@implementation IOTaskWrapper

-(id)initWithController:(id <IOTaskWrapperController>)cont
{
    if (self = [super init]){
		NSString *basePath;
		NSString *binPath; 
		NSString *proxy;
		char *proxyEnv;

		defaults = [NSUserDefaults standardUserDefaults];
		basePath = [defaults objectForKey: FinkBasePath];
		controller = cont;
		binPath = [basePath stringByAppendingPathComponent: @"/bin"];
						  
		//set PATH for apt-get; set PERL5LIB for fink
		environment = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
			[NSString stringWithFormat:
			    @"/%@:/%@/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:",
				binPath, basePath],
			@"PATH",
			[NSString stringWithFormat: @"%@/lib/perl5", basePath],
			@"PERL5LIB",
			nil];

		//if http proxy has been set in defaults, use it
		proxy = [defaults objectForKey: FinkHTTPProxyVariable];
		if ([proxy length] > 0){
			[environment setObject: proxy forKey: @"http_proxy"];
		//if not, and we haven't done so already, try to set it for the user
		}else if (! [defaults boolForKey: FinkLookedForProxy]){
			if (proxyEnv = getenv("http_proxy")){
				proxy = [NSString stringWithCString: proxyEnv];
				[environment setObject: proxy  forKey: @"http_proxy"];
				[defaults setObject: proxy forKey: FinkHTTPProxyVariable];
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
	NSString *executable = [arguments objectAtIndex: 0];

	[controller processStarted];

    [task setStandardOutput: [NSPipe pipe]];
    [task setStandardError: [task standardOutput]];
	[task setStandardInput: [NSPipe pipe]];	
    [task setLaunchPath: @"/usr/bin/sudo"];

	[arguments insertObject: @"-S" atIndex: 0];
	if ([defaults boolForKey: FinkAlwaysChooseDefaults] &&
		([executable isEqualToString: @"fink"] 			|| 
		 [executable isEqualToString: @"apt-get"])){
		[arguments insertObject: @"-y" atIndex: 2];
	}
	//give apt-get a chance to fix broken dependencies
	if ([executable isEqualToString: @"apt-get"]){
		[arguments insertObject: @"-f" atIndex: 2];
	}
    [task setArguments: arguments];
	[task setEnvironment: environment];

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
        [controller appendOutput: [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
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
		[s dataUsingEncoding: NSUTF8StringEncoding]];
}

@end

