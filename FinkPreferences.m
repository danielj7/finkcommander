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
	NSString *httpProxy; 
	NSString *ftpProxy;
	NSString *fetchAltDir;
	
	//General preferences
	basePath = [defaults objectForKey: FinkBasePath];
	if ([basePath isEqualToString: @"/sw"]){
		[pathChoiceMatrix selectCellWithTag: 0];
		[basePathTextField setStringValue: @""];
	}else{
		[pathChoiceMatrix selectCellWithTag: 1];
		[basePathTextField setStringValue: basePath];
	}
	pathChoiceChanged = NO;
	finkConfChanged = NO;
	[alwaysChooseDefaultsButton setState: [defaults boolForKey: FinkAlwaysChooseDefaults]];
	[askOnStartupButton setState: [defaults boolForKey: FinkAskForPasswordOnStartup]];
	[neverAskButton setState: [defaults boolForKey: FinkNeverAskForPassword]];
	[scrollToBottomButton setState: [defaults boolForKey: FinkAlwaysScrollToBottom]];
	[warnBeforeRunningButton setState: [defaults boolForKey: FinkWarnBeforeRunning]];
	[showPackagesInTitleButton setState: [defaults boolForKey: FinkPackagesInTitleBar]];
		
	//Table Preferences
	[updateWithFinkButton setState: [defaults boolForKey: FinkUpdateWithFink]];
	[scrollToSelectionButton setState: [defaults boolForKey: FinkScrollToSelection]];
	
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
	
	[defaults setBool: [updateWithFinkButton state] forKey: FinkUpdateWithFink];
	[defaults setBool: [alwaysChooseDefaultsButton state] forKey: FinkAlwaysChooseDefaults];
	[defaults setBool: [scrollToSelectionButton state] forKey: FinkScrollToSelection];
	[defaults setBool: [askOnStartupButton state] forKey: FinkAskForPasswordOnStartup];
	[defaults setBool: [neverAskButton state] forKey: FinkNeverAskForPassword];
	[defaults setBool: [scrollToBottomButton state] forKey: FinkAlwaysScrollToBottom];
	[defaults setBool: [warnBeforeRunningButton state] forKey: FinkWarnBeforeRunning];
	[defaults setBool: [showPackagesInTitleButton state] forKey: FinkPackagesInTitleBar];
	//give manually set path a chance to work on startup
	if (pathChoiceChanged){
		[defaults setBool: YES forKey: FinkBasePathFound];
	}

	if (finkConfChanged){
		[conf setUseUnstableMain: [useUnstableMainButton state]];
		[conf setUseUnstableCrypto: [useUnstableCryptoButton state]];
		[conf setVerboseOutput: [verboseOutputButton state]];
		[conf setPassiveFTP: [passiveFTPButton state]];
		[conf setKeepBuildDir: [keepBuildDirectoryButton state]];
		[conf setKeepRootDir: [keepRootDirectoryButton state]];

		[self setDownloadMethod];
		[self setHTTPProxyVariable];
		[self setFTPProxyVariable];
		[self setFetchAltDir];
		finkConfChanged = NO;

		[conf writeToFile];
	}
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

-(IBAction)setPathChoice:(id)sender
{
	pathChoiceChanged = YES;
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
	NSTextField *pathField = ([sender tag] == 0 ? basePathTextField : fetchAltDirTextField);
	
	[panel setCanChooseDirectories: YES];
	[panel setCanChooseFiles: NO];
	[panel setAllowsMultipleSelection: NO];
	
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
	}
}


@end
