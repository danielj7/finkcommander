//
//  FinkOutputParser.h
//  FinkCommander
//
//  Created by Steven Burr on Thu Jul 04 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FinkGlobals.h"

#define ISPROMPT(x) ([(x) contains: @"proceed? ["] 	|| \
					 [(x) contains: @"one: ["] 		|| \
					 [(x) containsCI: @"[y/n]"] 	|| \
					 [(x) contains: @"[anonymous]"] 	|| \
					 [(x) contains: [NSString stringWithFormat: @"[%@]", NSUserName()]])

#define ISMANDATORY_PROMPT(x)	([(x) contains: @"cvs.sourceforge.net's password:"] || \
								 [(x) contains: @"return to continue"])

enum {
	FC_NO_SIGNAL,
	FC_PROMPT_SIGNAL,
	FC_PASSWORD_ERROR_SIGNAL,
	FC_PASSWORD_PROMPT_SIGNAL
};


@interface FinkOutputParser: NSObject
{
    NSUserDefaults *defaults;
    NSString *command;
    BOOL passwordErrorHasOccurred;
}

-(id)initForCommand:(NSString *)cmd;
-(int)parseOutput:(NSString *)line;

@end
