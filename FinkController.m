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
	@"local",												\
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
	[NSNumber numberWithInt: LOCAL], @"local",        \
	[NSNumber numberWithInt: STATUS], @"status",            \
	[NSNumber numberWithInt: CATEGORY], @"category",        \
	[NSNumber numberWithInt: SUMMARY], @"summary",          \
	[NSNumber numberWithInt: MAINTAINER], @"maintainer",	\
	[NSNumber numberWithInt: INSTALLED], @"installed",      \
	[NSNumber numberWithInt: NAME], @"name",                \
	[NSNumber numberWithInt: FLAGGED], @"flagged",			\
	nil]
	
/*  Parse menu item title or toolbar item label to determine 
	the associated fink or apt-get command */
#define ACTION_ITEM_IDENTIFIER(theSender)                   \
	[[[([(theSender) isKindOfClass:[NSMenuItem class]] ?    \
		[(theSender) title] : 								\
		[(theSender) label]) 								\
			componentsSeparatedByString:@" "]          		\
			objectAtIndex:0] lowercaseString];          	\


/*
 *  Repeated Localized Strings
 */

#define LS_QUIT NSLocalizedString(@"Quit", "Quit button title")
#define LS_DOWNLOAD NSLocalizedString(@"Download", "Download button title")
#define LS_UPDATING_TABLE NSLocalizedString(@"Updating table data", "Status bar message")

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
	LOCAL = 2004,
    STATUS     	= 2005,
    CATEGORY   	= 2006,
    SUMMARY    	= 2007,
    MAINTAINER 	= 2008,
    INSTALLED  	= 2009,
    NAME	    = 2010,
	FLAGGED 	= 2011
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
-(instancetype)init
{
    if (self = [super init]){
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		defaults = [NSUserDefaults standardUserDefaults];

		[NSApp setDelegate: self];

		//Check whether this is the initial startup of 0.4.0 or later for this user;
		//if so, remove existing preferences relating to table columns
		if (![[defaults objectForKey:FinkUsersArray] containsObject:NSUserName()]){
			NSLog(@"Fixing preferences for first run of version 0.4 or later");
			fixPreferences();
		}

		/*	Set base path and perl path defaults, if necessary; 
			write base path into perl script used
			to obtain fink package data */
		findFinkBasePath();
		findPerlPath();
		fixScript();

		//Set environment variables for use in authorized commands, if
		//necessary
		if (! [defaults boolForKey:FinkInitialEnvironmentHasBeenSet]){
			setInitialEnvironmentVariables();
			[defaults setBool:YES forKey:FinkInitialEnvironmentHasBeenSet];
		}

		//Initialize package data storage object
		_packages = [FinkData sharedData];
		
		//Initialize fink installation information object
		_installationInfo = [FinkInstallationInfo sharedInfo];

		//Set instance variables used to store objects and state information
		//needed to run fink and apt-get commands
		launcher = [[NSBundle mainBundle] pathForResource:@"Launcher" ofType:nil];
		_finkTask = [[AuthorizedExecutable alloc] initWithExecutable:launcher];
		[_finkTask setDelegate:self];
		commandIsRunning = NO;
		pendingCommand = NO;
		
		//Set the instance variable for the package tree manager
		_treeManager = [[SBTreeWindowManager alloc] init];

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

		//Register for notification to check for updates
		//to update Package Inspector
		[center addObserver: self
			selector: @selector(checkForUpdate:)
			name: CheckForUpdate
			object: nil];

		searchTag = 2010;
		outputIsDynamic = NO;
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
    return tagNameArray[atag];
}

-(int)tagFromAttributeName:(NSString *)name
{
    return [NAME_TAG_DICTIONARY[name] intValue];
}

-(void)displayNumberOfPackages
{
    if ([defaults boolForKey: FinkPackagesInTitleBar]){
		[window setTitle: [NSString stringWithFormat:
			NSLocalizedString(@"Packages: %d Displayed, %d Installed", @"Main window title"),
			[[tableView displayedPackages] count],
			[[self packages] installedPackagesCount]]];
		if (! commandIsRunning){
			[msgText setStringValue: NSLocalizedString(@"Done", @"Status bar message")];
		}
    }else if (! commandIsRunning){
		[window setTitle: @"FinkCommander"];
		[msgText setStringValue: [NSString stringWithFormat:
			NSLocalizedString(@"%d packages (%d installed)", @"Status bar message"),
			[[tableView displayedPackages] count],
			[[self packages] installedPackagesCount]]];
    }
}

//Display running command below the table
-(void)displayCommand:(NSArray *)params
{
    [msgText setStringValue: 
		[NSString stringWithFormat: NSLocalizedString(@"Running %@", 
			@"Status bar message indicating a command is running"),
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
    [progressIndicator setUsesThreadedAnimation:YES];
    [progressIndicator startAnimation: nil];
}

-(void)incrementProgressIndicator:(float)inc
{
    double unused = 100.0 - [progressIndicator doubleValue];
    //failsafe to make sure we don't go beyond 100
    [progressIndicator incrementBy:MIN(inc, unused * 0.85)];
}

/*	Reset the interface--stop and remove progress indicator, revalidate
	command menu and toolbar items, reapply filter--after the table data
	is updated or a command is completed */
-(void)resetInterface:(NSNotification *)ignore
{
	[NSApp setApplicationIconImage:[NSImage imageNamed:@"NSApplicationIcon"]];
	[self stopProgressIndicator];
	[self displayNumberOfPackages];
	commandIsRunning = NO;
	if (![[ignore name] isEqualToString: @"FinkError"]){
		[tableView deselectAll: self];
	}
	[self controlTextDidChange: nil]; //reapplies filter, which re-sorts table
	[[self toolbar] validateVisibleItems];
}

//================================================================================
#pragma mark POST-INIT STARTUP
//================================================================================

-(void)awakeFromNib
{
    NSEnumerator *columnNameEnumerator = [[defaults objectForKey:FinkTableColumnsArray]
		objectEnumerator];
    NSString *columnName;
    id splitSuperview = [splitView superview];
    NSSize tableContentSize = [tableScrollView contentSize];

    //Substitute FinkScrollView for NSScrollView
    [splitView removeFromSuperview];
    splitView = [[FinkSplitView alloc] initWithFrame:[splitView frame]];
    [splitSuperview addSubview:splitView];
    [splitView addSubview:tableScrollView];
    [splitView addSubview:outputScrollView];
    [splitView connectSubviews]; //connects instance variables to scroll views
    [splitView adjustSubviews];
	[splitView setCollapseExpandMenuItem:collapseExpandMenuItem];
	
	[tableScrollView setBorderType:NSNoBorder];
	[outputScrollView setBorderType:NSNoBorder];

    //Substitute FinkTableView for NSTableView
    tableView = [[FinkTableView alloc] initWithFrame:
		NSMakeRect(0, 0, tableContentSize.width,
			 tableContentSize.height)];
    [tableScrollView setDocumentView:tableView];
    [tableView setDisplayedPackages:[[self packages] array]];
    [tableView sizeLastColumnToFit];
    [tableView setMenu:tableContextMenu];

    //Instantiate FinkTextViewController
    [self setTextViewController: [[FinkTextViewController alloc] 
								initWithView:textView
								forScrollView:outputScrollView]];
									
	//Set state of View menu column items
    while (nil != (columnName = [columnNameEnumerator nextObject])){
    	int atag = [self tagFromAttributeName:columnName];
		[[columnsMenu itemWithTag:atag] setState:NSOnState];
    }

	if ([outputScrollView bounds].size.height < 1.0){
		[collapseExpandMenuItem setTitle:LS_EXPAND];
	}else{
		[splitView expandOutputToMinimumRatio:0.0];
		[collapseExpandMenuItem setTitle:LS_COLLAPSE];
	}
	
    [self setupToolbar];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSTableColumn *lastColumn = [tableView tableColumnWithIdentifier:
				    [tableView lastIdentifier]];
	NSString *direction = [defaults objectForKey:FinkColumnStateDictionary][[tableView lastIdentifier]];
    NSString *basePath = [defaults objectForKey:FinkBasePath];

    if ([basePath length] <= 1 ){
		NSBeginAlertSheet(NSLocalizedString(@"Fink could not be located.", @"Alert sheet title"),
					LS_OK, nil,	nil, //title, buttons
					window, self, NULL,	NULL, nil, //window, delegate, selectors, c info
					NSLocalizedString(@"Please make sure Fink is installed before using FinkCommander. If you've already installed Fink, try setting the path to Fink manually in Preferences.", 
										@"Alert sheet message"), nil);
    }
    [self updateTable:nil];

    [tableView setHighlightedTableColumn:lastColumn];
    
    if ([direction isEqualToString:@"normal"])
    {
        [tableView setIndicatorImage: [tableView normalSortImage]
                       inTableColumn:lastColumn];
    }
    else if ([direction isEqualToString:@"reverse"])
    {
        [tableView setIndicatorImage: [tableView reverseSortImage]
                       inTableColumn:lastColumn];
    }

    if ([defaults boolForKey: FinkAutoExpandOutput]){
		[splitView collapseOutput: nil];
    }

	if ([defaults boolForKey:FinkCheckForNewVersion]){
		NSLog(@"Checking for FinkCommander update");
		[NSThread detachNewThreadSelector:@selector(checkForLatestVersion:) toTarget:self withObject:NO];
	}
}

//================================================================================
#pragma mark APPLICATION AND WINDOW DELEGATES
//================================================================================

//warn before quitting if a command is running
-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    int answer;

    if (commandIsRunning){ //see windowShouldClose: method
		answer = NSRunCriticalAlertPanel(LS_WARNING, 
						NSLocalizedString(@"Quitting now will interrupt a Fink process.", 
									@"Alert panel message"),
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
		[[NSMenuItem alloc] 
			initWithTitle:NSLocalizedString(@"Show Main Window", @"Menu Item Title")
			action:@selector(bringBackMainWindow:)
			keyEquivalent:@""];

	[windowMenu insertItem:raiseMainWindowItem atIndex:2];
	[windowMenu insertItem:[NSMenuItem separatorItem] atIndex:3];
}

//make sure the authorization terminates at the end of each FC session
-(void)applicationWillTerminate:(NSNotification*)anotification
{
	[NSApp setApplicationIconImage:[NSImage imageNamed:@"NSApplicationIcon"]];
    [[self finkTask] unAuthorize];
}

//================================================================================
#pragma mark MAIN MENU
//================================================================================

//----------------------------------------------->Application Menu
#pragma mark Application Menu

-(IBAction)showPreferencePanel:(id)sender
{
    if (![self preferences]){
		[self setPreferences: [[FinkPreferences alloc] init]];
    }
    [[self preferences] showWindow:self];
}

//Helper; separated from action method because also called on schedule
-(void)checkForLatestVersion:(BOOL)notifyWhenCurrent
{
	@autoreleasepool {
		NSString *installedVersion = [[NSBundle bundleForClass:[self class]]
			infoDictionary][@"CFBundleShortVersionString"];
		NSDictionary *latestVersionDict =
			[NSDictionary dictionaryWithContentsOfURL:
				[NSURL URLWithString:@"http://finkcommander.sourceforge.net/pages/version.xml"]];
		NSString *latestVersion = [defaults objectForKey: @"FinkAvailableUpdate"];

		if ([installedVersion compare: latestVersion] == NSOrderedAscending){
			int answer = NSRunCriticalAlertPanel(NSLocalizedString(@"A new version of FinkCommander is available from SourceForge.\nDo you want to upgrade your copy?",@"Update alert title"),
				NSLocalizedString(@"FinkCommander can automatically check for new and updated versions using its Software Update feature. Select Software Update in FinkCommander Preferences to specify how frequently to check for updates.", @"Update alert message"),
				NSLocalizedString(@"Upgrade Now", @"Update alert default"),
				NSLocalizedString(@"Change Preferences…", @"Update alert alternate"),
				NSLocalizedString( @"Ask Again Later", @"Update alert other"));
			switch (answer){
				case NSAlertDefaultReturn:
					[[NSWorkspace sharedWorkspace] openURL:
						[NSURL URLWithString:@"http://finkcommander.sourceforge.net"]];
				case NSAlertAlternateReturn:
					[self showPreferencePanel:nil];
			}
		}else if (notifyWhenCurrent && latestVersionDict){
			NSRunAlertPanel(
				NSLocalizedString(@"Current", @"Title of update alert panel when the current version of FC is installed"),
				NSLocalizedString(@"The latest version of FinkCommander is installed on your system.", @"Message of update alert panel when the current version of FC is installed"),
				LS_OK, nil, nil);
		}

		if (latestVersionDict){
			[defaults setObject:latestVersionDict[@"FinkCommander"] forKey: @"FinkAvailableUpdate"];
		}else if (notifyWhenCurrent){
			NSRunAlertPanel(LS_ERROR,
				NSLocalizedString(@"FinkCommander was unable to locate online update information.\n\nTry visiting the FinkCommander web site (available under the Help menu) to check for a more recent version of FinkCommander.", @"Alert message"),
				LS_OK, nil, nil);
		}
	}
}

-(void)checkForUpdate:(NSNotification *)aNotification
{
	[self checkForLatestVersion:YES];
}

//----------------------------------------------->File Menu
#pragma mark File Menu

//usually called by other methods after a command runs
-(IBAction)updateTable:(id)sender
{
    [self startProgressIndicatorAsIndeterminate:YES];
    [msgText setStringValue:NSLocalizedString(@"Updating table data", "Status bar message")];
    commandIsRunning = YES;

    [[self packages] update];
}

-(IBAction)saveOutput:(id)sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    NSString *defaultPath = [defaults objectForKey: FinkOutputPath];
    NSString *savePath = ([defaultPath length] > 0) ? defaultPath : NSHomeDirectory();
    NSString *fileName = @"Untitled";
	
	if (nil != [self lastCommand]){
		fileName = [NSString stringWithFormat: @"%@_%@",
					[self lastCommand],
					[[NSDate date] descriptionWithCalendarFormat:
								@"%d%b%Y" timeZone: nil locale: nil]];
	} 
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
    if (code == NSOKButton){
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

-(IBAction)toggleFlags:(id)sender
{
	int currentState = [[[tableView selectedPackageArray] lastObject]
								flagged];
	int newState = (NOT_FLAGGED == currentState) ? IS_FLAGGED : NOT_FLAGGED;
	NSEnumerator *e = [[tableView selectedPackageArray] objectEnumerator];
	FinkPackage *package;
	NSMutableArray *flagArray = [[defaults objectForKey:FinkFlaggedColumns] mutableCopy];

	while (nil != (package = [e nextObject])){
		[package setFlagged:newState];
		if (IS_FLAGGED == newState){
			[flagArray addObject:[package name]];
		}else if ([flagArray containsObject:[package name]]){
			[flagArray removeObject:[package name]];
		}
	}
	[defaults setObject:[flagArray copy] forKey:FinkFlaggedColumns];
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

    [[[self textViewController] textView] setString: @""];

    while (nil != (pkg = [e nextObject])){
		full = [NSString stringWithFormat: @"%@-%@:   %@\n",
			[pkg name],
			[pkg version],
			[pkg fulldesc]];
		if (i > 0){
			[[self textViewController] appendString:divider];
		}
		[[self textViewController] appendString:full];
		i++;
    }
}

//----------------------------------------------->Tools Menu
#pragma mark Tools Menu

-(void)runTerminateCommand:(NSNotification *)ignore
{
	NSString *pgid = [NSString stringWithFormat:@"%d", [[self parser] pgid]];
		
	if (![self killTask]) 	[self setKillTask: [[AuthorizedExecutable alloc] initWithExecutable:launcher]];
    [[self killTask] setArguments:
		[@[@"--kill", pgid] mutableCopy]];
    [[self killTask] setEnvironment:[defaults objectForKey:FinkEnvironmentSettings]];
    [[self killTask] authorizeWithQuery];
    [[self killTask] start];
	commandTerminated = YES;
}

-(IBAction)terminateCommand:(id)sender
{
    if ([defaults boolForKey: FinkWarnBeforeTerminating]){
		if (! [self warningDialog]){
			[self setWarningDialog: [[FinkWarningDialog alloc] init]];
		}
		[[self warningDialog] showTerminateWarning];
		return;
    }
    [self runTerminateCommand:nil];
}

//show package inspector
-(IBAction)showPackageInfoPanel:(id)sender
{
    NSString *sig = [[self installationInfo] formattedEmailSig];

    if (![self packageInfo]){
		[self setPackageInfo: [[FinkPackageInfo alloc] init]];
    }
    [[self packageInfo] setEmailSig: sig];
    [[self packageInfo] showWindow: self];
    [[self packageInfo] displayDescriptions: [tableView selectedPackageArray]];
}

//change inspector content when table selection changes
-(void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    if ([self packageInfo] && [[[self packageInfo] window] isVisible]){
		[[self packageInfo] displayDescriptions: [tableView selectedPackageArray]];
    }
}

//Helper for feedback commands
-(void)sendEmailWithMessage:(int)typeOfFeedback
{
    NSEnumerator *e = [[tableView selectedPackageArray] objectEnumerator];
    NSString *sig = [[self installationInfo] formattedEmailSig];
	NSString *feedbackMessage;
	NSString *emailTemplate;
	NSString *emailBody;
    FinkPackage *pkg;
    NSMutableArray *pkgNames = [NSMutableArray arrayWithCapacity:5];

    if (![self packageInfo]){
		[self setPackageInfo: [[FinkPackageInfo alloc] init]];
    }
	
	emailTemplate = @"Hello, there. This is a feedback e-mail with regard to package %@-%@. %@\n"; 
	
	if (typeOfFeedback == POSITIVE)
		feedbackMessage = @"It works like a charm, thanks!";
	else if (typeOfFeedback == NEGATIVE)
		feedbackMessage = @"I am having the following problem(s):\n";
	else
		feedbackMessage = @"Ooops, FinkCommander doesn't know whether this feedback is positive or negative!";
	
    [[self packageInfo] setEmailSig:sig];
	
    while (nil != (pkg = [e nextObject])){
		if (typeOfFeedback == POSITIVE   &&
			[[pkg installed] length] > 1 &&
			[[pkg installed] isEqualToString:[pkg stable]]){
			[pkgNames addObject:[pkg name]];
			continue;
		}
		if (typeOfFeedback == NEGATIVE							&&
			[[pkg stable] length] > 1							&&
			! [[pkg installed] isEqualToString:[pkg version]]	&&  //version = latest
			! [[pkg installed] isEqualToString:[pkg stable]]){
			[pkgNames addObject:[pkg name]];
		}
		emailBody = [NSString stringWithFormat:emailTemplate, [pkg name], [pkg version], feedbackMessage];
		[[NSWorkspace sharedWorkspace] openURL:[[self packageInfo] mailURLForPackage:pkg withBody:emailBody]];
    }
	if (typeOfFeedback == POSITIVE && [pkgNames count] > 0){
		NSString *msg = [pkgNames count] > 1 ? 
						NSLocalizedString(@"Your selection includes the following stable packages:\n\n\t%@\n\nStable packages are known to work properly, so sending positive feedback about them is unnecessary.", 
								@"Alert message, plural version") :
						NSLocalizedString(@"Your selection includes the following stable package:\n\n\t%@\n\nStable packages are known to work properly, so sending positive feedback about them is unnecessary.", 
								@"Alert message, singular version");
		NSBeginAlertSheet(LS_ERROR,
					LS_OK, nil, nil,
					window, self, NULL, NULL, nil,
					[NSString stringWithFormat: msg, [pkgNames componentsJoinedByString:@", "]],
					nil);
	}
	if (typeOfFeedback == NEGATIVE && [pkgNames count] > 0){
		NSString *msg = [pkgNames count] > 1 	?
				NSLocalizedString(@"You do not have the latest version of the following packages:\n\n\t%@\n\nUnless the problem you want to report is that you cannot install the latest versions, you should install and try them before sending negative feedback.", @"Alert message, plural version")  :
				NSLocalizedString(@"You do not have the latest version of the following package:\n\n\t%@\n\nUnless the problem you want to report is that you cannot install the latest version, you should install and try it before sending negative feedback.", @"Alert message, singular version");
 		NSBeginAlertSheet(LS_WARNING,
 					LS_OK, nil, nil,
 					window, self, NULL, NULL, nil,
					[NSString stringWithFormat: msg, 
						[pkgNames componentsJoinedByString:@", "]],
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
	FinkPackage *pkg = [tableView displayedPackages][[tableView selectedRow]];
	
	if (! [[pkg status] contains:@"u"]){
		NSBeep();
		return;
	}
	[[self treeManager] openNewWindowForPackageName:[pkg name]];
}

-(void)treeWindowWillClose:(id)sender
{
	[[self treeManager] closingTreeWindowWithController:sender];
}


-(IBAction)openDocumentation:(id)sender
{
	FinkPackage *pkg = [tableView displayedPackages][[tableView selectedRow]];
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSString *root = [[defaults objectForKey:FinkBasePath] 
						stringByAppendingPathComponent:@"share/doc"];
	NSString *path = [root stringByAppendingPathComponent:[pkg name]];
	NSArray *pathContents;

	if (![mgr fileExistsAtPath:path]){
		NSBeep();
		return;
	}
	pathContents = [mgr directoryContentsAtPath:path];
	if (nil != pathContents && [pathContents count] > 0){
		path = [path stringByAppendingPathComponent:pathContents[0]];
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

-(IBAction)openHelpInWebBrowser:(id)sender
{
	NSString *pathToHelp = 
		[[[NSBundle mainBundle] pathForResource:@"FinkCommander Help"
								ofType:nil]
						stringByAppendingPathComponent:@"fchelp.html"];
								
	openFileAtPath(pathToHelp);
}

// show the "About FinkCommander" window with some fink information
-(IBAction)showAboutWindow:(id)sender
{
	NSString *finkVersion = [NSString stringWithFormat:@"Fink version\n%@",[[FinkInstallationInfo sharedInfo] finkVersion]];
	NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[style setAlignment:NSCenterTextAlignment];
	NSDictionary *attributes = @{NSFontAttributeName: [NSFont systemFontOfSize:[NSFont smallSystemFontSize]],
		NSParagraphStyleAttributeName: style};
	NSAttributedString *credits = [[NSAttributedString alloc] initWithString:finkVersion attributes:attributes];
	[NSApp orderFrontStandardAboutPanelWithOptions:@{@"Credits": credits}];
}
//Help menu internet access items
-(IBAction)goToWebsite:(id)sender
{
    NSString *url = nil;

    switch ([sender tag]){
		case FCWEB:
			url = @"http://finkcommander.sourceforge.net/";
			break;
		case FCBUG:
			url = @"http://finkcommander.sourceforge.net/help/bugs.php";
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
	[self setToolbar: [[FinkToolbar alloc] initWithIdentifier: @"mainToolbar"]];
	[[self toolbar] setDelegate: self];
	[[self toolbar] setAllowsUserCustomization: YES];
	[[self toolbar] setAutosavesConfiguration: YES];
	[[self toolbar] setDisplayMode: NSToolbarDisplayModeIconOnly];
	[[self toolbar] setSearchField:searchTextField];
	id searchCell = [searchTextField cell];
	[searchCell setSearchMenuTemplate: [searchCell searchMenuTemplate]];
#ifndef OSXVER101
	[[self toolbar] setSizeMode:NSToolbarSizeModeSmall];
#endif
    [window setToolbar: [self toolbar]];
}

//reapply filter if search field values have changed
-(IBAction)refilter:(id)sender
{
	if ([(sender) isKindOfClass:[NSMenuItem class]]) {
		NSEnumerator *menuItems = [[[sender menu] itemArray] objectEnumerator];
		NSMenuItem *menuItem;
		while (nil != (menuItem = [menuItems nextObject])) {
			[menuItem setState:NSOffState];
		}
		[sender setState:NSOnState];
		searchTag = [sender tag];
	}
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

    itemDict = d[itemIdentifier];
    if ((value = itemDict[@"Label"])){
		[item setLabel: value];
		[item setPaletteLabel: value];
    }
    if ((value = itemDict[@"PaletteLabel"]))
		[item setPaletteLabel: value];
    if ((value = itemDict[@"ToolTip"]))
		[item setToolTip: value];
    if ((value = itemDict[@"Image"]))
		[item setImage: [NSImage imageNamed: value]];
    if ((value = itemDict[@"Action"])){
		[item setTarget: self];
		[item setAction: NSSelectorFromString([NSString
						  stringWithFormat: @"%@:", value])];
    }
    if ((tag = itemDict[@"Tag"])){
		[item setTag: [tag intValue]];
    }
    if ([itemIdentifier isEqualToString:@"FinkFilterItem"]){
		[item setView: searchView];
		[item setMinSize:NSMakeSize(204, NSHeight([searchView frame]))];
		[item setMaxSize:NSMakeSize(400, NSHeight([searchView frame]))];
    }
    return item;
}

-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return @[NSToolbarSeparatorItemIdentifier,
				NSToolbarSpaceItemIdentifier,
				NSToolbarFlexibleSpaceItemIdentifier,
				NSToolbarCustomizeToolbarItemIdentifier,
				@"FinkInstallSourceItem",
				@"FinkInstallBinaryItem",
				@"FinkRemoveSourceItem",
				@"FinkRemoveBinaryItem",
				@"FinkSelfUpdateItem",
				@"FinkSelfUpdateRsyncItem",
				@"FinkSelfUpdateCVSItem",
				@"FinkUpdateallItem",
				@"FinkUpdateBinaryItem",
				@"FinkDescribeItem",
				@"FinkTermInstallItem",
				@"FinkTermRsyncItem",
				@"FinkTermCvsItem",
				@"FinkInteractItem",
				@"FinkTerminateCommandItem",
				@"FinkBrowseItem",
				@"FinkPositiveEmailItem",
				@"FinkEmailItem",
				@"FinkFilterItem"];
}

-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return 	@[@"FinkInstallBinaryItem",
				@"FinkInstallSourceItem",
				@"FinkRemoveSourceItem",
				@"FinkSelfUpdateRsyncItem",
				NSToolbarSeparatorItemIdentifier,
				@"FinkTerminateCommandItem",
				@"FinkDescribeItem",
				@"FinkBrowseItem",
				@"FinkPositiveEmailItem",
				@"FinkEmailItem",
				NSToolbarFlexibleSpaceItemIdentifier,
				@"FinkFilterItem"];
}

//----------------------------------------------->Text Field Delegate
#pragma mark Text Field Delegate

-(void)controlTextDidChange:(NSNotification *)aNotification
{
    /* 	When this notification is received from the text field in the filter, apply
		the filter to the table data source */
    if ([[aNotification object] tag] == FILTER){
		/* 	Translate the tag for the selected menu in the popup button into a string
			corresponding to a fink package attribute */
		NSString *field = [self attributeNameFromTag: searchTag];
		NSString *filterText = [[searchTextField stringValue] lowercaseString];
		NSString *pkgAttribute;
		/* 	Used to store the subset of the packages array that matches the filter text */
		NSMutableArray *subset = [NSMutableArray array];
		NSEnumerator *e = [[[self packages] array] objectEnumerator];
                regex_t regex;
		FinkPackage *pkg;

		//Store selected object information before the filter is applied
		if ([defaults boolForKey: FinkScrollToSelection]){
			[tableView storeSelectedObjectInfo];
		} 
                if ([defaults boolForKey: FinkAllowRegexFiltering]){                    
                    regcomp(&regex, [filterText UTF8String], REG_EXTENDED);
                    // If regex construction fails it is no big deal really, probably in the middle of typing one like "Ben|"
		}		

		if ([filterText length] == 0){
			[tableView setDisplayedPackages: [[self packages] array]];
		}else{
			while (nil != (pkg = [e nextObject])){
				pkgAttribute = [[pkg valueForKey:field] lowercaseString];
				/* 	If the value matches the filter term, add it to the subset */
                                if([defaults boolForKey: FinkAllowRegexFiltering] && 
                                    !regexec(&regex, [pkgAttribute UTF8String], 0, 0, 0)){
                                    [subset addObject: pkg];
				} else 
				if ([pkgAttribute contains:filterText]){
					[subset addObject:pkg];
				}
			}
			[tableView setDisplayedPackages:[subset copy]];
		}
		[tableView resortTableAfterFilter];

		//Restore the selection and scroll back to it after the table is sorted
		if ([defaults boolForKey: FinkScrollToSelection]){
			[tableView scrollToSelectedObject];
		}
		[self displayNumberOfPackages];
	/* 	When the notification is received from the interaction dialog, automatically 
		select the radio button appropriate for the state of the text entry field  */
    }else if ([[aNotification object] tag] == INTERACTION){
		if ([[interactionField stringValue] length] > 0){
			[interactionMatrix selectCellWithTag:USER_CHOICE];
		}else{
			[interactionMatrix selectCellWithTag:DEFAULT];
		}
    }
}

//================================================================================
#pragma mark VALIDATION
//================================================================================

// Validation logic for menu and toolbar item validation methods
-(BOOL)validateItem:(id)theItem
{
	SEL itemAction = [theItem action];

    /*
	 *  Disable menu and toolbar items when the command will not be effective
	 */

    // If no row is selected, disable commands that operate on packages
    if ([tableView selectedRow] == -1){
		if (itemAction == @selector(runPackageSpecificCommand:) 	||
			itemAction == @selector(runForceRemove:)	           	||
			itemAction == @selector(showDescription:)           	||
			itemAction == @selector(showPackageInfoPanel:)			||
			itemAction == @selector(sendNegativeFeedback:)	   		||
			itemAction == @selector(sendPositiveFeedback:)	   		||
			itemAction == @selector(openDocumentation:)	   			||
			itemAction == @selector(openPackageFileViewer:)	   		||
			itemAction == @selector(toggleFlags:)               	||
			itemAction == @selector(runPackageSpecificCommandInTerminal:)){
			return NO;
		}
		// Otherwise, disable commands that are not appropriate for a particular package
    }else{
		// Disable apt-get install if there is no binary version
		NSString *itemName = ACTION_ITEM_IDENTIFIER(theItem);
		if ([itemName isEqualToString:@"install"] && [theItem tag] == APT_GET){
			NSEnumerator *e = [[tableView selectedPackageArray] objectEnumerator];
			FinkPackage *pkg;
			while (nil != (pkg = [e nextObject])){
				if ([[pkg binary] length] < 2){
					return NO;
				}
			}
		}
		// Disable package file accessors, if the package is not installed
		if (itemAction == @selector(openDocumentation:) 			||
			itemAction == @selector(openPackageFileViewer:)){
			FinkPackage *pkg = [tableView displayedPackages][[tableView selectedRow]];
			if (! [[pkg status] contains:@"u"]){ //current or outdated
				return NO;
			}
		}
	}

	/* 	If a command is running, disable fink, apt-get and dpkg commands,
		table update and save output */
	if (commandIsRunning){
		if (itemAction == @selector(runPackageSpecificCommand:)  	||
			itemAction == @selector(runNonSpecificCommand:)      	||
			itemAction == @selector(runForceRemove:)	       		||
			itemAction == @selector(showDescription:)	       		||
			itemAction == @selector(saveOutput:)		       		||
			itemAction == @selector(updateTable:)){
			return  NO;
		}
	// Otherwise disable the interaction and terminate commands
	}else{
		if (itemAction == @selector(raiseInteractionWindow:) ||
			itemAction == @selector(terminateCommand:)){
			return NO;
		}
	}

	// Disable sorting for columns not in the table
	if (itemAction == @selector(sortByPackageElement:) &&
		! [[defaults objectForKey:FinkTableColumnsArray] containsObject:
				[self attributeNameFromTag:[theItem tag]]]){
		return NO;
	}

	// Disable save output if there's nothing in the text view
	if ([[textView string] length] < 1 && [theItem action] == @selector(saveOutput:)){
		return NO;
	}

	/*
	 * Toggle menu item titles.
	 */

	if (itemAction == @selector(toggleFlags:)){
		if ([[[tableView selectedPackageArray] lastObject] flagged] == 0){
			[theItem setTitle:NSLocalizedString(@"Mark As Flagged",
									   @"Menu title: Put flag image in table column")];
		}else{
			[theItem setTitle:NSLocalizedString(@"Mark As Unflagged",
									   @"Menu title: Remove flag image from table column")];
		}
		return YES;
	}
	if (itemAction == @selector(toggleToolbarShown:)){
		if ([[self toolbar] isVisible]){
			[theItem setTitle:NSLocalizedString(@"Hide Toolbar", @"Menu title")];
		}else{
			[theItem setTitle:NSLocalizedString(@"Show Toolbar", @"Menu title")];
		}
		return YES;
	}
	return YES;
}

//Disable menu items
-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
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

/*
 *	Helper for Menu and Toolbar Commands 
 */

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
		cmd = ACTION_ITEM_IDENTIFIER(sender);
		[self setLastCommand:cmd];
		args = [NSMutableArray arrayWithObjects: exe, cmd, nil];
		if ([defaults boolForKey: FinkAlwaysChooseDefaults]){
			[args insertObject: @"-y" atIndex: 1];
		}
		if (type == APT_GET){
			[args insertObject: @"-f" atIndex: 1];
			[args insertObject: @"-q0" atIndex: 1];
		}
		if (type == FINK && [cmd isEqualToString:@"cleanup"]){
			args = [NSMutableArray arrayWithObjects: exe, cmd,
			@"--srcs", @"--debs", @"--bl", @"--dpkg-status", nil];
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

/*
 *	Run-in-Terminal Methods 
 */

#ifndef OSXVER101

//Helper
-(void)launchCommandInTerminal:(NSString *)cmd
{
	NSAppleScript *script;
	NSAppleEventDescriptor *descriptor;
	NSDictionary *errord;
	NSString *terminal = [[defaults objectForKey: @"FinkEnvironmentSettings"] valueForKey:@"TERM_PROGRAM"];

	if ([terminal isEqualToString: @"Apple_Terminal"]){
		cmd = [NSString stringWithFormat:@"tell application \"Terminal\"\nactivate\ndo script \"%@\"\n end tell", cmd];
	} else {
		if ([terminal isEqualToString: @"iTerm.app"]){
			cmd = [NSString stringWithFormat:@"tell application \"iTerm\"\nactivate\ntell the first terminal\nset mysession to (make new session at the end of sessions)\ntell mysession\nset name to \"FinkCommander\"\nexec command \"%@\"\nend tell\nend tell\nend tell", cmd];
		}
	}
	script = [[NSAppleScript alloc] initWithSource:cmd];
	descriptor = [script executeAndReturnError:&errord];
	if (! descriptor){
		NSLog(@"Apple script failed to execute");
		NSLog(@"Error dictionary:\n%@", [errord description]);
	}
}

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

#endif /* ! OSXVER101 */

/*
 *	Run-in-FinkCommander Methods 
 */

//Helper
-(void)launchCommandWithArguments:(NSMutableArray *)args
{
    NSString *exec = args[0];
	NSMutableDictionary *envvars = [NSMutableDictionary dictionaryWithDictionary: [defaults objectForKey:FinkEnvironmentSettings]];
	NSString *askpass;
	[envvars setValue:@(getenv("SSH_AUTH_SOCK")) forKey:@"SSH_AUTH_SOCK"];
	[envvars setValue:@"0" forKey:@"DISPLAY"];
	askpass = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/SSHAskPass.sh"];
	[envvars setValue:askpass forKey:@"SSH_ASKPASS"];

    pendingCommand = NO; 	//no command waiting in line
    toolIsBeingFixed = NO;
    commandIsRunning = YES;
    [self setParser:[[FinkOutputParser alloc] initForCommand:[self lastCommand]
											  executable:exec]];
    [self displayCommand: args];
	[NSApp setApplicationIconImage:[NSImage imageNamed:@"finkcommanderatwork"]];

    [[self finkTask] setArguments:args];
    [[self finkTask] setEnvironment:envvars];
    [[self finkTask] authorizeWithQuery];
    [[self finkTask] start];
	[[self textViewController] setLimits];
    [[[self textViewController] textView]
		replaceCharactersInRange:NSMakeRange(0, [[textView string] length])
					  withString:@""];
}

-(IBAction)runPackageSpecificCommand:(id)sender
{
    NSMutableArray *args = [self argumentListForCommand:sender packageSpecific:YES];

    if ([args containsObject: @"remove"] &&
		[defaults boolForKey: FinkWarnBeforeRemoving]){
		if (! [self warningDialog]){
			[self setWarningDialog: [[FinkWarningDialog alloc] init]];
		}
		[[self warningDialog] showRemoveWarningForArguments:args];
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
    int answer = 
		NSRunCriticalAlertPanel(LS_WARNING,
								NSLocalizedString(@"Running Force Remove will remove the selected package even if other packages depend on it\n\nAre you sure you want to proceed?", @"Alert panel message"),
								LS_REMOVE, LS_CANCEL, nil);
    if (answer == NSAlertAlternateReturn) return;

    args = [self argumentListForCommand:sender packageSpecific:YES];
    [self launchCommandWithArguments:args];
}

//Allow other objects, e.g. FinkConf, to run authorized commands
-(void)runCommandOnNotification:(NSNotification *)note
{
    NSMutableArray *args = [note object];
    NSString *cmd = args[0];
    NSNumber *indicator = [note userInfo][FinkRunProgressIndicator];

	Dprintf(@"Running command %@ on notification", cmd);

    if (commandIsRunning && !toolIsBeingFixed){
		NSRunAlertPanel(LS_SORRY,
				  NSLocalizedString(@"You must wait until the current process is complete before taking that action.\nTry again when the number of packages or the word \"Done\" appears below the output view.", @"Alert panel message"),
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
    //Prevent tasks run by consecutive notifications from tripping over each other
    [self performSelector:@selector(launchCommandWithArguments:)
					 withObject:args
					 afterDelay:1.0];
}

//================================================================================
#pragma mark INTERACTION SHEET
//================================================================================

-(IBAction)raiseInteractionWindow:(id)sender
{
    [splitView expandOutputToMinimumRatio:0.4];
    [[[self textViewController] textView] scrollRangeToVisible:
		NSMakeRange([[[[self textViewController] textView] string] length], 0)];

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
		if ([[interactionMatrix selectedCell] tag] == DEFAULT){
			[[self finkTask] writeToStdin: @"\n"];
		}else{
			[[self finkTask] writeToStdin: [NSString stringWithFormat:@"%@\n",
				[interactionField stringValue]]];
		}
		[[self textViewController] appendString:@"\n"];
		if ([defaults boolForKey:FinkAutoExpandOutput]){
			[splitView collapseOutput:nil];
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
    NSArray *phases = @[@"", @"Fetching %@", @"Unpacking %@",
		@"Configuring %@", @"Compiling %@",
		@"Building %@", @"Activating %@"];
    NSString *pname, *phaseString;

    pname = [[self parser] currentPackage];
    phaseString = phases[phaseIndex];
	phaseString = 
		[[NSBundle mainBundle] 
			localizedStringForKey:phaseString
			value:phaseString
			table:@"Programmatic"];
    [msgText setStringValue:[NSString stringWithFormat:phaseString, pname]];
    [self incrementProgressIndicator:[[self parser] increment]];
}

-(void)interactIfRequired
{
    if (! [defaults boolForKey:FinkAlwaysChooseDefaults]){
		NSBeep();
		[self raiseInteractionWindow:self];
    }
}

/*	Scroll to the latest addition to output if user has selected the option
	to always do so, or if the scroll thumb is at or near the bottom */
-(void)scrollToVisible:(NSNumber *)pixelsBelowView
{
    /*	Window or splitview resizing often results in some gap between
    	the scroll thumb and the bottom, so the test shouldn't be whether
		there are 0 pixels below the scroll view */
    if ([pixelsBelowView floatValue] <= 100.0 ||
		[defaults boolForKey: FinkAlwaysScrollToBottom]){
		[[[self textViewController] textView] scrollRangeToVisible:
			NSMakeRange([[[[self textViewController] textView] string] length], 0)];
    }
}

-(void)processOutput:(NSString *)output
{
	@autoreleasepool {

    /* Determine how much output is below the scroll view based on
       the following calculation (in vertical pixels):

       Total document length									-
       Length above scroll view (y coord of visible portion)  	-
       Length w/in scroll view 				      			  	=
       ----------------------------------------------------
       Length below scroll view

    This value is used to determine whether the user has scrolled up.
    If so, the output view will not automatically scroll to the bottom. */
        NSNumber *pixelsBelowView = [NSNumber numberWithFloat:
		abs([[[self textViewController] textView] bounds].size.height 			-
			[[[self textViewController] textView] visibleRect].origin.y 		-
			[[[self textViewController] textView] visibleRect].size.height)];

        int signal = [[self parser] parseOutput:output];
	
        if (commandTerminated) return;
        switch(signal)
        {
		case NONE:
			break;
		case PASSWORD_PROMPT:
			output = @"";
			[[self finkTask] stop];
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
			output = NSLocalizedString(@"The tool that FinkCommander uses to run commands as root does not have the necessary permissions.\nBy entering your password you will give the tool the authorization it needs to repair itself.\nUnder some circumstances you may need to enter your password twice.\n", @"Text displayed in output view");
			break;
		case SELF_REPAIR_COMPLETE:
			output = NSLocalizedString(@"\nSelf-repair succeeded.  Please re-try your command.\n", @"Text displayed in output view");
			commandTerminated = YES;
			break;
		case RESOURCE_DIR_ERROR:
			output = NSLocalizedString(@"\nSelf-repair succeeded, but FinkCommander was unable to change the permissions of the FinkCommander.app/Contents/Resources directory.\nPlease see the README.html file, available at http://finkcommander.sourceforge.net, for instructions on changing the permissions manually.\n", @"Error message that may be displayed in output view");
			break;
		case SELF_REPAIR_FAILED:
			output = NSLocalizedString(@"\nThe tool used to run Fink commands as root was unable to repair itself.\n", @"Error message that may be displayed in output view");
			break;
		case PGID:
			output = @"";
			break;
	}

	if (signal != DYNAMIC_OUTPUT){
		outputIsDynamic = NO;
		[[self textViewController] appendString:output];
	} else {
		if (!outputIsDynamic) {
			outputIsDynamic = YES;
			[[self textViewController] appendString:output];
		}else{
			[[self textViewController] replaceLastLineByString:output];
		}
	}
	//According to Moriarity example, we have to put off scrolling until next event loop
        [self performSelector:@selector(scrollToVisible:)
					 withObject:pixelsBelowView
					 afterDelay:0.0];
					 
	}
}

/*
 * Delegate Methods
 */

-(void)captureOutput:(NSString *)output forExecutable:(id)ignore
{
	[self processOutput:output];
}

-(void)executableFinished:(id)ignore withStatus:(NSNumber *)number
{
    int status = [number intValue];
    int outputLength = [[[[self textViewController] textView] string] length];
    NSString *last2lines = outputLength < 160 ? [[[self textViewController] textView] string] :
		[[[[self textViewController] textView] string] 
			substringWithRange: NSMakeRange(outputLength - 160, 159)];

    Dprintf(@"Finishing command %@ with status %d", [self lastCommand], status);
    NSBeep();

    /*	Make sure command was successful before updating table.
     	Checking exit status is not sufficient for some fink commands, so check
		approximately last two lines for "failed." */
    [tableView setDisplayedPackages:[[self packages] array]];
    if (status == 0 && ! [last2lines containsCI:@"failed"]){
		if (CMD_REQUIRES_UPDATE([self lastCommand]) && ! commandTerminated){
			[self updateTable:nil];   // resetInterface will be called by notification
		}else{
			[self resetInterface:nil];
		}
    }else{
		NSLog(@"Exit status of process = %d", status);
		if (! commandTerminated && ! 15 == status){
			[splitView expandOutputToMinimumRatio:0.0];
			NSBeginAlertSheet(LS_ERROR, LS_OK, nil, nil,
					 window, self, NULL, NULL, nil,
					 NSLocalizedString(@"FinkCommander detected a possible failure message.\nCheck the output window for problems.", @"Alert sheet message"),
					 nil);
		}
		[self resetInterface:[NSNotification notificationWithName:@"FinkError" object:nil]];
	}
	
    commandTerminated = NO;

    [[NSNotificationCenter defaultCenter]
		postNotificationName:FinkCommandCompleted
		object:[self lastCommand]];
}

@end
