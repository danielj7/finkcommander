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
	[alwaysChooseDefaultsButton setState: [defaults boolForKey: FinkAlwaysChooseDefaults]];
		
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

//---------------------------------------------------------------------->Actions


-(IBAction)setPreferences:(id)sender
{
	[self setBasePath];
	
	[defaults setBool: [updateWithFinkButton state] forKey: FinkUpdateWithFink];
	[defaults setBool: [alwaysChooseDefaultsButton state] forKey: FinkAlwaysChooseDefaults];
	[defaults setBool: [scrollToSelectionButton state] forKey: FinkScrollToSelection];
	//give manually set path a chance to work on startup
	if (pathChoiceChanged){
		[defaults setBool: YES forKey: FinkBasePathFound];
	}

	if (finkConfChanged){
		[conf setUseUnstableMain: [useUnstableMainButton state]];
		[conf setUseUnstableCrypto: [useUnstableCryptoButton state]];
		[conf setVerboseOutput: [verboseOutputButton state]];
		[conf setPassiveFTP: [passiveFTPButton state]];

		[self setHTTPProxyVariable];
		[self setFTPProxyVariable];

		[conf writeToFile];
	}
	
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


//---------------------------------------------------------------------->Delegate Methods
-(void)controlTextDidChange:(NSNotification *)aNotification
{
	int textFieldID = [[aNotification object] tag];
	
	if (textFieldID == 0){ //basePathTextField
		//automatically select alternate path radio button if user starts to type in 
		//path choice text field
		[pathChoiceMatrix selectCellWithTag: 1];
	}else if (textFieldID == 1){
		//automatically select http_proxy button if 
		[httpProxyButton setState: 
			([[httpProxyTextField stringValue] length] > 0 ? YES : NO)];	
	}
}


@end
