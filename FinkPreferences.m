/*
File: FinkPreferences.m

 See the header file, FinkPreferences.h, for interface and license information.

*/
#import "FinkPreferences.h"

@implementation FinkPreferences

//--------------------------------------------------------------->Startup and Shutdown

-(id)init
{
	self = [super initWithWindowNibName: @"Preferences"];
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
	[super dealloc];
}

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

//helper to set or reset state of preference widgets
//used on startup by windowDidLoad: method and when "Cancel" button is clicked
-(void)resetPreferences
{
	NSString *httpProxy;
	NSString *basePath;
	NSString *outputPath;
	NSString *ftpProxy;
	NSString *fetchAltDir;
	NSString *downloadMethod;
	int scrollBackLimit;
	int interval = [defaults integerForKey:FinkCheckForNewVersionInterval];
	
	/***  FinkCommander Preferences ***/

	[self setEnvironment];
	[self setEnvironmentKeys];

	pathChoiceChanged = NO;
	autoExpandChanged = NO;

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
	
	[alwaysChooseDefaultsButton setState: [defaults boolForKey: FinkAlwaysChooseDefaults]];
	[askOnStartupButton setState: [defaults boolForKey: FinkAskForPasswordOnStartup]];
	[neverAskButton setState: [defaults boolForKey: FinkNeverAskForPassword]];
	[scrollToBottomButton setState: [defaults boolForKey: FinkAlwaysScrollToBottom]];
	[warnBeforeRunningButton setState: [defaults boolForKey: FinkWarnBeforeRunning]];
	[warnBeforeRemovingButton setState: [defaults boolForKey: FinkWarnBeforeRemoving]];
	[showPackagesInTitleButton setState: [defaults boolForKey: FinkPackagesInTitleBar]];
	[autoExpandOutputButton setState: [defaults boolForKey: FinkAutoExpandOutput]];
	[updateWithFinkButton setState: [defaults boolForKey: FinkUpdateWithFink]];
	[scrollToSelectionButton setState: [defaults boolForKey: FinkScrollToSelection]];
	[giveEmailCreditButton setState: [defaults boolForKey: FinkGiveEmailCredit]];
	[checkForUpdateButton setState:  interval > 0];
	if (interval){
		[checkForUpdateIntervalTextField setIntValue:interval];
	}
	
	
	[self setTitleBarImage: nil];
	
	scrollBackLimit = [defaults integerForKey:FinkBufferLimit];
	[scrollBackLimitButton setState: scrollBackLimit];
	if (scrollBackLimit){
		[scrollBackLimitTextField setIntValue: scrollBackLimit];
	}
	
	/***  fink.conf Settings  ***/

	finkConfChanged = NO;
	
	[useUnstableMainButton setState: [conf useUnstableMain]];
	[useUnstableCryptoButton setState: [conf useUnstableCrypto]];
	[passiveFTPButton setState: [conf passiveFTP]];
	
	[verboseOutputPopupButton selectItemAtIndex:[conf verboseOutput]];
	
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
	
	if ([[conf rootMethod] isEqualToString: @"sudo"]){
		[rootMethodMatrix selectCellWithTag: 0];
	}else{
		[rootMethodMatrix selectCellWithTag: 1];
	}

	ftpProxy = [conf useFTPProxy];
	[ftpProxyButton setState: (ftpProxy != nil ? YES : NO)];
	[ftpProxyTextField setStringValue: (ftpProxy != nil ? ftpProxy : @"")];
	
	fetchAltDir = [conf fetchAltDir];
	[fetchAltDirButton setState: (fetchAltDir != nil ? YES : NO)];
	[fetchAltDirTextField setStringValue: (fetchAltDir != nil ? fetchAltDir : @"")];

	[environmentTableView reloadData];
	
}

-(void)windowDidLoad
{
	[self resetPreferences];
	[self validateEnvironmentButtons];
}

//---------------------------------------------------------------------->Action Helpers

//FinkCommander settings

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

//fink.conf settings

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

-(void)setRootMethod
{
	if ([[rootMethodMatrix selectedCell] tag] == 0){
		[conf setRootMethod: @"sudo"];
	}else{
		[conf setRootMethod: @"su"];
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

-(void)setFetchAltDir
{
	if ([fetchAltDirButton state] == NSOnState){
		[conf setFetchAltDir: [fetchAltDirTextField stringValue]];
	}else{
		[conf setFetchAltDir: nil];
	}
}

//public method used to reflect the user's selection of "Remove/Don't Warn" in the
//warning dialog
-(void)setWarnBeforeRemovingButtonState:(BOOL)b
{
	[warnBeforeRemovingButton setState:b];
}

//---------------------------------------------------------------------->Actions

//Apply button
-(IBAction)setPreferences:(id)sender
{
	[self setBasePath];
	[self setScrollBackLimit];
	
	[defaults setObject: [outputPathTextField stringValue] 	forKey: FinkOutputPath];
	[defaults setObject: environmentSettings				forKey: FinkEnvironmentSettings];
	
	[defaults setBool: [updateWithFinkButton state] 		forKey: FinkUpdateWithFink];
	[defaults setBool: [alwaysChooseDefaultsButton state] 	forKey: FinkAlwaysChooseDefaults];
	[defaults setBool: [scrollToSelectionButton state] 		forKey: FinkScrollToSelection];
	[defaults setBool: [askOnStartupButton state] 			forKey: FinkAskForPasswordOnStartup];
	[defaults setBool: [neverAskButton state] 				forKey: FinkNeverAskForPassword];
	[defaults setBool: [scrollToBottomButton state] 		forKey: FinkAlwaysScrollToBottom];
	[defaults setBool: [warnBeforeRunningButton state]	 	forKey: FinkWarnBeforeRunning];
	[defaults setBool: [warnBeforeRemovingButton state]	 	forKey: FinkWarnBeforeRemoving];
	[defaults setBool: [showPackagesInTitleButton state] 	forKey: FinkPackagesInTitleBar];
	[defaults setBool: [autoExpandOutputButton state] 		forKey: FinkAutoExpandOutput];
	[defaults setBool: [giveEmailCreditButton state]		forKey: FinkGiveEmailCredit];
	
	if ([checkForUpdateButton state]){
		[defaults setInteger:[checkForUpdateIntervalTextField intValue] 
					forKey:FinkCheckForNewVersionInterval];
	}

	//give manually set path a chance to work on startup
	if (pathChoiceChanged){
		[defaults setBool: YES forKey: FinkBasePathFound];
	}

	if (autoExpandChanged && [autoExpandOutputButton state]){
		[[NSNotificationCenter defaultCenter] 
			postNotificationName:FinkCollapseOutputView
			object:nil];
	}

	if (finkConfChanged){
		[conf setUseUnstableMain: [useUnstableMainButton state]];
		[conf setUseUnstableCrypto: [useUnstableCryptoButton state]];
		[conf setVerboseOutput:[verboseOutputPopupButton indexOfSelectedItem]];
			
		[conf setPassiveFTP: [passiveFTPButton state]];
		[conf setKeepBuildDir: [keepBuildDirectoryButton state]];
		[conf setKeepRootDir: [keepRootDirectoryButton state]];

		[self setDownloadMethod];
		[self setRootMethod];
		[self setHTTPProxyVariable];
		[self setFTPProxyVariable];
		[self setFetchAltDir];
		finkConfChanged = NO;

		[conf writeToFile];
	}
	[environmentTableView reloadData];
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

//flag changes that require additional action when the Apply or OK button is clicked

-(IBAction)setPathChoiceChanged:(id)sender
{
	pathChoiceChanged = YES;
}

-(IBAction)setAutoExpandChanged:(id)sender
{
	autoExpandChanged = YES;
}

-(IBAction)setFinkConfChanged:(id)sender
{
	finkConfChanged = YES;
}

-(IBAction)setFinkTreesChanged:(id)sender
{
	finkConfChanged = YES;
	[conf setFinkTreesChanged: YES];
	
}

//keep ask for password buttons consistent (2)

-(IBAction)neverAsk:(id)sender
{
	if ([neverAskButton state]){
		[askOnStartupButton setState: NO];
	}
}

-(IBAction)askOnStartup:(id)sender
{
	if ([askOnStartupButton state]){
		[neverAskButton setState: NO];
	}
}


-(IBAction)setTitleBarImage:(id)sender
{
	if ([showPackagesInTitleButton state]){
		[titleBarImageView setImage: [NSImage imageNamed: @"number"]];
	}else{
		[titleBarImageView setImage: [NSImage imageNamed: @"title"]];
	}
}

//Browse button

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

//Environment tab buttons

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
	
	while (n = [e nextObject]){
		[settingsToRemove addObject:[environmentKeyList objectAtIndex:[n intValue]]];
	}
	e = [settingsToRemove objectEnumerator];
	while (name = [e nextObject]){
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

//---------------------------------------------------------------------->Delegate Methods

//NSTextField delegate method; automatically set button state to match text input
-(void)controlTextDidChange:(NSNotification *)aNotification
{
	int textFieldID = [[aNotification object] tag];
	NSString *tfString = [[aNotification object] stringValue];

	//select the button that corresponds to the altered text field
	//the text fields were given the indicated tag #s in IB
	//
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

//table view delegate
-(void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[self validateEnvironmentButtons];
}

//---------------------------------------------------------------------->Data Source Methods

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

- (void)tableView:(NSTableView *)aTableView 
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



