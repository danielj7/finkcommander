/* 
File: SBString.h

 Category extending NSString class with a number of useful methods.
 Includes wrappers for fnmatch.h and regex.h functions.
 
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
#include <regex.h>
#include <string.h>

@interface NSString ( SBString )

//Does the string contain s? (CI stands for case insensitive)
-(BOOL)contains:(NSString *)s;
-(BOOL)containsCI:(NSString *)s;

//Does the string contain the shell pattern p?
-(BOOL)containsPattern:(NSString *)p;

//Search for regular expression pat in string
-(BOOL)containsExpression:(NSString *)pat;
-(NSRange)rangeOfExpression:(NSString *)pat;
-(NSRange)rangeOfExpression:(NSString *)pat
		inRange:(NSRange)range;
		
//Search for compiled regular expression in string;
//preferable to previous methods for repeated use of
//the same expression (I think).
-(NSRange)rangeOfCompiledExpression:(regex_t *)re;
-(NSRange)rangeOfCompiledExpression:(regex_t *)re
		inRange:(NSRange)range;

//Strip leading and trailing whitespace from string
-(NSString *)strip;

//Return a URL with properly escaped characters from an ordinary string
-(NSURL *)URLByAddingPercentEscapesToString;

@end

//Convenience function for use with rangeOfCompiledExpression methods.
//Must call regfree(&expr) sometime after use.
int compiledExpressionFromString(NSString *string, regex_t *expr);



