//
//  FinkPreferences.m
//  FinkCommander
//
//  Created by Steven Burr on Sun Mar 17 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "FinkPreferences.h"

NSString *FinkBasePath = @"FinkBasePath";
NSString *FinkBasePathFound = @"FinkBasePathFound";
NSString *FinkUpdateWithFink = @"FinkUpdateWithFink";
NSString *FinkScrollToSelectedRow = @"FinkScrollToSelectedRow";

@implementation FinkPreferences

-(id)init
{
	self = [super initWithWindowNibName: @"Preferences"];
	return self;
}

-(void)windowDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *basePath;
	
	basePath = [defaults objectForKey: FinkBasePath];

#ifdef DEBUG
	NSLog(@"FinkBasePath = %@", basePath);
#endif
	if ([basePath isEqualToString: @"/sw"]){
		[pathChoiceMatrix selectCellWithTag: 0];
		[basePathTextField setStringValue: @" "];
	}else{
		[pathChoiceMatrix selectCellWithTag: 1];
		[basePathTextField setStringValue: basePath];
	}

	[updateWithFinkButton setState: [defaults boolForKey: FinkUpdateWithFink]];
	[scrollToSelectionButton setState: [defaults boolForKey: FinkScrollToSelectedRow]];
}

-(IBAction)setPreferences:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	

	if ([[pathChoiceMatrix selectedCell] tag] == 0){
		[defaults setObject: @"/sw" forKey: FinkBasePath];
	}else{
		[defaults setObject: [basePathTextField stringValue] forKey: FinkBasePath];
	}
	
	[defaults setBool: [updateWithFinkButton state] forKey: FinkUpdateWithFink];
	[defaults setBool: [scrollToSelectionButton state] forKey: FinkScrollToSelectedRow];
}

-(IBAction)cancel:(id)sender
{
	[self close];
}

@end
