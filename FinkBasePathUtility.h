//
//  FinkBasePathUtility.h
//  FinkCommander
//
//  Created by Steven Burr on Wed Mar 20 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FinkPreferences.h"

@interface FinkBasePathUtility : NSObject {

}

-(void)findFinkBasePath;
-(void)fixScript;

@end
