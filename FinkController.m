/* 
 File: FinkController.m

See the header file, FinkController.h, for interface and license information.
 
*/

#import "FinkController.h"

//Global variables used in toolbar methods
NSString *FinkInstallSourceItem = @"FinkInstallSourceItem";
NSString *FinkInstallBinaryItem = @"FinkInstallBinaryItem";
NSString *FinkRemoveSourceItem = @"FinkRemoveSourceItem";
NSString *FinkRemoveBinaryItem = @"FinkRemoveBinaryItem";
NSString *FinkDescribeItem = @"FinkDescribeItem";
NSString *FinkSelfUpdateItem = @"FinkSelfUpdateItem";
NSString *FinkSelfUpdateCVSItem = @"FinkSelfUpdateCVSItem";
NSString *FinkUpdateBinaryItem = @"FinkUpdateBinaryItem";
NSString *FinkTerminateCommandItem = @"FinkTerminateCommandItem";
NSString *FinkFilterItem = @"FinkFilterItem";
NSString *FinkInteractItem = @"FinkInteractItem";
NSString *FinkEmailItem = @"FinkEmailItem";


@implementation FinkController

//--------------------------------------------------------------------------------
//		STARTUP AND SHUTDOWN
//--------------------------------------------------------------------------------

//----------------------------------------------->Initialize
+(void)initialize
{
	//set "factory defaults"
	//TBD:  consider putting this stuff in a plist file
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	NSNumber *on = [NSNumber numberWithInt: NSOnState];
	NSNumber *off = [NSNumber numberWithInt: NSOffState];
	
	[defaultValues setObject: @"" forKey: FinkBasePath];
	[defaultValues setObject: @"" forKey: FinkOutputPath];
	[defaultValues setObject: @"name" forKey: FinkSelectedColumnIdentifier];
	[defaultValues setObject: @"" forKey: FinkHTTPProxyVariable];
			
	[defaultValues setObject: [NSNumber numberWithBool: YES] forKey: FinkUpdateWithFink];
	[defaultValues setObject: [NSNumber numberWithBool: YES] forKey: FinkAlwaysScrollToBottom];
	[defaultValues setObject: [NSNumber numberWithBool: YES] forKey: FinkGiveEmailCredit];
	[defaultValues setObject: [NSNumber numberWithBool: YES] forKey: FinkWarnBeforeRemoving];
	[defaultValues setObject: [NSNumber numberWithBool: YES] forKey: FinkPackagesInTitleBar];
	[defaultValues setObject: [NSNumber numberWithBool: YES] forKey: FinkCheckForNewVersion];	

	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkAlwaysChooseDefaults];	
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkBasePathFound];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkScrollToSelection];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkLookedForProxy];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkAskForPasswordOnStartup];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkNeverAskForPassword];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkWarnBeforeRunning];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkAutoExpandOutput];

	[defaultValues setObject: [NSNumber numberWithFloat: 0.50] forKey: FinkOutputViewRatio];
	[defaultValues setObject:
		[NSDictionary dictionaryWithObjectsAndKeys:
			on, @"Version Column", 
			on, @"Installed Column",
			on, @"Binary Column",
			on, @"Unstable Column",
			on, @"Category Column",
			on, @"Description Column",
			off, @"Maintainer Column",
			nil]
		forKey: FinkViewMenuSelectionStates];
	[defaultValues setObject:
		[NSArray arrayWithObjects: @"name", @"version", @"binary", @"unstable",
			@"installed", @"category", @"description", nil]
		forKey: FinkTableColumnsArray];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
}

//----------------------------------------------->Init
-(id)init
{
	if (self = [super init]){
		FinkBasePathUtility *utility;
		NSEnumerator *e;
		NSString *attribute;
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		
		defaults = [NSUserDefaults standardUserDefaults];
			
		[self setWindowFrameAutosaveName: @"MainWindow"];
		[NSApp setDelegate: self];

		//Set base path default, if necessary; write base path into perl script used
		//to obtain fink package data
		utility = [[[FinkBasePathUtility alloc] init] autorelease];
		if (! [defaults boolForKey: FinkBasePathFound]){
			[utility findFinkBasePath];
		}
		[utility fixScript];	
		//Set instance variables used to store information related to fink package data
		packages = [[FinkDataController alloc] init];		// data used in table
		[self setDisplayedPackages: [packages array]];		// modifiable version for filter
		[self setSelectedPackages: nil];    				// used to update package data
		[self setLastCommand: @""];  						// ditto

		//Set instance variables used to display table
		[self setLastIdentifier: [defaults objectForKey: FinkSelectedColumnIdentifier]];
		reverseSortImage = [[NSImage imageNamed: @"reverse"] retain];
		normalSortImage = [[NSImage imageNamed: @"normal"] retain];
		// dictionary used to record whether table columns are sorted in normal or reverse order
		// enables proper sorting behavior; uses macro from FinkPackage to set attributes
		columnState = [[NSMutableDictionary alloc] init];
		e = [[NSArray arrayWithObjects: PACKAGE_ATTRIBUTES, nil] objectEnumerator];
		while (attribute = [e nextObject]){
			[columnState setObject: @"normal" forKey: attribute];
		}
		
		//Set instance variables used to store objects and state information  
		//needed to run fink and apt-get commands
		[self setCommandIsRunning: NO];		
		[self setPassword: nil];
		lastParams = [[NSMutableArray alloc] init];
		[self setPendingCommand: NO];
		
		//Flag used to avoid duplicate warnings when user terminates FC 
		//in middle of command with something other than App:Quit
		userChoseToTerminate = NO;
		
		//Register for notifications that run commands
		//  selector runs command if one is pending and password was entered 
		[center addObserver: self
				selector: @selector(runCommandAfterPasswordEntered:)
				name: @"passwordWasEntered"
				object: nil];
		//  selector runs commands that change the fink.conf file
		[center addObserver: self
				selector: @selector(runFinkConfCommand:)
				name: FinkConfChangeIsPending
				object: nil];
					
		//Register for notification that causes table to update 
		//and resume normal state
		[center addObserver: self
				selector: @selector(resetInterface:)
				name: FinkPackageArrayIsFinished
				object: nil];
					
		//Register for notification that causes output to collapse when
		//user selects the auto expand option
		[center addObserver: self
				selector: @selector(collapseOutput:)
				name: FinkCollapseOutputView
				object: nil];
	}
	return self;
}

//----------------------------------------------->Dealloc
-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[packages release];
	[displayedPackages release];
	[selectedPackages release];
	[preferences release];
	[parser release];
	[lastCommand release];
	[lastIdentifier release];
	[columnState release];
	[reverseSortImage release];
	[normalSortImage release];
	[lastParams release];
	[password release];
	[finkTask release];
	[toolbar release];
	[packageInfo release];
	[super dealloc];
}

//----------------------------------------------->Post-Init Startup
//helpers
-(void)checkForLatestVersion:(BOOL)notifyWhenCurrent
{
	NSString *installedVersion = [[[NSBundle bundleForClass:[self class]]
		infoDictionary] objectForKey:@"CFBundleVersion"];
	NSDictionary *latestVersionDict = 
		[NSDictionary dictionaryWithContentsOfURL:
			[NSURL URLWithString:@"http://finkcommander.sourceforge.net/pages/version.xml"]];
	NSString *latestVersion;	

	if (latestVersionDict){
		latestVersion = [latestVersionDict objectForKey: @"FinkCommander"];
	}else{
		NSRunAlertPanel(@"Error",
			@"FinkCommander was unable to locate on-line update information.\n\nTry visiting the FinkCommander web site (available under the Help menu) to check for a more recent version of FinkCommander.",
			@"OK", nil, nil);
		return;
	}
	if (! [installedVersion isEqualToString: latestVersion]){
		int answer = NSRunAlertPanel(@"Download",
								@"A more current version of FinkCommander (%@) is available.\nWould you like to go to the FinkCommander home page to download it?",
								@"Yes", @"No", nil, latestVersion);
		if (answer == NSAlertDefaultReturn){
			[[NSWorkspace sharedWorkspace] openURL: 
				[NSURL URLWithString: 
					[NSString stringWithFormat:
					@"http://finkcommander.sourceforge.net",
					latestVersion]]];
		}
	}else if (notifyWhenCurrent){
		NSRunAlertPanel(@"Current",
				  @"The latest version of FinkCommander is installed on your system.",
				  @"OK", nil, nil);
	}
}

-(void)awakeFromNib
{
	NSDictionary *selStates = [defaults objectForKey: FinkViewMenuSelectionStates];
	NSEnumerator *e = [selStates keyEnumerator];
	NSString *key;

	NSSize contentSize = [tableScrollView contentSize];

	tableView = [[FinkTableViewController alloc] initWithFrame:
		NSMakeRect(0, 0, contentSize.width, contentSize.height)];
	[tableScrollView setDocumentView: tableView];
	[tableView release];
	[tableView setDelegate: self];
	[tableView setDataSource: self];
	[tableView sizeLastColumnToFit];
	[tableView setMenu: tableContextMenu];

	while (key = [e nextObject])
	{
		int menuState = [[selStates objectForKey: key] intValue];
		[[viewMenu itemWithTitle: key] setState: menuState];
	}
		
	[self setupToolbar];

	if ([defaults boolForKey: FinkAutoExpandOutput]){
		[self collapseOutput: nil];
	}else{
		[self expandOutput: nil];
	}
	[msgText setStringValue:
		@"Updating table dataÉ"];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSTableColumn *lastColumn = [tableView tableColumnWithIdentifier:
		[self lastIdentifier]];
				
	if (! [defaults boolForKey: FinkBasePathFound]){
		NSBeginAlertSheet(@"Unable to Locate Fink",	@"OK", nil,	nil, //title, buttons
				[self window], self, NULL,	NULL, nil, //window, delegate, selectors, c info
				@"Try setting the path to Fink manually in Preferences.", nil);
	}
	
	[self updateTable:nil];
	[tableView setHighlightedTableColumn:lastColumn];
	[tableView setIndicatorImage:normalSortImage inTableColumn:lastColumn];
	if ([defaults boolForKey:FinkAskForPasswordOnStartup]){
		[self raisePwdWindow:self];
	}
}

//helper used in several methods
-(void)displayNumberOfPackages
{	
	if ([defaults boolForKey: FinkPackagesInTitleBar]){				
		[[self window] setTitle: [NSString stringWithFormat: 
			@"Packages: %d Displayed, %d Installed",
			[[self displayedPackages] count], [packages installedPackagesCount]]];
		if (! [self commandIsRunning]){
			[msgText setStringValue: @"Done"];
		}
	}else if (! [self commandIsRunning]){
		[[self window] setTitle: @"FinkCommander"];
		[msgText setStringValue: [NSString stringWithFormat:
			@"%d packages (%d installed)",
			[[self displayedPackages] count], [packages installedPackagesCount]]];
	}
}

//--------------------------------------------------------------------------------
//		ACCESSORS
//--------------------------------------------------------------------------------

-(FinkDataController *)packages  {return packages;}

-(NSMutableArray *)displayedPackages {return displayedPackages;}
-(void)setDisplayedPackages:(NSMutableArray *)a
{
	[a retain];
	[displayedPackages release];
	displayedPackages = a;
}

-(NSArray *)selectedPackages {return selectedPackages;}
-(void)setSelectedPackages:(NSArray *)a
{
	[a retain];
	[selectedPackages release];
	selectedPackages = a;
}

-(NSString *)lastCommand {return lastCommand;}
-(void)setLastCommand:(NSString *)s
{
	[s retain];
	[lastCommand release];
	lastCommand = s;	
}

-(NSString *)lastIdentifier {return lastIdentifier;}
-(void)setLastIdentifier:(NSString *)s
{
	[s retain];
	[lastIdentifier release];
	lastIdentifier = s;
}

-(BOOL)commandIsRunning {return commandIsRunning;}
-(void)setCommandIsRunning:(BOOL)b{
	commandIsRunning = b;
}

-(NSString *)password {return password;}
-(void)setPassword:(NSString *)s
{
	[s retain];
	[password release];
	password = s;
}

-(NSMutableArray *)lastParams {return lastParams;}
-(void)setLastParams:(NSMutableArray *)a
{
	[lastParams removeAllObjects];
	[lastParams addObjectsFromArray: a];
}

-(BOOL)pendingCommand {return pendingCommand;}
-(void)setPendingCommand:(BOOL)b
{
	pendingCommand = b;
}

-(NSArray *)selectedObjectInfo
{
    return selectedObjectInfo;
}

-(void)setSelectedObjectInfo:(NSArray *)array
{
    [array retain];
    [selectedObjectInfo release];
    selectedObjectInfo = array;
}

-(void)setParser:(FinkOutputParser *)p
{
    [p retain];
    [parser release];
    parser = p;
}


//not really an accessor, but it needs to go somewhere
-(NSArray *)selectedPackageArray
{
	NSEnumerator *e = [tableView selectedRowEnumerator];
	NSNumber *anIndex;
	NSMutableArray *pkgArray = [NSMutableArray arrayWithCapacity: 5];

	while (anIndex = [e nextObject]){
		[pkgArray addObject:
			[[self displayedPackages] objectAtIndex: [anIndex intValue]]];
	}
	return pkgArray;
}

//--------------------------------------------------------------------------------
//		APPLICATION AND WINDOW DELEGATES
//--------------------------------------------------------------------------------

//warn before quitting if a command is running
-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	int answer;
	
	if ([self commandIsRunning] && ! userChoseToTerminate){
		answer = NSRunCriticalAlertPanel(@"Warning!", 
			@"Quitting now will interrupt a Fink process.",
			@"Cancel", @"Quit", nil);
		if (answer == NSAlertDefaultReturn){
			return NO;
		}
	}
	return YES;
}

//since this is a single window app, quit when window closes
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

//but warn before closing window if a command is running
-(BOOL)windowShouldClose:(id)sender
{
	if ([self commandIsRunning]){
		int answer = NSRunCriticalAlertPanel(@"Warning!",
				@"Quitting now will interrupt a Fink process.",
				@"Cancel", @"Quit", nil);
		if (answer == NSAlertDefaultReturn){
			return NO;
		}
	}
	userChoseToTerminate = YES;
	return YES;
}

//--------------------------------------------------------------------------------
//		MENU COMMANDS AND HELPERS
//--------------------------------------------------------------------------------

//----------------------------------------------->Helpers

//display running command below table
-(void)displayCommand:(NSArray *)params
{
	[msgText setStringValue: [NSString stringWithFormat: @"Running %@É",
		[params componentsJoinedByString: @" "]]];
}

//set up the argument list and flags for either command method
-(NSMutableArray *)setupCommandFrom:(id)sender
{
	NSString *cmd; 
	NSString *executable;
	NSMutableArray *args;

	//determine command
	if ([sender isKindOfClass: [NSMenuItem class]]){
		cmd = [[sender title] lowercaseString];
	}else{
		cmd = [[[[sender label] componentsSeparatedByString:@" "] 
			objectAtIndex: 0] lowercaseString];
	}	

	//determine executable
	executable = ([sender tag] == SOURCE_COMMAND ? @"fink" : @"apt-get");
	args = [NSMutableArray arrayWithObjects: executable, cmd, nil];
	
	[self setCommandIsRunning: YES];
	[self setLastCommand: cmd];
	return args;
}

-(void)startProgressIndicatorAsIndeterminate:(BOOL)b
{
    [progressIndicator setIndeterminate:b];
    if (! [progressView isDescendantOf: progressViewHolder]){
		[progressViewHolder addSubview: progressView];
		[progressIndicator setUsesThreadedAnimation: YES];
		[progressIndicator startAnimation: nil];
    }else{
		;
#ifdef DEBUG
		NSLog(@"Called start PI while PI still running");
#endif //DEBUG
    }
}

-(void)stopProgressIndicator
{
    if ([progressView isDescendantOf: progressViewHolder]){
		[progressIndicator stopAnimation: nil];
		[progressView removeFromSuperview];
    }else{
#ifdef DEBUG
		NSLog(@"Called stop PI when PI not running");
#endif //DEBUG
    }
}

//----------------------------------------------->Menu Actions

-(IBAction)checkForLatestVersionAction:(id)sender
{
	[self checkForLatestVersion:YES];
}


-(IBAction)saveOutput:(id)sender
{
	NSSavePanel *panel = [NSSavePanel savePanel];
	NSString *defaultPath = [defaults objectForKey: FinkOutputPath];
	NSString *savePath = ([defaultPath length] > 0) ? defaultPath : NSHomeDirectory();
	NSString *fileName = [NSString stringWithFormat: @"%@_%@", 
			[self lastCommand], 
			[[NSDate date] descriptionWithCalendarFormat: @"%d%b%Y" timeZone: nil locale: nil]];
	
	[panel setRequiredFileType: @"txt"];
	
	[panel beginSheetForDirectory: savePath
		file: fileName
		modalForWindow: [self window]
		modalDelegate: self
		didEndSelector: @selector(didEnd:returnCode:contextInfo:)
		contextInfo: nil];
}

-(void)didEnd:(NSSavePanel *)sheet
	  returnCode:(int)code
	 contextInfo:(void *)contextInfo
{
	if (code = NSOKButton){
		NSData *odata = [[textView string] dataUsingEncoding: NSUTF8StringEncoding];
		[odata writeToFile: [sheet filename] atomically: YES];
	}
}

//run package-specific command with arguments derived from table selection
-(IBAction)runCommand:(id)sender
{
	NSMutableArray *args = [self setupCommandFrom: sender];
	NSMutableArray *pkgNames = [NSMutableArray arrayWithCapacity: 5];
	FinkPackage *pkg;
	NSEnumerator *e = [[self selectedPackageArray] objectEnumerator];

	while (pkg = [e nextObject]){
		[pkgNames addObject: [pkg name]];
	}
	
	//set up selectedPackages array for later use
	[self setSelectedPackages: pkgNames];

	//set up args array to run the command
	[args addObjectsFromArray: pkgNames];
	
	[self displayCommand: args];		
	[self runCommandWithParameters: args];
}

//run non-package-specific command; ignore table selection
-(IBAction)runUpdater:(id)sender
{
	NSMutableArray *args = [self setupCommandFrom: sender];
	
	[self displayCommand: args];	
	[self runCommandWithParameters: args];
}

-(IBAction)terminateCommand:(id)sender
{
	FinkProcessKiller *terminator = [[[FinkProcessKiller alloc] init] autorelease];
	int answer1 = NSRunAlertPanel(@"Caution",
			@"The terminate command will kill the current process without giving it the opportunity to run any clean-up routines.\nWhat would you like to do?",
			@"Terminate", @"Continue", nil);

	if (answer1 == NSAlertDefaultReturn){
		[terminator terminateChildProcesses];

		sleep(1);

		if ([[finkTask task] isRunning]){
			int answer2 = NSRunAlertPanel(@"Sorry",
					@"The current process is not responding to the terminate command.\nThe only way to stop it is to quit FinkCommander and run ps and sudo kill from the Terminal (see help for more details).\nWhat would you like to do?",
					@"Quit", @"Continue", nil);
			if (answer2 == NSAlertDefaultReturn){
				userChoseToTerminate = YES;
				[NSApp terminate: self];
			}
		}
	}
}

//update table using Fink
-(IBAction)updateTable:(id)sender
{	
	[self startProgressIndicatorAsIndeterminate:YES];
	[msgText setStringValue: @"Updating table dataÉ"]; 
	[self setCommandIsRunning: YES];
	[packages update]; //calls resetInterface by notification
}

-(IBAction)showDescription:(id)sender
{
	NSEnumerator *e = [[self selectedPackageArray] objectEnumerator];
	int i = 0;
	FinkPackage *pkg;
	NSString *full = nil;
	NSString *divider = @"____________________________________________________\n\n";

	[textView setString: @""];

	while (pkg = [e nextObject]){
		full = [NSString stringWithFormat: @"%@-%@:   %@\n",
			[pkg name],
			[pkg version],
			[pkg fulldesc]];
		if (i > 0){
			[[textView textStorage] appendAttributedString:
				[[[NSAttributedString alloc] initWithString: divider] autorelease]];
		}
		[[textView textStorage] appendAttributedString:
			[[[NSAttributedString alloc] initWithString: full] autorelease]];
		i++;
	}
}

-(IBAction)showPackageInfoPanel:(id)sender
{
	FinkInstallationInfo *info = [[[FinkInstallationInfo alloc] init] autorelease];
	NSString *sig = [info getInstallationInfo];

	if (!packageInfo){
		packageInfo = [[FinkPackageInfo alloc] init];
	}
	
	[packageInfo setEmailSig: sig];
	[[packageInfo window] zoom: nil];
	[packageInfo showWindow: self];
	[packageInfo displayDescriptions: [self selectedPackageArray]];
}

-(IBAction)showPreferencePanel:(id)sender
{
	if (!preferences){
		preferences = [[FinkPreferences alloc] init];
	}
	[preferences showWindow: self];
}

-(IBAction)chooseTableColumn:(id)sender
{
	int loc = [[sender title] rangeOfString: @" "].location;
	NSString *columnIdentifier = 
		[[[sender title] substringWithRange: NSMakeRange(0, loc)] lowercaseString];
	NSMutableDictionary *selStates = [[defaults objectForKey: FinkViewMenuSelectionStates] mutableCopy];
	NSDictionary *immutable;
	int newState = ([sender state] == NSOnState ? NSOffState : NSOnState);

	if (newState == NSOnState){
		[tableView addColumnWithName: columnIdentifier];
	}else{
		[tableView removeColumnWithName: columnIdentifier];
	}
		
	[sender setState: newState];
	[selStates setObject: [NSNumber numberWithInt: newState] forKey: [sender title]];
	immutable = selStates;
	[defaults setObject: immutable forKey: FinkViewMenuSelectionStates];
}

//help menu internet access items
-(IBAction)internetAccess:(id)sender
{
	NSString *url = nil;

	switch ([sender tag]){
		case FCWEB:
			url = @"http://finkcommander.sourceforge.net/";
			break;
		case FCBUG:
			url = @"http://sourceforge.net/tracker/?group_id=48896&atid=454467";
			break;
		case FINKDOC:
			url = @"http://fink.sourceforge.net/doc/index.php";
			break;
	}
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: url]];
}

-(IBAction)emailMaintainer:(id)sender
{
	NSEnumerator *e = [[self selectedPackageArray] objectEnumerator];
	FinkInstallationInfo *info = [[[FinkInstallationInfo alloc] init] autorelease];
	NSString *sig = [info getInstallationInfo];
	FinkPackage *pkg;

	if (!packageInfo){
		packageInfo = [[FinkPackageInfo alloc] init];
	}

	[packageInfo setEmailSig: sig];
	while (pkg = [e nextObject]){
		[packageInfo sendEmailForPackage: pkg];
	}
}


-(IBAction)collapseOutput:(id)sender
{
	if (! [splitView isSubviewCollapsed: outputScrollView]){
		NSRect oFrame = [outputScrollView frame];
		NSRect tFrame = [tableScrollView frame];
		NSRect sFrame = [splitView frame];
		float divwidth = [splitView dividerThickness];

		[defaults setFloat: (oFrame.size.height / sFrame.size.height)
							 forKey: FinkOutputViewRatio];
		tFrame.size.height = sFrame.size.height - divwidth;
		oFrame.size.height = 0.0;
		oFrame.origin.y = sFrame.size.height;

		[outputScrollView setFrame: oFrame];
		[tableScrollView setFrame: tFrame];

		[splitView setNeedsDisplay: YES];
	}
}

//work in progress:  attempt to make splitview slide down when it collapses
//so far any combination of increments and timing I try results in very jerky motion
#ifdef UNDEF
-(IBAction)collapseOutput:(id)sender
{	
	NSRect oFrame = [outputScrollView frame];
	NSRect sFrame = [splitView frame];
	float increment = oFrame.size.height / 5;
	NSDictionary *d = [NSDictionary dictionaryWithObject: [NSNumber numberWithFloat: increment]
									forKey: @"theIncrement"];
									
	if ([splitView isSubviewCollapsed: outputScrollView]) return;

	[defaults setFloat: (oFrame.size.height / sFrame.size.height)
					forKey: FinkOutputViewRatio];
	timer = [[NSTimer scheduledTimerWithTimeInterval: 0.1
						target: self
						selector: @selector(collapseByIncrements:)
						userInfo: d
						repeats: YES] retain];
}

-(void)collapseByIncrements:(NSTimer *)t
{
	NSRect oFrame = [outputScrollView frame];
	NSRect tFrame = [tableScrollView frame];
	float maxTFrameHeight = [splitView frame].size.height - [splitView dividerThickness];
	float increment = [[[t userInfo] objectForKey: @"theIncrement"] floatValue];
	
	tFrame.size.height = tFrame.size.height + increment;
	oFrame.size.height = oFrame.size.height - increment;

	if (oFrame.size.height <= 0 || tFrame.size.height >= maxTFrameHeight){
		oFrame.size.height = 0;
		tFrame.size.height = maxTFrameHeight;
		[timer invalidate];
		[timer release];
	}
	
	//need to set oFrame.origin.y
	
	[outputScrollView setFrame: oFrame];
	[tableScrollView setFrame: tFrame];
	[splitView setNeedsDisplay: YES];	
}
#endif //UNDEF

-(IBAction)expandOutput:(id)sender
{
	NSRect oFrame = [outputScrollView frame];
	NSRect tFrame = [tableScrollView frame];
	NSRect sFrame = [splitView frame];
	float divwidth = [splitView dividerThickness];

	oFrame.size.height = ceil(sFrame.size.height * [defaults floatForKey: FinkOutputViewRatio]);
	tFrame.size.height = sFrame.size.height - oFrame.size.height - divwidth;
	oFrame.origin.y = tFrame.size.height + divwidth;

	[outputScrollView setFrame: oFrame];
	[tableScrollView setFrame: tFrame];

	[splitView setNeedsDisplay: YES];
}

//----------------------------------------------->Menu Item Delegate
//Helper for menu item and toolbar item validators
-(BOOL)validateItem:(id)theItem
{
	//disable package-specific commands if no row selected
	if ([tableView selectedRow] == -1 						&&
	    ([theItem action] == @selector(runCommand:)  		||
		 [theItem action] == @selector(showDescription:)	||
		 [theItem action] == @selector(emailMaintainer:))){
		return NO;
	}
	//disable Source and Binary menu items and table update if command is running
	if ([self commandIsRunning] &&
		([theItem action] == @selector(runCommand:) 		||
		 [theItem action] == @selector(runUpdater:) 		||
		 [theItem action] == @selector(showDescription:)	||
		 [theItem action] == @selector(saveOutput:)			||
		 [theItem action] == @selector(updateTable:))){
		return  NO;
	}
	if (! [self commandIsRunning] &&
	 ([theItem action] == @selector(raiseInteractionWindow:) ||
		 [theItem action] == @selector(terminateCommand:))){
		return NO;
	}
	return YES;
}

//Disable menu items
-(BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	return [self validateItem: menuItem];
}


//--------------------------------------------------------------------------------
//		TOOLBAR METHODS
//--------------------------------------------------------------------------------

-(void)setupToolbar
{
    toolbar = [[NSToolbar alloc] initWithIdentifier: @"mainToolbar"];
    [toolbar setDelegate: self];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
	[toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    [[self window] setToolbar: toolbar]; 
}

//reapply filter if popup selection changes
-(IBAction)refilter:(id)sender
{	
	[searchTextField selectText: nil];
	[self controlTextDidChange: nil];
}

//----------------------------------------------->Delegate Methods
-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar
	   itemForItemIdentifier:(NSString *)itemIdentifier
   willBeInsertedIntoToolbar:(BOOL)flag
{
	NSBundle *b = [NSBundle mainBundle];
	NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:
				    [b pathForResource: @"Toolbar"
								ofType: @"plist"]];
	NSDictionary *itemDict;
	NSString *value;
	NSNumber *tag;
	NSToolbarItem *item = [[NSToolbarItem alloc]
			  initWithItemIdentifier: itemIdentifier];
			  
	itemDict = [d objectForKey: itemIdentifier];
	if (value = [itemDict objectForKey: @"Label"]){
		[item setLabel: value];
		[item setPaletteLabel: value];
	}
	if (value = [itemDict objectForKey: @"PaletteLabel"]) 
		[item setPaletteLabel: value];
	if (value = [itemDict objectForKey: @"ToolTip"]) 
		[item setToolTip: value];
	if (value = [itemDict objectForKey: @"Image"]) 
		[item setImage: [NSImage imageNamed: value]];
	if (value = [itemDict objectForKey: @"Action"]){
		[item setTarget: self];
		[item setAction: NSSelectorFromString([NSString 
			stringWithFormat: @"%@:", value])];
	}
	if (tag = [itemDict objectForKey: @"Tag"]){
		[item setTag: [tag intValue]];
	}
	if ([itemIdentifier isEqualToString: FinkFilterItem]){
		[item setView: searchView];
		[item setMinSize:NSMakeSize(204, NSHeight([searchView frame]))];
		[item setMaxSize:NSMakeSize(400, NSHeight([searchView frame]))];
	}
	return [item autorelease];
}

-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects: 
		NSToolbarSeparatorItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarCustomizeToolbarItemIdentifier,
		FinkInstallSourceItem,
		FinkInstallBinaryItem,
		FinkRemoveSourceItem,
		FinkRemoveBinaryItem,
		FinkSelfUpdateItem,
		FinkSelfUpdateCVSItem,
		FinkUpdateBinaryItem,
		FinkDescribeItem,
		FinkInteractItem,
		FinkTerminateCommandItem,
		FinkEmailItem,
		FinkFilterItem,
		nil];
}

-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:
		FinkInstallSourceItem,
		FinkInstallBinaryItem,
		FinkRemoveSourceItem,
		FinkSelfUpdateCVSItem,
		NSToolbarSeparatorItemIdentifier,
		FinkTerminateCommandItem,
		FinkDescribeItem,
		FinkEmailItem,
		NSToolbarFlexibleSpaceItemIdentifier,
		FinkFilterItem,
		nil];
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	return [self validateItem: theItem]; //helper preceding menu item validator
}

//START OF SCROLLING AND SORTING METHODS

//----------------------------------------------->Text Field Delegate

//The following two methods are used in the filter delegate method and the 
//didClickTableColumn method to scroll back to the previously selected row
//after the table is sorted.  It works almost the same way Mail does, except
//that only the latest selection is preserved.  For the filter, sorting and
//scrolling methods to work together, information on the selected object must
//be stored and then the rows must be deselected before the filter is applied 
//and before the table is sorted.

//TBD:  Store package and offset for each selected row; in scrollToSelectedObject
//iterate through array of stored information; select each package still found
//in table; scroll to the first package found.  This will duplicate Mail.

//store information needed to scroll back to selection after filter/sort
-(void)storeSelectedObjectInfo
{
	FinkPackage *selectedObject;
    int selectionIndex = [tableView selectedRow];
	int topRowIndex =  [tableView rowAtPoint:
		[[tableView superview] bounds].origin];
	int offset = selectionIndex - topRowIndex;

	if (selectionIndex >= 0){
		selectedObject = [[self displayedPackages]
							objectAtIndex: selectionIndex];
		[self setSelectedObjectInfo:
			[NSArray arrayWithObjects:
				selectedObject,
				[NSNumber numberWithInt: offset],
				nil]];
		[tableView deselectAll: self];
	}else{
		[self setSelectedObjectInfo: nil];
	}
}

//scroll back to selection after sort
-(void)scrollToSelectedObject
{
	if ([self selectedObjectInfo]){
		FinkPackage *selectedObject = [[self selectedObjectInfo] objectAtIndex: 0];
		int selection = [[self displayedPackages] indexOfObject: selectedObject];

		if (selection != NSNotFound){
			int offset = [[[self selectedObjectInfo] objectAtIndex: 1] intValue];
			NSPoint offsetRowOrigin = [tableView rectOfRow: selection - offset].origin;
			NSClipView *contentView = [tableView superview];
			NSPoint target = [contentView constrainScrollPoint: offsetRowOrigin];

			[contentView scrollToPoint: target];
			[tableScrollView reflectScrolledClipView: contentView];
			[tableView selectRow: selection byExtendingSelection: NO];
		}
	}
}

//called by delegate method; much simpler than the didClickTableColumn delegate method,
//because there is no need to record and adjust sort direction or visual indicators
-(void)resortTableAfterFilter
{
	NSTableColumn *lastColumn = [tableView tableColumnWithIdentifier:
		[self lastIdentifier]];
	NSString *direction = [columnState objectForKey: [self lastIdentifier]];

	[tableView sortTableAtColumn: lastColumn inDirection: direction];
}

//Delegate method:  filters data source each time the filter text field changes
-(void)controlTextDidChange:(NSNotification *)aNotification
{
	if ([[aNotification object] tag] == FILTER){
		NSString *field = [[[searchPopUpButton selectedItem] title] lowercaseString];
		NSString *filterText = [[searchTextField stringValue] lowercaseString];
		NSString *pkgAttribute;
		NSMutableArray *subset = [NSMutableArray array];
		NSEnumerator *e = [[packages array] objectEnumerator];
		FinkPackage *pkg;

		//store selected object information before the filter is applied
		if ([defaults boolForKey: FinkScrollToSelection]){
			[self storeSelectedObjectInfo];
		}
		
		if ([filterText length] == 0){
			[self setDisplayedPackages: [packages array]];
		}else{
			while (pkg = [e nextObject]){
				pkgAttribute = [[pkg performSelector: NSSelectorFromString(field)] lowercaseString];
				if ([pkgAttribute contains: filterText]){
					[subset addObject: pkg];
				}
			}
			[self setDisplayedPackages: subset];
		}
		[self resortTableAfterFilter];

		//restore the selection and scroll back to it after the table is sorted
		if ([defaults boolForKey: FinkScrollToSelection]){
			[self scrollToSelectedObject];
		}

		[self displayNumberOfPackages];

	}else if ([[aNotification object] tag] == INTERACTION){		
		if ([[interactionField stringValue] length]){
			[interactionMatrix selectCellWithTag: USER_CHOICE];
		}else{
			[interactionMatrix selectCellWithTag: DEFAULT];
		}
	}	
}

//--------------------------------------------------------------------------------
//		TABLE METHODS
//--------------------------------------------------------------------------------

//----------------------------------------------->Delegate Methods
//sorts table when column header is clicked
-(void)tableView:(NSTableView *)aTableView
	didClickTableColumn:(NSTableColumn *)aTableColumn
{
	NSString *identifier = [aTableColumn identifier];
	NSTableColumn *lastColumn = [tableView tableColumnWithIdentifier:
		[self lastIdentifier]];
	NSString *direction;

	// remove sort direction indicator from last selected column
	[tableView setIndicatorImage: nil inTableColumn: lastColumn];
	
	// if user clicks same column header twice in a row, change sort order
	if ([aTableColumn isEqualTo: lastColumn]){
		direction = [[columnState objectForKey: identifier] isEqualToString: @"normal"]
					? @"reverse" : @"normal";
		//record new state for next click on this column
		[columnState setObject: direction forKey: identifier];
	// otherwise, return sort order to previous state for selected column
	}else{
		direction = [columnState objectForKey: identifier];
	}

	// record currently selected column's identifier for next call to method
	// and for future sessions
	[self setLastIdentifier: identifier];
	[defaults setObject: identifier forKey: FinkSelectedColumnIdentifier];

	// reset visual indicators
	if ([direction isEqualToString: @"reverse"]){
		[tableView setIndicatorImage: reverseSortImage
				 inTableColumn: aTableColumn];
	}else{
		[tableView setIndicatorImage: normalSortImage
				 inTableColumn: aTableColumn];
	}
	[tableView setHighlightedTableColumn: aTableColumn];
	
	//sort the table contents
	if ([defaults boolForKey: FinkScrollToSelection]){
		[self storeSelectedObjectInfo];
	}	
	[tableView sortTableAtColumn: aTableColumn inDirection: direction];
	if ([defaults boolForKey: FinkScrollToSelection]){
		[self scrollToSelectedObject];
	}
}

//END OF SCROLLING AND SORTING METHODS

-(BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	if ([[[[self displayedPackages] objectAtIndex: rowIndex] name] contains: @"tcsh"]){
		NSBeginAlertSheet(@"Sorry",	@"OK", nil,	nil, 
				[self window], self, NULL,	NULL, nil,
					@"FinkCommander is unable to install tcsh.\nSee Help:FinkCommander Help:Known Bugs and Limitations",
					nil);
		return NO;
	}
	return YES;
}

//allows selection of table cells for copying, unlike setting the column to be non-editable
-(BOOL)textShouldBeginEditing:(NSText *)textObject
{
	return NO;
}

-(void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if (packageInfo && [[packageInfo window] isVisible]){
		[packageInfo displayDescriptions: [self selectedPackageArray]];
	}
}

//----------------------------------------------->Data Source Methods

-(int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[self displayedPackages] count];
}

-(id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			  row:(int)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	FinkPackage *package = [[self displayedPackages] objectAtIndex: rowIndex];
	return [package valueForKey: identifier];
}

//--------------------------------------------------------------------------------
//		SPLITVIEW DELEGATE METHOD(S)
//--------------------------------------------------------------------------------

//records ratio of textview/splitview so that splitview can be reset on startup
-(void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
	NSRect oFrame = [outputScrollView frame];
	NSRect sFrame = [splitView frame];

	[defaults setFloat: (oFrame.size.height / sFrame.size.height)
							forKey: FinkOutputViewRatio];
}

//--------------------------------------------------------------------------------
//		AUTHENTICATION AND PROCESS CONTROL
//--------------------------------------------------------------------------------

//----------------------------------------------->Password Entry Sheet Methods

-(IBAction)raisePwdWindow:(id)sender
{
	[NSApp beginSheet: pwdWindow
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo: nil];
}

-(IBAction)endPwdWindow:(id)sender
{
	[pwdWindow orderOut: sender];
	[NSApp endSheet:pwdWindow returnCode: 1];
}

-(void)sheetDidEnd:(NSWindow *)sheet
			  returnCode:(int)returnCode
			 contextInfo:(void *)contextInfo
{
	[self setPassword: [NSString stringWithFormat:
		@"%@\n", [pwdField stringValue]]];
	[[NSNotificationCenter defaultCenter] 
		postNotificationName: @"passwordWasEntered"
		object: nil];
	if (passwordError && [[finkTask task] isRunning]){
		[finkTask writeToStdin: [self password]];
	}
}

//----------------------------------------------->Interaction Sheet Methods

-(IBAction)raiseInteractionWindow:(id)sender
{
	if ([defaults boolForKey: FinkAutoExpandOutput]){
		[self expandOutput: nil];
	}
	[NSApp beginSheet: interactionWindow
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(interactionSheetDidEnd:returnCode:contextInfo:)
		  contextInfo: nil];
}

-(IBAction)endInteractionWindow:(id)sender
{
	int returnValue = [sender tag];  // 1 for Submit, 0 for Cancel
	[interactionWindow orderOut: sender];
	[NSApp endSheet:interactionWindow returnCode: returnValue];
}

-(void)interactionSheetDidEnd:(NSWindow *)sheet
				   returnCode:(int)returnCode
						contextInfo:(void *)contextInfo
{
	NSAttributedString *areturn = [[[NSAttributedString alloc]
		initWithString: @"\n"] autorelease];

	if (returnCode){  // Submit rather than Cancel
		if ([[interactionMatrix selectedCell] tag] == 0){
			[finkTask writeToStdin: @"\n"];
		}else{
			[finkTask writeToStdin: [NSString stringWithFormat: @"%@\n",
				[interactionField stringValue]]];
		}
		[[textView textStorage] appendAttributedString: areturn];
		if ([defaults boolForKey: FinkAutoExpandOutput]){
			[self collapseOutput: nil];
		}
	}
}

//----------------------------------------------->Process Commands

-(void)runCommandWithParameters:(NSMutableArray *)params
{
	NSString *executable = [params objectAtIndex: 0];
	NSMutableDictionary *d;
	NSString *proxy;
	NSString *basePath = [defaults objectForKey: FinkBasePath];
	NSString *binPath = [basePath stringByAppendingPathComponent: @"/bin"];
	char *proxyEnv;

	passwordError = NO;

	if ([[self password] length] < 1 && 
		! [defaults boolForKey: FinkNeverAskForPassword]){
		
		[self raisePwdWindow: self];
		[self setLastParams: params];
		[self setPendingCommand: YES];
		[self setCommandIsRunning: NO];
		[self displayNumberOfPackages];
		return;
	}
	if ([defaults boolForKey: FinkWarnBeforeRunning]){
		int answer = NSRunAlertPanel(@"Just Checking", 
			@"Are you sure you want to run this command:\n%@?",
			@"Yes", @"No", nil, 
			[params componentsJoinedByString: @" "]);

		if (answer == NSAlertAlternateReturn){
			[self setCommandIsRunning: NO];
			[self displayNumberOfPackages];
			return;
		}
	}
	if ([[params objectAtIndex: 1] isEqualToString: @"remove"] && 
		[defaults boolForKey: FinkWarnBeforeRemoving]){
		int answer = NSRunCriticalAlertPanel(@"Caution",
			@"Are you certain you want to remove the selected packages?\n(You can turn this warning  off in Preferences:Uniphobe or by pressing \"Remove/Don't Warn\".)",
			@"Don't Remove", @"Remove",  @"Remove/Don't Warn");
		switch(answer){
			case NSAlertDefaultReturn:
				[self setCommandIsRunning: NO];
				[self displayNumberOfPackages];
				return;
			case NSAlertOtherReturn:
				[defaults setBool: NO forKey: FinkWarnBeforeRemoving];
				if (preferences){
					[preferences setWarnBeforeRemovingButtonState: NO];
				}
				break;
		}
	}
	if ([defaults boolForKey: FinkAutoExpandOutput]){
		[self startProgressIndicatorAsIndeterminate:YES];
	}
	//set up launch path and arguments array
	[params insertObject: @"/usr/bin/sudo" atIndex: 0];
	[params insertObject: @"-S" atIndex: 1];
	if ([defaults boolForKey: FinkAlwaysChooseDefaults] &&
		([executable isEqualToString: @"fink"] 			||
		 [executable isEqualToString: @"apt-get"])){
		[params insertObject: @"-y" atIndex: 3];
	}
	//give apt-get a chance to fix broken dependencies
	if ([executable isEqualToString: @"apt-get"]){
		[params insertObject: @"-f" atIndex: 3];
	}

#ifdef DEBUG	
	NSLog(@"Command = %@", [params componentsJoinedByString: @" "]);
#endif //DEBUG
	
	//set up environment variables for task
	d = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			[NSString stringWithFormat:
				@"/%@:/%@/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:",
				binPath, basePath],
			@"PATH",
			[NSString stringWithFormat: @"%@/lib/perl5", basePath],
			@"PERL5LIB",
			@"ssh",
			@"CVS_RSH",
		nil];
	proxy = [defaults objectForKey: FinkHTTPProxyVariable];
	if ([proxy length] > 0){
		[d setObject: proxy forKey: @"http_proxy"];
	}else if (! [defaults boolForKey: FinkLookedForProxy]){
		if (proxyEnv = getenv("http_proxy")){
			proxy = [NSString stringWithCString: proxyEnv];
			[d setObject: proxy  forKey: @"http_proxy"];
			[defaults setObject: proxy forKey: FinkHTTPProxyVariable];
		}
		[defaults setBool: YES forKey: FinkLookedForProxy];
	}
		
	[self setPendingCommand: NO];

	if (finkTask) [finkTask release];
	finkTask = [[IOTaskWrapper alloc] initWithController: self];
	[finkTask setEnvironmentDictionary: d];

	// start the process asynchronously
	[finkTask startProcessWithArgs: params];
}

//if last command was not completed because no valid password was entered,
//run it again after receiving passwordWasEntered notification;
-(void)runCommandAfterPasswordEntered:(NSNotification *)note
{
	if ([self pendingCommand]){
		[self setCommandIsRunning: YES];
		[self displayCommand: [self lastParams]];
		[self runCommandWithParameters: [self lastParams]];
	}
}

//run commands to change fink.conf file after FinkConf object posts a notification
-(void)runFinkConfCommand:(NSNotification *)note
{
	NSMutableArray *args = [note object];
	NSString *cmd = [args objectAtIndex: 0];

	if ([self commandIsRunning]){
		NSRunAlertPanel(@"Sorry",
			@"You will have to wait until the current command is complete before changing the fink.conf settings.",
			@"OK", nil, nil);									 
			[preferences setFinkConfChanged: nil]; //action method; sets to YES
		return;
	}
	[self startProgressIndicatorAsIndeterminate:YES];	

	[self setLastCommand: 
		([cmd contains: @"fink"] ? [args objectAtIndex: 1] : cmd)];
	[self setCommandIsRunning: YES];
	passwordError = NO;
	[msgText setStringValue: @"Updating fink.conf file"];
	[self performSelector:@selector(runCommandWithParameters:) withObject: args afterDelay: 1.0];
}

//----------------------------------------------->IOTaskWrapper Protocol Implementation

-(void)scrollToVisible:(NSNumber *)n
{
	if ([n floatValue] <= 100.0 || 
		[defaults boolForKey: FinkAlwaysScrollToBottom]){
		[textView scrollRangeToVisible:	
			NSMakeRange([[textView string] length], 0)];
	}
}

-(void)appendOutput:(NSString *)output
{	
	//total document length (in pixels) - length above scroll view (y coord of visible portion) - 
	//length w/in scroll view = length below scroll view
	NSNumber *theTest = [NSNumber numberWithFloat: 
		abs([textView bounds].size.height - [textView visibleRect].origin.y 
			- [textView visibleRect].size.height)];
	int signal;

	signal = [parser parseOutput: output];

	switch(signal)
	{
		case FC_PROMPT_SIGNAL:
			NSBeep();
			[self raiseInteractionWindow: self];
			break;
		case FC_PASSWORD_ERROR_SIGNAL:
			passwordError = YES;
			[self raisePwdWindow: self];
			break;
		case FC_PASSWORD_PROMPT_SIGNAL:
			[finkTask writeToStdin: [self password]];
			break;
	}
	[[textView textStorage] appendAttributedString:  
		[[[NSAttributedString alloc] initWithString: output] autorelease]];
	//  according to Moriarity example, have to put off scrolling until next event loop
	[self performSelector: @selector(scrollToVisible:) withObject: theTest 
				  afterDelay: 0.0];
}


-(void)processStarted
{
    [textView setString: @""];    
    [self setParser:[[FinkOutputParser alloc] initForCommand:[self lastCommand]]];
}

//helper for processFinishedWithStatus:
-(BOOL)commandRequiresTableUpdate:(NSString *)cmd
{
	return  [cmd isEqualToString: @"install"]	||
			[cmd isEqualToString: @"remove"]	||
			[cmd isEqualToString: @"index"]		||
			[cmd contains: @"build"]			||  
			[cmd contains: @"update"];
}

//reset the interface--stop and remove progress indicator, revalidate
//command menu and toolbar items, reapply filter--after the table data
//is updated or a command is completed
-(void)resetInterface:(NSNotification *)ignore
{
	[self stopProgressIndicator];
	[self displayNumberOfPackages];
	[self setCommandIsRunning: NO];
	[tableView deselectAll: self];
	[self controlTextDidChange: nil]; //reapplies filter, which re-sorts table
}

-(void)processFinishedWithStatus:(int)status
{
	int outputLength = [[textView string] length];
	NSString *output = outputLength < 160 ? [textView string] : 
		[[textView string] substringWithRange: NSMakeRange(outputLength - 160, 159)];

	if (! [[self lastCommand] contains: @"cp"] && ! [[self lastCommand] contains: @"chown"] &&
		! [[self lastCommand] contains: @"mv"]){
		NSBeep();
	}
	
	// Make sure command was successful before updating table
	// Checking exit status is not sufficient for some fink commands, so check
	// approximately last two lines for "failed"
	[self setDisplayedPackages: [packages array]];
	if (status == 0 && ! [output containsCI: @"failed"]){
		if ([self commandRequiresTableUpdate: lastCommand]){
			if ([lastCommand contains: @"selfupdate"] ||
				[lastCommand contains: @"index"]	  ||
	            [defaults boolForKey: FinkUpdateWithFink]){
				[self updateTable: nil];   // resetInterface will be called by notification
			}else{
				[packages updateManuallyWithCommand: [self lastCommand]
										   packages: [self selectedPackages]];
				[self resetInterface: nil]; 
			}
		}else{
			[self resetInterface: nil];
		}
	}else{
		if ([defaults boolForKey: FinkAutoExpandOutput]){
			[self expandOutput: nil];
		}
		NSBeginAlertSheet(@"Error",	@"OK", nil,	nil, //title, buttons
		[self window], self, NULL,	NULL, nil,	 	 //window, delegate, selectors, context info
		@"FinkCommander detected a possible failure message.\nCheck the output window for problems.",
		nil);										 //msg string params
		[self updateTable: nil];
	}
	[[NSNotificationCenter defaultCenter]
		postNotificationName: FinkCommandCompleted 
		object: [self lastCommand]]; 
}

@end
