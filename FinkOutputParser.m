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

@interface FinkOutputParser ()
{
    regex_t _configure;
    regex_t _prompt;
    regex_t _manPrompt;
    regex_t _dynamicOutput;
}

@property (nonatomic) NSUserDefaults *defaults;
@property (nonatomic) NSMutableDictionary *ptracker;
@property (nonatomic) NSMutableArray *packageList;
@property (nonatomic) NSMutableArray *increments;
@property (nonatomic) NSString *command;

@property (nonatomic) FinkOutputSignalType currentPhase;
@property (nonatomic, getter=isInstalling) BOOL installing;
@property (nonatomic, getter=isReadingPackageList) BOOL readingPackageList;
@property (nonatomic, getter=isSelfRepair) BOOL selfRepair;

@property (nonatomic) CGFloat increment;
@property (nonatomic) NSInteger pgid;
@property (nonatomic, copy) NSString *currentPackage;

@end

@implementation FinkOutputParser

//------------------------------------------>Create and Destroy

-(instancetype)initForCommand:(NSString *)cmd
		executable:(NSString *)exe;
{
    if (self = [super init]){
        NSInteger aPrompt, mPrompt, config, dOutput;  //test regex compilation success

        _defaults = [NSUserDefaults standardUserDefaults];
        _command = cmd;
        _readingPackageList = NO;
        _selfRepair = NO;
        _installing = IS_INSTALL_CMD(_command) && [exe contains:@"fink"];
        _pgid = 0;

        /* Precompile regular expressions used to parse each line of output */
        config = compiledExpressionFromString(CONFIG_PAT, &_configure);
        aPrompt = compiledExpressionFromString(PROMPT_PAT, &_prompt);
        mPrompt = compiledExpressionFromString(MANPROMPT_PAT, &_manPrompt);
        dOutput = compiledExpressionFromString(DYNAMIC_PAT, &_dynamicOutput);
        if (mPrompt != 0 || aPrompt != 0 || config != 0 || dOutput != 0){
            NSLog(@"Compiling regex failed.");
        }

        if (_installing){
            _packageList = [[NSMutableArray alloc] init];
            [_packageList addObject:@""];
            _increments = [[NSMutableArray alloc] init];
            _currentPackage = @"";
        }
    }
    return self;
}

-(void)dealloc
{

    regfree(&_configure);
    regfree(&_prompt);
    regfree(&_manPrompt);
	regfree(&_dynamicOutput);

}

//------------------------------------------>Set Up Installation Arrays and Dictionary

//create array of packages to be installed
-(void)addPackagesFromLine:(NSString *)line
{
    [[self packageList] addObjectsFromArray:[[line strip] componentsSeparatedByString:@" "]];
    Dprintf(@"Package list: %@", [self packageList]);
}

//set up array of increments and dictionary of package names matched with
//the increment added so far for that package
-(BOOL)setupInstall
{
    CGFloat cumulative[] = {
        0.00,     //NONE
        0.20,     //FETCH 		+ .20
        0.25,     //UNPACK 		+ .05
        0.40,     //CONFIGURE 	+ .15
        0.90,     //COMPILE 	+ .50
        0.95,     //BUILD 		+ .05
        1.00};    //ACTIVATE 	+ .05
    CGFloat perpkg = (100.0 - STARTING_INCREMENT) / (float)([[self packageList] count]-1);
    NSInteger i;

    if (![self packageList]){
        NSLog(@"Warning: Empty package list; unable to track installation state");
        return NO;
    }

    if (! [self ptracker]) [self setPtracker: [[NSMutableDictionary alloc] init]];
    for (NSString *pname in [self packageList]){
        [self ptracker][pname] = @0.0f;
    }

    for (i = 0; i < 7; i++){
        CGFloat newincrement = cumulative[i] * perpkg;

        [[self increments] insertObject: @(newincrement)
					atIndex:i];
        Dprintf(@"increment %d = %f", i, [[self increments][i] floatValue]);
    }
    [self setCurrentPhase: NONE];
    return YES;
}


//------------------------------------------>Set Package Name and Increment for Phase

//set increment to a level that will bring the progress indicator up to date
//if a previous phase has been skipped (e.g. b/c pkg was already fetched)
-(void)setIncrementForLastPhase
{
    CGFloat phaseTotal;
    CGFloat pkgTotal;

    if (![self currentPackage] || ![self packageList] || [[self packageList] count] < 1 || ![self ptracker]){
        NSLog(@"Data objects for installation tracking were not created");
        [self setIncrement:0];
        return;
    }

    phaseTotal = [[self increments][[self currentPhase]] doubleValue];
    if ([[self currentPackage] isEqualToString:@"package"]){
        [self setIncrement:0];
        return;
    }else{
        pkgTotal = [[self ptracker][[self currentPackage]] doubleValue];
    }

    Dprintf(@"Incrementing for prior phase = %d, package = %@", [self currentPhase], [self currentPackage]);
    if (phaseTotal > pkgTotal){
        [self setIncrement:phaseTotal - pkgTotal];
        [self ptracker][[self currentPackage]] = @(phaseTotal);
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
    NSString *best = @"";

    if (![self packageList]){
        NSLog(@"Warning: No package list created; unable to determine current package");
        return best;
    }
    //first see if the line contains any of the names in the package list;
    //if so, return the longest name that matches
    for (NSString *candidate in [self packageList]){
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
                [[self packageList] componentsJoinedByString:@" "]);
        if ([fname length] > 0){
            for (NSString *candidate in [self packageList]){
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

-(FinkOutputSignalType)parseLineOfOutput:(NSString *)line
{
    NSString *sline = [line strip];
    //Read process group id for Launcher
    if (![self pgid] && [line contains:@"PGID="]){
        [self setPgid:[[line substringFromIndex:AFTER_EQUAL_SIGN] integerValue]];
        return PGID;
    }
    //Look for package lists
    if ([self isInstalling] && [self isReadingPackageList]){
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
        [self setReadingPackageList: NO];
        //If we were unable to create a package list, setupInstall returns NO, so that
        //we skip any blocks conditioned on the installing flag
        [self setInstalling: [self setupInstall]];
        //look for prompt or installation event immediately after pkg list
        if ([line containsCompiledExpression:&_prompt]){
            if ([self isInstalling]){
                return PROMPT_AND_START;
            }
            return PROMPT;
        }
        if (FETCHTRIGGER(sline)){
            Dprintf(@"Fetch phase triggered by:\n%@", line);
            [self setIncrementForLastPhase];
            [self setCurrentPackage:[self packageNameFromLine:line]];
            [self setCurrentPhase: FETCH];
            return START_AND_FETCH;
        }
        if (UNPACKTRIGGER(sline)){
            Dprintf(@"Unpack phase triggered by:\n%@", line);
            [self setIncrementForLastPhase];
            [self setCurrentPackage:[self packageNameFromLine:line]];
            [self setCurrentPhase: UNPACK];
            return START_AND_UNPACK;
        }
        if ([line contains: @"dpkg -i"]){
            Dprintf(@"Activate phase triggered by:\n%@", line);
            [self setIncrementForLastPhase];
            [self setCurrentPackage:[self packageNameFromLine:line]];
            [self setCurrentPhase: ACTIVATE];
            return START_AND_ACTIVATE;
        }
        //signal FinkController to start deteriminate PI
        return START_INSTALL;
    }
	if ([self isInstalling]){
		//Look for introduction to package lists
		if (INSTALLTRIGGER(line)){
			Dprintf(@"Package scan triggered by:\n%@", line);
			[self setReadingPackageList: YES];
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
			[self setCurrentPhase: FETCH];
			return FETCH;
		}
		if ([self currentPhase] != UNPACK && UNPACKTRIGGER(sline)){
			Dprintf(@"Unpack phase triggered by:\n%@", line);
			[self setIncrementForLastPhase];
			[self setCurrentPackage:[self packageNameFromLine:line]];
			[self setCurrentPhase: UNPACK];
			return UNPACK;
		}
		if ([self currentPhase] == UNPACK && [sline containsCompiledExpression:&_configure]){
			Dprintf(@"Configure phase triggered by:\n%@", line);
			[self setIncrementForLastPhase];
			[self setCurrentPhase: CONFIGURE];
			return CONFIGURE;
		}
		if ([self currentPhase] != COMPILE && COMPILETRIGGER(sline)){
			Dprintf(@"Compile phase triggered by:\n%@", line);
			[self setIncrementForLastPhase];
			[self setCurrentPhase: COMPILE];
			return COMPILE;
		}
		if ([line contains: @"dpkg-deb -b"]){
			Dprintf(@"Build phase triggered by:\n%@", line);
			//make sure we catch up if this file is archived
			if ([self currentPhase] < 1) [self setCurrentPhase: COMPILE];
			[self setIncrementForLastPhase];
			[self setCurrentPackage:[self packageNameFromLine:line]];
			[self setCurrentPhase: BUILD];
			return BUILD;
		}
		if ([line contains: @"dpkg -i"]){
			Dprintf(@"Activate phase triggered by:\n%@", line);
			if ([self currentPhase] < 1) [self setCurrentPhase: COMPILE];
			[self setIncrementForLastPhase];
			[self setCurrentPackage:[self packageNameFromLine:line]];
			[self setCurrentPhase: ACTIVATE];
			return ACTIVATE;
		}
	}

    //Look for prompts
    if ([line contains: @"Password:"]){
        return PASSWORD_PROMPT;
    }
    if ([line containsCompiledExpression:&_manPrompt]){
        return MANDATORY_PROMPT;
    }
    if ([line containsCompiledExpression:&_prompt] &&
        ! [[self defaults] boolForKey:FinkAlwaysChooseDefaults]){
        Dprintf(@"Found prompt: %@", line);
        return PROMPT;
    }
	if ([line containsCompiledExpression:&_dynamicOutput]){
		return DYNAMIC_OUTPUT;
	}

    //Look for self-repair messages
	//NB:  Find a way to avoid looking for this in every line
	if ([line contains:@"Running self-repair"]){
		[self setSelfRepair: YES];
		return RUNNING_SELF_REPAIR;
	}
	if ([self isSelfRepair]){		
		if ([line contains:@"Self-repair succeeded"]){
			[self setSelfRepair: NO];
			return SELF_REPAIR_COMPLETE;
		}
		if ([line contains:@"Unable to modify Resource directory\n"]){
			[self setSelfRepair: NO];
			return RESOURCE_DIR_ERROR;
		}
		if ([line contains:@"Self-repair failed\n"]){
			[self setSelfRepair: NO];
			return SELF_REPAIR_FAILED;
		}
	}
    return NONE;
}

-(FinkOutputSignalType)parseOutput:(NSString *)output
{
    NSArray *lines = [output componentsSeparatedByString: @"\n"];
    FinkOutputSignalType signal = NONE;  //false when used as boolean value

    for (NSString *line in lines){
        signal = [self parseLineOfOutput:line];
        if (signal) return signal;
    }
    return signal;
}

@end
