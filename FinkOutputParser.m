//
//  FinkOutputParser.m
//  FinkCommander
//
//  Created by Steven Burr on Thu Jul 04 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "FinkOutputParser.h"


@implementation FinkOutputParser

-(id)initForCommand:(NSString *)cmd
{
    if (self = [super init]){
		command = [cmd retain];
        defaults = [NSUserDefaults standardUserDefaults];
		passwordErrorHasOccurred = NO;
    }
    return self;
}


-(void)dealloc
{
    [command release];
}


-(int)parseLineOfOutput:(NSString *)line
{
    if ((ISPROMPT(line)) && ! [defaults boolForKey:FinkAlwaysChooseDefaults]){
		return FC_PROMPT_SIGNAL;
    }else if ((ISMANDATORY_PROMPT(line))){
		return FC_PROMPT_SIGNAL;
    }else if ([line contains: @"Sorry, try again."]){
		passwordErrorHasOccurred = YES;
		return FC_PASSWORD_ERROR_SIGNAL;
    }else if ([line contains: @"Password:"] && ! passwordErrorHasOccurred){
		return FC_PASSWORD_PROMPT_SIGNAL;
    }else{
		return FC_NO_SIGNAL;
    }
}


-(int)parseOutput:(NSString *)output
{
    NSEnumerator *e = [[output componentsSeparatedByString: @"\n"] objectEnumerator];
    NSString *line;
    int signal;

    while (line = [e nextObject]){
		if (signal = [self parseLineOfOutput:line]) return signal;
    }
    return signal;
}

@end
