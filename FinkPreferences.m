/*
File: FinkPreferences.m

 See the header file, FinkPreferences.h, for interface and license information.

 */
#import "FinkPreferences.h"

//Global variables used throughout FinkCommander source code to set 
//user defaults.
NSString *FinkBasePath = @"FinkBasePath";
NSString *FinkBasePathFound = @"FinkBasePathFound";
NSString *FinkUpdateWithFink = @"FinkUpdateWithFink";
NSString *FinkAlwaysChooseDefaults = @"FinkAlwaysChooseDefaults";
NSString *FinkScrollToSelection = @"FinkScrollToSelection";
NSString *FinkSelectedColumnIdentifier = @"FinkSelectedColumnIdentifier";
NSString *FinkSelectedPopupMenuTitle = @"FinkSelectedPopupMenuTitle";
NSString *FinkHTTPProxyVariable = @"FinkHTTPProxyVariable";
NSString *FinkLookedForProxy = @"FinkLookedForProxy";

//Global variables used in toolbar methods
//(Should these be moved to FinkController?)
NSString *FinkInstallSourceItem = @"FinkInstallSourceItem";
NSString *FinkInstallBinaryItem = @"FinkInstallBinaryItem";
NSString *FinkRemoveSourceItem = @"FinkRemoveSourceItem";
NSString *FinkRemoveBinaryItem = @"FinkRemoveBinaryItem";
NSString *FinkTerminateCommandItem = @"FinkTerminateCommandItem";
NSString *FinkFilterItem = @"FinkFilterItem";

@implementation FinkPreferences

//--------------------------------------------------------------->Startup and Shutdown

-(id)init
{
	self = [super initWithWindowNibName: @"Preferences"];
	defaults = [NSUserDefaults standardUserDefaults];
	[self setWindowFrameAutosaveName: @"Preferences"];

	return self;
}

//helper to set or reset state of preference widgets
//used on startup by windowDidLoad: method and when "Cancel" button clicked
-(void)resetPreferences
{
	NSString *basePath;
	NSString *proxy = [defaults objectForKey: FinkHTTPProxyVariable];
	
	basePath = [defaults objectForKey: FinkBasePath];
	if ([basePath isEqualToString: @"/sw"]){
		[pathChoiceMatrix selectCellWithTag: 0];
		[basePathTextField setStringValue: @""];
	}else{
		[pathChoiceMatrix selectCellWithTag: 1];
		[basePathTextField setStringValue: basePath];
	}

	[updateWithFinkButton setState: [defaults boolForKey: FinkUpdateWithFink]];
	[alwaysChooseDefaultsButton setState: [defaults boolForKey: FinkAlwaysChooseDefaults]];
	[scrollToSelectionButton setState: [defaults boolForKey: FinkScrollToSelection]];
	if ([proxy length] > 0){
		[httpProxyButton setState: YES];
	}else{
		[httpProxyButton setState: NO];
	}
	[httpProxyTextField setStringValue: [defaults objectForKey: FinkHTTPProxyVariable]];
	pathChoiceChanged = NO;
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

//---------------------------------------------------------------------->Delegate Methods
//automatically select alternate path radio button if user starts to type in 
//path choice text field
-(void)controlTextDidChange:(NSNotification *)aNotification
{
	[pathChoiceMatrix selectCellWithTag: 1];
}


@end
