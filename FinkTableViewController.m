/*
File: FinkTableViewController.m

 See the header file, FinkTableViewController.h, for interface and license information.

*/

#import "FinkTableViewController.h"

@implementation FinkTableViewController

-(id)initWithFrame:(NSRect)rect
{
	defaults = [NSUserDefaults standardUserDefaults];

	if (self = [super initWithFrame: rect]){
		NSString *identifier;
		NSArray *columns = [defaults objectForKey: FinkTableColumnsArray];
		NSEnumerator *e = [columns objectEnumerator];

		while (identifier = [e nextObject]){
			[self addTableColumn: [self makeColumnWithName: identifier]];
		}

		//configure
		[self setAutosaveName: @"FinkTableView"];
		[self setAutosaveTableColumns: YES];
		[self setAllowsMultipleSelection: YES];
		[self setAllowsColumnSelection: NO];
	}
	return self;
}

//----------------------------------------------->Column Manipulation

-(NSTableColumn *)makeColumnWithName:(NSString *)identifier
{
	NSTableColumn *newColumn= [[[NSTableColumn alloc]
				initWithIdentifier:identifier] autorelease];
				
	[[newColumn headerCell] setStringValue: [identifier capitalizedString]];
	[[newColumn headerCell] setAlignment: NSLeftTextAlignment];
	[newColumn setEditable: NO];
	if ([identifier isEqualToString: @"binary"] || [identifier isEqualToString: @"unstable"]){
	 		NSTextFieldCell *cell = [[[NSTextFieldCell alloc] initTextCell: @""]
			autorelease]; //setDataCell: retains
		[cell setAlignment: NSCenterTextAlignment];
		[newColumn setDataCell: cell];
	}
	return newColumn;
}

//called by View menu action method
-(void)addColumnWithName:(NSString *)identifier
{
	NSArray *columnNames = [defaults objectForKey: FinkTableColumnsArray];
	NSTableColumn *newColumn = [self makeColumnWithName: identifier];
	NSTableColumn *lastColumn = [[self tableColumns] objectAtIndex: [self numberOfColumns] - 1];
	
	[lastColumn setWidth: [lastColumn width] * 0.5];
	[newColumn setWidth: [lastColumn width] * 0.5];
	[self addTableColumn: newColumn];		
	[self sizeLastColumnToFit];
	[lastColumn setWidth: [lastColumn width] + 10.0];  //adding new column leaves small gap
	
	columnNames = [columnNames arrayByAddingObject: identifier];
	[defaults setObject: columnNames forKey: FinkTableColumnsArray];
}

-(void)removeColumnWithName:(NSString *)identifier
{	
	NSArray *columns = [defaults objectForKey: FinkTableColumnsArray];
	NSMutableArray *reducedColumns = [columns mutableCopy];
	
	[self removeTableColumn: [self tableColumnWithIdentifier: identifier]];
	[self sizeLastColumnToFit];
	[reducedColumns removeObject: identifier];
	columns = reducedColumns;
	[defaults setObject: columns forKey: FinkTableColumnsArray];
}

//------------------------------------------------->Sorting Methods

//basic sorting method
-(void)sortTableAtColumn:(NSTableColumn *)aTableColumn inDirection:(NSString *)direction
{
	//FIX THIS: instead of referring back to FinkController; FC shd probb send FTVC
	//a message whenever the package array changes
	[[[self dataSource] displayedPackages] sortUsingSelector:
		NSSelectorFromString([NSString stringWithFormat: @"%@CompareBy%@:", direction,
			[[aTableColumn identifier] capitalizedString]])]; // e.g. reverseCompareByName:
	[self reloadData];
}


@end
