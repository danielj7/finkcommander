//
//  FinkOutputParser.h
//  FinkCommander
//
/*
File: FinkOutputParser.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 The FinkOutputParser class parses the output from a fink or apt-get command
 and returns signals to FinkController indicating whether interaction with the user
 or GUI changes are necessary.

 Copyright (C) 2002  Steven J. Burr

 This program is free software; you may redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

 Contact the author at sburrious@users.sourceforge.net.

 */

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
