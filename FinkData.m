//Change FinkController to optionally use FinkData instead of FinkDataController
//and to register with NSDistributedNotificationCenter

/*  
File: FinkData.m

See the header file, FinkDataController.h, for interface and license information.

*/

#import "FinkData.h"

//Globals: placed here to make it easier to change values if fink output changes
NSString *WEB_KEY = @"Web site:";
NSString *MAINTAINER_KEY = @"Maintainer:";
int URL_START = 10;
int NAME_START = 12;

@implementation FinkData

//---------------------------------------------------------->The Ususal

-(void)dealloc
{
	[array release];
	[super dealloc];
}

// Accessors
-(NSMutableArray *)array
{
	return array;
}

-(void)setArray:(NSMutableArray *)a
{
	[a retain];
	[array release];
	array = a;
}


//---------------------------------------->Methods for Obtaining Fink Package Data 

-(NSString *)binaryList
{
	NSTask *listCmd = [[NSTask alloc] init];
	//create pipe and file handle for reading from the task's standard output
	NSPipe *pipeIn  = [NSPipe pipe];
	NSFileHandle *cmdStdout = [pipeIn fileHandleForReading];
	NSString *output;
	NSEnumerator *e;
	NSString *line;
	NSMutableArray *pkgLines = [NSMutableArray array];

	[listCmd setLaunchPath: [[[NSUserDefaults standardUserDefaults] objectForKey: FinkBasePath]
		stringByAppendingPathComponent: @"/bin/apt-cache"]];
	[listCmd setArguments: [NSArray arrayWithObjects: @"dumpavail", nil]];
	[listCmd setStandardOutput: pipeIn];
	
	[listCmd launch];
	output = [NSString stringWithCString: [[cmdStdout readDataToEndOfFile] bytes]];
	e = [[output componentsSeparatedByString: @"\n"] reverseObjectEnumerator];
	
	while (line = [e nextObject]){
		if ([line contains:@"Package:"]){
			line = [line substringWithRange: NSMakeRange(9, [line length] - 9)];
			[pkgLines addObject: [NSString stringWithFormat: @" %@#", line]];
		}
	}
 	
 	[listCmd release];
	return [pkgLines componentsJoinedByString: @"\n"];
}

-(NSString *)parseWeburlFromString:(NSString *)s
{
	NSRange r;
	if ([s length] <= URL_START){
		return @"";
	}
	r = NSMakeRange(URL_START, [s length] - URL_START);
	return [s substringWithRange: r];
}

-(NSArray *)parseMaintainerInfoFromString:(NSString *)s
{
	NSString *name;
	NSString *address;
	int emailstart = [s rangeOfString: @"<"].location;
	int emailend   = [s rangeOfString: @">"].location;

	if (emailstart == NSNotFound || emailend == NSNotFound){
		return [NSArray arrayWithObjects: @"", @"", nil];
	}	
	name = [s substringWithRange: NSMakeRange(NAME_START, emailstart - NAME_START - 1)];
	address = [s substringWithRange:
			NSMakeRange(emailstart + 1, emailend - emailstart - 1)];
	return [NSArray arrayWithObjects: name, address, nil];
}

-(NSArray *)descriptionComponentsFromString:(NSString *)s
{
	NSString *line;
	NSString *web = @"";
	NSString *maint = @"";
	NSString *email = @"";
	NSArray *lines = [s componentsSeparatedByString: @"\n"];
	NSEnumerator *e = [lines objectEnumerator];

	line = [e nextObject]; //discard--name-version: short desc

	while (line = [e nextObject]){
		line = [line strip];
		if ([line contains: WEB_KEY]){
			web = [self parseWeburlFromString: line];
		}else if ([line contains: MAINTAINER_KEY]){
			NSArray *info = [self parseMaintainerInfoFromString: line];
			maint = [info objectAtIndex: 0];
			email = [info objectAtIndex: 1];
		}
	}
	return [NSArray arrayWithObjects: web, maint, email, nil];
}

-(NSArray *)packageArray
{
	CBPerl *interpreter = [[CBPerl alloc] init];
	NSString *basePath = [[NSUserDefaults standardUserDefaults] objectForKey:FinkBasePath];
	NSString *script = [NSString stringWithContentsOfFile: 
						[[NSBundle mainBundle] pathForResource: @"scriptfile" ofType: @"txt"]];
	NSString *scriptResult;
	NSArray *scriptResultArray;
	NSArray *components;
	NSMutableArray *packageComponentsArray = [NSMutableArray array];
	NSEnumerator *e;
	
	LOGIFDEBUG(@"Creating package array");
		
	[interpreter useLib: [NSString stringWithFormat: @"%@/lib/perl5", basePath]];
	[interpreter useLib: [NSString stringWithFormat: @"%@/lib/perl5/darwin", basePath]];
	[interpreter useModule: @"Fink::Services"];
	[interpreter useModule: @"Fink::Package"];
	[interpreter eval: [NSString stringWithFormat: 
							@"$config = &Fink::Services::read_config(\"%@/etc/fink.conf\");",
							basePath]];
		
	[interpreter eval: script];
	scriptResult = [interpreter varAsString:@"result"];

	scriptResultArray = [scriptResult componentsSeparatedByString:@"\n----\n"];
	scriptResultArray = [scriptResultArray 
							subarrayWithRange:NSMakeRange(1, [scriptResultArray count]-1)];
	e = [scriptResultArray objectEnumerator];
	while (components = [[e nextObject] componentsSeparatedByString: @"**\n"]){
		[packageComponentsArray addObject:components];
	}

	[interpreter release];
	return packageComponentsArray;
}

-(void)update:(id)ignore
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableArray *collector = [NSMutableArray array];
    NSString *binaryPackages;
    NSEnumerator *e;
    NSArray *listRecord;
    FinkPackage *p;
    NSArray *components;
    NSLock *arrayLock = [[NSLock alloc] init];
    NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];

    binaryPackages = [self binaryList];
    e = [[self packageArray] objectEnumerator];

    while (listRecord = [e nextObject]){
		p = [[[FinkPackage alloc] init] autorelease];
		[p setName: [listRecord objectAtIndex: 0]];
		[p setVersion: [listRecord objectAtIndex: 1]];
		[p setInstalled: [listRecord objectAtIndex: 2]];
		[p setCategory: [listRecord objectAtIndex: 3]];
		[p setDescription: [listRecord objectAtIndex: 4]];
		if ([[listRecord objectAtIndex: 5] isEqualToString: @"stable"]){
			[p setUnstable: @" "];
		}else{
			[p setUnstable: @"*"];
		}
		[p setFulldesc: [listRecord objectAtIndex: 6]];
		components = [self descriptionComponentsFromString: [p fulldesc]];
		[p setWeburl: [components objectAtIndex: 0]];
		[p setMaintainer: [components objectAtIndex: 1]];
		[p setEmail: [components objectAtIndex: 2]];
		//make sure FULL name matches package on binary list
		if ([binaryPackages contains:
					[NSString stringWithFormat: @" %@#", [p name]]]){
			[p setBinary: @"*"];
		}else{
			[p setBinary: @" "];
		} 
		[collector addObject: p];
    }

	if (DEBUGGING) {NSLog(@"Collector count: %d", [collector count]);}
	
if ([arrayLock tryLock]){
	[self setArray: collector];
	[arrayLock unlock];
    }

	if (DEBUGGING) {NSLog(@"array count: %d", [array count]);}
	
    //notify FinkController that table needs to be updated
    [center postNotificationName:FinkPackageArrayIsFinished object:nil];
    [arrayLock release];		
	[pool release];
    [NSThread exit];
}

-(void)updateManuallyWithCommand:(NSString *)cmd packages:(NSArray *)pkgs
{
    FinkPackage *pkg;
    NSEnumerator *e = [pkgs objectEnumerator];

    if ([cmd isEqualToString: @"install"]){
	while (pkg = [e nextObject]){
	    [pkg setInstalled: @"current"];
	}
    }else if ([cmd isEqualToString: @"remove"]){
	while (pkg = [e nextObject]){
	    [pkg setInstalled: @"archived"];
	}
    }else if ([cmd isEqualToString: @"update-all"]){
	e = [[self array] objectEnumerator];
	while (pkg = [e nextObject]){
	    if ([[pkg installed] isEqualToString: @"outdated"]){
		[pkg setInstalled: @"current"];
	    }
	}
    }
}


//---------------------------------------->Utility Method

-(int)installedPackagesCount
{
    int count = 0;
    NSEnumerator *e = [[self array] objectEnumerator];
    FinkPackage *pkg;

    while (pkg = [e nextObject]){
	if ([[pkg installed] contains: @"t"]){
	    count++;
	}
    }
    return count;
}

@end
