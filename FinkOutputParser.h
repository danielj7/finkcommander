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

//Increment added to progress indicator at start
#define STARTING_INCREMENT 5.0

//Line parsing macros

#define FETCHSTARTED(x) ([(x) hasPrefix: @"wget"]  		|| \
						 [(x) hasPrefix: @"curl"]  		|| \
						 [(x) hasPrefix: @"axel"])

#define UNPACKSTARTED(x) ([(x) hasPrefix:@"tar"]    	|| \
						  [(x) hasPrefix:@"bzip"]    	|| \
						  [(x) contains:@"/tar "]    	|| \
						  [(x) contains:@"/bzip2 "])

#define CONFIGURESTARTED(x)	([[(x) strip] hasPrefix:@"./configure"] 	|| \
							 [[(x) strip] hasPrefix:@"patch"])

#define COMPILESTARTED(x)	([[(x) strip] hasPrefix: @"make"] 				|| \
							 [[(x) strip] containsPattern: @"gcc -[!E]?*"]	|| \
							 [[(x) strip] hasPrefix: @"building"])

#define ISPROMPT(x) ([(x) contains: @"you want to proceed?"]	|| \
					 [(x) contains: @"Make your choice:"]		|| \
					 [(x) contains: @"Pick one:"]				|| \
					 [(x) containsCI: @"[y/n]"] 				|| \
					 [(x) contains: @"[anonymous]"] 			|| \
					 [(x) contains: [NSString stringWithFormat: @"[%@]", NSUserName()]])

//fink's --yes option does not work for these prompts:
#define ISMANDATORY_PROMPT(x)	([(x) contains: @"cvs.sourceforge.net's password:"] || 	\
								 [(x) contains: @"return to continue"] 				||	\
								 [(x) contains: @"CVS password:"])

enum {
    //used for signals, to track phases, as indices in increments array
    NONE = 0,
    FETCH = 1,
    UNPACK = 2,
    CONFIGURE = 3,
    COMPILE = 4,
    BUILD = 5,
    ACTIVATE = 6,
    //used only as signals
    START_INSTALL = 7,
    PASSWORD_PROMPT = 8,
    PASSWORD_ERROR = 9,
    PROMPT = 10,
	PROMPT_AND_START = 11
};
 

@interface FinkOutputParser: NSObject
{
    NSUserDefaults *defaults;

	NSMutableDictionary *ptracker;
    NSMutableArray *packageList;
	NSMutableArray *increments;
	NSString *command;
    NSString *currentPackage;

    float increment;
    int currentPhase;
	BOOL determinate;
    BOOL passwordErrorHasOccurred;
    BOOL readingPackageList;
    BOOL installStarted;
}

-(id)initForCommand:(NSString *)cmd;

-(float)increment;
-(NSString *)currentPackage;
-(void)setCurrentPackage:(NSString *)p;

-(int)parseOutput:(NSString *)output;

@end
