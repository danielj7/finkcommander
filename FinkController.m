/* 
 File: FinkController.m

See the header file, FinkController.h, for interface and license information.

*/

#import "FinkController.h"

@implementation FinkController

//----------------------------------------------->Startup and Dealloc

+(void)initialize
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
	[defaultValues setObject: @"" forKey: FinkBasePath];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkBasePathFound];
	[defaultValues setObject: [NSNumber numberWithBool: NO] forKey: FinkUpdateWithFink];
		
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
#ifdef DEBUG
	NSLog(@"Registered defaults: %@", defaultValues);
#endif //DEBUG
}


-(id)init
{
	NSEnumerator *e;
	NSString *attribute;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if (self = [super init])
	{
		[self setWindowFrameAutosaveName: @"MainWindow"];
		[NSApp setDelegate: self];
		
		//needed for rebuilds; after first build, default value is set
		//and apparently remains set, but rebuilds put unmodified version of
		//fpkg_list.pl back in FinkCommander.app/Resources
		[defaults removeObjectForKey: FinkBasePathFound];
						
		if (![defaults boolForKey: FinkBasePathFound]){
#ifdef DEBUG
			NSLog(@"Looking for fink base path");
#endif //DEBUG
			utility = [[[FinkBasePathUtility alloc] init] autorelease];
			[utility findFinkBasePath];
			[utility fixScript];
		}		
	
		packages = [[FinkDataController alloc] init];		// table data source
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
		
#ifndef REFACTOR
		[self setPassword: nil];
		lastParams = [[NSMutableArray alloc] init];
		[self setPendingCommand: NO];		
			
		//register for notification that password was entered
		[[NSNotificationCenter defaultCenter] addObserver: self
					selector: @selector(runCommandWithPassword:)
					name: @"passwordWasEntered"
					object: nil];
#endif //REFACTOR
		[[NSNotificationCenter defaultCenter] addObserver: self
					selector: @selector(refreshTable:)
					name: @"packageArrayIsFinished"
					object: nil];
	}
	return self;
}


-(void)dealloc
{
	[packages release];
	[selectedPackages release];
	[preferences release];
	[utility release];
	[lastCommand release];
	[lastIdentifier release];
	[columnState release];
	[reverseSortImage release];
	[normalSortImage release];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
#ifndef REFACTOR
	[lastParams release];
	[password release];
#endif //REFACTOR	
	[finkTask release];
	[super dealloc];
}


-(void)awakeFromNib
{
	;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSTableColumn *lastColumn = [tableView tableColumnWithIdentifier:
		[self lastIdentifier]];
		
	if (![[NSUserDefaults standardUserDefaults] boolForKey: FinkBasePathFound]){
		// TBD:  substitute alert and reference to help
		NSLog(@"FinkCommander was unable to find the path to your fink installation.");
		NSLog(@"If you know the path, try setting it in Preferences and then run File: Update Table");
	}
	[msgText setStringValue:
		@"Gathering data for table; this will take a moment . . ."];
	[packages update];
	[tableView reloadData];
	[tableView setHighlightedTableColumn: lastColumn];
	[tableView setIndicatorImage: normalSortImage inTableColumn: lastColumn];
}


//helper used for 1st time in next method
-(void)displayNumberOfPackages
{
	[msgText setStringValue: [NSString stringWithFormat: @"%d packages",
		[[packages array] count]]];
}

//method called when FinkDataController is finished updating package
-(void)refreshTable:(NSNotification *)ignore
{
	[tableView reloadData];
	[self displayNumberOfPackages];
	[self setCommandIsRunning: NO];
}



//----------------------------------------------->Accessors

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

#ifndef REFACTOR
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
#endif //REFACTOR

//----------------------------------------------->Sheet Methods

//Administrator Password Entry Sheet

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

//----------------------------------------------->Action Methods and Helpers

//helper:  display running command above table
-(void)displayCommand:(NSArray *)params
{
	[msgText setStringValue: [NSString stringWithFormat: @"Running %@ . . .",
		[[params subarrayWithRange: NSMakeRange(1, [params count] - 1)]
		componentsJoinedByString: @" "]]];
}

//helper:  set up the argument list for either command method
-(NSMutableArray *)setupCommandFrom:(id)sender
{
	NSString *cmd = [[sender title] lowercaseString];
	NSString *theMenu = [[sender menu] title];
	NSString *executable;
	NSMutableArray *args;

	[self setCommandIsRunning: YES];
	executable = [theMenu isEqualToString: @"Source"] ? @"fink" : @"apt-get";
	args = [NSMutableArray arrayWithObjects: executable, cmd, nil];
	[self setLastCommand: cmd];
	return args;
}

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
		[pkgs addObject: [[packages array] objectAtIndex: [anIndex intValue]]];
	}
	[self setSelectedPackages: pkgs];

#ifdef DEBUG
	NSLog(@"selectedPackages contains %d items", [selectedPackages count]);
#endif //DEBUG

	//set up args array to run the command
	while(anIndex = [e2 nextObject]){
		[args addObject: [[[packages array] objectAtIndex: [anIndex intValue]] name]];
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
		[self displayCommand: [self lastParams]];
		[self runCommandWithParams: [self lastParams]];
	}	
}

//allow user to update table using Fink, rather than relying on 
//FinkCommander's manual update
-(IBAction)updateTable:(id)sender
{
	[msgText setStringValue: @"Updating table data . . . "]; //time lag here
	[self setCommandIsRunning: YES];
	[packages update];
}

-(IBAction)showPreferencePanel:(id)sender
{
	if (!preferences){
		preferences = [[FinkPreferences alloc] init];
	}
	[preferences showWindow: self];
}



//----------------------------------------------->Table Data Source Methods

-(int)numberOfRowsInTableView:(NSTableView *)aTableView
{
//	[self displayNumberOfPackages];
	return [[packages array] count];
}

-(id)tableView:(NSTableView *)aTableView
	objectValueForTableColumn:(NSTableColumn *)aTableColumn
	row:(int)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	FinkPackage *package = [[packages array] objectAtIndex: rowIndex];
	return [package valueForKey: identifier];
}


//----------------------------------------------->Delegate Methods

//sort table columns
-(void)tableView:(NSTableView *)aTableView
    mouseDownInHeaderOfTableColumn:(NSTableColumn *)aTableColumn
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

	// sort data source; reload table; reset visual indicators
	[[packages array] sortUsingSelector:
		NSSelectorFromString([NSString stringWithFormat: @"%@CompareBy%@:", direction,
			[identifier capitalizedString]])]; // e.g. reverseCompareByName:
	[tableView reloadData];	
	if ([direction isEqualToString: @"reverse"]){
		[tableView setIndicatorImage: reverseSortImage
				 inTableColumn: aTableColumn];
	}else{
		[tableView setIndicatorImage: normalSortImage
				 inTableColumn: aTableColumn];
	}
	[tableView setHighlightedTableColumn: aTableColumn];
}

//Disable menu item selections
-(BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	//disable package-specific commands if no row selected
	if ([tableView selectedRow] == -1 &&
	    [menuItem action] == @selector(runCommand:)){
		return NO;
	}
	//disable Source and Binary menu items if command is running
	if (([self commandIsRunning])
	      &&
	     ([[[menuItem menu] title] isEqualToString: @"Source"] ||
		  [[[menuItem menu] title] isEqualToString: @"Binary"] ||
		  [[menuItem title] isEqualToString: @"Update table"])){
		return NO;
	}
	return YES;	
}


//----------------------------------------------->IOTaskWrapper Protocol Implementation

//helper
- (void)scrollToVisible:(id)ignore
{
	[textView scrollRangeToVisible:
		NSMakeRange([[textView string] length], 0)];
}

//much of the code in this method was borrowed from the Moriarity example at
//http://developer.apple.com/samplecode/Sample_Code/Cocoa/Moriarity.htm
- (void)appendOutput:(NSString *)output
{
		NSAttributedString *lastOutput;
		lastOutput = [[[NSAttributedString alloc] initWithString:
			output] autorelease];

		//TBD:  respond as specified by user; right now this just enters a return
		//[i.e. the default] any time Fink asks for a response 
		if ([[lastOutput string] rangeOfString: @"]"].length > 0){
			[finkTask writeToStdin: @"\n"];
		}
		
		//prevent crash or repeated calls to run selfupdate-cvs if user has
		//core developer access to fink CVS repository
		if([[lastOutput string] rangeOfString:
			 @"cvs.sourceforge.net's password:"].length > 0){
			[[finkTask task] terminate];
			[finkTask stopProcess];
		}
		
		//look for password error message from sudo; if it's received, enter a 
		//return to terminate the process, then notify the user
		if([[lastOutput string] rangeOfString: @"Sorry, try again."].length > 0){
			NSLog(@"Detected password error.");
			[finkTask writeToStdin: @"\n\n\n"];
			[finkTask stopProcess];
			[self setPassword: nil];
		}

		[[textView textStorage] appendAttributedString: lastOutput];		
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
	if (status == 0 && [output rangeOfString:@"failed"
						options: NSCaseInsensitiveSearch
						range: NSMakeRange([output length] - 50, 49)].length == 0){
		if ([self commandRequiresTableUpdate: [self lastCommand]]){
			if ([lastCommand rangeOfString: @"selfupdate"].length > 0 ||
	            [[NSUserDefaults standardUserDefaults] boolForKey: FinkUpdateWithFink]){
				[msgText setStringValue: @"Updating table data . . . "];
				[packages update];   // refreshTable will be called by notification
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
		@"FinkCommander detected a failure message.\nCheck the output window for problems.",
		nil);										//msg string params
		[self refreshTable: nil];
	}
}

@end
