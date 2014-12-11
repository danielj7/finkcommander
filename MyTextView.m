/* MyTextView.m */
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

#import "MyTextView.h"

#define HAND_IMAGE @"hand.tiff"

#define HAND_HOTSPOT_X 6
#define HAND_HOTSPOT_Y 0

@implementation MyTextView


/*
 * Initialization.
 */

+ (instancetype) myTextViewToReplace: (NSTextView *) textView
	in: (NSScrollView *) scrollView
{
    MyTextView *myTextView =
	    [[MyTextView alloc] initWithFrame: [textView frame]];

    [myTextView setAlignment: [textView alignment]];
    [myTextView setAllowsUndo: [textView allowsUndo]];
    [myTextView setAutoresizingMask: [textView autoresizingMask]];
    [myTextView setBackgroundColor: [textView backgroundColor]];
    [myTextView setDelegate: [textView delegate]];
    [myTextView setDrawsBackground: [textView drawsBackground]];
    [myTextView setEditable: [textView isEditable]];
    [myTextView setImportsGraphics: [textView importsGraphics]];
    [myTextView setRichText: [textView isRichText]];
    [myTextView setSelectable: [textView isSelectable]];
    [myTextView setTextColor: [textView textColor]];
    [myTextView setToolTip: [textView toolTip]];
	//[myTextView setFont:[textView font]];

    [scrollView setDocumentView: myTextView];

    return myTextView;
}

/*
 * Change cursor to `hand' when the mouse points to a link.
 */

static NSCursor *handCursor = nil;

+ (NSCursor *) handCursor
{
    NSImage *image;

    if (handCursor == nil) {
	image = [NSImage imageNamed: HAND_IMAGE];
		if (image != nil) {
			handCursor = [[NSCursor alloc] initWithImage: image
				hotSpot: NSMakePoint(HAND_HOTSPOT_X, HAND_HOTSPOT_Y)];
		} else {
			handCursor = [NSCursor arrowCursor];
		}
    }

    return handCursor;
}

- (NSRange) visibleRangeInBounds: (NSRect) bounds
{
    NSLayoutManager *layoutManager = [self layoutManager];
    NSTextContainer *textContainer = [self textContainer];
    NSRange glyphRange;

    if (layoutManager == nil || textContainer == nil) {
		return NSMakeRange(0, 0);
    }

    glyphRange = [layoutManager glyphRangeForBoundingRect: bounds
	    inTextContainer: textContainer];
    return [layoutManager characterRangeForGlyphRange: glyphRange
	    actualGlyphRange: (NSRange *) NULL];
}

- (NSRect) rectOfRange: (NSRange) range
{
    if (range.length > 0) {
	return [[self layoutManager] boundingRectForGlyphRange: range
		inTextContainer: [self textContainer]];
    } else {
		return NSMakeRect(0, 0, 0, 0);
    }
}

- (void) updateAnchoredRectsInBounds: (NSRect) bounds
{
    NSRange range = [self visibleRangeInBounds: bounds];
    int i;
    NSString *link;
    NSRange linkRange;

    for (i = range.location; i < NSMaxRange(range); i = NSMaxRange(linkRange)) {
		link = [[self textStorage] attribute: NSLinkAttributeName
			atIndex: i longestEffectiveRange: &linkRange inRange: range];
		if (link != nil) {
			[self addCursorRect: [self rectOfRange: linkRange]
				cursor: [[self class] handCursor]];
		}
    }
}

- (void) resetCursorRects
{
    [self updateAnchoredRectsInBounds: [self visibleRect]];
}

/*
 * Pop-up menu.
 */

- (NSMenu *) menuForEvent: (NSEvent *) event
{
    return [self menu];
}


@end
