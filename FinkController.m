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


@implementation FinkController

//--------------------------------------------------------------------------------
//		STARTUP AND SHUTDOWN
//--------------------------------------------------------------------------------

//----------------------------------------------->Initialize
+(void)initialize
{
	//set "factory defaults"
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
	[defaultValues setObject: @"" forKey: FinkBasePath];
	[defaultValues setObject: @"name" forKey: FinkSelectedColumnIdentifier];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkBasePathFound];
	[defaultValues setObject: [NSNumber numberWithBool: YES] forKey: FinkUpdateWithFink];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkAlwaysChooseDefaults];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkScrollToSelection];
	[defaultValues setObject: @"" forKey: FinkHTTPProxyVariable];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkLookedForProxy];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkAskForPasswordOnStartup];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkNeverAskForPassword];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkAlwaysScrollToBottom];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkWarnBeforeRunning];
		
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
}

//----------------------------------------------->Init
-(id)init
{
	if (self = [super init]){

		NSEnumerator *e;
		NSString *attribute;
	
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
		// enables proper sorting behavior; uses macro from FinkPackages to set attributes
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
		
		userChoseToTerminate = NO;
		
		//Register for notifications that run commands
		//  selector runs command if one is pending and password was entered 
		[[NSNotificationCenter defaultCenter] addObserver: self
					selector: @selector(runCommandWithPassword:)
					name: @"passwordWasEntered"
					object: nil];
		//  selector runs commands that change the fink.conf file
		[[NSNotificationCenter defaultCenter] addObserver: self
					selector: @selector(runFinkConfCommand:)
					name: FinkConfChangeIsPending
					object: nil];
					
		//Register for notification that causes table to update 
		//and resume normal state
		[[NSNotificationCenter defaultCenter] addObserver: self
					selector: @selector(refreshTable:)
					name: FinkPackageArrayIsFinished
					object: nil];
					
		return self;
	}
	return nil;
}

//----------------------------------------------->Dealloc
-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[packages release];
	[displayedPackages release];
	[selectedPackages release];
	[preferences release];
	[utility release];
	[lastCommand release];
	[lastIdentifier release];
	[columnState release];
	[reverseSortImage release];
	[normalSortImage release];
	[lastParams release];
	[password release];
	[finkTask release];
	[toolbar release];
	[super dealloc];
}


//----------------------------------------------->Post-Init Startup
-(void)awakeFromNib
{
	[self setupToolbar];

	//save table column state between runs
	[tableView setAutosaveName: @"FinkTable"];
	[tableView setAutosaveTableColumns: YES];
	[scrollView setBorderType: NSNoBorder];
	
	[msgText setStringValue:
		@"Updating table dataÉ"];
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSTableColumn *lastColumn = [tableView tableColumnWithIdentifier:
		[self lastIdentifier]];
				
	if (! [[NSUserDefaults standardUserDefaults] boolForKey: FinkBasePathFound]){
		NSBeginAlertSheet(@"Unable to Locate Fink",	@"OK", nil,	nil, //title, buttons
				[self window], self, NULL,	NULL, nil, //window, delegate, selectors, c info
				@"Try setting the path to Fink manually in Preferences.", nil);
	}
	[self updateTable: nil];
	[tableView setHighlightedTableColumn: lastColumn];
	[tableView setIndicatorImage: normalSortImage inTableColumn: lastColumn];
	if ([defaults boolForKey: FinkAskForPasswordOnStartup]){
		[self raisePwdWindow: self];
	}
}

//helper used in several methods
-(void)displayNumberOfPackages
{
	if (! [self commandIsRunning]){
		[msgText setStringValue: [NSString stringWithFormat: @"%d packages",
			[[self displayedPackages] count]]];
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

//but don't close window if command is running
-(BOOL)windowShouldClose:(id)sender
{
	if ([self commandIsRunning]){
		NSBeep();
		return NO;
	}
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
		cmd = [[[[sender label] componentsSeparatedByString:@" "] objectAtIndex: 0]			lowercaseString];
	}	

	//determine executable: source menu or toolbar item tag == 0
	//binary item tag == 1
	executable = ([sender tag] == 0 ? @"fink" : @"apt-get");
	args = [NSMutableArray arrayWithObjects: executable, cmd, nil];
	
	[self setCommandIsRunning: YES];
	[self setLastCommand: cmd];
	return args;
}

//----------------------------------------------->Menu Actions

//run package-specific command with arguments derived from table selection
-(IBAction)runCommand:(id)sender
{
	NSMutableArray *args = [self setupCommandFrom: sender];
	NSMutableArray *pkgs = [NSMutableArray array];
	NSNumber *anIndex;
	NSEnumerator *e1 = [tableView selectedRowEnumerator];
	NSEnumerator *e2 = [tableView selectedRowEnumerator];
	
	//set up selectedPackages array for later use
	while(anIndex = [e1 nextObject]){
		[pkgs addObject: [[self displayedPackages] objectAtIndex: [anIndex intValue]]];
	}
	[self setSelectedPackages: pkgs];

	//set up args array to run the command
	while(anIndex = [e2 nextObject]){
		[args addObject: [[[self displayedPackages] objectAtIndex: [anIndex intValue]] name]];
	}
	
	[self displayCommand: args];		
	[self runCommandWithParams: args];
}

//run non-package-specific command; ignore table selection
-(IBAction)runUpdater:(id)sender
{
	NSMutableArray *args = [self setupCommandFrom: sender];
	
	[self displayCommand: args];	
	[self runCommandWithParams: args];
}

-(IBAction)terminateCommand:(id)sender
{
	[[finkTask task] terminate];
	if ([[finkTask task] isRunning]){
		int answer = NSRunAlertPanel(@"Sorry",
				@"The current process is not responding to the terminate command.\nThe only way to stop it is to quit FinkCommander.\nWhat would you like to do?",
				@"Quit", @"Continue", nil);
		if (answer == NSAlertDefaultReturn){
			userChoseToTerminate = YES;
			[NSApp terminate: self];
		}
	}
}

//update table using Fink
-(IBAction)updateTable:(id)sender
{	
	[progressViewHolder addSubview: progressView];
	[progressIndicator setUsesThreadedAnimation: YES];
	[progressIndicator startAnimation: sender];
	[msgText setStringValue: @"Updating table dataÉ"]; 
	[self setCommandIsRunning: YES];
	[packages update]; //calls refreshTable by notification
}

-(IBAction)showPreferencePanel:(id)sender
{
	if (!preferences){
		preferences = [[FinkPreferences alloc] init];
	}
	[preferences showWindow: self];
}

//help menu items
-(IBAction)goToFinkCommanderWebSite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL: 
		[NSURL URLWithString: @"http://finkcommander.sourceforge.net/"]];
}

-(IBAction)goToFinkWebSite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL: 
		[NSURL URLWithString: @"http://fink.sourceforge.net/doc/index.php"]];
}

-(IBAction)goToBugReportPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:
		[NSURL URLWithString: @"http://sourceforge.net/tracker/?group_id=48896&atid=454467"]];
}


//----------------------------------------------->Menu Item Delegate

//Disable menu item selections
-(BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	//disable package-specific commands if no row selected
	if ([tableView selectedRow] == -1 &&
	    [menuItem action] == @selector(runCommand:)){
		return NO;
	}
	//disable Source and Binary menu items if command is running
	if ([self commandIsRunning] &&
		([menuItem action] == @selector(runCommand:) ||
		 [menuItem action] == @selector(runUpdater:) ||
		 [menuItem action] == @selector(updateTable:))){
		return  NO;
	}
	if (! [self commandIsRunning] && 
		([menuItem action] == @selector(raiseInteractionWindow:) ||
		 [menuItem action] == @selector(terminateCommand:))){
		return NO;
	}
	return YES;
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
    [[self window] setToolbar: toolbar]; 
}

//reapply filter if popup selection changes
-(IBAction)refilter:(id)sender
{
	[self controlTextDidChange: nil];
}

//refresh table after filter applied without re-validating menu and 
//toolbar items while a command is running (unlike refreshTable:)
-(void)refreshAfterFilter
{
	NSTableColumn *lastColumn = [tableView tableColumnWithIdentifier:
		[self lastIdentifier]];
	NSString *direction = [columnState objectForKey: [self lastIdentifier]];

	[self sortTableAtColumn: lastColumn inDirection: direction];
}


//----------------------------------------------->Delegate Methods

-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar
	   itemForItemIdentifier:(NSString *)itemIdentifier
	willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
	if ([itemIdentifier isEqualToString: FinkInstallSourceItem]){
		[item setLabel: @"Install"];
		[item setPaletteLabel: @"Install Source"];
		[item setToolTip: @"Install package(s) from source"];
		[item setTag: 0]; 		//source command
		[item setImage: [NSImage imageNamed:@"addsrc"]];
		[item setTarget: self];
		[item setAction: @selector(runCommand:)];
	}else if ([itemIdentifier isEqualToString: FinkInstallBinaryItem]){
		[item setLabel: @"Install Binary"];
		[item setPaletteLabel: [item label]];
		[item setToolTip: @"Install binary package(s)"];
		[item setTag: 1]; 		//binary command
		[item setImage: [NSImage imageNamed:@"addbin"]];
		[item setTarget: self];
		[item setAction: @selector(runCommand:)];
	}else if ([itemIdentifier isEqualToString: FinkRemoveSourceItem]){
		[item setLabel: @"Remove"];
		[item setPaletteLabel: @"Remove Source"];
		[item setToolTip: @"Delete files for package(s), but retain deb files for possible reinstallation"];
		[item setTag: 0]; 		//source command
		[item setImage: [NSImage imageNamed:@"delsrc"]];
		[item setTarget: self];
		[item setAction: @selector(runCommand:)];
	}else if ([itemIdentifier isEqualToString: FinkRemoveBinaryItem]){
		[item setLabel: @"Remove Binary"];
		[item setPaletteLabel: [item label]];
		[item setToolTip: @"Delete files for package(s), but retain deb files for possible reinstallation"];
		[item setTag: 1]; 		//binary command
		[item setImage: [NSImage imageNamed:@"delbin"]];
		[item setTarget: self];
		[item setAction: @selector(runCommand:)];
	}else if ([itemIdentifier isEqualToString: FinkDescribeItem]){
		[item setLabel: @"Describe"];
		[item setPaletteLabel: [item label]];
		[item setToolTip: @"Print full description of package(s) in output window"];
		[item setTag: 0]; 		//source command
		[item setImage: [NSImage imageNamed: @"describe"]];
		[item setTarget: self];
		[item setAction: @selector(runCommand:)];
	}else if ([itemIdentifier isEqualToString: FinkSelfUpdateItem]){
		[item setLabel: @"Selfupdate"];
		[item setPaletteLabel: [item label]];
		[item setToolTip: @"Update package descriptions and package manager"];
		[item setTag: 0]; 		//source command
		[item setImage: [NSImage imageNamed: @"update"]];
		[item setTarget: self];
		[item setAction: @selector(runUpdater:)];
	}else if ([itemIdentifier isEqualToString: FinkSelfUpdateCVSItem]){
		[item setLabel: @"Selfupdate-cvs"];
		[item setPaletteLabel: [item label]];
		[item setToolTip: @"Update package descriptions and package manager from fink cvs repository"];
		[item setTag: 0]; 		//source command
		[item setImage: [NSImage imageNamed: @"cvs"]];
		[item setTarget: self];
		[item setAction: @selector(runUpdater:)];
	}else if ([itemIdentifier isEqualToString: FinkUpdateBinaryItem]){
		[item setLabel: @"Update"];
		[item setPaletteLabel: @"Apt-Get Update"];
		[item setToolTip: @"Update binary package descriptions"];
		[item setTag: 1]; 		//binary command
		[item setImage: [NSImage imageNamed: @"updatebin"]];
		[item setTarget: self];
		[item setAction: @selector(runUpdater:)];
	}else if ([itemIdentifier isEqualToString: FinkTerminateCommandItem]){
		[item setLabel: @"Terminate"];
		[item setPaletteLabel: [item label]];
		[item setToolTip: @"Terminate current command"];
		[item setImage: [NSImage imageNamed: @"terminate"]];
		[item setTarget: self];
		[item setAction: @selector(terminateCommand:)];
	}else if ([itemIdentifier isEqualToString: FinkFilterItem]) {
		NSRect fRect = [searchView frame];
		[item setLabel:@"Filter Table Data"];
		[item setPaletteLabel:[item label]];
		[item setView: searchView];
		[item setMinSize: fRect.size];
		[item setMaxSize: fRect.size];
	}else if ([itemIdentifier isEqualToString: FinkInteractItem]){
		[item setLabel: @"Interact"];
		[item setPaletteLabel: [item label]];
		[item setToolTip: @"Raise interaction sheet (use if command has stalled)"];
		[item setImage: [NSImage imageNamed: @"interact"]];
		[item setTarget: self];
		[item setAction: @selector(raiseInteractionWindow:)];
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
		FinkFilterItem,
		nil];
}

-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:
		FinkInstallSourceItem,
		FinkInstallBinaryItem,
		FinkRemoveSourceItem,
		FinkInteractItem,
		FinkTerminateCommandItem,
		NSToolbarFlexibleSpaceItemIdentifier,
		FinkFilterItem,
		nil];
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	if ([self commandIsRunning] &&
		([theItem action] == @selector(runCommand:) ||
		 [theItem action] == @selector(runUpdater:))){
		return  NO;
	}
	if (! [self commandIsRunning] &&
		([theItem action] == @selector(raiseInteractionWindow:) ||
		 [theItem action] == @selector(terminateCommand:))){
		return NO;
	}	
	if ([tableView selectedRow] == -1 &&
	    [theItem action] == @selector(runCommand:)){
		return NO;
	}	
	return YES;
}

//----------------------------------------------->Text Field Delegate
//Used to filter table data
-(void)controlTextDidChange:(NSNotification *)aNotification
{
	NSString *field = [[[searchPopUpButton selectedItem] title] lowercaseString];
	NSString *filterText = [[searchTextField stringValue] lowercaseString];
	NSString *pkgAttribute;
	NSMutableArray *subset = [NSMutableArray array];
	NSEnumerator *e = [[packages array] objectEnumerator];
	FinkPackage *pkg;

	if ([[aNotification object] tag] == 0){ 		//filter text field
		if ([filterText length] == 0){
			[self setDisplayedPackages: [packages array]];
		}else{
			//deselect rows so automatic scrolling doesn't interfere
			[tableView deselectAll: self];
			while (pkg = [e nextObject]){
				pkgAttribute = [[pkg performSelector: NSSelectorFromString(field)] lowercaseString];
				if ([pkgAttribute contains: filterText]){
					[subset addObject: pkg];
				}
			}
			[self setDisplayedPackages: subset];
		}
		[self refreshAfterFilter];
		[self displayNumberOfPackages];
	}else{											//interaction sheet text field
		[interactionMatrix selectCellWithTag: 1];
	}	
}


//--------------------------------------------------------------------------------
//		TABLE METHODS
//--------------------------------------------------------------------------------

//----------------------------------------------->Helper Methods

//helper used in refreshTable and in didClickTableColumn: delegate method
-(void)sortTableAtColumn: (NSTableColumn *)aTableColumn inDirection:(NSString *)direction
{
	FinkPackage *pkg = nil;
	int indexBeforeSort;
	int indexAfterSort = 0;
	BOOL shouldScroll = [defaults boolForKey: FinkScrollToSelection];

	indexBeforeSort = [tableView selectedRow];
	if (indexBeforeSort >= 0 && shouldScroll){
		pkg = [[packages array] objectAtIndex: [tableView selectedRow]];
	}

	// sort data source; reload table; reset visual indicators
	[[self displayedPackages] sortUsingSelector:
		NSSelectorFromString([NSString stringWithFormat: @"%@CompareBy%@:", direction,
			[[aTableColumn identifier] capitalizedString]])]; // e.g. reverseCompareByName:
	[tableView reloadData];

	if (indexBeforeSort >= 0 && shouldScroll){
		indexAfterSort = [[packages array] indexOfObject: pkg];
		[tableView scrollRowToVisible: indexAfterSort];
		[tableView selectRow: indexAfterSort byExtendingSelection: NO];
	}
}

//method called when FinkDataController is finished updating package
//or when commands are completed
-(void)refreshTable:(NSNotification *)ignore
{
	NSTableColumn *lastColumn = [tableView tableColumnWithIdentifier:
		[self lastIdentifier]];
	NSString *direction = [columnState objectForKey: [self lastIdentifier]];

	if ([progressView isDescendantOf: progressViewHolder]){
		[progressIndicator stopAnimation: nil];
		[progressView removeFromSuperview];
	}
	[self displayNumberOfPackages];
	[self setCommandIsRunning: NO];
	[self sortTableAtColumn: lastColumn inDirection: direction]; //reloads table data
	[self controlTextDidChange: nil]; //reapplies filter
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


//----------------------------------------------->Delegate Method
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
	
	[self sortTableAtColumn: aTableColumn inDirection: direction];
}

-(BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	if ([[[[self displayedPackages] objectAtIndex: rowIndex] name] contains: @"tcsh"]){
		NSBeginAlertSheet(@"Sorry",	@"OK", nil,	nil, 
				[self window], self, NULL,	NULL, nil,
					@"FinkCommander is unable to install that package.\nSee Help:FinkCommander Guide:Known Bugs and Limitations",
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
	[[NSNotificationCenter defaultCenter] postNotificationName: @"passwordWasEntered"
										object: nil];
}

//----------------------------------------------->Interaction Sheet Methods

-(IBAction)raiseInteractionWindow:(id)sender
{
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
	}
}

//----------------------------------------------->Process Commands

-(void)runCommandWithParams:(NSMutableArray *)params
{
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
	[self setPendingCommand: NO];

	[finkTask release];
	finkTask = [[IOTaskWrapper alloc] initWithController: self];

	// start the process asynchronously
	[finkTask startProcessWithArgs: params];
}

//if last command was not completed because no valid password was entered,
//run it again after receiving passwordWasEntered notification;
-(void)runCommandWithPassword:(NSNotification *)note
{
	if ([self pendingCommand]){
		[self setCommandIsRunning: YES];
		[self displayCommand: [self lastParams]];
		[self runCommandWithParams: [self lastParams]];
	}
}

//run commands to change fink.conf file
-(void)runFinkConfCommand:(NSNotification *)note
{
	NSMutableArray *args = [note object];
	NSString *cmd = [args objectAtIndex: 0];

	if ([self commandIsRunning]){
		NSBeginAlertSheet(@"Sorry",	@"OK", nil,	nil,    //title, buttons
			[self window], self, NULL,	NULL, nil,	 	//window, delegate, selectors, context info
			@"You will have to wait until the current command is complete before changing the fink.conf settings.",
			nil);										//msg string params
		return;
	}

	[progressViewHolder addSubview: progressView];
	[progressIndicator setUsesThreadedAnimation: YES];
	[progressIndicator startAnimation: nil];	

	[self setLastCommand: 
		([cmd contains: @"fink"] ? [args objectAtIndex: 1] : cmd)];
	[self setCommandIsRunning: YES];
	[msgText setStringValue: @"Updating fink.conf file"];
	[self performSelector:@selector(runCommandWithParams:) withObject: args afterDelay: 1.0];
}


//----------------------------------------------->IOTaskWrapper Protocol Implementation

-(void)scrollToVisible:(NSNumber *)n
{
	if ([n floatValue] <= 3.0 || 
		[defaults boolForKey: FinkAlwaysScrollToBottom]){
		[textView scrollRangeToVisible:	
			NSMakeRange([[textView string] length], 0)];
	}
}

-(void)appendOutput:(NSString *)output
{
	NSAttributedString *lastOutput;
	BOOL alwaysChooseDefaultSelected = [[NSUserDefaults standardUserDefaults]
		boolForKey: FinkAlwaysChooseDefaults];
	NSNumber *theTest = [NSNumber numberWithFloat: 
		abs([textView bounds].size.height - [textView visibleRect].origin.y 
			- [textView visibleRect].size.height)];
	
	lastOutput = [[[NSAttributedString alloc] initWithString: output] autorelease];

	//interaction
	if ([output rangeOfString: @"Password:"].length > 0){
		[finkTask writeToStdin: [self password]];
	}
	if ( ! alwaysChooseDefaultSelected        &&
		 ([output rangeOfString: @"proceed? ["].length > 0  ||
		  [output rangeOfString: @"one: ["].length > 0 ||
		  [output rangeOfString: @"[y/n]" options: NSCaseInsensitiveSearch].length > 0 ||
		  [output rangeOfString: [NSString stringWithFormat: @"[%@]", NSUserName()]].length > 0 ||
		  [output rangeOfString: @"[anonymous]"].length > 0)){
			NSBeep();
			[self raiseInteractionWindow: self];
	}
	if ([output rangeOfString:           //handle non-anonymous cvs
			@"cvs.sourceforge.net's password:"].length > 0){ 
		[self raiseInteractionWindow: self];
	}
	
	//look for password error message from sudo; if it's received, enter a 
	//return to make sure process terminates
	if([output contains: @"Sorry, try again."]){
		NSLog(@"Detected password error");
		[finkTask writeToStdin: @"\n"];
		[finkTask stopProcess];
		[self setPassword: nil];
	}

	//display latest output in text view
	[[textView textStorage] appendAttributedString: lastOutput];
	//  according to Moriarity example, have to put off scrolling until next event loop
	[self performSelector: @selector(scrollToVisible:) withObject: theTest 
		afterDelay: 0.0];
}

-(void)processStarted
{
	[textView setString: @""];
}

//helper for processFinishedWithStatus:
-(BOOL)commandRequiresTableUpdate:(NSString *)cmd
{
	if ([cmd isEqualToString: @"install"] 	  ||
		[cmd isEqualToString: @"remove"]	  ||
		[cmd isEqualToString: @"update-all"]  ||
		[cmd contains: @"index"]			  ||
	    [cmd contains: @"selfupdate"]){
		return YES;
	}
	return NO;
}

-(void)processFinishedWithStatus:(int)status
{
	int outputLength = [[textView string] length];
	NSString *output = outputLength < 160 ? [textView string] : 
		[[textView string] substringWithRange: NSMakeRange(outputLength - 160, 159)];

	if (! [[self lastCommand] contains: @"cp"] && ! [[self lastCommand] contains: @"mv"]){
		NSBeep();
	}
	
	// Make sure command was succesful before updating table
	// Checking exit status is not sufficient for some fink commands, so check
	// approximately last two lines for "failed"
	[self setDisplayedPackages: [packages array]];
	if (status == 0 && ! [output containsCI: @"failed"]){
		if ([self commandRequiresTableUpdate: lastCommand]){
			if ([lastCommand contains: @"selfupdate"] ||
				[lastCommand contains: @"index"]	  ||
	            [defaults boolForKey: FinkUpdateWithFink]){
				[self updateTable: nil];   // refreshTable will be called by notification
			}else{
				[packages updateManuallyWithCommand: [self lastCommand]
										   packages: [self selectedPackages]];
				[self refreshTable: nil]; 
			}
		}else{
			[self refreshTable: nil];
		}
	}else{
		NSBeginAlertSheet(@"Error",	@"OK", nil,	nil, //title, buttons
		[self window], self, NULL,	NULL, nil,	 	//window, delegate, selectors, context info
		@"FinkCommander detected a possible failure message.\nCheck the output window for problems.",
		nil);										//msg string params
		[self updateTable: nil];
	}
	[[NSNotificationCenter defaultCenter]
		postNotificationName: FinkCommandCompleted 
		object: [self lastCommand]]; 
}

@end
