/*
File: FinkTextViewController.h

 FinkTextViewController's sole raison d'etre is
 to implement a limited scrollback buffer for the fink command output
 text displayed by FinkCommander.  A subclass rather than a category
 was used in order to track the number of calls to the appendString
 method with an instance variable.

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
 
#import <Cocoa/Cocoa.h>
#import "FinkGlobals.h"

@interface FinkTextViewController : NSObject <NSTextViewDelegate>
{
	NSInteger lines;
	NSInteger bufferLimit;
	NSInteger minDelete;
}

-(instancetype)initWithView:(NSTextView *)aTextView
	   forScrollView:(NSScrollView *)aScrollView NS_DESIGNATED_INITIALIZER;
-(void)setLimits;
-(void)appendString:(NSString *)s;
-(void)replaceLastLineByString:(NSString *)s;

@property (nonatomic, strong) NSTextView *textView;
@property (nonatomic, strong) NSScrollView *scrollView;


@end
