//
//  FinkPreferences.h
//  FinkCommander
//
//  Created by Steven Burr on Sun Mar 17 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

// eliminate for release version:
#define DEBUG 

extern NSString *FinkBasePath;
extern NSString *FinkBasePathFound;
extern NSString *FinkUpdateWithFink;

@interface FinkPreferences : NSWindowController 
{
	IBOutlet NSMatrix *pathChoiceMatrix;
	IBOutlet NSTextField *basePathTextField;
	IBOutlet NSButton *updateWithFinkButton;
}

-(IBAction)setPreferences:(id)sender;
-(IBAction)cancel:(id)sender;

@end
