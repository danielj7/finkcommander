/* 
 File: FinkController.m

See the header file, FinkController.h, for interface and license information.

*/

//Code that should be moved to separate process control class or deleted
//to complete the design changes described in "DESIGN.txt" is marked
//MOVE/ENDMOVE

#import "FinkController.h"

@implementation FinkController

//----------------------------------------------->Startup and Dealloc

-(id)init
{
	NSEnumerator *e;
	NSString *attribute;
	
	if (self = [super init])
	{
		[self setWindowFrameAutosaveName: @"MainWindow"];
		[NSApp setDelegate: self];
	
		packages = [[FinkDataController alloc] init];		// table data source

//MOVE		
		binPath =  [[NSString alloc] initWithString:
			[[packages basePath] stringByAppendingPathComponent: @"/bin"]];
		[self setPassword: nil];
//ENDMOVE

		[self setLastCommand: @""];      					// used to update package data
		
//MOVE
		lastParams = [[NSMutableArray alloc] init];
		[self setPendingCommand: NO];
//ENDMOVE

		//variables used to display table
		[self setLastIdentifier: @"name"];  // TBD: retrieve from user defaults
		reverseSortImage = [[NSImage alloc] initWithContentsOfFile:
			[[NSBundle mainBundle] pathForResource: @"reverse" ofType: @"tiff"]];
		normalSortImage = [[NSImage alloc] initWithContentsOfFile:
			[[NSBundle mainBundle] pathForResource: @"normal" ofType: @"tiff"]];
			
		//stores whether table columns are sorted in normal or reverse order to enable
		//proper sorting behavior; uses definitions from FinkPackages to set attributes
		columnState = [[NSMutableDictionary alloc] init];
		e = [[NSArray arrayWithObjects: PACKAGE_ATTRIBUTES, nil] objectEnumerator];
		while (attribute = [e nextObject]){  // TBD: save state between runs
			[columnState setObject: @"normal" forKey: attribute];
		}

//MOVE
		environment = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSString stringWithFormat: 
			  @"/%@:/%@/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:",
			  binPath, [packages basePath]],
			@"PATH",
			nil];	
			
		//register for notification that password was entered
		[[NSNotificationCenter defaultCenter] addObserver: self
					selector: @selector(runCommandWithPassword:)
					name: @"passwordWasEntered"
					object: nil];
//ENDMOVE
	}
	return self;
}

-(void)awakeFromNib
{
	//have to do this BEFORE applicationDidFinishLaunching, or it doesn't happen
	[msgText setStringValue:
		@"Gathering data for table; this will take a moment . . ."];
}

//helper used for 1st time in next method
-(void)displayNumberOfPackages
{
	[msgText setStringValue: [NSString stringWithFormat: @"%d packages",
		[[packages array] count]]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSTableColumn *lastColumn = [tableView tableColumnWithIdentifier:
		[self lastIdentifier]];
	
	[packages update];
	[tableView reloadData];
	[self displayNumberOfPackages];
	[tableView setHighlightedTableColumn: lastColumn];
	[tableView setIndicatorImage: normalSortImage inTableColumn: lastColumn];
}

-(void)dealloc
{
	[packages release];
	[binPath release];
	[password release];
	[lastCommand release];
	[lastParams release];
	[lastIdentifier release];
	[columnState release];
	[environment release];
	[reverseSortImage release];
	[normalSortImage release];
	
	[super dealloc];
}

//----------------------------------------------->Accessors

-(FinkDataController *)packages  {return packages;}

-(NSString *)binPath {return binPath;}

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


//MOVE
-(NSString *)password {return password;}
-(void)setPassword:(NSString *)s
{
	[s retain];
	[password release];
	password = s;
}


-(NSMutableArray *)lastParams {return lastParams;}
-(void)setLastParams:(NSArray *)a
{
	[lastParams removeAllObjects];
	[lastParams addObjectsFromArray: a];
}

-(BOOL)pendingCommand {return pendingCommand;}
-(void)setPendingCommand:(BOOL)b
{
	pendingCommand = b;
}


//----------------------------------------------->Sheet Methods

//Administrator Password Entry Sheet

-(IBAction)raisePwdWindow:(id)sender
{
	[NSApp beginSheet: pwdWindow
	   modalForWindow: mainWindow
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
//ENDMOVE

//----------------------------------------------->Action Methods and Helpers

//helper:  display running command above table
-(void)displayCommand:(NSArray *)params
{
	[msgText setStringValue: [NSString stringWithFormat: @"Running %@ . . .",
		[[params subarrayWithRange: NSMakeRange(1, [params count] - 1)]
		componentsJoinedByString: @" "]]];
}

//helper:  set up the argument list for either action method
-(NSMutableArray *)setupCommandFrom:(id)sender
{
	NSString *cmd = [[sender title] lowercaseString];
	NSString *theMenu = [[sender menu] title];
	NSString *executable;
	NSMutableArray *args;

	executable = [theMenu isEqualToString: @"Source"] ? @"fink" : @"apt-get";
	args = [NSMutableArray arrayWithObjects:
		[[self binPath] stringByAppendingPathComponent: executable],
		cmd, nil];
	[self setLastCommand: cmd];

	return args;
}

//run package-specific command with arguments derived from table selection
-(IBAction)runCommand:(id)sender
{
	NSMutableArray *args = [[self setupCommandFrom: sender] retain];
	NSMutableArray *pkgNames = [NSMutableArray array];
	NSEnumerator *e = [tableView selectedRowEnumerator];
	NSNumber *anIndex;

	//put package names selected into a separate array for additional use below
	while(anIndex = [e nextObject]){
		[pkgNames addObject: [[[packages array] objectAtIndex: [anIndex intValue]] name]];
	}
	[args addObjectsFromArray: pkgNames];

	[self displayCommand: args];
		
	[self runCommandWithParams: args];
	[args release];
}

//run non-package-specific command; ignore table selection
-(IBAction)runUpdater:(id)sender
{
	NSMutableArray *args = [[self setupCommandFrom: sender] retain];
	
	[msgText setStringValue: [NSString stringWithFormat: @"Running %@ . . .",
		[args lastObject]]];
		
	[self displayCommand: args];
	
	[self runCommandWithParams: args];
	[args release];
}


-(void)runCommandWithParams:(NSArray *)params
{
	NSMutableArray *fullParams = [NSMutableArray arrayWithObjects:
		@"/usr/bin/sudo", @"-S", nil];

	[fullParams addObjectsFromArray: params];

	if ([[self password] length] < 1){
		[self raisePwdWindow: self];
		[self setLastParams: params];
		[self setPendingCommand: YES];
		[self displayNumberOfPackages];
		return;
	}
	[self setPendingCommand: NO];

	finkTask = [[IOTaskWrapper alloc] initWithController: self arguments: fullParams
												environment: environment];
	// start the process asynchronously
	[finkTask startProcessWithPassword: [NSData dataWithData:
		[[self password] dataUsingEncoding: NSUTF8StringEncoding]]];
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
	[packages update];
	[tableView reloadData];
	[self displayNumberOfPackages];
}


//----------------------------------------------->Table Data Source Methods

-(int)numberOfRowsInTableView:(NSTableView *)aTableView
{		
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

//Disable row selection change while command is running
- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
	if ([[finkTask task] isRunning]){
		NSBeep();
		return NO;
	}
	return YES;
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
	if ([[finkTask task] isRunning] &&
	     ([[[menuItem menu] title] isEqualToString: @"Source"] ||
		 [[[menuItem menu] title] isEqualToString: @"Binary"])){
		return NO;
	}
	return YES;	
}


//----------------------------------------------->IOTaskWrapper Protocol Helpers

//somewhat problematic because, e.g., installing one package may result in removal of
//another; but it's probably better to live with an occasional inaccuracy in the
//table than always calling the very expensive [packages update] after an install
-(void)updatePackageData
{
	NSString *cmd = [self lastCommand];
	NSEnumerator *e = [tableView selectedRowEnumerator];
	FinkPackage *pkg;
	int row;

	if ([cmd isEqualToString: @"install"]){
		while (row = [[e nextObject] intValue]){
			pkg = [[packages array] objectAtIndex: row];
			[pkg setInstalled: @"current"];
		}
	}else if ([cmd isEqualToString: @"remove"]){
		while (row = [[e nextObject] intValue]){
			pkg = [[packages array] objectAtIndex: row];
			[pkg setInstalled: @" "];
		}
	}else if ([cmd isEqualToString: @"selfupdate"]){
		[packages update];
	}else if ([cmd isEqualToString: @"update-all"]){
		e = [[packages array] objectEnumerator];
		while (pkg = [e nextObject]){
			if ([[pkg installed] isEqualToString: @"outdated"]){
				[pkg setInstalled: @"current"];
			}
		}
	}
}

- (void)scrollToVisible:(id)ignore
{
	[textView scrollRangeToVisible:
		NSMakeRange([[textView string] length], 0)];
}


//----------------------------------------------->IOTaskWrapper Protocol Implementation

//much of the code in this method was borrowed from the Moriarity example at
//http://developer.apple.com/samplecode/Sample_Code/Cocoa/Moriarity.htm
- (void)appendOutput:(NSString *)output
{
		NSAttributedString *lastOutput;
		int alertChoice;
		
		lastOutput = [[[NSAttributedString alloc] initWithString:
			output] autorelease];

//MOVE		
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
			NSRunAlertPanel(@"Selfupdate Error", 
			@"FinkCommander currently supports only anonymous access to CVS.",
			@"Darn", nil, nil);
		}
		
		//look for password error message from sudo; if it's received, enter a 
		//return to terminate the process, then notify the user
		if([[lastOutput string] rangeOfString: @"Sorry, try again."].length > 0){
			[[finkTask task] terminate];
			[self setPassword: nil];
			[self setPendingCommand: YES];
			alertChoice = NSRunAlertPanel(@"Password Rejected", @"Please try again.",
								 @"OK", @"Cancel", nil);
			if (alertChoice == NSAlertDefaultReturn){
				[self raisePwdWindow: self];
			}
		}
//ENDMOVE

		[[textView textStorage] appendAttributedString: lastOutput];
		
		// This next bit's a tad mysterious, so I've included the explanation from Moriarity
		// to remind myself why it's here:
		// set up a selector to be called the next time through the event loop to scroll
        // the view to the just pasted text.  We don't want to scroll right now,
        // because of a bug in Mac OS X version 10.1 that causes scrolling in the context
        // of a text storage update to starve the app of events
		[self performSelector: @selector(scrollToVisible:) withObject: nil afterDelay: 0.0];
}

-(void)processStarted
{
	[textView setString: @""];
}

-(void)processFinishedWithStatus:(int)status
{
	NSString *output = [NSString stringWithString: [textView string]];
	
	NSBeep();

	// Checking status is not sufficient for some fink commands
	if (status == 0 && [output rangeOfString:@"failed"
						options: NSCaseInsensitiveSearch
						range: NSMakeRange([output length] - 50, 49)].length == 0){
		[self updatePackageData];
		[tableView reloadData];
	}else{
		NSBeginAlertSheet(@"Error",		//title
		@"OK",							//default button label
		nil,							//alternate button label
		nil,							//other button label
		mainWindow,						//window
		self,							//modal delegate
		NULL,							//didEnd selector
		NULL,							//didDismiss selector
		nil,							//context info
		@"FinkCommander detected a failure message.  Check the output window for problems.",
		nil);							//msg string params
	}
	[self displayNumberOfPackages];
}

@end
