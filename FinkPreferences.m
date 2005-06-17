/*
File: FinkPreferences.m

 See the header file, FinkPreferences.h, for interface and license information.

*/

#import "FinkPreferences.h"

/* Radio button tags */
enum {
	CURL,
	WGET,
	AXEL
};

/* Text field tags */
enum {
	HTTP_PROXY = 1,
	FTP_PROXY = 2,
	FETCH_ALT_DIR = 3,
	OUTPUT_PATH = 4,
	ENVIRONMENT_SETTING = 5,
	PERL_PATH = 6,
	FINK_BASEPATH = 7
};

@implementation FinkPreferences

//--------------------------------------------------------------------------------
#pragma mark STARTUP AND SHUTDOWN
//--------------------------------------------------------------------------------

-(id)init
{
	self = [super initWithWindowNibName:@"Preferences"];
	if (nil != self){
		defaults = [NSUserDefaults standardUserDefaults];
		conf = [[FinkConf alloc] init];  //Object representing the user's fink.conf settings
		[self setWindowFrameAutosaveName: @"Preferences"];
		environmentArray = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)awakeFromNib
{
	//This is a bit anachronistic
	if ([conf extendedVerboseOptions]){
		[verboseOutputPopupButton insertItemWithTitle:NSLocalizedString(@"Low", @"Verbosity level for Fink") atIndex:1];
		[verboseOutputPopupButton insertItemWithTitle:NSLocalizedString(@"Medium", @"Verbosity level for Fink") atIndex:2];
	}
	[environmentTableView setAutosaveName: @"FinkEnvironmentTableView"];
	[environmentTableView setAutosaveTableColumns: YES];
}

-(void)dealloc
{
	[conf release];
	[environmentArray release];
	[super dealloc];
}

//--------------------------------------------------------------------------------
#pragma mark GENERAL HELPERS
//--------------------------------------------------------------------------------

/* 	Transform environment settings in defaults into series of 
	two-item dictionaries (name/value) and place them in environmentArray */
-(void)readEnvironmentDefaultsIntoArray
{
	NSDictionary *environmentSettings = [defaults objectForKey:FinkEnvironmentSettings];
	NSEnumerator *e = [environmentSettings keyEnumerator];
	NSString *name;
	NSMutableDictionary *setting;
	
	[environmentArray removeAllObjects];
	while (nil != (name = [e nextObject])){
		setting = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				name, @"name", [environmentSettings objectForKey:name], @"value", nil];
		[environmentArray addObject:setting];
	}
}

-(void)addEnvironmentKey:(NSString *)name
	value:(NSString *)value
{
	NSMutableDictionary *newSetting = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		name, @"name", value, @"value", nil];
	NSMutableDictionary *setting;
	NSString *key;
	int i, limit = [environmentArray count];

	//Make sure we have no duplicate keys
	for (i=0; i<limit; i++){
		setting = [environmentArray objectAtIndex:i];
		key = [setting objectForKey:@"name"];
		if ([key isEqualToString:name]){
			Dprintf(@"Found setting for %@", name);
			[environmentArray removeObjectAtIndex:i];
			break;
		}
	}
	
	[environmentArray addObject:newSetting];
	[environmentTableView reloadData];
}

/* 	Aggregate the dictionaries in environmentArray into a single dictionary and
	write it to defaults */
-(void)writeEnvironmentArrayIntoDefaults
{
	NSMutableDictionary *environmentSettings = [NSMutableDictionary dictionaryWithCapacity:
													[environmentArray count]];
	NSEnumerator *e = [environmentArray objectEnumerator];
	NSMutableDictionary *setting;
	NSDictionary *newSettings;
	NSString *name, *value;
	
	while (nil != (setting = [e nextObject])){
		name = [setting objectForKey:@"name"];
		value = [setting objectForKey:@"value"];
		[environmentSettings setObject:value forKey:name];
	}
	newSettings = [environmentSettings copy];
	[defaults setObject:newSettings forKey:FinkEnvironmentSettings];
	[newSettings release];
}

-(void)validateEnvironmentButtons
{
	//Enable Add button only if both key and value fields have content
	BOOL addEnabled = [[nameTextField stringValue] length] > 0 &&    
						 [[valueTextField stringValue] length] > 0;
	//Enable Delete button whenever a row is selected
	BOOL deleteEnabled = [environmentTableView numberOfSelectedRows] > 0;
	
	[addEnvironmentSettingButton setEnabled:addEnabled];
	[deleteEnvironmentSettingButton setEnabled:deleteEnabled];
}


//Set preferences to reflect existing defaults and fink.conf settings.
//Used on startup and by cancel button.
-(void)resetPreferences
{
	NSString *httpProxy;
	NSString *ftpProxy;
	NSString *fetchAltDir;
	NSString *downloadMethod;
	NSString *basePath;
	NSString *outputPath;
	NSMutableDictionary *environmentSettings = [[[defaults objectForKey:FinkEnvironmentSettings]
													mutableCopy] autorelease];
	int scrollBackLimit;
	int interval = [defaults integerForKey:FinkCheckForNewVersionInterval];
	
	Dprintf(@"Resetting preferences");
	
	/***  FinkCommander Preferences ***/

	//Commander Tab
	[warnBeforeRemovingButton setState: [defaults boolForKey: FinkWarnBeforeRemoving]];
	[warnBeforeTerminatingButton setState: [defaults boolForKey: FinkWarnBeforeTerminating]];
	[alwaysChooseDefaultsButton setState: [defaults boolForKey: FinkAlwaysChooseDefaults]];
	[giveEmailCreditButton setState: [defaults boolForKey: FinkGiveEmailCredit]];
	[checkForUpdateButton setState:  interval > 0];	
	if (interval){
		[checkForUpdateIntervalTextField setIntValue:interval];
		[checkForUpdateIntervalStepper setIntValue:interval];
	}
	
	//Paths Tab
	pathChoiceChanged = NO;
	basePath = [defaults objectForKey: FinkBasePath];
	if ([basePath isEqualToString: @"/sw"]){
		[pathChoiceMatrix selectCellWithTag: 0];
		[basePathTextField setStringValue: @""];
	}else{
		[pathChoiceMatrix selectCellWithTag: 1];
		[basePathTextField setStringValue: basePath];
	}
	outputPath = [defaults objectForKey: FinkOutputPath];
	[outputPathButton setState: [outputPath length] > 0];
	[outputPathTextField setStringValue: outputPath];
	[perlPathTextField setStringValue:[defaults objectForKey:FinkPerlPath]];
		
	//Display Tab
	autoExpandChanged = NO;
	[scrollToBottomButton setState: [defaults boolForKey: FinkAlwaysScrollToBottom]];
	[showPackagesInTitleButton setState: [defaults boolForKey: FinkPackagesInTitleBar]];
	[autoExpandOutputButton setState: [defaults boolForKey: FinkAutoExpandOutput]];
	[scrollToSelectionButton setState: [defaults boolForKey: FinkScrollToSelection]];
	[allowRegexFilterButton setState: [defaults boolForKey: FinkAllowRegexFiltering]];

	[showRedundantPackagesButton setState: [defaults boolForKey: FinkShowRedundantPackages]];	
	[self setTitleBarImage: self];  //action method
	scrollBackLimit = [defaults integerForKey:FinkBufferLimit];
	[scrollBackLimitButton setState: scrollBackLimit];
	if (scrollBackLimit){
		[scrollBackLimitTextField setIntValue: scrollBackLimit];
	}
	
	/***  Fink Settings in fink.conf ***/

	finkConfChanged = NO;
	
	//Fink Tab
	[useUnstableMainButton setState: [conf useUnstableMain]];
	[useUnstableCryptoButton setState: [conf useUnstableCrypto]];
	[verboseOutputPopupButton selectItemAtIndex:[conf verboseOutput]];
	if ([[conf rootMethod] isEqualToString: @"sudo"]){
		[rootMethodMatrix selectCellWithTag: 0];
	}else{
		[rootMethodMatrix selectCellWithTag: 1];
	}
	fetchAltDir = [conf fetchAltDir];
	[fetchAltDirButton setState: (fetchAltDir != nil ? YES : NO)];
	[fetchAltDirTextField setStringValue: (fetchAltDir != nil ? fetchAltDir : @"")];
	
	//Download Tab
	[passiveFTPButton setState: [conf passiveFTP]];

	httpProxy = [conf useHTTPProxy];
	[httpProxyButton setState: ([httpProxy length] > 0 ? YES : NO)];
	[httpProxyTextField setStringValue: httpProxy];
	
	ftpProxy = [conf useFTPProxy];
	[ftpProxyButton setState: ([ftpProxy length] > 0 ? YES : NO)];
	[ftpProxyTextField setStringValue: ftpProxy];

	downloadMethod = [conf downloadMethod];
	if ([downloadMethod isEqualToString:@"curl"]){
		[downloadMethodMatrix selectCellWithTag:0];
	}else if ([downloadMethod isEqualToString:@"wget"]){
		[downloadMethodMatrix selectCellWithTag:1];
	}else{
		[downloadMethodMatrix selectCellWithTag:2];
	}

	/***  Environment Tab  ***/
	
	[self readEnvironmentDefaultsIntoArray];
	[environmentTableView reloadData];
}

//--------------------------------------------------------------------------------
#pragma mark ACTION HELPERS
//--------------------------------------------------------------------------------

/*** FinkCommander Settings ***/

-(void)setBasePath
{
	if ([[pathChoiceMatrix selectedCell] tag] == 0){
		[defaults setObject: @"/sw" forKey: FinkBasePath];
	}else{
		[defaults setObject: [basePathTextField stringValue] forKey: FinkBasePath];
	}
}

-(void)setScrollBackLimit
{
	int scrollBackLimit = [scrollBackLimitButton state] == NSOnState ?
							[scrollBackLimitTextField intValue] : 0;
							
	[defaults setInteger:scrollBackLimit forKey:FinkBufferLimit];
}

/*** Fink Settings in fink.conf ***/

-(void)setRootMethod
{
	if ([[rootMethodMatrix selectedCell] tag] == 0){
		[conf setRootMethod: @"sudo"];
	}else{
		[conf setRootMethod: @"su"];
	}
}

-(void)setFetchAltDir
{
	if ([fetchAltDirButton state] == NSOnState){
		[conf setFetchAltDir: [fetchAltDirTextField stringValue]];
	}else{
		[conf setFetchAltDir: nil];
	}
}

-(void)setDownloadMethod
{
	switch ([[downloadMethodMatrix selectedCell] tag]){
		case CURL: 
			[conf setDownloadMethod:@"curl"];
			break;
		case WGET:
			[conf setDownloadMethod: @"wget"];
			break;
		case AXEL:
			[conf setDownloadMethod: @"axel"];
			break;
	}
}

-(void)setHTTPProxyVariable
{
	if ([httpProxyButton state] == NSOnState){
		NSString *proxy = [httpProxyTextField stringValue];
		[conf setUseHTTPProxy: proxy];
	}else{
		[conf setUseHTTPProxy: nil];
	}
}

-(void)setFTPProxyVariable
{
	if ([ftpProxyButton state] == NSOnState){
		NSString *proxy = [ftpProxyTextField stringValue];
		[conf setUseFTPProxy:proxy];
	}else{
		[conf setUseFTPProxy: nil];
	}
}

//--------------------------------------------------------------------------------
#pragma mark ACTIONS
//--------------------------------------------------------------------------------

//Apply button
-(IBAction)setPreferences:(id)sender
{
	/*** FinkCommander Preferences ***/

	//Commander Tab
	[defaults setBool: [alwaysChooseDefaultsButton state] 	forKey: FinkAlwaysChooseDefaults];
	[defaults setBool: [warnBeforeRemovingButton state]	 	forKey: FinkWarnBeforeRemoving];
	[defaults setBool: [warnBeforeTerminatingButton state]	forKey: FinkWarnBeforeTerminating];
	[defaults setBool: [giveEmailCreditButton state]		forKey: FinkGiveEmailCredit];
	[defaults setBool: [allowRegexFilterButton state] 	forKey: FinkAllowRegexFiltering];
	if ([checkForUpdateButton state]){
		[defaults setInteger:[checkForUpdateIntervalTextField intValue]
							   forKey:FinkCheckForNewVersionInterval];
	}else{
		[defaults setInteger:0 forKey:FinkCheckForNewVersionInterval];
	}
	
	//Paths Tab
	[self setBasePath];
	[defaults setObject:[outputPathTextField stringValue] forKey: FinkOutputPath];
	[defaults setObject:[perlPathTextField stringValue] forKey:FinkPerlPath];
		//Give manually set path a chance to work on startup
	if (pathChoiceChanged){
		[defaults setBool:YES forKey:FinkBasePathFound];
		fixScript();
	}
	
	//Display Tab
	[self setScrollBackLimit];
	[defaults setBool: [scrollToSelectionButton state] 		forKey: FinkScrollToSelection];
	[defaults setBool: [scrollToBottomButton state] 		forKey: FinkAlwaysScrollToBottom];
	[defaults setBool: [showPackagesInTitleButton state] 	forKey: FinkPackagesInTitleBar];
	[defaults setBool: [autoExpandOutputButton state] 		forKey: FinkAutoExpandOutput];
	[defaults setBool: [showRedundantPackagesButton state] 	forKey: FinkShowRedundantPackages];
		//Notify FinkController to collapse output if user chose to
		//automatically expand and collapse
	if (autoExpandChanged && [autoExpandOutputButton state]){
		[[NSNotificationCenter defaultCenter]
			postNotificationName:FinkCollapseOutputView
						  object:nil];
	}
	
	//Environment Tab
	[self writeEnvironmentArrayIntoDefaults];

	/***  Fink Settings in fink.conf ***/
	
	if (finkConfChanged){ 
		//Set to yes whenever user selects a button or changes a field in the Fink or
		//Downloads tabs

		//Fink Tab
		[conf setUseUnstableCrypto: [useUnstableCryptoButton state]];
		[conf setUseUnstableMain: [useUnstableMainButton state]];
		[conf setVerboseOutput:[verboseOutputPopupButton indexOfSelectedItem]];
		[conf setKeepBuildDir: [keepBuildDirectoryButton state]];
		[conf setKeepRootDir: [keepRootDirectoryButton state]];
		[self setRootMethod];

		//Download Tab
		[self setDownloadMethod];
		[conf setPassiveFTP: [passiveFTPButton state]];
		[self setHTTPProxyVariable];
		[self setFTPProxyVariable];
		[self setFetchAltDir];

		finkConfChanged = NO;
		[conf writeToFile];
	}
}

//OK Button
-(IBAction)setAndClose:(id)sender
{
	[self setPreferences:nil];
	[self close];
}

//Cancel Button
-(IBAction)cancel:(id)sender
{
	[self resetPreferences];
	[self close];
}

/*** Flags ***/

//Connected to path-to-fink matrix
-(IBAction)setPathChoiceChanged:(id)sender
{
	pathChoiceChanged = YES;
}

//Connected to all buttons in fink.conf tabs
-(IBAction)setFinkConfChanged:(id)sender
{
	finkConfChanged = YES;
}

//Connected to use unstable and use unstable crypto buttons
-(IBAction)setFinkTreesChanged:(id)sender
{
	finkConfChanged = YES;
	[conf setFinkTreesChanged: YES];
}

/*** Display Tab Buttons ***/

//Change image of title bar in preference panel to reflect user's choice
-(IBAction)setTitleBarImage:(id)sender
{
	if ([showPackagesInTitleButton state]){
		[titleBarImageView setImage: [NSImage imageNamed: @"number"]];
	}else{
		[titleBarImageView setImage: [NSImage imageNamed: @"title"]];
	}
}

-(IBAction)setAutoExpandChanged:(id)sender
{
	//Determines whether a notification to collapse the output view
	//is sent to FinkSplitView
	autoExpandChanged = YES;
}

/*** Dialog Opened by Browse Buttons ***/

-(IBAction)selectDirectory:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	NSString *directory = NSHomeDirectory();
	NSTextField *pathField = nil;

	switch([sender tag]){
		case FINK_BASEPATH: 
			pathField = basePathTextField;
			directory = @"/usr";
			break;
		case FETCH_ALT_DIR:
			pathField = fetchAltDirTextField;
			break;
		case OUTPUT_PATH:
			pathField = outputPathTextField;
			break;
		case PERL_PATH:
			pathField = perlPathTextField;
			directory = @"/usr";
			break;
	}
	
	[panel setCanChooseDirectories: YES];
	[panel setCanChooseFiles: NO];
	[panel setAllowsMultipleSelection: NO];
	[panel setPrompt: NSLocalizedString(@"Choose", @"Title for panel asking user to choose a directory")];
	
	[panel beginSheetForDirectory:directory
		file: nil
		types: nil
		modalForWindow: [self window]
		modalDelegate: self
		didEndSelector: @selector(openPanelDidEnd:returnCode:textField:)
		contextInfo: pathField];
}

-(void)openPanelDidEnd:(NSOpenPanel *)openPanel
				  returnCode:(int)returnCode
				   textField:(NSTextField *)textField
{
	if (returnCode == NSOKButton){
		NSString *path = [[openPanel filenames] objectAtIndex:0];
		Dprintf(@"Path chosen: %@", path);
		[textField setStringValue: path];
		Dprintf(@"Text field value: %@", [textField stringValue]);

		//FinkPreferences is registered for this notification to make
		//sure buttons associated with text fields accurately reflect the
		//fields' state
		[[NSNotificationCenter defaultCenter]
				postNotificationName: NSControlTextDidChangeNotification
							  object: textField];

		Dprintf(@"Text field value after notification: %@", [textField stringValue]);
	}
}

/*** Environment Tab Buttons ***/

-(IBAction)addEnvironmentSetting:(id)sender
{
	NSString *name = [nameTextField stringValue];
	NSString *value = [valueTextField stringValue];
	[self addEnvironmentKey:name value:value];
	[nameTextField setStringValue:@""];
	[valueTextField setStringValue:@""];
	[self validateEnvironmentButtons];	
}

-(IBAction)removeEnvironmentSettings:(id)sender
{
	NSEnumerator *e = [environmentTableView selectedRowEnumerator];
	NSNumber *n;
	int row;
	
	while (nil != (n = [e nextObject])){
		row = [n intValue];
		[environmentArray removeObjectAtIndex:row];
	}
	[environmentTableView reloadData];
	[self validateEnvironmentButtons];
}

-(IBAction)restoreEnvironmentSettings:(id)sender
{
	setInitialEnvironmentVariables();
	[self readEnvironmentDefaultsIntoArray];
	[environmentTableView reloadData];	
	[self validateEnvironmentButtons];
}

//--------------------------------------------------------------------------------
#pragma mark DELEGATE METHODS
//--------------------------------------------------------------------------------

-(void)windowDidLoad
{
	[self resetPreferences];
	[self validateEnvironmentButtons];
}

//NSTextField delegate method; automatically set button state to match text input
-(void)controlTextDidChange:(NSNotification *)aNotification
{
	NSTextField *tField = [aNotification object];
	int textFieldID = [tField tag];
	NSString *tfString = [tField stringValue];

	//Select the button that corresponds to the altered text field.
	//The text fields were given the indicated tag numbers in IB.
	switch(textFieldID){
		case FINK_BASEPATH:
			[pathChoiceMatrix selectCellWithTag:
				([tfString length] > 0 ? 1 : 0)]; //0 == default
			break;
		case HTTP_PROXY:
			[httpProxyButton setState: 
				([[httpProxyTextField stringValue] length] > 0 ? YES : NO)];
			finkConfChanged = YES;
			break;
		case FTP_PROXY:
			[ftpProxyButton setState:
				([[ftpProxyTextField stringValue] length] > 0 ? YES : NO)];
			finkConfChanged = YES;
			break;
		case FETCH_ALT_DIR:
			[fetchAltDirButton setState:
				([[fetchAltDirTextField stringValue] length] > 0 ? YES : NO)];
			finkConfChanged = YES;
			break;
		case OUTPUT_PATH:
			[outputPathButton setState:
				([tfString length] > 0 ? YES : NO)];
			break;
		case ENVIRONMENT_SETTING:
			[self validateEnvironmentButtons];
			break;
		default:
			break;
	}
}


//Environment table view delegate
-(void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[self validateEnvironmentButtons];
}


//--------------------------------------------------------------------------------
#pragma mark ENVIRONMENT TABLE DATA SOURCE METHODS
//--------------------------------------------------------------------------------

-(int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [environmentArray count];
}

-(id)tableView:(NSTableView *)aTableView
	objectValueForTableColumn:(NSTableColumn *)aTableColumn
	row:(int)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	return [[environmentArray objectAtIndex:rowIndex] objectForKey:identifier];
}

-(void)tableView:(NSTableView *)aTableView 
		setObjectValue:(id)anObject 
		forTableColumn:(NSTableColumn *)aTableColumn 
		row:(int)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	[[environmentArray objectAtIndex:rowIndex] setObject:anObject forKey:identifier];
}

@end

