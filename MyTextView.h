/* MyTextView.h */

/*
 * Copyright (c) 2002 Hoshi Takanori
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */

#import <Cocoa/Cocoa.h>

@interface MyTextView : NSTextView
+ (id) myTextViewToReplace: (NSTextView *) textView
	in: (NSScrollView *) scrollView;
+ (NSCursor *) handCursor;
- (NSRange) visibleRangeInBounds: (NSRect) bounds;
- (NSRect) rectOfRange: (NSRange) range;
- (void) updateAnchoredRectsInBounds: (NSRect) bounds;
- (void) resetCursorRects;
@end
