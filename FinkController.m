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
	
	NSDictionary *defaultValues = [NSDictionary dictionaryWithContentsOfFile:
		[[NSBundle mainBundle] pathForResource: @"UserDefaults" ofType: @"plist"]];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
}

//----------------------------------------------->Init
-(id)init
{
	if (self = [super init]){
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		
		defaults = [NSUserDefaults standardUserDefaults];
			
		[self setWindowFrameAutosaveName: @"MainWindow"];
		[NSApp setDelegate: self];

		//Set base path default, if necessary; write base path into perl script used
		//to obtain fink package data
		findFinkBasePath(); 
		fixScript();
		
		if (! [defaults boolForKey:FinkInitialEnvironmentHasBeenSet]){
			setInitialEnvironmentVariables();
			[defaults setBool:YES forKey:FinkInitialEnvironmentHasBeenSet];
		}

		//Set instance variables used to store information related to fink package data

		packages = [[FinkDataController alloc] init];	// data used in table
		[self setSelectedPackages: nil];    			// used to update package data
		
		//Set instance variables used to store objects and state information  
		//needed to run fink and apt-get commands
		commandIsRunning = NO;		
		[self setPassword: nil];
		[self setLastParams: nil];
		pendingCommand = NO;
				
		//Flag used to avoid duplicate warnings when user terminates FC 
		//in middle of command with something other than App:Quit
		userChoseToTerminate = NO;

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
		//Register for notification that causes output to collapse when
		//user selects the auto expand option
		[center addObserver: self
				selector: @selector(collapseOutput:)
				name: FinkCollapseOutputView
				object: nil];
		//Register notification that table selection changed in order
		//to update Package Inspector
		[center addObserver: self
				selector: @selector(tableViewSelectionDidChange:)
				name: NSTableViewSelectionDidChangeNotification
				object: nil];
	}
	return self;
}

//----------------------------------------------->Dealloc
-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[packages release];
	[selectedPackages release];
	[preferences release];
	[parser release];
	[lastCommand release];
	[lastParams release];
	[password release];
	[finkTask release];
	[toolbar release];
	[packageInfo release];
	[super dealloc];
}

//----------------------------------------------->Post-Init Startup

-(void)awakeFromNib
{
	NSEnumerator *e = [[viewMenu itemArray] objectEnumerator];
	NSEnumerator *f;
	NSArray *colArray = [defaults objectForKey:FinkTableColumnsArray];
	NSMenuItem *vmenuItem;
	NSString *col;
	NSSize tableContentSize = [tableScrollView contentSize];
	NSSize outputContentSize = [outputScrollView contentSize];

	tableView = 
		[[FinkTableViewController alloc] 
			initWithFrame:NSMakeRect(0, 0, tableContentSize.width, tableContentSize.height)];
	[tableScrollView setDocumentView: tableView];
	[tableView release];
	[tableView setDisplayedPackages:[packages array]];
	[tableView sizeLastColumnToFit];
	[tableView setMenu:tableContextMenu];
	
	textView = 
		[[FinkTextViewController alloc] 
			initWithFrame:NSMakeRect(0, 0, outputContentSize.width, outputContentSize.height)];
	[outputScrollView setDocumentView:textView];
	[textView release];

	while (vmenuItem = [e nextObject]){
		f = [colArray objectEnumerator];
		while (col = [f nextObject]){
			if ([[vmenuItem title] contains:NSLocalizedString(col, nil)]){
				[vmenuItem setState:NSOnState];
				break;
			}
		}
	}
	[self setupToolbar];

	if ([defaults boolForKey: FinkAutoExpandOutput]){
		[self collapseOutput: nil];
	}else{
		//restore to pre-terminate state
		[self expandOutput: nil]; 
	}
	[msgText setStringValue:
		NSLocalizedString(@"UpdatingTable", nil)];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSTableColumn *lastColumn = [tableView tableColumnWithIdentifier:
		[tableView lastIdentifier]];
	NSString *basePath = [defaults objectForKey:FinkBasePath];
	int interval = [defaults integerForKey:FinkCheckForNewVersionInterval];
	NSDate *lastCheckDate = [defaults objectForKey:FinkLastCheckedForNewVersion];
				
	if ([basePath length] <= 1 ){
		NSBeginAlertSheet(NSLocalizedString(@"UnableToLocate", nil),	
				NSLocalizedString(@"OK", nil), nil,	nil, //title, buttons
				[self window], self, NULL,	NULL, nil, //window, delegate, selectors, c info
				NSLocalizedString(@"TrySetting", nil), nil);
	}
	[self updateTable:nil];

	[tableView setHighlightedTableColumn:lastColumn];
	[tableView setIndicatorImage:[tableView normalSortImage] inTableColumn:lastColumn];

	if ([defaults boolForKey:FinkAskForPasswordOnStartup]){
		[self raisePwdWindow:self];
	}
	
#ifdef DEBUGGING
	NSLog(@"Interval for new version check: %d", interval);
	NSLog(@"Last checked for new version: %@", lastCheckDate);
#endif
	
	if (interval && -([lastCheckDate timeIntervalSinceNow] / (24 * 60 * 60)) >= interval){
		NSLog(@"Checking for FinkCommander update");
		[self checkForLatestVersion:NO]; //don't notify if current
	}
}

//helper used in several methods
-(void)displayNumberOfPackages
{	
	if ([defaults boolForKey: FinkPackagesInTitleBar]){				
		[[self window] setTitle: [NSString stringWithFormat: 
			NSLocalizedString(@"PackagesDisplayed", nil),
			[[tableView displayedPackages] count], [packages installedPackagesCount]]];
		if (! commandIsRunning){
			[msgText setStringValue: NSLocalizedString(@"Done", nil)];
		}
	}else if (! commandIsRunning){
		[[self window] setTitle: @"FinkCommander"];
		[msgText setStringValue: [NSString stringWithFormat:
			NSLocalizedString(@"packagesInstalled", nil),
			[[tableView displayedPackages] count], [packages installedPackagesCount]]];
	}
}

//--------------------------------------------------------------------------------
//		ACCESSORS
//--------------------------------------------------------------------------------

-(FinkDataController *)packages  {return packages;}

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

-(void)setPassword:(NSString *)s
{
	[s retain];
	[password release];
	password = s;
}

-(NSMutableArray *)lastParams {return lastParams;}
-(void)setLastParams:(NSMutableArray *)a
{
	[a retain];
	[lastParams release];
	lastParams = a;
}

-(void)setParser:(FinkOutputParser *)p
{
    [p retain];
    [parser release];
    parser = p;
}

//--------------------------------------------------------------------------------
//		APPLICATION AND WINDOW DELEGATES
//--------------------------------------------------------------------------------

//warn before quitting if a command is running
-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	int answer;
	
	if (commandIsRunning && 
		! userChoseToTerminate){ //see windowShouldClose: method
		answer = NSRunCriticalAlertPanel(NSLocalizedString(@"Warning", nil), 
			NSLocalizedString(@"QuittingNow", nil),
			NSLocalizedString(@"Cancel", nil), 
			NSLocalizedString(@"Quit", nil), nil);
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
	if (commandIsRunning){
		int answer = NSRunCriticalAlertPanel(NSLocalizedString(@"Warning", nil),
				NSLocalizedString(@"QuittingNow", nil),
				NSLocalizedString(@"Cancel", nil), 
				NSLocalizedString(@"Quit", nil), nil);
		if (answer == NSAlertDefaultReturn){
			return NO;
		}
	}
	userChoseToTerminate = YES; //flag to make sure we ask only once
	return YES;
}

//--------------------------------------------------------------------------------
//		MENU COMMANDS AND HELPERS
//--------------------------------------------------------------------------------

//----------------------------------------------->Helpers Used In Various Methods

//display running command below table
-(void)displayCommand:(NSArray *)params
{
	[msgText setStringValue: [NSString stringWithFormat: NSLocalizedString(@"Running", nil),
		[params componentsJoinedByString: @" "]]];
}

-(void)startProgressIndicatorAsIndeterminate:(BOOL)b
{
    [progressIndicator setIndeterminate:b];
    if (! [progressView isDescendantOf: progressViewHolder]){
		[progressViewHolder addSubview: progressView];
		[progressIndicator setUsesThreadedAnimation: YES];
		[progressIndicator startAnimation: nil];
    }
}

-(void)stopProgressIndicator
{
    if ([progressView isDescendantOf: progressViewHolder]){
		[progressIndicator stopAnimation: nil];
		[progressView removeFromSuperview];
	}
}

//reset the interface--stop and remove progress indicator, revalidate
//command menu and toolbar items, reapply filter--after the table data
//is updated or a command is completed
-(void)resetInterface:(NSNotification *)ignore
{
	[self stopProgressIndicator];
	[self displayNumberOfPackages];
	commandIsRunning = NO;
	[tableView deselectAll: self];
	[self controlTextDidChange: nil]; //reapplies filter, which re-sorts table
}

-(NSString *)attributeNameFromTag:(int)atag
{
	switch(atag){
		case NAME:
			return @"name";
		case VERSION:
			return @"version";
		case INSTALLED:
			return @"installed";
		case BINARY:
			return @"binary";
		case UNSTABLE:
			return @"unstable";
		case STABLE:
			return @"stable";
		case STATUS:
			return @"status";
		case CATEGORY:
			return @"category";
		case SUMMARY:
			return @"summary";
		case MAINTAINER:
			return @"maintainer";
	}
	return @"";
}

//----------------------------------------------->Running Commands

//usually called by other methods after a command runs
-(IBAction)updateTable:(id)sender
{
	[self startProgressIndicatorAsIndeterminate:YES];
	[msgText setStringValue: NSLocalizedString(@"UpdatingTable", nil)];
	commandIsRunning = YES;

	[packages update];
}

//there are separate action methods for running package-specific and
//non-package-specific commands; this allows choosing the appropriate
//method in IB, rather than changing the command method, when new 
//commands are added (the sender tag is already used to distinguish
//fink and apt-get commands)

//helper: sets up the argument list and flags for either command method
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
	executable = [NSString stringWithFormat:@"%@/bin/%@", 
					[defaults objectForKey:FinkBasePath], executable];
	args = [NSMutableArray arrayWithObjects: executable, cmd, nil];

	commandIsRunning = YES;
	[self setLastCommand: cmd];
	return args;
}

//run package-specific command with arguments derived from table selection
-(IBAction)runCommand:(id)sender
{
	NSMutableArray *args = [self setupCommandFrom: sender];
	NSMutableArray *pkgNames = [NSMutableArray array];
	FinkPackage *pkg;
	NSEnumerator *e = [[tableView selectedPackageArray] objectEnumerator];

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

-(IBAction)forceRemove:(id)sender
{
	NSString *dpkg = [NSString stringWithFormat:@"%@/bin/%@", 
						[defaults objectForKey:FinkBasePath], @"dpkg"];
	NSMutableArray *args = [NSMutableArray arrayWithObjects:
		dpkg, @"--remove", @"--force-depends", nil];
	NSMutableArray *pkgNames = [NSMutableArray array];
	NSEnumerator *e = [[tableView selectedPackageArray] objectEnumerator];
	FinkPackage *pkg;

	int answer = NSRunCriticalAlertPanel(NSLocalizedString(@"Warning", nil),
							  NSLocalizedString(@"RunningForceRemove", nil),
							  NSLocalizedString(@"Yes", nil),
							  NSLocalizedString(@"No", nil), nil);

	if (answer == NSAlertAlternateReturn){
		return;
	}
	
	while (pkg = [e nextObject]){
		[pkgNames addObject: [pkg name]];
	}
	commandIsRunning = YES;
	[self setLastCommand: @"dpkg"];
	[self setSelectedPackages:pkgNames];
	[args addObjectsFromArray:pkgNames];
	[self displayCommand:args];
	[self runCommandWithParameters: args];
}

//faster substitute for fink describe command; preserves original
//formatting, unlike package inspector
-(IBAction)showDescription:(id)sender
{
	NSEnumerator *e = [[tableView selectedPackageArray] objectEnumerator];
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

//----------------------------------------------->Version Checker

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
		NSRunAlertPanel(NSLocalizedString(@"Error", nil),
				  NSLocalizedString(@"FinkCommanderWasUnable", nil),
				  NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	if (! [installedVersion isEqualToString: latestVersion]){
		int answer = NSRunAlertPanel(NSLocalizedString(@"Download", nil),
							   NSLocalizedString(@"AMoreCurrentVersion", nil),
							   NSLocalizedString(@"Yes", nil), 
							   NSLocalizedString(@"No", nil), nil, latestVersion);
		if (answer == NSAlertDefaultReturn){
			[[NSWorkspace sharedWorkspace] openURL:
				[NSURL URLWithString:
					[NSString stringWithFormat:@"http://finkcommander.sourceforge.net",
						latestVersion]]];
		}
	}else if (notifyWhenCurrent){
		NSRunAlertPanel(NSLocalizedString(@"Current", nil),
				  NSLocalizedString(@"TheLatest", nil),
				  NSLocalizedString(@"OK", nil), nil, nil);
	}
	[defaults setObject:[NSDate date] forKey:FinkLastCheckedForNewVersion];
}

-(IBAction)checkForLatestVersionAction:(id)sender
{
	[self checkForLatestVersion:YES];
}

//----------------------------------------------->Save Output

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
		NSData *odata = [[textView string] dataUsingEncoding: NSMacOSRomanStringEncoding];
		[odata writeToFile: [sheet filename] atomically:YES];
	}
}

//----------------------------------------------->Terminator III

-(IBAction)terminateCommand:(id)sender
{
	int answer1 = NSRunAlertPanel(NSLocalizedString(@"Caution", nil),
			NSLocalizedString(@"TheTerminateCommand", nil),
			NSLocalizedString(@"Terminate", nil), 
			NSLocalizedString(@"Continue", nil), nil);

	if (answer1 == NSAlertDefaultReturn){
		terminateChildProcesses();

		sleep(1);

		if ([[finkTask task] isRunning]){
			int answer2 = NSRunAlertPanel(NSLocalizedString(@"Sorry", nil),
					NSLocalizedString(@"TheCurrentProcess", nil),
					NSLocalizedString(@"Quit", nil), 
					NSLocalizedString(@"Continue", nil), nil);
			if (answer2 == NSAlertDefaultReturn){
				userChoseToTerminate = YES;
				[NSApp terminate: self];
			}
		}
	}
}

//----------------------------------------------->Show Windows/Panels

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
	[packageInfo displayDescriptions: [tableView selectedPackageArray]];
}

-(IBAction)showPreferencePanel:(id)sender
{
	if (!preferences){
		preferences = [[FinkPreferences alloc] init];
	}
	[preferences showWindow: self];
}

//----------------------------------------------->Internet Access

//help menu internet access items
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
	}
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: url]];
}

-(IBAction)emailMaintainer:(id)sender
{
	NSEnumerator *e = [[tableView selectedPackageArray] objectEnumerator];
	FinkInstallationInfo *info = [[[FinkInstallationInfo alloc] init] autorelease];
	NSString *sig = [info getInstallationInfo];
	FinkPackage *pkg;

	if (!packageInfo){
		packageInfo = [[FinkPackageInfo alloc] init];
	}

	[packageInfo setEmailSig: sig];
	while (pkg = [e nextObject]){
		[[NSWorkspace sharedWorkspace] openURL:[packageInfo mailURLForPackage:pkg]];
	}
}

//----------------------------------------------->Change Information Display

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
//helper for menu item and toolbar item validators
-(BOOL)validateItem:(id)theItem
{
	//disable package-specific commands if no row selected
	if ([tableView selectedRow] == -1 						&&
	    ([theItem action] == @selector(runCommand:)  		||
		 [theItem action] == @selector(forceRemove:)		||
		 [theItem action] == @selector(showDescription:)	||
		 [theItem action] == @selector(emailMaintainer:))){
		return NO;
	}
	//disable Source and Binary menu items and table update if command is running
	if (commandIsRunning &&
		([theItem action] == @selector(runCommand:) 		||
		 [theItem action] == @selector(runUpdater:) 		||
		 [theItem action] == @selector(forceRemove:)		||
		 [theItem action] == @selector(showDescription:)	||
		 [theItem action] == @selector(saveOutput:)			||
		 [theItem action] == @selector(updateTable:))){
		return  NO;
	}
	if (! commandIsRunning &&
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

//use Toolbar.plist file to populate toolbar
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

//----------------------------------------------->Text Field Delegate

//filter data source each time the filter text field changes
-(void)controlTextDidChange:(NSNotification *)aNotification
{
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
			while (pkg = [e nextObject]){
				pkgAttribute = [[pkg performSelector: NSSelectorFromString(field)] lowercaseString];
				if ([pkgAttribute contains: filterText]){
					[subset addObject: pkg];
				}
			}
			[tableView setDisplayedPackages: subset];
		}
		[tableView resortTableAfterFilter];

		//restore the selection and scroll back to it after the table is sorted
		if ([defaults boolForKey: FinkScrollToSelection]){
			[tableView scrollToSelectedObject];
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
//		TABLEVIEW AND SPLITVIEW NOTIFICATION METHODS
//--------------------------------------------------------------------------------

-(void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if (packageInfo && [[packageInfo window] isVisible]){
		[packageInfo displayDescriptions: [tableView selectedPackageArray]];
	}
}

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

	if ([self lastParams]){
		[[NSNotificationCenter defaultCenter]
			postNotificationName: FinkRunCommandNotification
						  object: [self lastParams]];
		[self setLastParams: nil];
	}

	if (passwordError && [[finkTask task] isRunning]){
		[finkTask writeToStdin: password];
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
		[textView appendString:@"\n"];
		if ([defaults boolForKey: FinkAutoExpandOutput]){
			[self collapseOutput: nil];
		}
	}
}

//----------------------------------------------->Process Commands

-(void)runCommandWithParameters:(NSMutableArray *)params
{
	NSString *executable = [params objectAtIndex: 0];
	
	passwordError = NO;

	if ([password length] < 1 && 
		! [defaults boolForKey: FinkNeverAskForPassword]){
		[self setLastParams:params];
		pendingCommand = YES;
		commandIsRunning = NO;
		[self displayNumberOfPackages];
		[self raisePwdWindow:self];
		return;
	}
	if ([defaults boolForKey: FinkWarnBeforeRunning]){
		int answer = NSRunAlertPanel(NSLocalizedString(@"JustChecking", nil), 
			NSLocalizedString(@"AreYouSure", nil),
			NSLocalizedString(@"Yes", nil), 
			NSLocalizedString(@"No", nil), nil, 
			[params componentsJoinedByString: @" "]);

		if (answer == NSAlertAlternateReturn){
			commandIsRunning = NO;
			[self displayNumberOfPackages];
			return;
		}
	}
	if ([[params objectAtIndex: 1] isEqualToString: @"remove"] && 
		[defaults boolForKey: FinkWarnBeforeRemoving]){
		int answer = NSRunCriticalAlertPanel(NSLocalizedString(@"Caution", nil),
			NSLocalizedString(@"AreYouCertain", nil),
			NSLocalizedString(@"DontRemove", nil), 
			NSLocalizedString(@"Remove", nil),  
			NSLocalizedString(@"RemoveDontWarn", nil));
		switch(answer){
			case NSAlertDefaultReturn:
				commandIsRunning = NO;
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
		([executable contains: @"fink"] 			||
		 [executable contains: @"apt-get"])){
		[params insertObject: @"-y" atIndex: 3];
	}
	if ([executable isEqualToString: @"apt-get"]){ //give apt-get a chance to fix broken dependencies
		[params insertObject: @"-f" atIndex: 3];
	}
	pendingCommand = NO;

	[finkTask release];
	finkTask = [[IOTaskWrapper alloc] initWithController: self];
	[finkTask setEnvironmentDictionary: [defaults objectForKey:FinkEnvironmentSettings]];

#ifdef DEBUGGING
	NSLog(@"Command = %@", [params componentsJoinedByString: @" "]);
#endif

	// start the process asynchronously
	[finkTask startProcessWithArgs: params];
}

-(void)runCommandOnNotification:(NSNotification *)note
{
	NSMutableArray *args = [note object];
	NSString *cmd = [args objectAtIndex: 0];
	NSNumber *indicator = [[note userInfo] objectForKey:FinkRunProgressIndicator];
		
	if (commandIsRunning){
		NSRunAlertPanel(NSLocalizedString(@"Sorry", nil),
				  NSLocalizedString(@"YouMustWait", nil),
				  NSLocalizedString(@"OK", nil), nil, nil);
		if ([cmd isEqualToString:@"/bin/cp"]){
			[preferences setFinkConfChanged: nil]; //action method; sets to YES
		}
		return;
	}
		
	if (indicator){
		[self startProgressIndicatorAsIndeterminate:[indicator intValue]];
	}
		
	[self setLastCommand: ([cmd contains:@"fink"] ? [args objectAtIndex:1] : cmd)];
	commandIsRunning = YES; 
	[self displayCommand: args];
	//prevent tasks run by consecutive notifications from tripping over each other
	[self performSelector:@selector(runCommandWithParameters:) withObject:args afterDelay:1.0];
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
			[finkTask writeToStdin: password];
			break;
	}

	[textView appendString:output];

	//according to Moriarity example, we have to put off scrolling until next event loop
	[self performSelector:@selector(scrollToVisible:) withObject:theTest 
				  afterDelay:0.0];
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
			[cmd contains: @"dpkg"]				|| 
			[cmd contains: @"update"];
}


-(void)processFinishedWithStatus:(int)status
{
	int outputLength = [[textView string] length];
	NSString *last2lines = outputLength < 160 ? [textView string] : 
		[[textView string] substringWithRange: NSMakeRange(outputLength - 160, 159)];

#ifdef DEBUGGING		
	NSLog(@"Finishing; lastCommand = %@", lastCommand);
#endif

	if (! [[self lastCommand] contains: @"cp"] && ! [[self lastCommand] contains: @"chown"] &&
		! [[self lastCommand] contains: @"mv"]){
		NSBeep();
	}
	
	// Make sure command was successful before updating table
	// Checking exit status is not sufficient for some fink commands, so check
	// approximately last two lines for "failed"
	[tableView setDisplayedPackages: [packages array]];
	if (status == 0 && ! [last2lines containsCI: @"failed"]){
		if ([self commandRequiresTableUpdate: lastCommand]){
			if ([lastCommand contains: @"selfupdate"] 	||
				[lastCommand contains: @"dpkg"]			||
				[lastCommand contains: @"index"]	  	||
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
		NSBeginAlertSheet(NSLocalizedString(@"Error", nil),		//title
			NSLocalizedString(@"OK", nil), nil,	nil, 			//buttons
			[self window], self, NULL, NULL, nil,	 			//window, delegate, selectors, context
			NSLocalizedString(@"FinkCommanderDetected", nil),	//msg string
			nil);												//msg string params
		[self updateTable: nil];
	}
	[[NSNotificationCenter defaultCenter]
		postNotificationName:FinkCommandCompleted 
		object:[self lastCommand]]; 
}

@end
