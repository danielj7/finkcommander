/*
 File SBDateColumnController.m

 See header file SBDateColumnController.h for license and interface information.

 */

#import "SBDateColumnController.h"

//----------------------------------------------------------
#pragma mark FORMAT MACROS
//----------------------------------------------------------

/* 	Definitions of date formats and the minimum widths that will accomodate
	the formats. These macros are used in the formatForWidth: method to determine
	the longest possible date format that will fit in the current column length. */

#define FULL_MONTH_WITH_DAY_AND_TIME_WIDTH [NSLocalizedStringFromTable(@"240.0", @"Date", @"Minimum width for full month name, day, year, time") floatValue]
#define FULL_MONTH_WITH_DAY_AND_TIME_FORMAT NSLocalizedStringFromTable(@"%A, %B %e, %Y, %I:%M %p", @"Date",  @"Full month name, day, year, time")

#define ABBREVIATED_WITH_DAY_AND_TIME_WIDTH [NSLocalizedStringFromTable(@"170.0", @"Date",  @"Minimum width for abbreviated day and month names, day, year, time") floatValue]
#define ABBREVIATED_WITH_DAY_AND_TIME_FORMAT NSLocalizedStringFromTable(@"%a, %b %e, %Y, %I:%M %p", @"Date", @"Abbreviated day and month names, day, year, time")

#define NUMERIC_Y4_WITH_TIME_WIDTH [NSLocalizedStringFromTable(@"145.0", @"Date", @"Minimum width for numeric format with two-digit year plus time") floatValue]
#define NUMERIC_Y4_WITH_TIME_FORMAT NSLocalizedStringFromTable(@"%m/%d/%Y, %I:%M %p", @"Date", @"Numeric format with two-digit year plus time")

#define NUMERIC_Y2_WITH_TIME_WIDTH [NSLocalizedStringFromTable(@"130.0", @"Date", @"Minimum width for numeric format with two-digit year plus time") floatValue]
#define NUMERIC_Y2_WITH_TIME_FORMAT NSLocalizedStringFromTable(@"%m/%d/%y, %I:%M %p", @"Date", @"Numeric format with two-digit year plus time")

#define NUMERIC_Y4_WIDTH [NSLocalizedStringFromTable(@"80.0", @"Date", @"Minimum width for numeric format with four-digit year") floatValue]
#define NUMERIC_Y4_FORMAT NSLocalizedStringFromTable(@"%m/%d/%Y", @"Date", @"Numeric format with four-digit year")

#define NUMERIC_Y2_FORMAT NSLocalizedStringFromTable(@"%m/%d/%y", @"Date", @"Numeric format with two-digit year")


@implementation SBDateColumnController

//----------------------------------------------------------
#pragma mark CREATION AND DESTRUCTION
//----------------------------------------------------------

-(id)init
{
    return [self initWithColumn:nil];
}

-(id)initWithColumn:(NSTableColumn *)myColumn
{
    return [self initWithColumn:myColumn 
						shortTitle:
							NSLocalizedStringFromTable(@"Date", @"Date",
								@"Default column title")];
}

-(id)initWithColumn:(NSTableColumn *)myColumn
		 shortTitle:(NSString *)stitle
{
    return [self initWithColumn:myColumn 
						shortTitle:stitle 
						 longTitle:nil];
}

-(id)initWithColumn:(NSTableColumn *)myColumn
		 shortTitle:(NSString *)stitle 
		  longTitle:(NSString *)ltitle
{
    self = [super init];
    if (nil != self){
		[self setColumn:myColumn];
		[self setShortTitle:stitle];
		[self setLongTitle:ltitle];

		if ([[[self column] tableView] isKindOfClass:[NSOutlineView class]]){
			[[NSNotificationCenter defaultCenter]
				addObserver:self
				selector:@selector(adjustColumnAndHeaderDisplay:)
				name:NSOutlineViewColumnDidResizeNotification
				object:nil];
		}else{
			[[NSNotificationCenter defaultCenter]
				addObserver:self
				selector:@selector(adjustColumnAndHeaderDisplay:)
				name:NSTableViewColumnDidResizeNotification
				object:nil];
		}

		if (nil != [self column]){
			[self adjustColumnAndHeaderDisplay:nil];
		}
    }
    return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [_sbColumn release];
    [_sbShortTitle release];
    [_sbLongTitle release];

    [super dealloc];
}

//----------------------------------------------------------
#pragma mark ACCESSORS
//----------------------------------------------------------

-(NSTableColumn *)column { return _sbColumn; }

-(void)setColumn:(NSTableColumn *)newColumn
{
    [newColumn retain];
    [_sbColumn release];
    _sbColumn = newColumn;
}

-(NSString *)shortTitle { return _sbShortTitle; }

-(void)setShortTitle:(NSString *)newShortTitle
{
    [newShortTitle retain];
    [_sbShortTitle release];
    _sbShortTitle = newShortTitle;
}

-(NSString *)longTitle { return _sbLongTitle; }

-(void)setLongTitle:(NSString *)newLongTitle
{
    [newLongTitle retain];
    [_sbLongTitle release];
    _sbLongTitle = newLongTitle;
}

//----------------------------------------------------------
#pragma mark DISPLAY ADJUSTMENT
//----------------------------------------------------------

-(NSString *)formatForWidth:(float)width
{
    if (width >= FULL_MONTH_WITH_DAY_AND_TIME_WIDTH)
		return FULL_MONTH_WITH_DAY_AND_TIME_FORMAT;
    if (width >= ABBREVIATED_WITH_DAY_AND_TIME_WIDTH)
		return ABBREVIATED_WITH_DAY_AND_TIME_FORMAT;
    if (width >= NUMERIC_Y4_WITH_TIME_WIDTH)
		return NUMERIC_Y4_WITH_TIME_FORMAT;
    if (width >= NUMERIC_Y2_WITH_TIME_WIDTH) 
		return NUMERIC_Y2_WITH_TIME_FORMAT;
    if (width >= NUMERIC_Y4_WIDTH) 
		return NUMERIC_Y4_FORMAT;
    return NUMERIC_Y2_FORMAT;
}

//Set appropriate format for new column width
-(void)adjustColumnDisplay
{
    float width = [[self column] width];

    NSString *format = [self formatForWidth:width];
    NSDateFormatter *dateFormatter= [[NSDateFormatter alloc]
					 initWithDateFormat:format
				allowNaturalLanguage:YES];

    [[[self column] dataCell] setFormatter:dateFormatter];
    [dateFormatter release];
}

//Use a more descriptive title if it will fit in the column
-(void)adjustHeaderDisplay
{
    if (nil != [self longTitle]){
		float width = [[self column] width];

		if (width < [[self longTitle] length] * 7.0){  
			//approximate width per character with system standard font
			[[[self column] headerCell] setStringValue:[self shortTitle]];
		}else{
			[[[self column] headerCell] setStringValue:[self longTitle]];
		}
    }
}

// Method invoked by columnDidResize notification
-(void)adjustColumnAndHeaderDisplay:(NSNotification *)n
{
    [self adjustColumnDisplay];
    [self adjustHeaderDisplay];
    [[[self column] tableView] reloadData];
}

@end
