/* 
File: SBString.h

 Category extending NSString class with following method(s):

 contains:s -- test whether string contains string s
 containsPattern:p -- test whether string contains shell-style pattern p

   Note:  The same methods are supplied in case insensitive versions,
   denoted with a "CI" at the end of the method name.  Parameters
   are all NSStrings.

 strip -- strip leading and trailing whitespace from a string

 Copyright (C) 2002  Steven J. Burr

 This program is free software; you may redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

*/

#import <Foundation/Foundation.h>
#include <fnmatch.h>

@interface NSString ( SBString )

//Run the test indicated by the function name
//CI stands for case insensitive
-(BOOL)contains:(NSString *)s;
-(BOOL)containsCI:(NSString *)s;
-(BOOL)containsPattern:(NSString *)p;

//Strip leading and trailing whitespace from a string
-(NSString *)strip;

@end
