/* 
 File: FinkController.m

See the header file, FinkController.h, for interface and license information.
 
*/

#import "FinkController.h"

@implementation FinkController

//--------------------------------------------------------------------------------
//		STARTUP AND SHUTDOWN
//--------------------------------------------------------------------------------

//----------------------------------------------->Initialize
+(void)initialize
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	//set "factory defaults"
	[defaultValues setObject: @"" forKey: FinkBasePath];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkBasePathFound];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkUpdateWithFink];
	[defaultValues setObject: [NSNumber numberWithBool: YES] forKey: FinkScrollToSelectedRow];
	[defaultValues setObject: [NSNumber numberWithBool: YES] forKey: FinkAlwaysChooseDefaults];
		
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
#ifdef DEBUG
	NSLog(@"Registered defaults: %@", defaultValues);
#endif //DEBUG
}

//----------------------------------------------->Init
-(id)init
{
	NSEnumerator *e;
	NSString *attribute;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if (self = [super init])
	{
		[self setWindowFrameAutosaveName: @"MainWindow"];
		[NSApp setDelegate: self];

		utility = [[[FinkBasePathUtility alloc] init] autorelease];
		if (! [defaults boolForKey: FinkBasePathFound]){
			[utility findFinkBasePath];
		}
		[utility fixScript];
	
		packages = [[FinkDataController alloc] init];		// data used in table
		[self setDisplayPackages: [packages array]];
		[self setSelectedPackages: nil];    				// used to update package data
		[self setLastCommand: @""];  

		//variables used to display table
		[self setLastIdentifier: @"name"];
		reverseSortImage = [[NSImage imageNamed: @"reverse"] retain];
		normalSortImage = [[NSImage imageNamed: @"normal"] retain];
			
		//stores whether table columns are sorted in normal or reverse order to enable
		//proper sorting behavior; uses definitions from FinkPackages to set attributes
		columnState = [[NSMutableDictionary alloc] init];
		e = [[NSArray arrayWithObjects: PACKAGE_ATTRIBUTES, nil] objectEnumerator];
		while (attribute = [e nextObject]){
			[columnState setObject: @"normal" forKey: attribute];
		}
		
		[self setCommandIsRunning: NO];		
		[self setPassword: nil];
		lastParams = [[NSMutableArray alloc] init];
		[self setPendingCommand: NO];
			
		//register for notification that password was entered
		[[NSNotificationCenter defaultCenter] addObserver: self
					selector: @selector(runCommandWithPassword:)
					name: @"passwordWasEntered"
					object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
					selector: @selector(refreshTable:)
					name: @"packageArrayIsFinished"
					object: nil];
	}
	return self;
}

//----------------------------------------------->Dealloc
-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[packages release];
	[displayPackages release];
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
	[super dealloc];
}


//----------------------------------------------->Post-Init Startup
-(void)awakeFromNib
{
	[self setupToolbar];

	//save table column state between runs
	[tableView setAutosaveName: @"FinkTable"];
	[tableView setAutosaveTableColumns: YES];
	
	[msgText setStringValue:
		@"Updating table data�"];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSTableColumn *lastColumn = [tableView tableColumnWithIdentifier:
		[self lastIdentifier]];
		
	if (![[NSUserDefaults standardUserDefaults] boolForKey: FinkBasePathFound]){
		NSBeginAlertSheet(@"Unable to Locate Fink",	@"OK", nil,	nil, //title, buttons
				[self window], self, NULL,	NULL, nil, //window, delegate, selectors, context info
				@"Try setting the path to Fink manually in Preferences.", nil);
	}
	[self updateTable: nil];
	[tableView setHighlightedTableColumn: lastColumn];
	[tableView setIndicatorImage: normalSortImage inTableColumn: lastColumn];
}

//helper used in several methods
-(void)displayNumberOfPackages
{
	if (! [self commandIsRunning]){
		[msgText setStringValue: [NSString stringWithFormat: @"%d packages",
			[[self displayPackages] count]]];
	}
}

//helper used in refreshTable and in table column clicked delegate
-(void)sortTableAtColumn: (NSTableColumn *)aTableColumn inDirection:(NSString *)direction
{
	BOOL scrollToSelection = [[NSUserDefaults standardUserDefaults] boolForKey:
		FinkScrollToSelectedRow];
	FinkPackage *pkg = nil;
	int row = [tableView selectedRow];
	int newrow;

	if (scrollToSelection && row >= 0){
		pkg = [[self displayPackages] objectAtIndex: row];
	}

	// sort data source; reload table; reset visual indicators
	[[self displayPackages] sortUsingSelector:
		NSSelectorFromString([NSString stringWithFormat: @"%@CompareBy%@:", direction,
			[[aTableColumn identifier] capitalizedString]])]; // e.g. reverseCompareByName:
	[tableView reloadData];

	if (scrollToSelection && row >= 0){
		newrow = [[self displayPackages] indexOfObject: pkg];
		[tableView selectRow: newrow byExtendingSelection: NO];
		[tableView scrollRowToVisible: newrow];
	}
}


//method called when FinkDataController is finished updating package
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
	[self controlTextDidChange: nil];
}

//version of same method called when filter applied
//avoids re-validating command controls if filter is applied while a 
//command is running
-(void)refreshAfterFilter
{
	NSTableColumn *lastColumn = [tableView tableColumnWithIdentifier:
		[self lastIdentifier]];
	NSString *direction = [columnState objectForKey: [self lastIdentifier]];

	[self sortTableAtColumn: lastColumn inDirection: direction];
}


//--------------------------------------------------------------------------------
//		ACCESSORS
//--------------------------------------------------------------------------------

-(FinkDataController *)packages  {return packages;}

-(NSMutableArray *)displayPackages {return displayPackages;}
-(void)setDisplayPackages:(NSMutableArray *)a
{
	[a retain];
	[displayPackages release];
	displayPackages = a;
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
	
	if ([self commandIsRunning]){
		answer = NSRunCriticalAlertPanel(@"Warning!", @"Quitting now will interrupt a Fink process.",
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

//display running command above table
-(void)displayCommand:(NSArray *)params
{
	[msgText setStringValue: [NSString stringWithFormat: @"Running %@�",
		[[params subarrayWithRange: NSMakeRange(1, [params count] - 1)]
		componentsJoinedByString: @" "]]];
}

//set up the argument list for either command method
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
	NSMutableArray *args = [[self setupCommandFrom: sender] retain];
	NSMutableArray *pkgs = [NSMutableArray array];
	NSNumber *anIndex;
	NSEnumerator *e1 = [tableView selectedRowEnumerator];
	NSEnumerator *e2 = [tableView selectedRowEnumerator];
	
	//set up selectedPackages array for later use
	while(anIndex = [e1 nextObject]){
		[pkgs addObject: [[self displayPackages] objectAtIndex: [anIndex intValue]]];
	}
	[self setSelectedPackages: pkgs];

	//set up args array to run the command
	while(anIndex = [e2 nextObject]){
		[args addObject: [[[self displayPackages] objectAtIndex: [anIndex intValue]] name]];
	}
	
	[self displayCommand: args];		
	[self runCommandWithParams: args];
	[args release];
}

//run non-package-specific command; ignore table selection
-(IBAction)runUpdater:(id)sender
{
	NSMutableArray *args = [[self setupCommandFrom: sender] retain];
	
	[self displayCommand: args];	
	[self runCommandWithParams: args];
	[args release];
}

//allow user to update table using Fink
-(IBAction)updateTable:(id)sender
{	
	[progressViewHolder addSubview: progressView];
	[progressIndicator startAnimation: sender];
	[msgText setStringValue: @"Updating table data�"]; //time lag here
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
	if ([self commandIsRunning]
	 &&
	 ([[[menuItem menu] title] isEqualToString: @"Source"] ||
	  [[[menuItem menu] title] isEqualToString: @"Binary"] ||
      [[menuItem title] isEqualToString: @"Update table"])){
		return NO;
	}
	return YES;
}


//--------------------------------------------------------------------------------
//		TOOLBAR METHODS
//--------------------------------------------------------------------------------

-(void)setupToolbar
{
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: @"mainToolbar"];
    [toolbar setDelegate: self];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [[self window] setToolbar: [toolbar autorelease]];
}

//reapply filter if popup selection changes--NOT WORKING
-(IBAction)refilter:(id)sender
{
	[self controlTextDidChange: nil];
}

//----------------------------------------------->Delegate MethodS

-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar
	   itemForItemIdentifier:(NSString *)itemIdentifier
	willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
	if ([itemIdentifier isEqualToString: FinkInstallSourceItem]){
		[item setLabel: @"Install Source"];
		[item setPaletteLabel: [item label]];
		[item setToolTip: @"Install package from source"];
		[item setTag: 0]; 		//source command
		[item setImage: [NSImage imageNamed:@"addsrc"]];
		[item setTarget: self];
		[item setAction: @selector(runCommand:)];
	}else if ([itemIdentifier isEqualToString: FinkInstallBinaryItem]){
		[item setLabel: @"Install Binary"];
		[item setPaletteLabel: [item label]];
		[item setToolTip: @"Install binary package"];
		[item setTag: 1]; 		//binary command
		[item setImage: [NSImage imageNamed:@"addbin"]];
		[item setTarget: self];
		[item setAction: @selector(runCommand:)];
	}else if ([itemIdentifier isEqualToString: FinkRemoveSourceItem]){
		[item setLabel: @"Remove"];
		[item setPaletteLabel: [item label]];
		[item setToolTip: @"Remove package (but keep deb file)"];
		[item setTag: 0]; 		//source command
		[item setImage: [NSImage imageNamed:@"delete"]];
		[item setTarget: self];
		[item setAction: @selector(runCommand:)];
	}else if ([itemIdentifier isEqualToString: FinkFilterItem]) {
		NSRect fRect = [searchView frame];
		[item setLabel:@"Filter Table Data"];
		[item setPaletteLabel:[item label]];
		[item setView: searchView];
		[item setMinSize: fRect.size];
		[item setMaxSize: fRect.size];
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
		FinkFilterItem,
		nil];
}

-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:
		FinkInstallSourceItem,
		FinkInstallBinaryItem,
		FinkRemoveSourceItem, 	
		NSToolbarFlexibleSpaceItemIdentifier,
		FinkFilterItem,
		nil];
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	if ([tableView selectedRow] == -1 &&
	    [theItem action] == @selector(runCommand:)){
		return NO;
	}
	if ([self commandIsRunning] &&
		([theItem action] == @selector(runCommand:) ||
		 [theItem action] == @selector(runUpdater:))){
		return  NO;
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
		[self setDisplayPackages: [packages array]];
		}else{
			while (pkg = [e nextObject]){
				pkgAttribute = [[pkg performSelector: NSSelectorFromString(field)] lowercaseString];
				if ([pkgAttribute rangeOfString: filterText].length > 0){
					[subset addObject: pkg];
				}
			}
			[self setDisplayPackages: subset];
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

//----------------------------------------------->Data Source Methods

-(int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[self displayPackages] count];
}

-(id)tableView:(NSTableView *)aTableView
	objectValueForTableColumn:(NSTableColumn *)aTableColumn
	row:(int)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	FinkPackage *package = [[self displayPackages] objectAtIndex: rowIndex];
	return [package valueForKey: identifier];
}


//----------------------------------------------->Delegate Method
//sorts table when column header clicked
//note:  response is faster when mouseDownInTableColumnHeader method is used;
//but then table re-sorts any time a column is resized, which is annoying
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
	[self setLastIdentifier: identifier];

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
	[interactionWindow orderOut: sender];
	[NSApp endSheet:interactionWindow returnCode: 1];
}

-(void)interactionSheetDidEnd:(NSWindow *)sheet
				   returnCode:(int)returnCode
						contextInfo:(void *)contextInfo
{
	NSAttributedString *areturn = [[[NSAttributedString alloc]
		initWithString: @"\n"] autorelease];

	if ([[interactionMatrix selectedCell] tag] == 0){
		[finkTask writeToStdin: @"\n"];
	}else{
		[finkTask writeToStdin: [NSString stringWithFormat: @"%@\n",
			[interactionField stringValue]]];
	}
	[[textView textStorage] appendAttributedString: areturn];
}

//----------------------------------------------->Process Commands

-(void)runCommandWithParams:(NSMutableArray *)params
{
	if ([[self password] length] < 1){
		[self raisePwdWindow: self];
		[self setLastParams: params];
		[self setPendingCommand: YES];
		[self setCommandIsRunning: NO];
		[self displayNumberOfPackages];
		return;
	}
	[self setPendingCommand: NO];

	if (finkTask){
		[finkTask release];
	}
	finkTask = [[IOTaskWrapper alloc] initWithController: self];

	[finkTask setPassword: [NSData dataWithData:
		[[self password] dataUsingEncoding: NSUTF8StringEncoding]]];
	// start the process asynchronously
	[finkTask startProcessWithArgs: params];
}

//if last command was not completed because no valid password was entered,
//run it again after receiving passwordWasEntered notification
-(void)runCommandWithPassword:(NSNotification *)note
{
	if ([self pendingCommand]){
		[self setCommandIsRunning: YES];
		[self displayCommand: [self lastParams]];
		[self runCommandWithParams: [self lastParams]];
	}
}


//----------------------------------------------->IOTaskWrapper Protocol Implementation

-(void)scrollToVisible:(id)ignore
{
	[textView scrollRangeToVisible:
		NSMakeRange([[textView string] length], 0)];
}

-(void)appendOutput:(NSString *)output
{
	NSAttributedString *lastOutput;
	BOOL alwaysChooseDefaultSelected = [[NSUserDefaults standardUserDefaults]
		boolForKey: FinkAlwaysChooseDefaults];

	lastOutput = [[[NSAttributedString alloc] initWithString:
		output] autorelease];

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
	if([output rangeOfString: @"Sorry, try again."].length > 0){
		NSLog(@"Detected password error.");
		[finkTask writeToStdin: @"\n"];
		[finkTask stopProcess];
		[self setPassword: nil];
	}

	[[textView textStorage] appendAttributedString: lastOutput];
	//according to Moriarity example, have to put off scrolling until next event loop
	[self performSelector: @selector(scrollToVisible:) withObject: nil afterDelay: 0.0];
}

-(void)processStarted
{
	[textView setString: @""];
}

//helper
-(BOOL)commandRequiresTableUpdate:(NSString *)cmd
{
	if ([cmd isEqualToString: @"install"] 	  ||
		[cmd isEqualToString: @"remove"]	  ||
		[cmd isEqualToString: @"update-all"]  ||
	    [cmd rangeOfString: @"selfupdate"].length > 0){
		return YES;
	}
	return NO;
}

-(void)processFinishedWithStatus:(int)status
{
	NSString *output = [NSString stringWithString: [textView string]];
	NSBeep();
	
	// Make sure command was succesful before updating table
	// Checking exit status is not sufficient for some fink commands, so check
	// last 50 chars of output for "failed"
	[self setDisplayPackages: [packages array]];
	if (status == 0 && [output rangeOfString:@"failed"
						options: NSCaseInsensitiveSearch
						range: NSMakeRange(0, [output length] - 1)].length == 0){
		if ([self commandRequiresTableUpdate: [self lastCommand]]){
			if ([lastCommand rangeOfString: @"selfupdate"].length > 0 ||
	            [[NSUserDefaults standardUserDefaults] boolForKey: FinkUpdateWithFink]){
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
		[packages update];
	}
}

@end
