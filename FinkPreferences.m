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
	NSString *proxy = [defaults objectForKey: FinkHTTPProxyVariable];
	
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
	[httpProxyButton setState: ([proxy length] > 0 ? YES : NO)];
	[httpProxyTextField setStringValue: [defaults objectForKey: FinkHTTPProxyVariable]];
	
	//Table Preferences
	[updateWithFinkButton setState: [defaults boolForKey: FinkUpdateWithFink]];
	[scrollToSelectionButton setState: [defaults boolForKey: FinkScrollToSelection]];
	
	//Fink Preferences
	[useUnstableMainButton setState: [conf useUnstableMain]];
	[useUnstableCryptoButton setState: [conf useUnstableCrypto]];
	[verboseOutputButton setState: [conf verboseOutput]];
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
		[defaults setObject: [httpProxyTextField stringValue] forKey: FinkHTTPProxyVariable];
	}else
		[defaults setObject: @"" forKey: FinkHTTPProxyVariable];
}

//---------------------------------------------------------------------->Actions


-(IBAction)setPreferences:(id)sender
{
	[self setBasePath];
	[self setHTTPProxyVariable];
	
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
//automatically select alternate path radio button if user starts to type in 
//path choice text field
-(void)controlTextDidChange:(NSNotification *)aNotification
{
	[pathChoiceMatrix selectCellWithTag: 1];
}


@end
