
#import "SBDateColumnController.h"

//Used IB to determine approximate pixel width needed for each format

#define Y2_WIDTH         NSLocalizedStringFromTable(@"80.0", @"Date", \
                            @"Pixel width for numeric format with two-digit year")
#define NUMERIC_Y2       NSLocalizedStringFromTable(@"%m/%d/%y", @"Date", \
                            @"Numeric format with two-digit year")

#define Y4_WIDTH         NSLocalizedStringFromTable(@"95.0", @"Date", \
                            @"Pixel width for numeric format with four-digit year")
#define NUMERIC_Y4       NSLocalizedStringFromTable(@"%m/%d/%Y", @"Date", \
                            @"Numeric format with four-digit year")

#define AB_WIDTH         NSLocalizedStringFromTable(@"125.0", @"Date", \
                            @"Pixel width for month-abbreviated format")
#define M_ABBREV         NSLocalizedStringFromTable(@"%b %e, %Y", @"Date", \
                            @"Abbreviated month, day, year")

#define FULL_WIDTH       NSLocalizedStringFromTable(@"145.0", @"Date", \
                            @"Pixel width for full format")
#define M_FULL           NSLocalizedStringFromTable(@"%B %e, %Y", @"Date", \
                            @"Full month, day, year")

#define YT2_WIDTH        NSLocalizedStringFromTable(@"160.0", @"Date", \
                            @"Pixel width for numeric format with time")
#define NUMERIC_Y2_TIME  NSLocalizedStringFromTable(@"%m/%d/%y  %I:%M %p", \
                            @"Date", @"Numeric format with two-digit year plus time")

#define ABT_WIDTH        NSLocalizedStringFromTable(@"190.0", @"Date", \
                            @"Pixel width for numeric format with two-digit year")
#define M_ABBREV_TIME    NSLocalizedStringFromTable(@"%b %e, %Y  %I:%M %p", @"Date", \
                            @"Abbreviated month, day, year plus time")

#define M_FULL_TIME      NSLocalizedStringFromTable(@"%B %e, %Y  %I:%M %p", @"Date", \
                            @"Full month, day, year plus time")

@implementation SBDateColumnController

//----------------------------------------------------------
#pragma mark CREATION AND DESTRUCTION
//----------------------------------------------------------

-(id)initWithColumn:(NSTableColumn *)myColumn
{
    return [self initWithColumn:myColumn 
	       shortTitle:@"Date"];
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
    if (nil != (self = [super init])){
		[self setColumn:myColumn];
		[self setShortTitle:stitle];
		[self setLongTitle:ltitle];
		
		Dprintf(@"SBDCC initialized for column %@", [[self column] identifier]);

		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(adjustColumnAndHeaderDisplay:)
			name:NSOutlineViewColumnDidResizeNotification
			object:nil];

#ifdef UNDEF
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(adjustColumnAndHeaderDisplay:)
			name:NSTableViewColumnDidResizeNotification
			object:nil];
#endif
		
		[self adjustColumnAndHeaderDisplay:nil];
    }
    return self;
}

-(void)dealloc
{
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
    if (width <= [Y2_WIDTH floatValue])   return NUMERIC_Y2;
    if (width <= [Y4_WIDTH floatValue])   return NUMERIC_Y4;
    if (width <= [AB_WIDTH floatValue])   return M_ABBREV;
    if (width <= [FULL_WIDTH floatValue]) return M_FULL;
    if (width <= [YT2_WIDTH floatValue])  return NUMERIC_Y2_TIME;
    if (width <= [ABT_WIDTH floatValue])  return M_ABBREV_TIME;
    return M_FULL_TIME;
}

-(void)adjustColumnDisplay
{
    float width = [[self column] width];
	
	Dprintf(@"Adjusting column %@ width %f", [[self column] identifier], width);
    NSCell *dateCell = [[NSCell alloc] initTextCell:@""];
    NSString *format = [self formatForWidth:width];
    NSDateFormatter *dateFormat= [[NSDateFormatter alloc]
		initWithDateFormat:format
		allowNaturalLanguage:YES];

    [dateCell setFormatter:dateFormat];
    [dateFormat release];
    [[self column] setDataCell:dateCell];
    [dateCell release];
}

-(void)adjustHeaderDisplay
{
    if (nil != [self longTitle]){
		float width = [[self column] width];

		if (width < [[self longTitle] length] * 6.0){  //approximate pixels per character
			[[[self column] headerCell] setStringValue:[self shortTitle]];
		}else{
			[[[self column] headerCell] setStringValue:[self longTitle]];
		}
    }
}

-(void)adjustColumnAndHeaderDisplay:(NSNotification *)n
{
    [self adjustColumnDisplay];
    [self adjustHeaderDisplay];
    [[[self column] tableView] reloadData];
}

@end
