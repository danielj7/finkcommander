/*
File: FinkPreferences.m

 See the header file, FinkPreferences.h, for interface and license information.

 */
#import "FinkPreferences.h"

NSString *FinkBasePath = @"FinkBasePath";
NSString *FinkBasePathFound = @"FinkBasePathFound";
NSString *FinkUpdateWithFink = @"FinkUpdateWithFink";
NSString *FinkScrollToSelectedRow = @"FinkScrollToSelectedRow";
NSString *FinkAlwaysChooseDefaults = @"FinkAlwaysChooseDefaults";

@implementation FinkPreferences

//--------------------------------------------------------------->Startup and Shutdown

-(id)init
{
	self = [super initWithWindowNibName: @"Preferences"];
	defaults = [NSUserDefaults standardUserDefaults];
	return self;
}

//helper to set or reset state of preference widgets
-(void)resetPreferences
{
	NSString *basePath;
	
	basePath = [defaults objectForKey: FinkBasePath];
	if ([basePath isEqualToString: @"/sw"]){
		[pathChoiceMatrix selectCellWithTag: 0];
		[basePathTextField setStringValue: @""];
	}else{
		[pathChoiceMatrix selectCellWithTag: 1];
		[basePathTextField setStringValue: basePath];
	}

	[updateWithFinkButton setState: [defaults boolForKey: FinkUpdateWithFink]];
	[scrollToSelectionButton setState: [defaults boolForKey: FinkScrollToSelectedRow]];
	[alwaysChooseDefaultsButton setState: [defaults boolForKey: FinkAlwaysChooseDefaults]];
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

//---------------------------------------------------------------------->Actions


-(IBAction)setPreferences:(id)sender
{
	[self setBasePath];
	
	[defaults setBool: [updateWithFinkButton state] forKey: FinkUpdateWithFink];
	[defaults setBool: [scrollToSelectionButton state] forKey: FinkScrollToSelectedRow];
	[defaults setBool: [alwaysChooseDefaultsButton state] forKey: FinkAlwaysChooseDefaults];
	
	[self close];
}

-(IBAction)cancel:(id)sender
{
	[self resetPreferences];
	[self close];
}

@end
