/*
File: FinkController.m

See the header file, FinkController.h, for interface and license information.

*/

#import "FinkController.h"
//================================================================================
#pragma mark MACROS
//================================================================================

#define CMD_REQUIRES_UPDATE(x) 								\
   ([(x) isEqualToString: @"install"]		|| 				\
	[(x) isEqualToString: @"remove"]		|| 				\
	[(x) isEqualToString: @"index"]			|| 				\
	[(x) contains: @"build"]				|| 				\
	[(x) contains: @"dpkg"]					|| 				\
	[(x) contains: @"update"])

/* 
 * Macros defining collections used to translate between tag numbers
 * in MainMenu.nib and strings identifying FinkPackage attributes 
 */

#define TAG_NAME_ARRAY 										\
 [NSArray arrayWithObjects: 								\
	@"version",           									\
	@"binary",           									\
	@"stable",												\
	@"unstable",											\
	@"status",												\
	@"category",											\
	@"summary",												\
	@"maintainer",											\
	@"installed",											\
	@"name",												\
	@"flagged",												\
	nil]

#define NAME_TAG_DICTIONARY 								\
	[NSDictionary dictionaryWithObjectsAndKeys: 			\
	[NSNumber numberWithInt: VERSION], @"version",          \
	[NSNumber numberWithInt: BINARY], @"binary",            \
	[NSNumber numberWithInt: STABLE], @"stable",            \
	[NSNumber numberWithInt: UNSTABLE], @"unstable",        \
	[NSNumber numberWithInt: STATUS], @"status",            \
	[NSNumber numberWithInt: CATEGORY], @"category",        \
	[NSNumber numberWithInt: SUMMARY], @"summary",          \
	[NSNumber numberWithInt: MAINTAINER], @"maintainer",	\
	[NSNumber numberWithInt: INSTALLED], @"installed",      \
	[NSNumber numberWithInt: NAME], @"name",                \
	[NSNumber numberWithInt: FLAGGED], @"flagged",			\
	nil]

/*
 *  Repeated Localized Strings
 */

#define LS_QUIT NSLocalizedString(@"Quit", "Quit button title")
#define LS_DOWNLOAD NSLocalizedString(@"Download", "Download button title")

//================================================================================
#pragma mark CONSTANTS
//================================================================================

/* Constants corresponding to the tag for the identified attribute
in MainMenu.nib menu items  */
enum {
    VERSION    	= 2000,
    BINARY     	= 2001,
    STABLE     	= 2002,
    UNSTABLE   	= 2003,
    STATUS     	= 2004,
    CATEGORY   	= 2005,
    SUMMARY    	= 2006,
    MAINTAINER 	= 2007,
    INSTALLED  	= 2008,
    NAME	    = 2009,
	FLAGGED 	= 2010
};

/* Identify web site to open based on menu item tag */
enum {
    FCWEB 	= 1000,
    FCBUG 	= 1001,
    FINKDOC = 1002,
    FINKBUG	= 1003
};

/* Identify executable based on menu item tag */
enum{
    FINK,
    APT_GET,
    DPKG
};

/* Identify text field changed by item tag */
enum {
    FILTER,
    INTERACTION
};

/* Identify matrix selection in interaction sheet by tag */
enum {
    DEFAULT,
    USER_CHOICE
};

/* Identify type of feedback email */
enum {
    POSITIVE,
    NEGATIVE
};

@implementation FinkController

//================================================================================
#pragma mark INTITIALIZATION
//================================================================================

//----------------------------------------------->Initialize
+(void)initialize
{
    //set "factory defaults"
    NSDictionary *defaultValues = [NSDictionary dictionaryWithContentsOfFile:
		[[NSBundle mainBundle] pathForResource:@"UserDefaults"
							   ofType: @"plist"]];

    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
}

//----------------------------------------------->Init
-(id)init
{
    if (self = [super init]){
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		defaults = [NSUserDefaults standardUserDefaults];

		[NSApp setDelegate: self];

		//Check whether this is the initial startup of 0.4.0 or later for this user;
		//if so, remove existing preferences relating to table columns
		if (![[defaults objectForKey:FinkUsersArray] containsObject:NSUserName()]){
			NSLog(@"Fixing preferences for first run of version 0.4");
			fixPreferences();
		}

		//Set base path default, if necessary; write base path into perl script used
		//to obtain fink package data
		findFinkBasePath();
		fixScript();

		//Set environment variables for use in authorized commands, if
		//necessary
		if (! [defaults boolForKey:FinkInitialEnvironmentHasBeenSet]){
			setInitialEnvironmentVariables();
			[defaults setBool:YES forKey:FinkInitialEnvironmentHasBeenSet];
		}

		//Initialize package data storage object
		packages = [FinkData sharedData];

		//Set instance variables used to store objects and state information
		//needed to run fink and apt-get commands
		launcher = [[NSBundle mainBundle] pathForResource:@"Launcher" ofType:nil];
		finkTask = [[AuthorizedExecutable alloc] initWithExecutable:launcher];
		[finkTask setDelegate:self];
		commandIsRunning = NO;
		pendingCommand = NO;
		
		//Set the instance variable for the package tree manager
		treeManager = [[SBTreeWindowManager alloc] init];

		//Set flag used to avoid duplicate warnings when user terminates FC
		//in middle of command with something other than App:Quit
		userConfirmedQuit = NO;

		//Set flag indicating user has chosen to terminate a command;
		//used to stop appending text to output
		commandTerminated = NO;

		//Register for notification that causes table to update
		//and resume normal state
		[center addObserver: self
				selector: @selector(resetInterface:)
					name: FinkPackageArrayIsFinished
				  object: nil];

		//Register for notification that another object needs to run
		//a command with root privileges
		[center addObserver: self
				selector: @selector(runCommandOnNotification:)
					name: FinkRunCommandNotification
				  object: nil];

		//Register for notification that a command needs to be terminated;
		//sent by FinkWarningDialog when user confirms termination
		[center addObserver: self
			 selector: @selector(runTerminateCommand:)
				 name: FinkTerminateNotification
			   object: nil];

		//Register for notification that table selection changed in order
		//to update Package Inspector
		[center addObserver: self
				selector: @selector(tableViewSelectionDidChange:)
					name: NSTableViewSelectionDidChangeNotification
				  object: nil];
    }
    return self;
}

//================================================================================
#pragma mark DEALLOCATION
//================================================================================

//----------------------------------------------->Dealloc
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [packages release];
    [preferences release];
	[textViewController release];
    [parser release];
    [lastCommand release];
    [finkTask release];
    [killTask release];
    [toolbar release];
    [packageInfo release];
    [warningDialog release];
	[treeManager release];
    [super dealloc];
}


//================================================================================
#pragma mark GENERAL HELPERS
//================================================================================

/* 	
	Tag <-> Name Translation 
	Using tags rather than titles to tie the View menu items and search fields to
	particular columns makes it possible to localize the column names. 
*/

-(NSString *)attributeNameFromTag:(int)atag
{
    NSArray *tagNameArray = TAG_NAME_ARRAY;

    atag = atag % 2000;
    if (atag < 0 || atag > [tagNameArray count] - 1){
		NSLog(@"Warning: Tag-to-name translation failed; index %d out of bounds", atag);
		return nil;
    }
    return [tagNameArray objectAtIndex:atag];
}

-(int)tagFromAttributeName:(NSString *)name
{
    return [[NAME_TAG_DICTIONARY objectForKey:name] intValue];
}

-(void)displayNumberOfPackages
{
    if ([defaults boolForKey: FinkPackagesInTitleBar]){
		[window setTitle: [NSString stringWithFormat:
			NSLocalizedString(@"PackagesDisplayed", nil),
			[[tableView displayedPackages] count],
			[packages installedPackagesCount]]];
		if (! commandIsRunning){
			[msgText setStringValue: NSLocalizedString(@"Done", nil)];
		}
    }else if (! commandIsRunning){
		[window setTitle: @"FinkCommander"];
		[msgText setStringValue: [NSString stringWithFormat:
			NSLocalizedString(@"packagesInstalled", nil),
			[[tableView displayedPackages] count],
			[packages installedPackagesCount]]];
    }
}

//Display running command below the table
-(void)displayCommand:(NSArray *)params
{
    [msgText setStringValue: 
		[NSString stringWithFormat: NSLocalizedString(@"Running", nil),
		[params componentsJoinedByString: @" "]]];
}

-(void)stopProgressIndicator
{
    if ([progressView isDescendantOf: progressViewHolder]){
		[progressIndicator stopAnimation: nil];
		[progressView removeFromSuperview];
    }
}

-(void)startProgressIndicatorAsIndeterminate:(BOOL)b
{
    if (! [progressView isDescendantOf: progressViewHolder]){
		[progressViewHolder addSubview: progressView];
    }
    [progressIndicator setIndeterminate:b];
    [progressIndicator setDoubleValue:0.0];
    [progressIndicator setUsesThreadedAnimation: YES];
    [progressIndicator startAnimation: nil];
}

-(void)incrementProgressIndicator:(float)inc
{
    double progress = 100.0 - [progressIndicator doubleValue];
    //failsafe to make sure we don't go beyond 100
    [progressIndicator incrementBy:MIN(inc, progress * 0.85)];
}

//Reset the interface--stop and remove progress indicator, revalidate
//command menu and toolbar items, reapply filter--after the table data
//is updated or a command is completed
-(void)resetInterface:(NSNotification *)ignore
{
	[NSApp setApplicationIconImage:[NSImage imageNamed:@"NSApplicationIcon"]];
    [self stopProgressIndicator];
    [self displayNumberOfPackages];
    commandIsRunning = NO;
    [tableView deselectAll: self];
    [self controlTextDidChange: nil]; //reapplies filter, which re-sorts table
    [toolbar validateVisibleItems];
}

//================================================================================
#pragma mark POST-INIT STARTUP
//================================================================================

-(void)awakeFromNib
{
    NSEnumerator *e = [[defaults objectForKey:FinkTableColumnsArray]
		objectEnumerator];
    NSString *col;
    id splitSuperview = [splitView superview];
    NSSize tableContentSize = [tableScrollView contentSize];

    //Substitute FinkScrollView for NSScrollView
    [tableScrollView retain];  //keep subviews available after the split
    [outputScrollView retain]; // view is removed from its superview
    [splitView removeFromSuperview];
    splitView = [[FinkSplitView alloc] initWithFrame:[splitView frame]];
    [splitSuperview addSubview:splitView];
    [splitView release];  						//retained by superview
    [splitView addSubview:tableScrollView];
	[tableScrollView release];
    [splitView addSubview:outputScrollView];
    [outputScrollView release];
    [splitView connectSubviews]; //connects instance variables to scroll views
    [splitView adjustSubviews];
	[splitView setCollapseExpandMenuItem:collapseExpandMenuItem];

    //Substitute FinkTableView for NSTableView
    tableView = [[FinkTableView alloc] initWithFrame:
		NSMakeRect(0, 0, tableContentSize.width,
			 tableContentSize.height)];
    [tableScrollView setDocumentView:tableView];
    [tableView release];
    [tableView setDisplayedPackages:[packages array]];
    [tableView sizeLastColumnToFit];
    [tableView setMenu:tableContextMenu];

    //Instantiate FinkTextViewController
    textViewController = [[FinkTextViewController alloc] 
								initWithView:textView
								forScrollView:outputScrollView];
									
	//Set state of View menu column items
    while (nil != (col = [e nextObject])){
		int atag = [self tagFromAttributeName:col];
		[[columnsMenu itemWithTag:atag] setState:NSOnState];
    }

	if ([outputScrollView bounds].size.height < 1.0){
		[collapseExpandMenuItem setTitle:LS_EXPAND];
	}else{
		[splitView expandOutputToMinimumRatio:0.0];
		[collapseExpandMenuItem setTitle:LS_COLLAPSE];
	}
	

    [self setupToolbar];

    [msgText setStringValue:
		NSLocalizedString(@"UpdatingTable", nil)];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSTableColumn *lastColumn = [tableView tableColumnWithIdentifier:
				    [tableView lastIdentifier]];
	NSString *direction = [[defaults objectForKey:FinkColumnStateDictionary]
							objectForKey:[tableView lastIdentifier]];
    NSString *basePath = [defaults objectForKey:FinkBasePath];
    int interval = [defaults integerForKey:FinkCheckForNewVersionInterval];
    NSDate *lastCheckDate = [defaults objectForKey:FinkLastCheckedForNewVersion];

    if ([basePath length] <= 1 ){
		NSBeginAlertSheet(NSLocalizedString(@"UnableToLocate", nil),
					LS_OK, nil,	nil, //title, buttons
					window, self, NULL,	NULL, nil, //window, delegate, selectors, c info
					NSLocalizedString(@"TrySetting", nil), nil);
    }
    [self updateTable:nil];

    [tableView setHighlightedTableColumn:lastColumn];
    [tableView setIndicatorImage: [tableView performSelector:
				NSSelectorFromString([NSString stringWithFormat:@"%@SortImage", direction])]
		inTableColumn:lastColumn];

    if ([defaults boolForKey: FinkAutoExpandOutput]){
		[splitView collapseOutput: nil];
    }

    Dprintf(@"Interval for new version check: %d", interval);
    Dprintf(@"Last checked for new version: %@", [lastCheckDate description]);

    if (interval > 0 && -([lastCheckDate timeIntervalSinceNow] / 34560) >= interval){ //24*60*60
		NSLog(@"Checking for FinkCommander update");
		[self checkForLatestVersion:NO]; //don't notify if current
    }
}

//================================================================================
#pragma mark ACCESSORS
//================================================================================

-(FinkData *)packages  {return packages;}

-(NSString *)lastCommand {return lastCommand;}
-(void)setLastCommand:(NSString *)s
{
    [s retain];
    [lastCommand release];
    lastCommand = s;
}

-(void)setParser:(FinkOutputParser *)p
{
    [p retain];
    [parser release];
    parser = p;
}

-(NSTextField *)searchTextField
{
    return searchTextField;
}

-(NSPopUpButton *)searchPopUpButton
{
    return searchPopUpButton;
}

//================================================================================
#pragma mark APPLICATION AND WINDOW DELEGATES
//================================================================================

//warn before quitting if a command is running
-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    int answer;

    if (commandIsRunning && ! userConfirmedQuit){ //see windowShouldClose: method
		answer = NSRunCriticalAlertPanel(LS_WARNING, NSLocalizedString(@"QuittingNow", nil),
										LS_QUIT, LS_CANCEL, nil);
		if (answer == NSAlertAlternateReturn){
			return NO;
		}
    }
    return YES;
}

-(void)windowWillClose:(NSNotification *)n
{
	NSMenuItem *raiseMainWindowItem = 
		[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Show Main Window", @"Menu Item Title")
							action:@selector(bringBackMainWindow:)
							keyEquivalent:@""];

	[windowMenu insertItem:raiseMainWindowItem atIndex:2];
	[raiseMainWindowItem release];
	[windowMenu insertItem:[NSMenuItem separatorItem] atIndex:3];
}

//make sure the authorization terminates at the end of each FC session
-(void)applicationWillTerminate:(NSNotification*)anotification
{
    [finkTask unAuthorize];
}

//================================================================================
#pragma mark MAIN MENU
//================================================================================

//----------------------------------------------->Application Menu
#pragma mark Application Menu

-(IBAction)showPreferencePanel:(id)sender
{
    if (!preferences){
		preferences = [[FinkPreferences alloc] init];
    }
    [preferences showWindow:self];
}

//helper; separated from action method because also called on schedule
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
		NSRunAlertPanel(LS_ERROR,
				  NSLocalizedString(@"FinkCommanderWasUnable", nil),
				  LS_OK, nil, nil);
		return;
    }
    if (! [installedVersion isEqualToString: latestVersion]){
		int answer = NSRunAlertPanel(LS_DOWNLOAD,
							   NSLocalizedString(@"AMoreCurrentVersion", nil),
							   LS_DOWNLOAD, LS_CANCEL, nil, latestVersion);
		if (answer == NSAlertDefaultReturn){
			[[NSWorkspace sharedWorkspace] openURL:
				[NSURL URLWithString:@"http://finkcommander.sourceforge.net"]];
		}
    }else if (notifyWhenCurrent){
		NSRunAlertPanel(NSLocalizedString(@"Current", nil),
				  NSLocalizedString(@"TheLatest", nil),
				  LS_OK, nil, nil);
    }
    [defaults setObject:[NSDate date] forKey:FinkLastCheckedForNewVersion];
}

-(IBAction)checkForLatestVersionAction:(id)sender
{
    [self checkForLatestVersion:YES];
}

//----------------------------------------------->File Menu
#pragma mark File Menu

//usually called by other methods after a command runs
-(IBAction)updateTable:(id)sender
{
    [self startProgressIndicatorAsIndeterminate:YES];
    [msgText setStringValue:NSLocalizedString(@"UpdatingTable", nil)];
    commandIsRunning = YES;

    [packages update];
}

-(IBAction)saveOutput:(id)sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    NSString *defaultPath = [defaults objectForKey: FinkOutputPath];
    NSString *savePath = ([defaultPath length] > 0) ? defaultPath : NSHomeDirectory();
    NSString *fileName = [NSString stringWithFormat: @"%@_%@",
			     [self lastCommand],
			     [[NSDate date] descriptionWithCalendarFormat:
											  @"%d%b%Y" timeZone: nil locale: nil]];

    [panel setRequiredFileType: @"txt"];
    [panel beginSheetForDirectory:savePath
			file:fileName
			modalForWindow:window
			modalDelegate:self
			didEndSelector:@selector(didEnd:returnCode:contextInfo:)
			contextInfo:nil];
}

-(void)didEnd:(NSSavePanel *)sheet
   returnCode:(int)code
  contextInfo:(void *)contextInfo
{
    if (code = NSOKButton){
		NSData *odata = [[textView string] dataUsingEncoding: NSMacOSRomanStringEncoding];
		[odata writeToFile: [sheet filename] atomically:YES];
    }
}

//----------------------------------------------->View Menu
#pragma mark View Menu

//remove or add column
-(IBAction)chooseTableColumn:(id)sender
{
    NSString *columnIdentifier = [self attributeNameFromTag:[sender tag]];
    int newState = ([sender state] == NSOnState ? NSOffState : NSOnState);

    if (newState == NSOnState){
		[tableView addColumnWithName:columnIdentifier];
    }else{
		[tableView removeColumnWithName:columnIdentifier];
    }
    [sender setState:newState];
}

-(IBAction)sortByPackageElement:(id)sender
{
	NSString *identifier = [self attributeNameFromTag:[sender tag]];
	NSTableColumn *column = [tableView tableColumnWithIdentifier:identifier];
	[tableView tableView:tableView didClickTableColumn:column];
}

-(IBAction)collapseExpandOutput:(id)sender
{
	if ([outputScrollView bounds].size.height > 1.0){
		[splitView collapseOutput:nil];
	}else{
		[splitView expandOutputToMinimumRatio:0.0];
	}
}

-(IBAction)toggleFlags:(id)sender
{
	int currentState = [[[tableView selectedPackageArray] lastObject]
								flagged];
	int newState = (NOT_FLAGGED == currentState) ? IS_FLAGGED : NOT_FLAGGED;
	NSEnumerator *e = [[tableView selectedPackageArray] objectEnumerator];
	FinkPackage *package;
	NSMutableArray *flagArray = [[[defaults objectForKey:FinkFlaggedColumns] mutableCopy] autorelease];

	while (nil != (package = [e nextObject])){
		[package setFlagged:newState];
		if (1 == newState){
			[flagArray addObject:[package name]];
		}else if ([flagArray containsObject:[package name]]){
			[flagArray removeObject:[package name]];
		}
	}
	[defaults setObject:[[flagArray copy] autorelease] forKey:FinkFlaggedColumns];
	[tableView reloadData];
}

//----------------------------------------------->Source Menu
#pragma mark Source Menu

//faster substitute for fink describe command; preserves original
//formatting, unlike package inspector
-(IBAction)showDescription:(id)sender
{
    NSEnumerator *e = [[tableView selectedPackageArray] objectEnumerator];
    int i = 0;
    FinkPackage *pkg;
    NSString *full = nil;
    NSString *divider = @"____________________________________________________\n\n";

    [[textViewController textView] setString: @""];

    while (nil != (pkg = [e nextObject])){
		full = [NSString stringWithFormat: @"%@-%@:   %@\n",
			[pkg name],
			[pkg version],
			[pkg fulldesc]];
		if (i > 0){
			[[[textViewController textView] textStorage] appendAttributedString:
				[[[NSAttributedString alloc] initWithString: divider] autorelease]];
		}
		[[[textViewController textView] textStorage] appendAttributedString:
			[[[NSAttributedString alloc] initWithString: full] autorelease]];
		i++;
    }
}

//----------------------------------------------->Tools Menu
#pragma mark Tools Menu

-(void)runTerminateCommand:(NSNotification *)ignore
{
	NSString *pgid = [NSString stringWithFormat:@"%d", [parser pgid]];
		
	if (!killTask) 	killTask = [[AuthorizedExecutable alloc] initWithExecutable:launcher];
    [killTask setArguments:
		[NSArray arrayWithObjects: @"--kill", pgid, nil]];
    [killTask setEnvironment:[defaults objectForKey:FinkEnvironmentSettings]];
    [killTask authorizeWithQuery];
    [killTask start];
}

-(IBAction)terminateCommand:(id)sender
{
    if ([defaults boolForKey: FinkWarnBeforeTerminating]){
		if (! warningDialog){
			warningDialog = [[FinkWarningDialog alloc] init];
		}
		[warningDialog showTerminateWarning];
		return;
    }
    [self runTerminateCommand:nil];
}

//show package inspector
-(IBAction)showPackageInfoPanel:(id)sender
{
    FinkInstallationInfo *info = [[[FinkInstallationInfo alloc] init] autorelease];
    NSString *sig = [info formattedEmailSig];

    if (!packageInfo){
		packageInfo = [[FinkPackageInfo alloc] init];
    }
    [packageInfo setEmailSig: sig];
    [[packageInfo window] zoom: nil];
    [packageInfo showWindow: self];
    [packageInfo displayDescriptions: [tableView selectedPackageArray]];
}

//change inspector content when table selection changes
-(void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    if (packageInfo && [[packageInfo window] isVisible]){
		[packageInfo displayDescriptions: [tableView selectedPackageArray]];
    }
}

//Helper for feedback commands
-(void)sendEmailWithMessage:(int)typeOfFeedback
{
    NSEnumerator *e = [[tableView selectedPackageArray] objectEnumerator];
    FinkInstallationInfo *info = [[[FinkInstallationInfo alloc] init] autorelease];
    NSString *sig = [info formattedEmailSig];
    FinkPackage *pkg;
	NSMutableArray *pkgNames = [NSMutableArray arrayWithCapacity:5];

    if (!packageInfo){
		packageInfo = [[FinkPackageInfo alloc] init];
    }

    [packageInfo setEmailSig:sig];
    while (nil != (pkg = [e nextObject])){
		if (typeOfFeedback == POSITIVE && [[pkg installed] isEqualToString:[pkg stable]]){
			[pkgNames addObject:[pkg name]];
			continue;
		}
		if (typeOfFeedback == NEGATIVE							&&
			[[pkg installed] length] > 1						&&
			! [[pkg installed] isEqualToString:[pkg version]]	&&  //version = latest
			! [[pkg installed] isEqualToString:[pkg stable]]){
			[pkgNames addObject:[pkg name]];
		}
		[[NSWorkspace sharedWorkspace] openURL:[packageInfo mailURLForPackage:pkg]];
    }
	if (typeOfFeedback == POSITIVE && [pkgNames count] > 0){
		NSString *msg = [pkgNames count] > 1 ? 
						NSLocalizedString(@"UnnecessaryPositiveFeedbackPlural", nil) :
						NSLocalizedString(@"UnnecessaryPositiveFeedbackSingular", nil);
		NSBeginAlertSheet(LS_ERROR,
					LS_OK, nil, nil,
					window, self, NULL, NULL, nil,
					[NSString stringWithFormat: msg, [pkgNames componentsJoinedByString:@", "]],
					nil);
	}
	if (typeOfFeedback == NEGATIVE && [pkgNames count] > 0){
		NSString *msg = [pkgNames count] > 1 ?
		NSLocalizedString(@"OutdatedNegativeFeedbackPlural", nil) :
		NSLocalizedString(@"OutdatedNegativeFeedbackSingular", nil);
		NSBeginAlertSheet(LS_WARNING,
					LS_OK, nil, nil,
					window, self, NULL, NULL, nil,
					[NSString stringWithFormat: msg, [pkgNames componentsJoinedByString:@", "]],
					nil);
	}
}

-(IBAction)sendPositiveFeedback:(id)sender
{
	[self sendEmailWithMessage:POSITIVE];
}

-(IBAction)sendNegativeFeedback:(id)sender
{
	[self sendEmailWithMessage:NEGATIVE];
}

-(IBAction)openPackageFileViewer:(id)sender
{
	FinkPackage *pkg = [[tableView displayedPackages] objectAtIndex:
		[tableView selectedRow]];
	
	if (! [[pkg status] contains:@"u"]){
		NSBeep();//Substitute alert sheet?
		return;
	}
	[treeManager openNewOutlineForPackageName:[pkg name]];
}

-(IBAction)openDocumentation:(id)sender
{
	FinkPackage *pkg = [[tableView displayedPackages] objectAtIndex:
						[tableView selectedRow]];
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSString *root = [[defaults objectForKey:FinkBasePath] 
						stringByAppendingPathComponent:@"share/doc"];
	NSString *path = [root stringByAppendingPathComponent:[pkg nameWithoutSplitoff]];
	NSArray *pathContents;

	if (![mgr fileExistsAtPath:path]){
		NSBeep();  //Substitute alert sheet?
		return;
	}
	pathContents = [mgr directoryContentsAtPath:path];
	if (nil != pathContents && [pathContents count] > 0){
		path = [path stringByAppendingPathComponent:[pathContents objectAtIndex:0]];
	}
	[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:root];
}

//----------------------------------------------->Window Menu
#pragma mark Window Menu

-(IBAction)bringBackMainWindow:(id)sender
{
	[window makeKeyAndOrderFront:sender];
	[windowMenu removeItemAtIndex:2];
	[windowMenu removeItemAtIndex:2];
}

//----------------------------------------------->Help and Tools Menu
#pragma mark Help Menu

//Help menu internet access items
-(IBAction)goToWebsite:(id)sender
{
    NSString *url = nil;

    switch ([sender tag]){
		case FCWEB:
			url = @"http://finkcommander.sourceforge.net/";
			break;
		case FCBUG:
			url = @"http://finkcommander.sourceforge.net/pages/bugs.html";
			break;
		case FINKDOC:
			url = @"http://fink.sourceforge.net/doc/index.php";
			break;
		case FINKBUG:
			url = @"http://sourceforge.net/tracker/?func=add&group_id=17203&atid=117203";
			break;
    }
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

//================================================================================
#pragma mark TOOLBAR
//================================================================================

-(void)setupToolbar
{
    toolbar = [[FinkToolbar alloc] initWithIdentifier: @"mainToolbar"];
    [toolbar setDelegate: self];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
	[toolbar setSearchField:searchTextField];
	[toolbar setSearchButton:searchPopUpButton];
    [window setToolbar: toolbar];
}

//reapply filter if popup selection changes
-(IBAction)refilter:(id)sender
{
    [searchTextField selectText: nil];
    [self controlTextDidChange: nil];
}

//----------------------------------------------->Toolbar Delegates
#pragma mark Toolbar Delegates

/* 
 * Use the Toolbar.plist file to populate the toolbar.
 */

-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar
    itemForItemIdentifier:(NSString *)itemIdentifier
	willBeInsertedIntoToolbar:(BOOL)flag
{
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:
						[[NSBundle mainBundle] pathForResource: @"Toolbar" ofType: @"plist"]];
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
    if ([itemIdentifier isEqualToString:@"FinkFilterItem"]){
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
				@"FinkInstallSourceItem",
				@"FinkInstallBinaryItem",
				@"FinkRemoveSourceItem",
				@"FinkRemoveBinaryItem",
				@"FinkSelfUpdateItem",
				@"FinkSelfUpdateCVSItem",
				@"FinkUpdateallItem",
				@"FinkUpdateBinaryItem",
				@"FinkDescribeItem",
				@"FinkTermInstallItem",
				@"FinkTermCvsItem",
				@"FinkInteractItem",
				@"FinkTerminateCommandItem",
				@"FinkPositiveEmailItem",
				@"FinkEmailItem",
				@"FinkFilterItem",		
				nil];
}

-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return 	[NSArray arrayWithObjects:
				@"FinkInstallSourceItem",
				@"FinkTermInstallItem",
				@"FinkRemoveSourceItem",
				@"FinkSelfUpdateCVSItem",
				NSToolbarSeparatorItemIdentifier,
				@"FinkTerminateCommandItem",
				@"FinkPositiveEmailItem",
				@"FinkEmailItem",
				NSToolbarFlexibleSpaceItemIdentifier,
				@"FinkFilterItem",
				nil];
}

//----------------------------------------------->Text Field Delegate
#pragma mark Text Field Delegate

-(void)controlTextDidChange:(NSNotification *)aNotification
{
    //filter data source each time the filter text field changes
    if ([[aNotification object] tag] == FILTER){
		NSString *field = [self attributeNameFromTag:[[searchPopUpButton selectedItem] tag]];
		NSString *filterText = [[searchTextField stringValue] lowercaseString];
		NSString *pkgAttribute;
		NSMutableArray *subset = [NSMutableArray array];
		NSEnumerator *e = [[packages array] objectEnumerator];
		FinkPackage *pkg;

		//store selected object information before the filter is applied
		if ([defaults boolForKey: FinkScrollToSelection]){
			[tableView storeSelectedObjectInfo];
		}

		if ([filterText length] == 0){
			[tableView setDisplayedPackages: [packages array]];
		}else{
			while (nil != (pkg = [e nextObject])){
				pkgAttribute = 
					NSLocalizedString([[pkg performSelector: NSSelectorFromString(field)]
												lowercaseString], nil);
				if ([pkgAttribute contains: filterText]){
					[subset addObject: pkg];
				}
			}
			[tableView setDisplayedPackages:[[subset copy] autorelease]];
		}
		[tableView resortTableAfterFilter];

		//restore the selection and scroll back to it after the table is sorted
		if ([defaults boolForKey: FinkScrollToSelection]){
			[tableView scrollToSelectedObject];
		}
		[self displayNumberOfPackages];
	//in interaction dialogue, automatically select the radio button appropriate
	//for the state of the text entry field
    }else if ([[aNotification object] tag] == INTERACTION){
		if ([[interactionField stringValue] length]){
			[interactionMatrix selectCellWithTag: USER_CHOICE];
		}else{
			[interactionMatrix selectCellWithTag: DEFAULT];
		}
    }
}

//================================================================================
#pragma mark VALIDATION
//================================================================================

//helper for menu item and toolbar item validators
-(BOOL)validateItem:(id)theItem
{
    //disable package-specific commands if no row selected
    if (([tableView selectedRow] == -1 			||	
		 ! [window isKeyWindow])									&&

		([theItem action] == @selector(runPackageSpecificCommand:)  		||
		[theItem action] == @selector(runPackageSpecificCommandInTerminal:)	||
		[theItem action] == @selector(runForceRemove:)						||
		[theItem action] == @selector(showDescription:)						||
		[theItem action] == @selector(sendNegativeFeedback:)				||
		[theItem action] == @selector(sendPositiveFeedback:)				||
		[theItem action] == @selector(openDocumentation:)					||
		[theItem action] == @selector(openPackageFileViewer:)				||
		[theItem action] == @selector(openPackageFiles:)					||
		[theItem action] == @selector(toggleFlags:))){
		return NO;
    }
	//disable sorting for columns not in table
	if ([theItem action] == @selector(sortByPackageElement:) &&
		! [[defaults objectForKey:FinkTableColumnsArray] containsObject:
			[self attributeNameFromTag:[theItem tag]]]){
		return NO;
	}
    //disable Source and Binary menu items and table update if command is running
    if (commandIsRunning &&
		([theItem action] == @selector(runPackageSpecificCommand:) 	||
		[theItem action] == @selector(runNonSpecificCommand:) 		||
		[theItem action] == @selector(runForceRemove:)				||
		[theItem action] == @selector(showDescription:)				||
		[theItem action] == @selector(saveOutput:)					||
		[theItem action] == @selector(updateTable:))){
		return  NO;
    }
    if (! commandIsRunning &&
		([theItem action] == @selector(raiseInteractionWindow:) ||
		[theItem action] == @selector(terminateCommand:))){
		return NO;
    }
    // no output to save if lastCommand is null, prevents (null) filename
    if ([self lastCommand] == 0 		&&
		[theItem action] == @selector(saveOutput:)){
		return NO;
    }
	// toggle menu item titles
	if ([theItem action] == @selector(toggleFlags:)){
		if ([[[tableView selectedPackageArray] lastObject] flagged] == 0){
			[theItem setTitle:NSLocalizedString(@"Mark As Flagged", nil)];
		}else{
			[theItem setTitle:NSLocalizedString(@"Mark As Unflagged", nil)];
		}
		return YES;
	}
	if ([theItem action] == @selector(toggleToolbarShown:)){
		if ([toolbar isVisible]){
			[theItem setTitle:NSLocalizedString(@"Hide Toolbar", nil)];
		}else{
			[theItem setTitle:NSLocalizedString(@"Show Toolbar", nil)];
		}
		return YES;
	}
    return YES;
}

//Disable menu items
-(BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    return [self validateItem: menuItem];
}

//Disable toolbar items
-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return [self validateItem: theItem];
}

//================================================================================
#pragma mark RUNNING AUTHORIZED COMMANDS
//================================================================================

/*** Helper for Menu and Toolbar Commands ***/

-(NSMutableArray *)argumentListForCommand:(id)sender
					packageSpecific:(BOOL)pkgSpec
{
    NSString *cmd, *exe = @"";
    NSMutableArray *args;
    FinkPackage *pkg;
    NSEnumerator *e;
	int type = [sender tag];

    //Identify executable
    switch (type){
		case FINK:
			exe = @"fink";
			break;
		case APT_GET:
			exe = @"apt-get";
			break;
		case DPKG:
			exe = @"dpkg";
			break;
    }
    exe = [[defaults objectForKey:FinkBasePath] stringByAppendingPathComponent:
				[NSString stringWithFormat:@"/bin/%@", exe]];

	//Put executable, command name and options in argument array
    if (type == FINK || type == APT_GET){
		cmd = [sender isKindOfClass:[NSMenuItem class]] ? [sender title] : [sender label];
		cmd = [[[cmd componentsSeparatedByString:@" "] objectAtIndex:0] lowercaseString];
		[self setLastCommand:cmd];
		args = [NSMutableArray arrayWithObjects: exe, cmd, nil];
		if ([defaults boolForKey: FinkAlwaysChooseDefaults]){
			[args insertObject: @"-y" atIndex: 1];
		}
		if (type == APT_GET){
			[args insertObject: @"-f" atIndex: 1];
			[args insertObject: @"-q0" atIndex: 1];
		}
    }else{
		[self setLastCommand:exe];
		args = [NSMutableArray arrayWithObjects: exe, @"--remove",
			@"--force-depends", nil];
    }

	//Put package names in argument array, if this is a package-specific command
    if (pkgSpec){
		e  = [[tableView selectedPackageArray] objectEnumerator];
		while (nil != (pkg = [e nextObject])){
			[args addObject: [pkg name]];
		}
    }
    return args;
}

/*** Run-in-Terminal Methods ***/

-(IBAction)runPackageSpecificCommandInTerminal:(id)sender
{
	NSMutableArray *args = [self argumentListForCommand:sender packageSpecific:YES];
	
	if ([sender tag] == APT_GET) [args insertObject:@"sudo" atIndex:0];
	[self launchCommandInTerminal:[args componentsJoinedByString:@" "]];
}

-(IBAction)runNonSpecificCommandInTerminal:(id)sender
{
	NSMutableArray *args = [self argumentListForCommand:sender packageSpecific:NO];
	
	if ([sender tag] == APT_GET) [args insertObject:@"sudo" atIndex:0];
	[self launchCommandInTerminal:[args componentsJoinedByString:@" "]];
}

-(void)launchCommandInTerminal:(NSString *)cmd
{
	NSAppleScript *script;
	NSAppleEventDescriptor *descriptor;
	NSDictionary *errord;

	cmd = [NSString stringWithFormat:@"tell application \"Terminal\"\nactivate\ndo script \"%@\"\n end tell", cmd];
	script = [[[NSAppleScript alloc] initWithSource:cmd] autorelease];
	descriptor = [script executeAndReturnError:&errord];
	if (! descriptor){
		NSLog(@"Apple script failed to execute");
		NSLog(@"Error dictionary:\n%@", [errord description]);
	}
}

/*** Run-in-FinkCommander Methods ***/

-(IBAction)runPackageSpecificCommand:(id)sender
{
    NSMutableArray *args = [self argumentListForCommand:sender packageSpecific:YES];

    if ([args containsObject: @"remove"] &&
		[defaults boolForKey: FinkWarnBeforeRemoving]){
		if (! warningDialog){
			warningDialog = [[FinkWarningDialog alloc] init];
		}
		[warningDialog showRemoveWarningForArguments:args];
		return;
    }
    [self launchCommandWithArguments:args];
}

-(IBAction)runNonSpecificCommand:(id)sender
{
    NSMutableArray *args = [self argumentListForCommand:sender packageSpecific:NO];
    [self launchCommandWithArguments:args];
}

-(IBAction)runForceRemove:(id)sender
{
    NSMutableArray *args;
    int answer = NSRunCriticalAlertPanel(LS_WARNING,
										 NSLocalizedString(@"RunningForceRemove", nil),
										 LS_REMOVE, LS_CANCEL, nil);
    if (answer == NSAlertAlternateReturn) return;

    args = [self argumentListForCommand:sender packageSpecific:YES];
    [self launchCommandWithArguments:args];
}

//Allow other objects, e.g. FinkConf, to run authorized commands
-(void)runCommandOnNotification:(NSNotification *)note
{
    NSMutableArray *args = [note object];
    NSString *cmd = [args objectAtIndex: 0];
    NSNumber *indicator = [[note userInfo] objectForKey:FinkRunProgressIndicator];

	Dprintf(@"Running command %@ on notification", cmd);

    if (commandIsRunning && !toolIsBeingFixed){
		NSRunAlertPanel(LS_SORRY,
				  NSLocalizedString(@"YouMustWait", nil),
				  LS_OK, nil, nil);
		return;
	}
	if ([cmd contains:@"fink"]){
		[self setLastCommand:@"index"];
	}else{
		[self setLastCommand:cmd];
	}
    if (indicator){
		[self startProgressIndicatorAsIndeterminate:[indicator intValue]];
    }
    //prevent tasks run by consecutive notifications from tripping over each other
    [self performSelector:@selector(launchCommandWithArguments:)
					 withObject:args
					 afterDelay:1.0];
}

-(void)launchCommandWithArguments:(NSMutableArray *)args
{
    NSString *exec = [args objectAtIndex:0];

    pendingCommand = NO;
    toolIsBeingFixed = NO;
    commandIsRunning = YES;
    [self setParser:[[FinkOutputParser alloc] initForCommand:[self lastCommand]
											  executable:exec]];
    [self displayCommand: args];
	[NSApp setApplicationIconImage:[NSImage imageNamed:@"finkcommanderatwork"]];

    [finkTask setArguments:args];
    [finkTask setEnvironment:[defaults objectForKey:FinkEnvironmentSettings]];
    [finkTask authorizeWithQuery];
    [finkTask start];
	[textViewController setLimits];
    [[textViewController textView] 
		replaceCharactersInRange:NSMakeRange(0, [[textView string] length])
		withString:@""];
}

//================================================================================
#pragma mark INTERACTION SHEET
//================================================================================

-(IBAction)raiseInteractionWindow:(id)sender
{
    [splitView expandOutputToMinimumRatio:0.4];
    [[textViewController textView] scrollRangeToVisible:
		NSMakeRange([[[textViewController textView] string] length], 0)];

    [NSApp beginSheet: interactionWindow
		  modalForWindow: window
		   modalDelegate: self
		  didEndSelector: @selector(interactionSheetDidEnd:returnCode:contextInfo:)
			 contextInfo: nil];
}

-(IBAction)endInteractionWindow:(id)sender
{
    int returnValue = [sender tag];  // 1 for Submit, 0 for Cancel
    [interactionWindow orderOut:sender];
    [NSApp endSheet:interactionWindow returnCode:returnValue];
}

-(void)interactionSheetDidEnd:(NSWindow *)sheet
				   returnCode:(int)returnCode
				  contextInfo:(void *)contextInfo
{
    if (returnCode){  // Submit rather than Cancel
		if ([[interactionMatrix selectedCell] tag] == 0){
			[finkTask writeToStdin: @"\n"];
		}else{
			[finkTask writeToStdin: [NSString stringWithFormat:@"%@\n",
				[interactionField stringValue]]];
		}
		[textViewController appendString:@"\n"];
		if ([defaults boolForKey: FinkAutoExpandOutput]){
			[splitView collapseOutput: nil];
		}
    }
}

//================================================================================
#pragma mark AUTHORIZED EXECUTABLE DELEGATE METHODS
//================================================================================

/*
 * Helpers 
 */

-(void)startInstall
{
    [self startProgressIndicatorAsIndeterminate:NO];
    [self incrementProgressIndicator:STARTING_INCREMENT];
}

-(void)setGUIForPhase:(int)phaseIndex
{
    NSArray *phases = [NSArray arrayWithObjects:
		@"", @"Fetching", @"Unpacking",
		@"Configuring", @"Compiling",
		@"Building", @"Activating", nil];
    NSString *pname, *phaseString;

    pname = [parser currentPackage];
    phaseString = [phases objectAtIndex:phaseIndex];
    [msgText setStringValue:[NSString stringWithFormat:
		NSLocalizedString(phaseString, nil), pname]];
    [self incrementProgressIndicator:[parser increment]];
}

-(void)interactIfRequired
{
    if (! [defaults boolForKey:FinkAlwaysChooseDefaults]){
		NSBeep();
		[self raiseInteractionWindow:self];
    }
}

//Scroll to the latest addition to output if user has selected the option
//to always do so, or if the scroll thumb is at or near the bottom
-(void)scrollToVisible:(NSNumber *)pixelsBelowView
{
    //Window or splitview resizing often results in some gap between
    //the scroll thumb and the bottom, so the test shouldn't be whether
    //there are 0 pixels below the scroll view
    if ([pixelsBelowView floatValue] <= 100.0 ||
		[defaults boolForKey: FinkAlwaysScrollToBottom]){
		[[textViewController textView] scrollRangeToVisible:
			NSMakeRange([[[textViewController textView] string] length], 0)];
    }
}

-(void)processOutput:(NSString *)output
{
    /* Determine how much output is below the scroll view based on
       the following calculation (in vertical pixels):

       Total document length									-
       Length above scroll view (y coord of visible portion)  	-
       Length w/in scroll view 				      			  	=
       ----------------------------------------------------
       Length below scroll view

    //This value is used to determine whether the user has scrolled up.
    //If so, the output view will not automatically scroll to the bottom. */
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSNumber *pixelsBelowView = [NSNumber numberWithFloat:
				    abs([[textViewController textView] bounds].size.height -
			[[textViewController textView] visibleRect].origin.y -
			[[textViewController textView] visibleRect].size.height)];
    int signal;
	
	signal = [parser parseOutput:output];
	
    if (commandTerminated) return;
    switch(signal)
    {
		case NONE:
			break;
		case PASSWORD_PROMPT:
			output = @"";
			[finkTask stop];
			break;
		case PROMPT:
			[self interactIfRequired];
			break;
		case MANDATORY_PROMPT:
			NSBeep();
			[self raiseInteractionWindow:self];
			break;
		case PROMPT_AND_START:
			[self startInstall];
			[self interactIfRequired];
			break;
		case START_INSTALL:
			[self startInstall];
			break;
		case START_AND_FETCH:
			[self startInstall];			//fall through
		case FETCH:
			[self setGUIForPhase:FETCH];
			break;
		case START_AND_UNPACK:
			[self startInstall]; 			//fall through
		case UNPACK:
			[self setGUIForPhase:UNPACK];
			break;
		case CONFIGURE:
			[self setGUIForPhase:CONFIGURE];
			break;
		case COMPILE:
			[self setGUIForPhase:COMPILE];
			break;
		case BUILD:
			[self setGUIForPhase:BUILD];
			break;
		case START_AND_ACTIVATE:
			[self startInstall];			//fall through
		case ACTIVATE:
			[self setGUIForPhase:ACTIVATE];
			break;
		case RUNNING_SELF_REPAIR:
			output = NSLocalizedString(@"ToolWillSelfRepair", nil);
			break;
		case SELF_REPAIR_COMPLETE:
			output = NSLocalizedString(@"ToolHasSelfRepaired", nil);
			commandTerminated = YES;
			break;
		case RESOURCE_DIR:
			output = NSLocalizedString(@"ResourceDirChangeFailed", nil);
			break;
		case SELF_REPAIR_FAILED:
			output = NSLocalizedString(@"SelfRepairFailed", nil);
			break;
		case PGID:
			Dprintf(@"pgid for Launcher = %d", [parser pgid]);
			output = @"";
			break;
    }

    [textViewController appendString:output];
	//According to Moriarity example, we have to put off scrolling until next event loop
    [self performSelector:@selector(scrollToVisible:)
					 withObject:pixelsBelowView
					 afterDelay:0.0];
					 
	[pool release];
}

/*
 * Delegate Methods
 */

-(void)captureStdOut:(NSString *)output forExecutable:(id)ignore
{
	[self processOutput:output];
}

-(void)captureStdErr:(NSString *)output forExecutable:(id)ignore
{
	[self processOutput:output];
}

-(void)executableFinished:(id)ignore withStatus:(NSNumber *)number
{
    int status = [number intValue];
    int outputLength = [[[textViewController textView] string] length];
    NSString *last2lines = outputLength < 160 ? [[textViewController textView] string] :
		[[[textViewController textView] string] 
			substringWithRange: NSMakeRange(outputLength - 160, 159)];

    Dprintf(@"Finishing command %@ with status %d", lastCommand, status);
    NSBeep();

    // Make sure command was successful before updating table.
    // Checking exit status is not sufficient for some fink commands, so check
    // approximately last two lines for "failed."
    [tableView setDisplayedPackages:[packages array]];
    if (status == 0 && ! [last2lines containsCI: @"failed"]){
		if (CMD_REQUIRES_UPDATE(lastCommand) && ! commandTerminated){
			[self updateTable: nil];   // resetInterface will be called by notification
		}else{
			[self resetInterface: nil];
		}
    }else{
		if (! commandTerminated){
			[splitView expandOutputToMinimumRatio:0.0];
			NSBeginAlertSheet(LS_ERROR, LS_OK, nil, nil,
					 window, self, NULL, NULL, nil,
					 NSLocalizedString(@"FinkCommanderDetected", nil),
					 nil);
		}
		[self updateTable: nil];
    }

    commandTerminated = NO;

    [[NSNotificationCenter defaultCenter]
		postNotificationName:FinkCommandCompleted
		object:[self lastCommand]];
}

@end
