
#import "SBFileItemTree.h"

@implementation SBFileItemTree

//----------------------------------------------------------
#pragma mark CREATION AND DESTRUCTION
//----------------------------------------------------------

-(id)init
{
	return [self initWithWindowName:@"Untitled"];
}

-(id)initWithWindowName:(NSString *)name
{
	return [self initWithWindowName:name fileArray:nil];
}

//Designated initializer
-(id)initWithWindowName:(NSString *)name 
	 fileArray:(NSMutableArray *)flist
{
	self = [super initWithWindowNibName:@"TreeView"];
	if (nil != self){
		totalSize = 0;
		itemCount = 0;
		if (nil != flist && [flist count] > 0){
			[self setRootItem: [[SBFileItem alloc]
					initWithPath:[flist objectAtIndex:0]]];
			[self buildTreeFromFileList:flist];
		}
		[self _setSbname:name];		
		[[self window] setTitle:name];
		[[self window] setReleasedWhenClosed:YES];
		[[NSNotificationCenter defaultCenter] 
			addObserver:self 
			selector:@selector(applicationWillTerminate:)
			name:NSApplicationWillTerminateNotification
			object:nil];
	}
	return self;
}

-(void)awakeFromNib
{
	NSTableColumn *mdateColumn = [outlineView tableColumnWithIdentifier:@"mdate"];
	NSCell *dateCell = [[[NSCell alloc] initTextCell:@""] autorelease];
	NSDateFormatter *dateFormat = [[[NSDateFormatter alloc]
		initWithDateFormat:@"%b %2e, %Y"
		allowNaturalLanguage:YES] autorelease];
	
	[outlineView setTarget:self];
	[outlineView setDoubleAction:@selector(openSelectedFiles:)];
	[dateCell setFormatter:dateFormat];
	[mdateColumn setDataCell:dateCell];
}

-(BOOL)windowShouldClose:(id)sender
{
	NSLog(@"Close message sent to %@", [self window]);
	/*	The following is needed to release all items in a tree.  NSOutline
		apparently retains an item when its parent is expanded and doesn't
		release it until the parent is collapsed.  */
	if (nil != [self rootItem]) [self collapseItemAndChildren:[self rootItem]];
	return YES;
}

-(void)windowWillClose:(NSNotification *)n
{
	NSLog(@"Closing %@", [self window]);
	[[self rootItem] setChildren:nil];
}

-(void)applicationWillTerminate:(NSNotification *)n
{
	[[self window] performClose:self];
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_sbrootItem release];
	[_sbname release];
	NSLog(@"Deallocating %@", [self description]);
	[super dealloc];
}

//----------------------------------------------------------
#pragma mark UI METHODS
//----------------------------------------------------------

-(void)startedLoading
{
	[loadingIndicator setUsesThreadedAnimation:YES];
	[loadingIndicator startAnimation:self];
}

-(void)finishedLoading
{
	[loadingIndicator stopAnimation:self];
	[loadingIndicator removeFromSuperview];

	if (nil == [self rootItem]){
		[msgTextField setStringValue:@"Error:  No such package installed"];
	}else{
		[msgTextField setStringValue:
			[NSString stringWithFormat:@"Total size: %u KB; file count: %u",
				totalSize / 1024 + 1, itemCount]];
	}
}

//----------------------------------------------------------
#pragma mark ACCESSORS
//----------------------------------------------------------

-(SBFileItem *)rootItem 
{
    return _sbrootItem;
}

-(void)setRootItem:(SBFileItem *)newRootItem
{
	[newRootItem retain];
	[_sbrootItem release];
	_sbrootItem = newRootItem;
}

-(NSString *)_sbname { return _sbname; }

-(void)_setSbname:(NSString *)newSbname
{
	[newSbname retain];
	[_sbname release];
	_sbname = newSbname;
}


//----------------------------------------------------------
#pragma mark TREE BUILDING METHODS
//----------------------------------------------------------

-(void)buildTreeFromFileList:(NSMutableArray *)flist
{
    NSEnumerator *e;
    NSString *apath;
	SBFileItem *item;

	[self showWindow:self];
	
	[self startedLoading];

    e = [flist objectEnumerator];
    while (nil != (apath = [e nextObject])){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		item = [[SBFileItem alloc] initWithPath:apath]; //retain count = 1
		[self addItemToTree:item];  //adds to array, retain count = 2
		if (nil == [item children]){
			totalSize += [item size];
			itemCount++;
		}
		[item release]; //retain count = 1
		[pool release];
    }
	[outlineView reloadItem:[self rootItem] reloadChildren:YES];

	[self finishedLoading];
}

-(SBFileItem *)parentOfItem:(SBFileItem *)item
{
    SBFileItem *parent = [self rootItem];
    NSString *ppath;
    NSEnumerator *e;
    NSString *component;
    NSMutableArray *componentArray = [NSMutableArray array];

	//If this item (the argument) is one level down from the root, the root is the parent
    ppath = [item pathToParent];
	if ([ppath isEqualToString:[[self rootItem] path]]){
		return [self rootItem];
	}
	
	//Otherwise make an array of the full path of each ancestor in the tree
	while ([ppath length] > [[[self rootItem] path] length]){
		[componentArray addObject:ppath];
		ppath = [ppath stringByDeletingLastPathComponent];
	}

	/*	Check each path in the array in reverse order (i.e. from the root downward) 
		to determine whether there is an associated SBFileItem for that path. 
		If one is missing at any point, there is a gap in tree branches leading to 
		this item.  Return nil so that addItemToTree is called for the path
		component where the gap begins.  
		If there is no gap, the return value will be the SBFileItem corresponding
		to the parent directory for this item.  */
	e = [componentArray reverseObjectEnumerator];
    while (nil != (component = [e nextObject])){
		parent = [parent childWithPath:component]; 
		if (nil == parent) return nil;
    }
    return parent;
}

-(void)addItemToTree:(SBFileItem *)item
{
    SBFileItem *pitem;

    if ([item isEqual:[self rootItem]] || nil == item){
		return;
    }
    pitem = [self parentOfItem:item];
    if (nil != pitem){
		if (nil != [pitem children] && ! [pitem hasChild:item]){
			[pitem addChild:item];  //adds to children array
		}
		return;
    }
    pitem = [[[SBFileItem alloc] initWithPath:[item pathToParent]] autorelease];
    [self addItemToTree:pitem];    
    [self addItemToTree:item];
}

//----------------------------------------------------------
#pragma mark NSOUTLINE MANIPULATION
//----------------------------------------------------------

// NSOutline collapseItem:collapseChildren: appears not to work
-(void)collapseItemAndChildren:(SBFileItem *)item
{
	if (nil != [item children]){
		SBFileItem *child;
		NSEnumerator *e = [[item children] objectEnumerator];
		while (nil != (child = [e nextObject])){
			[self collapseItemAndChildren:child];
		}
	}
	[outlineView collapseItem:item];
}

//----------------------------------------------------------
#pragma mark NSOUTLINE DATA SOURCE METHODS
//----------------------------------------------------------

-(int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item 
{
    return (nil == item) ? 1 : [item numberOfChildren];
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item 
{
    return (nil == item) ? YES : ([item numberOfChildren] != -1);
}

-(id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item 
{
    return (nil == item) ? [self rootItem] : [item childAtIndex:index];
}

-(id)outlineView:(NSOutlineView *)outlineView 
	objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{
	NSString *identifier = [tableColumn identifier];
	if ([identifier isEqualToString:@"size"]){
		unsigned long itemSize = (nil == item) ? 
			[[[self rootItem] valueForKey:identifier] unsignedLongValue]:
			[[item valueForKey:identifier] unsignedLongValue];
		itemSize = itemSize / 1024 + 1;
		return [NSString stringWithFormat:@"%u KB", itemSize];
	}
    return (nil == item) ? (id)[[self rootItem] valueForKey:identifier] : 
						   (id)[item valueForKey:identifier];
}

//----------------------------------------------------------
#pragma mark ACTIONS
//----------------------------------------------------------

-(IBAction)openSelectedFiles:(id)sender
{
	NSEnumerator *e = [outlineView selectedRowEnumerator];
	NSNumber *rownum;
	SBFileItem *item;
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSString *stnddpath;
	BOOL successful;
	NSMutableArray *problemFiles = [NSMutableArray array];
	
	while (nil != (rownum = [e nextObject])){
		item = [outlineView itemAtRow:[rownum intValue]];
		if (nil != [item children]) continue;  //skip directories
		stnddpath = [[item path] stringByStandardizingPath];
		if ([stnddpath hasSuffix:@".html"]){
			NSURL *fileURL = [NSURL fileURLWithPath:stnddpath];
			successful = [ws openURL:fileURL];
		}else{
			//TBD:  Allow user to specify preferred application
			successful = [ws openFile:stnddpath withApplication:@"TextEdit"];
		}
		if (! successful){
			[problemFiles addObject:stnddpath];
		}
	}
	if ([problemFiles count] > 0){
		NSRunAlertPanel(@"Error",
				  @"The following could not be opened:\n\n%@",
				  @"OK", nil, nil, 
				  [problemFiles componentsJoinedByString:@" "]);
	}
}

@end
