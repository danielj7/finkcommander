/*
File: FinkPreferences.m

 See the header file, FinkPreferences.h, for interface and license information.

*/

#import "FinkPreferences.h"

@implementation FinkPreferences

//--------------------------------------------------------------------------------
#pragma mark STARTUP AND SHUTDOWN
//--------------------------------------------------------------------------------

-(id)init
{
	self = [super initWithWindowNibName:@"Preferences"];
	defaults = [NSUserDefaults standardUserDefaults];
	conf = [[FinkConf alloc] init];
	
	[self setWindowFrameAutosaveName: @"Preferences"];

	return self;
}

-(void)awakeFromNib
{
	if ([conf extendedVerboseOptions]){
		[verboseOutputPopupButton insertItemWithTitle:NSLocalizedString(@"Low", nil) atIndex:1];
		[verboseOutputPopupButton insertItemWithTitle:NSLocalizedString(@"Medium", nil) atIndex:2];
	}
}

-(void)dealloc
{
	[conf release];
	[environmentSettings release];
	[environmentKeyList release];
	[super dealloc];
}

//--------------------------------------------------------------------------------
#pragma mark GENERAL HELPERS
//--------------------------------------------------------------------------------

-(void)validateEnvironmentButtons
{
	BOOL addEnabled = [[nameTextField stringValue] length] > 0 && 
						 [[valueTextField stringValue] length] > 0;
	BOOL deleteEnabled = [environmentTableView numberOfSelectedRows] > 0;
	
	[addEnvironmentSettingButton setEnabled:addEnabled];
	[deleteEnvironmentSettingButton setEnabled:deleteEnabled];
}

-(void)setEnvironment
{
    [environmentSettings release];
    environmentSettings = 
		[[defaults objectForKey:FinkEnvironmentSettings] mutableCopy];
}

-(void)setEnvironmentKeys
{
    [environmentKeyList release];
    environmentKeyList = [[environmentSettings allKeys] mutableCopy];
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
	int scrollBackLimit;
	int interval = [defaults integerForKey:FinkCheckForNewVersionInterval];
	
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
		
	//Display Tab
	autoExpandChanged = NO;
	[scrollToBottomButton setState: [defaults boolForKey: FinkAlwaysScrollToBottom]];
	[showPackagesInTitleButton setState: [defaults boolForKey: FinkPackagesInTitleBar]];
	[autoExpandOutputButton setState: [defaults boolForKey: FinkAutoExpandOutput]];
	[scrollToSelectionButton setState: [defaults boolForKey: FinkScrollToSelection]];
	[showRedundantPackagesButton setState: [defaults boolForKey: FinkShowRedundantPackages]];	
	[self setTitleBarImage: self];  //action method
	scrollBackLimit = [defaults integerForKey:FinkBufferLimit];
	[scrollBackLimitButton setState: scrollBackLimit];
	if (scrollBackLimit){
		[scrollBackLimitTextField setIntValue: scrollBackLimit];
	}

	//Environment Tab
	[self setEnvironment];
	[self setEnvironmentKeys];
	[environmentTableView reloadData];
	
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
	httpProxy = [environmentSettings objectForKey:@"http_proxy"];
	if (! httpProxy) httpProxy = [conf useHTTPProxy];
	if (! httpProxy) httpProxy = @"";
	[httpProxyButton setState: ([httpProxy length] > 0 ? YES : NO)];
	[httpProxyTextField setStringValue: httpProxy];
	downloadMethod = [conf downloadMethod];
	if ([downloadMethod isEqualToString:@"curl"]){
		[downloadMethodMatrix selectCellWithTag:0];
	}else if ([downloadMethod isEqualToString:@"wget"]){
		[downloadMethodMatrix selectCellWithTag:1];
	}else{
		[downloadMethodMatrix selectCellWithTag:2];
	}
	ftpProxy = [conf useFTPProxy];
	[ftpProxyButton setState: (ftpProxy != nil ? YES : NO)];
	[ftpProxyTextField setStringValue: (ftpProxy != nil ? ftpProxy : @"")];
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
		case 0: 
			[conf setDownloadMethod:@"curl"];
			break;
		case 1:
			[conf setDownloadMethod: @"wget"];
			break;
		case 2:
			[conf setDownloadMethod: @"axel"];
			break;
	}
}

-(void)setHTTPProxyVariable
{
	if ([httpProxyButton state] == NSOnState){
		NSString *proxy = [httpProxyTextField stringValue];
		[conf setUseHTTPProxy: proxy];
		[environmentSettings setObject:proxy forKey:@"http_proxy"];
	}else{
		[conf setUseHTTPProxy: nil];
	}
}

-(void)setFTPProxyVariable
{
	if ([ftpProxyButton state] == NSOnState){
		[conf setUseFTPProxy: [ftpProxyTextField stringValue]];
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
	if ([checkForUpdateButton state]){
		[defaults setInteger:[checkForUpdateIntervalTextField intValue]
							   forKey:FinkCheckForNewVersionInterval];
	}else{
		[defaults setInteger:0 forKey:FinkCheckForNewVersionInterval];
	}
	
	//Paths Tab
	[self setBasePath];
	[defaults setObject: [outputPathTextField stringValue] 	forKey: FinkOutputPath];
		//Give manually set path a chance to work on startup
	if (pathChoiceChanged){
		[defaults setBool: YES forKey: FinkBasePathFound];
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
	[defaults setObject: environmentSettings forKey: FinkEnvironmentSettings];
	[environmentTableView reloadData];

	/***  Fink Settings in fink.conf ***/
	
	if (finkConfChanged){

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
	autoExpandChanged = YES;
}

/*** Dialog Opened by Browse Buttons ***/

-(IBAction)selectDirectory:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	NSTextField *pathField = nil;

	switch([sender tag]){
		case 0: 
			pathField = basePathTextField;
			break;
		case 3:
			pathField = fetchAltDirTextField;
			break;
		case 4:
			pathField = outputPathTextField;
			break;
	}
	
	[panel setCanChooseDirectories: YES];
	[panel setCanChooseFiles: NO];
	[panel setAllowsMultipleSelection: NO];
	[panel setPrompt: NSLocalizedString(@"Choose", nil)];
	
	[panel beginSheetForDirectory: NSHomeDirectory()
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
		[textField setStringValue: [openPanel filename]];

		[[NSNotificationCenter defaultCenter]
				postNotificationName: NSControlTextDidChangeNotification
							  object: textField];
	}
}

/*** Environment Tab Buttons ***/

-(IBAction)addEnvironmentSetting:(id)sender
{
	NSString *name = [nameTextField stringValue];
	NSString *value = [valueTextField stringValue];

	[environmentSettings setObject:value forKey:name];
	[self setEnvironmentKeys];
	[environmentTableView reloadData];
	[nameTextField setStringValue:@""];
	[valueTextField setStringValue:@""];
	[self validateEnvironmentButtons];
}

-(IBAction)removeEnvironmentSettings:(id)sender
{
	NSEnumerator *e = [environmentTableView selectedRowEnumerator];
	NSMutableArray *settingsToRemove = [NSMutableArray array];
	NSNumber *n;
	NSString *name;
	
	while (nil != (n = [e nextObject])){
		[settingsToRemove addObject:[environmentKeyList objectAtIndex:[n intValue]]];
	}
	e = [settingsToRemove objectEnumerator];
	while (nil != (name = [e nextObject])){
		[environmentSettings removeObjectForKey:name];
	}
	[self setEnvironmentKeys];
	[environmentTableView reloadData];
	[self validateEnvironmentButtons];
}

-(IBAction)restoreEnvironmentSettings:(id)sender
{
	setInitialEnvironmentVariables();
	[self setEnvironment];
	[self setEnvironmentKeys];
	[environmentTableView reloadData];	
	[self validateEnvironmentButtons];
}

//--------------------------------------------------------------------------------
#pragma mark DELEGATE METHODS
//--------------------------------------------------------------------------------

/*** Window Delegates ***/

-(void)windowDidBecomeKey:(NSNotification *)ignore
{
	[self resetPreferences];
}

-(void)windowDidLoad
{
	[self resetPreferences];
	[self validateEnvironmentButtons];
}

//NSTextField delegate method; automatically set button state to match text input
-(void)controlTextDidChange:(NSNotification *)aNotification
{
	int textFieldID = [[aNotification object] tag];
	NSString *tfString = [[aNotification object] stringValue];

	//Select the button that corresponds to the altered text field.
	//The text fields were given the indicated tag numbers in IB.
	switch(textFieldID){
		case 0:
			[pathChoiceMatrix selectCellWithTag:
				([tfString length] > 0 ? 1 : 0)]; //0 == default
			break;
		case 1:
			[httpProxyButton setState: 
				([[httpProxyTextField stringValue] length] > 0 ? YES : NO)];
			finkConfChanged = YES;
			break;
		case 2:
			[ftpProxyButton setState:
				([[ftpProxyTextField stringValue] length] > 0 ? YES : NO)];
			finkConfChanged = YES;
			break;
		case 3:
			[fetchAltDirButton setState:
				([[fetchAltDirTextField stringValue] length] > 0 ? YES : NO)];
			finkConfChanged = YES;
			break;
		case 4:
			[outputPathButton setState:
				([tfString length] > 0 ? 1 : 0)];
			break;
		case 5:
			[self validateEnvironmentButtons];
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
	return [environmentKeyList count];
}

-(id)tableView:(NSTableView *)aTableView
	objectValueForTableColumn:(NSTableColumn *)aTableColumn
	row:(int)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	NSString *name = [environmentKeyList objectAtIndex:rowIndex];
	NSString *columnValue = [identifier isEqualToString:@"name"] ? 
							name :
							[environmentSettings objectForKey:name];

	return columnValue;
}

-(void)tableView:(NSTableView *)aTableView 
		setObjectValue:(id)anObject 
		forTableColumn:(NSTableColumn *)aTableColumn 
		row:(int)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	NSString *name = [environmentKeyList objectAtIndex:rowIndex];
	
	if ([identifier isEqualToString:@"value"]){
		[environmentSettings setObject:anObject forKey:name];
	}else{
		NSString *value = [environmentSettings objectForKey:name];
		[environmentSettings removeObjectForKey:name];
		[environmentSettings setObject:value forKey:anObject];
	}
	[self setEnvironmentKeys];
}

@end

