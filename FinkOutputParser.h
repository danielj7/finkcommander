/*
File: FinkOutputParser.h

 FinkCommander

 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.

 The FinkOutputParser class parses the output from a fink or apt-get command
 and returns signals to FinkController indicating whether interaction with the user
 or GUI changes are necessary.  In some cases FinkController will send messages back
 asking for additional information, such as the name of the package currently
 being handled by Fink or the amount of increment to add to the progress indicator.

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
#import "FinkUtilities.h"
#import "FinkGlobals.h"

//Increment added to progress indicator at start

#define STARTING_INCREMENT 5.0

//Commands for which determinate PI is displayed

#define IS_INSTALL_CMD(x) 	([(x) contains:@"install"]		|| \
							 [(x) contains:@"build"]		|| \
							 [(x) contains:@"update-all"]	|| \
							 [(x) contains:@"selfupdate"])

//Line parsing macros

#define INSTALLTRIGGER(x)	([(x) containsPattern:@"*following *package* will be *installed*"] || \
							 [(x) contains:@"will be rebuilt"])

#define FETCHTRIGGER(x) 	([(x) hasPrefix: @"wget -"]  					|| \
							 [(x) hasPrefix: @"curl -"]  					|| \
							 [(x) hasPrefix: @"axel -"])

#define UNPACKTRIGGER(x) 	(([(x) containsPattern:@"mkdir -p */src/*"]    	&& \
							  ![(x) contains:@"root"])								|| \
							 [(x) containsPattern:@"*/bin/tar -*"]			|| \
							 [(x) containsPattern:@"*/bin/bzip2 -*"])

#define CONFIGURETRIGGER(x)	([(x) hasPrefix:@"./configure"] 				|| \
							 [(x) hasPrefix:@"checking for"]				|| \
							 [(x) hasPrefix:@"patching file"])

#define COMPILETRIGGER(x)	(([(x) hasPrefix: @"make"]						&& \
							  ![(x) contains:@"makefile"])							|| \
							 [(x) hasPrefix: @"Compiling"]					|| \
							 [(x) containsPattern: @"g77 [- ]*"]			|| \
							 [(x) containsPattern: @"g[c+][c+] -[!E]*"]		|| \
							 [(x) containsPattern: @"cc -[!E]*"]			|| \
							 [(x) containsPattern: @"c++ -[!E]*"])

#define ISPROMPT(x) 		([(x) containsPattern: @"*proceed? \[*"]				|| \
							 [(x) contains: @"Make your choice:"]					|| \
							 [(x) contains: @"Pick one:"]							|| \
							 [(x) containsCI: @"[y/n]"] 							|| \
							 [(x) contains: @"[anonymous]"] 						|| \
							 [(x) contains: [NSString stringWithFormat: @"[%@]", NSUserName()]])

	//fink's --yes option does not work for these prompts:
#define ISMANDATORY_PROMPT(x)	([(x) contains: @"cvs.sourceforge.net's password:"] || 	\
								 [(x) contains: @"return to continue"] 				||	\
								 [(x) contains: @"CVS password:"])

enum {
    //used for signals, to track phases, as indices in increments array
    NONE,
    FETCH,
    UNPACK,
    CONFIGURE,
    COMPILE,
    BUILD,
    ACTIVATE,
	//used only as signals
    START_INSTALL,
    PASSWORD_PROMPT,
    PROMPT,
	MANDATORY_PROMPT,
	PROMPT_AND_START,
	START_AND_FETCH,
	START_AND_UNPACK,
	START_AND_ACTIVATE,
	RUNNING_SELF_REPAIR,
	SELF_REPAIR_COMPLETE,
	RESOURCE_DIR,
	SELF_REPAIR_FAILED
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
	BOOL installing;
    BOOL readingPackageList;
	BOOL self_repair;
}

-(id)initForCommand:(NSString *)cmd
	executable:(NSString *)exe;

-(float)increment;

-(NSString *)currentPackage;

-(void)setCurrentPackage:(NSString *)p;

-(int)parseOutput:(NSString *)output;

@end
