//
//  FinkPreferences.h
//  FinkCommander
//
//  Created by Steven Burr on Sun Mar 17 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

extern NSString *FinkBasePath;
extern NSString *FinkBasePathFound;

@interface FinkPreferences : NSWindowController 
{
	IBOutlet NSMatrix *pathChoiceMatrix;
	IBOutlet NSTextField *basePathTextField;
	
}

-(IBAction)setPreferences:(id)sender;
-(IBAction)cancel:(id)sender;

@end
