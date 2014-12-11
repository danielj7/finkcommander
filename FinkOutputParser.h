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
 FinkOutputParser also reads and stores the process group id for a command for possible
 later use in terminating the command.

 Copyright (C) 2002, 2003  Steven J. Burr

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

/* 	Constants used to signal FinkController that the output requires a GUI event */
enum {
    //Used for signals, to track phases, as indices in increments array
    NONE,
    FETCH,
    UNPACK,
    CONFIGURE,
    COMPILE,
    BUILD,
    ACTIVATE,
	//Used only as signals
    PGID,
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
    RESOURCE_DIR_ERROR,
    SELF_REPAIR_FAILED,
	DYNAMIC_OUTPUT
};
 

@interface FinkOutputParser: NSObject
{
    NSUserDefaults *defaults;

    NSMutableDictionary *ptracker;
    NSMutableArray *packageList;
    NSMutableArray *increments;
    NSString *command;
    NSString *currentPackage;

    regex_t configure;
    regex_t prompt;
    regex_t manPrompt;
	regex_t dynamicOutput;

    float increment;
    int currentPhase;
    int pgid;
    BOOL installing;
    BOOL readingPackageList;
    BOOL selfRepair;
}

-(instancetype)initForCommand:(NSString *)cmd
	executable:(NSString *)exe NS_DESIGNATED_INITIALIZER;

-(float)increment;

-(int)pgid;

-(NSString *)currentPackage;

-(int)parseOutput:(NSString *)output;

@end
