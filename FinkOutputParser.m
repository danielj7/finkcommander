/*
File: FinkOutputParser.m

 See the header file, FinkOutputParser.h, for interface and license information.

*/

#import "FinkOutputParser.h"

@implementation FinkOutputParser

//------------------------------------------>Create and Destroy

-(id)initForCommand:(NSString *)cmd
{
    if (self = [super init]){
		defaults = [NSUserDefaults standardUserDefaults];
		command = [cmd retain];
		packageList = [[NSMutableArray alloc] init];
		[packageList addObject:@""];
		increments = [[NSMutableArray alloc] init];
		[self setCurrentPackage:@""];
		passwordErrorHasOccurred = readingPackageList = installStarted = NO;		
		determinate = [command contains:@"install"] || [command isEqualToString:@"rebuild"];
    }
    return self;
}

-(void)dealloc
{
	[ptracker release];
	[packageList release];
	[increments release];
	[command release];
	[currentPackage release];
	
	[super dealloc];
}

//------------------------------------------>Accessors

-(float)increment{ return increment; }

-(NSString *)currentPackage { return currentPackage; }

-(void)setCurrentPackage:(NSString *)p
{
	[p retain];
    [currentPackage release];
    currentPackage = p;

	NSLog(@"Set current package to %@", currentPackage);
}


//------------------------------------------>Set Up Installation Arrays and Dictionary

//create array of packages to be installed
-(void)addPackagesFromLine:(NSString *)line
{
	NSString *pname;
	int i;

    [packageList addObjectsFromArray:[[line strip] componentsSeparatedByString:@" "]];
	for (i = 0; i < [packageList count]; i++){
		pname = [packageList objectAtIndex:i];
		if ([pname contains:@"-base"]){
			int index = [pname rangeOfString:@"-"].location;
			[packageList replaceObjectAtIndex:i
						 withObject:[pname substringToIndex:index]];
		}
	}

	NSLog(@"Package list: %@", packageList);
}

//set up array of increments and dictionary of package names matched with
//the increment added so far for that package
-(void)setupInstall
{
    NSEnumerator *e = [packageList objectEnumerator];
    NSString *pname;
    float cumulative[] = {
		0.00,     //NONE
		0.20,     //FETCH 		+ .20
		0.25,     //UNPACK 		+ .05
		0.40,     //CONFIGURE 	+ .15
		0.90,     //COMPILE 	+ .50
		0.95,     //BUILD 		+ .05
		1.00};    //ACTIVATE 	+ .05
    float perpkg = (100.0 - STARTING_INCREMENT) / (float)([packageList count]-1);
    int i;

    if (! ptracker) ptracker = [[NSMutableDictionary alloc] init];
    while (pname = [e nextObject]){
		[ptracker setObject:[NSNumber numberWithFloat:0.0] forKey:pname];
    }
	
    for (i = 0; i < 7; i++){
		float newincrement = cumulative[i] * perpkg;

		[increments insertObject: [NSNumber numberWithFloat: newincrement]
								  atIndex:i];

		NSLog(@"increment %d = %f", i, [[increments objectAtIndex:i] floatValue]);
    }
    currentPhase = NONE;
}


//------------------------------------------>Set Package Name and Increment for Phase

//set increment to a level that will bring the progress indicator up to date
//if a previous phase has been skipped (e.g. b/c pkg was already fetched)
-(void)setIncrementForCurrentPhase
{
    float phaseTotal = [[increments objectAtIndex:currentPhase] floatValue];
	float pkgTotal;
	
	if ([currentPackage isEqualToString:@"package"]){
		int index = currentPhase > 0 ? currentPhase - 1 : 0;
		pkgTotal = phaseTotal - [[increments objectAtIndex: index] floatValue];
	}else{
		pkgTotal = [[ptracker objectForKey:currentPackage] floatValue];
	}
	
	NSLog(@"Current phase = %d", currentPhase);
	NSLog(@"Current package = %@", currentPackage);
	NSLog(@"Total increment for current phase: %f", phaseTotal);
	NSLog(@"Total increment for package so far: %f", pkgTotal);

    increment = phaseTotal - pkgTotal;
	
	NSLog(@"Adding increment: %f - %f = %f", phaseTotal, pkgTotal, increment);
    
	[ptracker setObject:[NSNumber numberWithFloat:phaseTotal] forKey:currentPackage];
}


//find longest name in packageList that matches a string in this line
-(NSString *)packageNameFromLine:(NSString *)line
{
    NSEnumerator *e = [packageList objectEnumerator];
    NSString *candidate;
    NSString *longestMatch = @"";
	
//	NSLog(@"Searching for package name in line:\n%@", line);
    while (candidate = [e nextObject]){
//		NSLog(@"Candidate = %@", candidate);
		if ([line containsCI:candidate]){
//			NSLog(@"Found %@ in line", candidate);
 			if ([candidate length] > [longestMatch length]){
				longestMatch = candidate;
//				NSLog(@"Longest match so far: %@", longestMatch);
			}
		}
    }
	if ([longestMatch length] < 1){
		longestMatch = @"package";
	}
	
	NSLog(@"Returning package %@", longestMatch);
	
    return longestMatch;
}


//------------------------------------------>Parse Output

-(int)parseLineOfOutput:(NSString *)line
{
	//Look for package lists
	if (determinate && readingPackageList){
	
		NSLog(@"Looking for packages in %@", line);
	
		//lines listing pkgs to be installed start with a space
		if ([line hasPrefix:@" "]){
		
			NSLog(@"Parsing line for package names:\n%@", line);
		
			[self addPackagesFromLine:line];
			return NONE;
		}
		//skip blanks and intro for additional packages
		//continue to scan for package names
		if ([line length] < 1 ||
			[line contains: @"will be installed"]){
			return NONE;
		}
		//not blank, list or intro; done looking for package names
		readingPackageList = NO;
		[self setupInstall];
		if (ISPROMPT(line)){
			return PROMPT_AND_START;
		}
		//signal FinkController to start deteriminate PI
		return START_INSTALL;
    }
	//start scanning for names of pkgs to be installed when intro found
    if (determinate 							&& 
		([line contains:@"will be installed"]	||
		 [line contains:@"will be rebuilt"])){
		readingPackageList = YES;
		return NONE;
    }
	
	//Look for installation events
	if (determinate && FETCHSTARTED(line)){
		NSLog(@"Fetch phase triggered by:\n%@", line);
		NSString *name = [self packageNameFromLine:line];
		//no action required if retrying failed download
		if ([name isEqualToString:currentPackage]) return NONE;
		[self setCurrentPackage:name];
		[self setIncrementForCurrentPhase];
		currentPhase = FETCH;
		return FETCH;
    }
    if (determinate && UNPACKSTARTED(line)){
		NSLog(@"Unpack phase triggered by:\n%@", line);
		[self setCurrentPackage:[self packageNameFromLine:line]];
		[self setIncrementForCurrentPhase];
		currentPhase = UNPACK;
		return UNPACK;
    }
    if (determinate	&& (currentPhase != CONFIGURE) && CONFIGURESTARTED(line)){
		NSLog(@"Configure phase triggered by:\n%@", line);
		[self setIncrementForCurrentPhase];
		currentPhase = CONFIGURE;
		return CONFIGURE;
    }
    if (determinate	&& (currentPhase != COMPILE) && COMPILESTARTED(line)){
		NSLog(@"Compile phase triggered by:\n%@", line);
		[self setIncrementForCurrentPhase];
		currentPhase = COMPILE;
		return COMPILE;
    }
    if (determinate && [line contains: @"dpkg-deb -b"]){
		NSLog(@"Build phase triggered by:\n%@", line);
		[self setCurrentPackage:[self packageNameFromLine:line]];
		//make sure we catch up if this file is archived
		if (currentPhase < 1) currentPhase = COMPILE;
		[self setIncrementForCurrentPhase];
		currentPhase = BUILD;
		return BUILD;
    }
    if (determinate && [line contains: @"dpkg -i"]){
		NSLog(@"Activate phase triggered by:\n%@", line);
		[self setCurrentPackage:[self packageNameFromLine:line]];
		[self setIncrementForCurrentPhase];
		currentPhase = ACTIVATE;
		return ACTIVATE;
    }	
	
	//Look for password events
	if ([line contains: @"Sorry, try again."]){
		passwordErrorHasOccurred = YES;
		return PASSWORD_ERROR;
    }
	if ([line contains: @"Password:"] && ! passwordErrorHasOccurred){
		return PASSWORD_PROMPT;
    }
	
	//Look for prompts
    if ((ISPROMPT(line)) && ! [defaults boolForKey:FinkAlwaysChooseDefaults]){
	
		NSLog(@"Found prompt: %@", line);
	
		return PROMPT;
    } 
	if ((ISMANDATORY_PROMPT(line))){
		return PROMPT;
    } 
	return NONE;
}


-(int)parseOutput:(NSString *)output
{
    NSEnumerator *e = [[output componentsSeparatedByString: @"\n"] objectEnumerator];
    NSString *line;
    int signal = NONE;  //false when used as boolean value

    while (line = [e nextObject]){
		signal = [self parseLineOfOutput:line];
		if (signal) return signal;
    }
    return signal;
}

@end
