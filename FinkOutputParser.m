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
		[self setCurrentPackage:@""];
		passwordErrorHasOccurred = readingPackageList = installStarted = NO;
    }
    return self;
}

-(void)dealloc
{
	[ptracker release];
	[packageList release];
    [command release];
	[currentPackage release];
	[super dealloc];
}

//------------------------------------------>Accessors and Related

-(float)increment{ return increment; }

//set increment to a level that will bring the progress indicator up to date
//if a previous phase has been skipped (e.g. b/c pkg was already fetched)
-(void)setIncrementForCurrentPhase
{
    float completed = increments[currentPhase];

    increment = completed - [[ptracker objectForKey:currentPackage] floatValue];    
    [ptracker setObject:[NSNumber numberWithFloat:completed] forKey:currentPackage];
	
	NSLog(@"Increment added: %f; completed so far: %f", increment, completed);
}

-(NSString *)currentPackage { return currentPackage; }

-(void)setCurrentPackage:(NSString *)p
{
    [p retain];
    [currentPackage release];
    currentPackage = p;
	
	NSLog(@"Current package: %@", currentPackage);
}

//find longest name in packageList that matches a string in this line
-(NSString *)packageNameFromLine:(NSString *)line
{
    NSEnumerator *e = [packageList objectEnumerator];
    NSString *candidate;
    NSString *longestMatch = @"";
	
	NSLog(@"Searching for package name in line:\n%@", line);

    while (candidate = [e nextObject]){
		
		NSLog(@"Candidate = %@", candidate);
		
		if ([line containsCI:candidate]){
		
			NSLog(@"Found %@ in line", candidate);

 			if ([candidate length] > [longestMatch length]){
				longestMatch = candidate;
				
				NSLog(@"Longest match so far: %@", longestMatch);

			}
		}
    }
	
	NSLog(@"Returning package %@", longestMatch);
	
    return longestMatch;
}

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


//------------------------------------------>Setup

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
    float perpkg = (100.0 - STARTING_INCREMENT) / (float)[packageList count];
    int i;
	
    if (! ptracker) ptracker = [[NSMutableDictionary alloc] init];
    while (pname = [e nextObject]){
		[ptracker setObject:[NSNumber numberWithFloat:0.0] forKey:pname];
    }
    for (i = 0; i < 7; i++){
		increments[i] = cumulative[i] * perpkg;
		
		NSLog(@"increment %d: %f", i, increments[i]);

    }
    currentPhase = NONE;
}


//------------------------------------------>Parse

-(int)parseLineOfOutput:(NSString *)line
{
	//Look for package lists
	if (readingPackageList){
	
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
		//done looking for package names
		readingPackageList = NO;
		[self setupInstall];
		if (ISPROMPT(line)){
			return PROMPT_AND_START;
		}
		//signal FinkController to start deteriminate PI
		return START_INSTALL;
    }
	//start scanning for names of pkgs to be installed when intro found
    if ([line contains: @"will be installed"]){
		readingPackageList = YES;
		return NONE;
    }
	
	//Look for installation events
	if ([line hasPrefix: @"wget"]  || 
		[line hasPrefix: @"curl"]  ||
		[line hasPrefix: @"axel"]){
		NSString *name = [self packageNameFromLine:line];
		//no action required if retrying failed download
		if ([name isEqualToString:currentPackage]) return NONE;
		[self setCurrentPackage:name];
		[self setIncrementForCurrentPhase];
		currentPhase = FETCH;
		return FETCH;
    }
    if ([line hasPrefix:@"tar"]     ||
		[line hasPrefix:@"bzip"]    ||
		[line contains:@"/tar "]    ||
		[line contains:@"/bzip2 "]){
		[self setCurrentPackage:[self packageNameFromLine:line]];
		[self setIncrementForCurrentPhase];
		currentPhase = UNPACK;
		return UNPACK;
    }
    if (currentPhase != CONFIGURE 					&&
		([[line strip] hasPrefix:@"./configure"] 	||
		 [[line strip] hasPrefix:@"patch"])){
		[self setIncrementForCurrentPhase];
		currentPhase = CONFIGURE;
		return CONFIGURE;
    }
    if (currentPhase != COMPILE &&
		[[line strip] hasPrefix: @"make"]){
		[self setIncrementForCurrentPhase];
		currentPhase = COMPILE;
		return COMPILE;
    }
    if ([line contains: @"dpkg-deb -b"]){
		[self setCurrentPackage:[self packageNameFromLine:line]];
		//make sure we catch up if this file is archived
		if (currentPhase < 1) currentPhase = COMPILE;
		[self setIncrementForCurrentPhase];
		currentPhase = BUILD;
		return BUILD;
    }
    if ([line contains: @"dpkg -i"]){
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
