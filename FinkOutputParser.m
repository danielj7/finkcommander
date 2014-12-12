/*
 File: FinkOutputParser.m

 See the header file, FinkOutputParser.h, for interface and license information.

 */

#import "FinkOutputParser.h"

//------------------------------------------>Macros

//Commands for which determinate PI is displayed

#define IS_INSTALL_CMD(x) 													\
    ([(x) contains:@"install"]			|| 									\
     [(x) contains:@"build"]			|| 									\
     [(x) contains:@"update-all"]		|| 									\
     [(x) contains:@"selfupdate"])
    
//Line parsing macros

#define INSTALLTRIGGER(x)													\
    ([(x) containsPattern:@"*following *package* will be *installed*"]  || 	\
     [(x) contains:@"will be rebuilt"])

#define FETCHTRIGGER(x) 													\
    [(x) containsExpression:@"^(wget|curl|axel) -"]

#define UNPACKTRIGGER(x) 													\
    (([(x) containsPattern:@"mkdir -p */src/*"] 				&& 			\
     ![(x) contains:@"root"])									||			\
     [(x) containsExpression:@"/bin/(tar|bzip2) -.*"])

#define COMPILETRIGGER(x)													\
    (([(x) hasPrefix: @"make"]									&& 			\
     ![(x) contains:@"makefile"])								|| 			\
      [(x) containsExpression:@"^(g?[c+7]{2} (-[^E]| ))|Compiling |pbxbuild "])

#define CONFIG_PAT															\
	@"^(\\./configure|checking for|patching file) "

#define PROMPT_PAT															\
    [NSString stringWithFormat:												\
        @"proceed\\? \\[.*\\]|your choice:|Pick one|\\[(Yn)\\]|\\[[Yy]+/[Nn]+\\]|\\[[Nn]+/[Yy]+\\]|\\? \\[[0-9]+\\]|\\[anonymous\\]|\\[root\\]|\\[%@\\]", 		\
            NSUserName()]

 //fink's --yes option does not work for these prompts:
#define MANPROMPT_PAT														\
    @"(CVS|cvs).*password|\\[default=N\\]|either license\\?|(key|[Rr]eturn) to continue"

// dynamic output is output that replaces the current line in stdout to simulate movement
#define DYNAMIC_PAT														\
	@"Downloading.*\\[[\\\\\\|\\*-/]\\]"

#define AFTER_EQUAL_SIGN 5

@implementation FinkOutputParser

//------------------------------------------>Create and Destroy

-(instancetype)initForCommand:(NSString *)cmd
		executable:(NSString *)exe;
{
    if (self = [super init]){
        int aPrompt, mPrompt, config, dOutput;  //test regex compilation success

        defaults = [NSUserDefaults standardUserDefaults];
        command = cmd;
        readingPackageList = NO;
        selfRepair = NO;
        installing = IS_INSTALL_CMD(command) && [exe contains:@"fink"];
        _pgid = 0;

        /* Precompile regular expressions used to parse each line of output */
        config = compiledExpressionFromString(CONFIG_PAT, &configure);
        aPrompt = compiledExpressionFromString(PROMPT_PAT, &prompt);
        mPrompt = compiledExpressionFromString(MANPROMPT_PAT, &manPrompt);
		dOutput = compiledExpressionFromString(DYNAMIC_PAT, &dynamicOutput);
        if (mPrompt != 0 || aPrompt != 0){
            NSLog(@"Compiling regex failed.");
        }

        if (installing){
            packageList = [[NSMutableArray alloc] init];
            [packageList addObject:@""];
            increments = [[NSMutableArray alloc] init];
            _currentPackage = @"";
        }
    }
    return self;
}

-(void)dealloc
{

    regfree(&configure);
    regfree(&prompt);
    regfree(&manPrompt);
	regfree (&dynamicOutput);

}

//------------------------------------------>Set Up Installation Arrays and Dictionary

//create array of packages to be installed
-(void)addPackagesFromLine:(NSString *)line
{
    [packageList addObjectsFromArray:[[line strip] componentsSeparatedByString:@" "]];
    Dprintf(@"Package list: %@", packageList);
}

//set up array of increments and dictionary of package names matched with
//the increment added so far for that package
-(BOOL)setupInstall
{
    NSEnumerator *e;
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

    if (!packageList){
        NSLog(@"Warning: Empty package list; unable to track installation state");
        return NO;
    }

    e = [packageList objectEnumerator];
    if (! ptracker) ptracker = [[NSMutableDictionary alloc] init];
    while (nil != (pname = [e nextObject])){
        ptracker[pname] = @0.0f;
    }

    for (i = 0; i < 7; i++){
        float newincrement = cumulative[i] * perpkg;

        [increments insertObject: @(newincrement)
					atIndex:i];
        Dprintf(@"increment %d = %f", i, [increments[i] floatValue]);
    }
    currentPhase = NONE;
    return YES;
}


//------------------------------------------>Set Package Name and Increment for Phase

//set increment to a level that will bring the progress indicator up to date
//if a previous phase has been skipped (e.g. b/c pkg was already fetched)
-(void)setIncrementForLastPhase
{
    float phaseTotal;
    float pkgTotal;

    if (![self currentPackage] || !packageList || [packageList count] < 1 || !ptracker){
        NSLog(@"Data objects for installation tracking were not created");
        [self setIncrement:0];
        return;
    }

    phaseTotal = [increments[currentPhase] floatValue];
    if ([[self currentPackage] isEqualToString:@"package"]){
        [self setIncrement:0];
        return;
    }else{
        pkgTotal = [ptracker[[self currentPackage]] floatValue];
    }

    Dprintf(@"Incrementing for prior phase = %d, package = %@", currentPhase, [self currentPackage]);
    if (phaseTotal > pkgTotal){
        [self setIncrement:phaseTotal - pkgTotal];
        ptracker[[self currentPackage]] = @(phaseTotal);
        Dprintf(@"Adding increment: %f - %f = %f", phaseTotal, pkgTotal, [self increment]);
    }else{
        [self setIncrement:0];
        Dprintf(@"Old total increment %f >= new total %f; setting increment to 0",
                pkgTotal, phaseTotal);

    }
}

//find longest name in packageList that matches a string in this line
-(NSString *)packageNameFromLine:(NSString *)line
{
    NSEnumerator *e;
    NSString *candidate;
    NSString *best = @"";

    if (!packageList){
        NSLog(@"Warning: No package list created; unable to determine current package");
        return best;
    }
    e = [packageList objectEnumerator];
    //first see if the line contains any of the names in the package list;
    //if so, return the longest name that matches
    while (nil != (candidate = [e nextObject])){
        if ([line containsCI:candidate]){
            if ([candidate length] > [best length]){
                best = candidate;
            }
        }
    }
    //sometimes the actual file name doesn't include the fink package name,
    //e.g.  <pkg>-ssl is built from <pkg>-<version>.tgz;
    //so parse the line for the file name and look for it in the package list
    if ([best length] < 1 && [line contains:@"-"]){
        NSString *path = [[[[line strip] componentsSeparatedByString:@" "] lastObject] lastPathComponent];
        NSString *chars;
        NSMutableString *fname = [NSMutableString stringWithString:@""];
        NSScanner *lineScanner;
        NSCharacterSet *nums = [NSCharacterSet decimalDigitCharacterSet];
        BOOL foundDash;

        Dprintf(@"Failed to find listed package in line:%@", line);
        Dprintf(@"Found full file name+version %@ in line", path);
        lineScanner = [NSScanner scannerWithString:path];
        while (! [lineScanner isAtEnd]){
            foundDash = [lineScanner scanUpToString:@"-" intoString:&chars];
            if  (! foundDash){
                Dprintf(@"Stopped scanning");
                break;
            }
            [fname appendString:chars];
            [lineScanner scanString:@"-" intoString:nil];
            if ([lineScanner scanCharactersFromSet:nums intoString:nil]){
                break;
            }
            [fname appendString:@"-"];
        }
        Dprintf(@"Looking for best match for %@ in:\n%@", fname,
                [packageList componentsJoinedByString:@" "]);
        if ([fname length] > 0){
            e = [packageList objectEnumerator];
            while (nil != (candidate = [e nextObject])){
                if ([candidate contains:fname]){  //e.g. wget-ssl contains wget
                    Dprintf(@"Listed package %@ contains %@", candidate, fname);
                    if ([best length] < 1){
                        best = candidate;
                    }else if ([candidate length] < [best length]){
                        best = candidate;
                    }
                }
            }
        }
    }
    if ([best length] < 1){
        best = @"package";
    }
    return best;
}


//------------------------------------------>Parse Output

-(int)parseLineOfOutput:(NSString *)line
{
    NSString *sline = [line strip];
    //Read process group id for Launcher
    if (![self pgid] && [line contains:@"PGID="]){
        [self setPgid:[[line substringFromIndex:AFTER_EQUAL_SIGN] intValue]];
        return PGID;
    }
    //Look for package lists
    if (installing && readingPackageList){
        //lines listing pkgs to be installed start with a space
        if ([line hasPrefix:@" "]){
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
        //If we were unable to create a package list, setupInstall returns NO, so that
        //we skip any blocks conditioned on the installing flag
        installing = [self setupInstall];
        //look for prompt or installation event immediately after pkg list
        if ([line containsCompiledExpression:&prompt]){
            if (installing){
                return PROMPT_AND_START;
            }
            return PROMPT;
        }
        if (FETCHTRIGGER(sline)){
            Dprintf(@"Fetch phase triggered by:\n%@", line);
            [self setIncrementForLastPhase];
            [self setCurrentPackage:[self packageNameFromLine:line]];
            currentPhase = FETCH;
            return START_AND_FETCH;
        }
        if (UNPACKTRIGGER(sline)){
            Dprintf(@"Unpack phase triggered by:\n%@", line);
            [self setIncrementForLastPhase];
            [self setCurrentPackage:[self packageNameFromLine:line]];
            currentPhase = UNPACK;
            return START_AND_UNPACK;
        }
        if ([line contains: @"dpkg -i"]){
            Dprintf(@"Activate phase triggered by:\n%@", line);
            [self setIncrementForLastPhase];
            [self setCurrentPackage:[self packageNameFromLine:line]];
            currentPhase = ACTIVATE;
            return START_AND_ACTIVATE;
        }
        //signal FinkController to start deteriminate PI
        return START_INSTALL;
    }
	if (installing){
		//Look for introduction to package lists
		if (INSTALLTRIGGER(line)){
			Dprintf(@"Package scan triggered by:\n%@", line);
			readingPackageList = YES;
			return NONE;
		}
		//Look for installation events
		if (FETCHTRIGGER(sline)){
			NSString *name = [self packageNameFromLine:line];
			Dprintf(@"Fetch phase triggered by:\n%@", line);
			//no action required if retrying failed download
			if ([name isEqualToString:[self currentPackage]]) return NONE;
			[self setIncrementForLastPhase];
			[self setCurrentPackage:name];
			currentPhase = FETCH;
			return FETCH;
		}
		if (currentPhase != UNPACK && UNPACKTRIGGER(sline)){
			Dprintf(@"Unpack phase triggered by:\n%@", line);
			[self setIncrementForLastPhase];
			[self setCurrentPackage:[self packageNameFromLine:line]];
			currentPhase = UNPACK;
			return UNPACK;
		}
		if (currentPhase == UNPACK && [sline containsCompiledExpression:&configure]){
			Dprintf(@"Configure phase triggered by:\n%@", line);
			[self setIncrementForLastPhase];
			currentPhase = CONFIGURE;
			return CONFIGURE;
		}
		if (currentPhase != COMPILE && COMPILETRIGGER(sline)){
			Dprintf(@"Compile phase triggered by:\n%@", line);
			[self setIncrementForLastPhase];
			currentPhase = COMPILE;
			return COMPILE;
		}
		if ([line contains: @"dpkg-deb -b"]){
			Dprintf(@"Build phase triggered by:\n%@", line);
			//make sure we catch up if this file is archived
			if (currentPhase < 1) currentPhase = COMPILE;
			[self setIncrementForLastPhase];
			[self setCurrentPackage:[self packageNameFromLine:line]];
			currentPhase = BUILD;
			return BUILD;
		}
		if ([line contains: @"dpkg -i"]){
			Dprintf(@"Activate phase triggered by:\n%@", line);
			if (currentPhase < 1) currentPhase = COMPILE;
			[self setIncrementForLastPhase];
			[self setCurrentPackage:[self packageNameFromLine:line]];
			currentPhase = ACTIVATE;
			return ACTIVATE;
		}
	}

    //Look for prompts
    if ([line contains: @"Password:"]){
        return PASSWORD_PROMPT;
    }
    if ([line containsCompiledExpression:&manPrompt]){
        return MANDATORY_PROMPT;
    }
    if ([line containsCompiledExpression:&prompt] &&
        ! [defaults boolForKey:FinkAlwaysChooseDefaults]){
        Dprintf(@"Found prompt: %@", line);
        return PROMPT;
    }
	if ([line containsCompiledExpression:&dynamicOutput]){
		return DYNAMIC_OUTPUT;
	}

    //Look for self-repair messages
	//NB:  Find a way to avoid looking for this in every line
	if ([line contains:@"Running self-repair"]){
		selfRepair = YES;
		return RUNNING_SELF_REPAIR;
	}
	if (selfRepair){		
		if ([line contains:@"Self-repair succeeded"]){
			selfRepair = NO;
			return SELF_REPAIR_COMPLETE;
		}
		if ([line contains:@"Unable to modify Resource directory\n"]){
			selfRepair = NO;
			return RESOURCE_DIR_ERROR;
		}
		if ([line contains:@"Self-repair failed\n"]){
			selfRepair = NO;
			return SELF_REPAIR_FAILED;
		}
	}
    return NONE;
}

-(int)parseOutput:(NSString *)output
{
    NSEnumerator *e;
    NSString *line;
    int signal = NONE;  //false when used as boolean value

    e  = [[output componentsSeparatedByString: @"\n"] objectEnumerator];

    while (nil != (line = [e nextObject])){
        signal = [self parseLineOfOutput:line];
        if (signal) return signal;
    }
    return signal;
}

@end
