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

-(void)dealloc
{
	[conf release];
	[super dealloc];
}

//helper to set or reset state of preference widgets
//used on startup by windowDidLoad: method and when "Cancel" button clicked
-(void)resetPreferences
{
	NSString *basePath;
	NSString *outputPath;
	NSString *httpProxy; 
	NSString *ftpProxy;
	NSString *fetchAltDir;
	
	//FinkCommander Preferences
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
	pathChoiceChanged = NO;
	autoExpandChanged = NO;
	finkConfChanged = NO;
	[alwaysChooseDefaultsButton setState: [defaults boolForKey: FinkAlwaysChooseDefaults]];
	[askOnStartupButton setState: [defaults boolForKey: FinkAskForPasswordOnStartup]];
	[neverAskButton setState: [defaults boolForKey: FinkNeverAskForPassword]];
	[scrollToBottomButton setState: [defaults boolForKey: FinkAlwaysScrollToBottom]];
	[warnBeforeRunningButton setState: [defaults boolForKey: FinkWarnBeforeRunning]];
	[warnBeforeRemovingButton setState: [defaults boolForKey: FinkWarnBeforeRemoving]];
	[showPackagesInTitleButton setState: [defaults boolForKey: FinkPackagesInTitleBar]];
	[self setTitleBarImage: nil];
	[autoExpandOutputButton setState: [defaults boolForKey: FinkAutoExpandOutput]];
	[updateWithFinkButton setState: [defaults boolForKey: FinkUpdateWithFink]];
	[scrollToSelectionButton setState: [defaults boolForKey: FinkScrollToSelection]];
	[giveEmailCreditButton setState: [defaults boolForKey: FinkGiveEmailCredit]];
	
	//Fink Preferences
	[useUnstableMainButton setState: [conf useUnstableMain]];
	[useUnstableCryptoButton setState: [conf useUnstableCrypto]];
	[verboseOutputButton setState: [conf verboseOutput]];
	[passiveFTPButton setState: [conf passiveFTP]];
	httpProxy = [defaults objectForKey: FinkHTTPProxyVariable];

	if ([httpProxy length] == 0 && [conf useHTTPProxy] != nil){
		httpProxy = [conf useHTTPProxy];
		[defaults setBool: YES forKey: FinkLookedForProxy];
	}
	[httpProxyButton setState: ([httpProxy length] > 0 ? YES : NO)];
	[httpProxyTextField setStringValue: httpProxy];
	
	if ([[conf downloadMethod] isEqualToString: @"curl"]){
		[downloadMethodMatrix selectCellWithTag: 0];
	}else{
		[downloadMethodMatrix selectCellWithTag: 1];
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
}

-(void)windowDidLoad
{
	[self resetPreferences];
}

//---------------------------------------------------------------------->Helpers

-(void)setBasePath
{
	if ([[pathChoiceMatrix selectedCell] tag] == 0){
		[defaults setObject: @"/sw" forKey: FinkBasePath];
	}else{
		[defaults setObject: [basePathTextField stringValue] forKey: FinkBasePath];
	}
}

-(void)setDownloadMethod
{
	if ([[downloadMethodMatrix selectedCell] tag] == 0){
		[conf setDownloadMethod: @"curl"];
	}else{
		[conf setDownloadMethod: @"wget"];
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
		[defaults setObject: proxy forKey: FinkHTTPProxyVariable];
		[conf setUseHTTPProxy: proxy];
	}else{
		[defaults setObject: @"" forKey: FinkHTTPProxyVariable];
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

//---------------------------------------------------------------------->Actions

-(IBAction)setPreferences:(id)sender
{
	[self setBasePath];
	[defaults setObject: [outputPathTextField stringValue] 	forKey: FinkOutputPath];
	
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
	//give manually set path a chance to work on startup
	if (pathChoiceChanged){
		[defaults setBool: YES forKey: FinkBasePathFound];
	}

	if (autoExpandChanged && [autoExpandOutputButton state]){
		[[NSNotificationCenter defaultCenter] postNotificationName: FinkCollapseOutputView
			object: nil];
	}

	if (finkConfChanged){
		[conf setUseUnstableMain: [useUnstableMainButton state]];
		[conf setUseUnstableCrypto: [useUnstableCryptoButton state]];
		[conf setVerboseOutput: [verboseOutputButton state]];
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
}

-(void)setWarnBeforeRemovingButtonState:(BOOL)b
{
	[warnBeforeRemovingButton setState: b];
}

-(IBAction)setAndClose:(id)sender
{
	[self setPreferences: nil];
	[self close];
}

-(IBAction)cancel:(id)sender
{
	[self resetPreferences];
	[self close];
}

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


//didEndSelector for following method
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
	[panel setPrompt: @"Choose"];
	
	[panel beginSheetForDirectory: NSHomeDirectory()
		file: nil
		types: nil
		modalForWindow: [self window]
		modalDelegate: self
		didEndSelector: @selector(openPanelDidEnd:returnCode:textField:)
		contextInfo: pathField];
}

//---------------------------------------------------------------------->Delegate Method(s)

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
	}
}


@end
