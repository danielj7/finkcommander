/*
 File SBFileItemTree.m

 See header file SBFileItemTree.h for license and interface information.

 */

#import "SBFileItemTree.h"

NSString *SBAscendingOrder = @"SBAscendingOrder";
NSString *SBDescendingOrder = @"SBDescendingOrder";

//----------------------------------------------------------
#pragma mark SORTING FUNCTIONS
//----------------------------------------------------------

int sortByFilename(id firstItem, id secondItem, void *direction)
{
	NSString *firstName = [firstItem filename];
	NSString *secondName = [secondItem filename];
    int result = [firstName compare:secondName];
    NSString *order = (NSString *)direction;

    if ([order isEqualToString:SBAscendingOrder]) return result;
    return (0 - result);
}

int sortByMdate(id firstItem, id secondItem, void *direction)
{
	NSDate *itemOne = [firstItem mdate];
	NSDate *itemTwo = [secondItem mdate];
    int result = [itemOne compare:itemTwo];
    NSString *order = (NSString *)direction;

    if (result == NSOrderedSame){
		NSString *firstName = [firstItem filename];
		NSString *secondName = [secondItem filename];
		result = [firstName compare:secondName];
    }
    if ([order isEqualToString:SBAscendingOrder]) return result;
    return (0 - result);
}

int sortBySize(id firstItem, id secondItem, void *direction)
{
	SBFileItem *itemOne = (SBFileItem *)firstItem;
	SBFileItem *itemTwo = (SBFileItem *)secondItem;
	float firstSize = [itemOne size];
	float secondSize = [itemTwo size];
	int result = firstSize - secondSize;
	NSString *order = (NSString *)direction;
	
    if (result == 0){
		NSString *firstName = [firstItem filename];
		NSString *secondName = [secondItem filename];
		result = [firstName compare:secondName];		
    }
    result = result < 0 ? -1 : 1;
    if ([order isEqualToString:SBAscendingOrder]) return result;
    return (0 - result);
}


@implementation SBFileItemTree

//----------------------------------------------------------
#pragma mark CREATION AND DESTRUCTION
//----------------------------------------------------------

-(id)initWithFileArray:(NSMutableArray *)flist name:(NSString *)aName
{
    self = [super init];
    if (nil != self){
		[self setName:aName];
		sbLock = [[NSLock alloc] init];
		totalSize = 0;
		itemCount = 0;
		if (nil != flist && [flist count] > 0){
			[self setRootItem: [[SBFileItem alloc]
				   initWithPath:[flist objectAtIndex:0]]];
			//in case base path is symlink; standardizing path doesn't seem to work
			[[self rootItem] setChildren:[NSArray array]]; 
		}
    }
    return self;
}

-(void)dealloc
{
	[_sbrootItem release];
	[_sbName release];
	[sbLock release];
	Dprintf(@"Deallocating %@", [self description]);
	
	[super dealloc];
}

//----------------------------------------------------------
#pragma mark ACCESSORS
//----------------------------------------------------------

-(unsigned long)totalSize { return totalSize; }
-(unsigned long)itemCount { return itemCount; }

-(SBFileItem *)rootItem { return _sbrootItem; }

-(void)setRootItem:(SBFileItem *)newRootItem
{
	[newRootItem retain];
	[_sbrootItem release];
	_sbrootItem = newRootItem;
}

-(NSString *)name { return _sbName; }

-(void)setName:(NSString *)newName
{
    [newName retain];
    [_sbName release];
    _sbName = newName;
}

//----------------------------------------------------------
#pragma mark TREE BUILDING METHODS
//----------------------------------------------------------


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

    //Otherwise make an array of the full paths of each ancestor in the tree
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
	//There is no gap; add this item to its parent's children
    if (nil != pitem){
		if (nil != [pitem children] && ! [pitem hasChild:item]){
			[pitem addChild:item];  //adds to children array
		}
		return;
    }
	//There is a gap, we have to add the parent before adding this item
    pitem = [[[SBFileItem alloc] initWithPath:[item pathToParent]] autorelease];
    [self addItemToTree:pitem];
    [self addItemToTree:item];
}

/* 	This method runs in a separate thread to prevent the building of the tree from
	stalling the whole application */
-(void)buildTreeFromFileList:(NSMutableArray *)flist
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSEnumerator *e = [flist objectEnumerator];
    NSString *apath;
    SBFileItem *item;
	
	while (nil != (apath = [e nextObject]) && [apath length] > 0){
		[sbLock lock];
		item = [[SBFileItem alloc] initWithPath:apath]; //retain count = 1
		[self addItemToTree:item];  	//adds to array, retain count = 2
		if (nil == [item children]){ 	//not dir, so add to size and item count
			totalSize += [item size];
			itemCount++;
		}
		[item release]; //retain count = 1
		[sbLock unlock];
    }
	/*  If the item list is short enough, the DO notification is posted before the 
		window controller has a chance to register for it!  This seems like kind
		of an ugly hack to prevent this from happening, but it's all I can come up 
		with for now.  */
	if (itemCount < 200){
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
	}
	/* 	Let the window controller, which is running in another thread, know that
		the tree is ready for display.  */
	[[NSDistributedNotificationCenter defaultCenter]
			postNotificationName:@"SBTreeCompleteNotification"
			object:[self name]];
	Dprintf(@"Posted SBTreeCompleteNotification for %@", [self name]);
    [pool release];
    return;
}

//----------------------------------------------------------
#pragma mark SORTING METHODS
//----------------------------------------------------------

/* Recursively sort each file item's children */
-(void)sortChildrenOfItem:(SBFileItem *)pitem
		byElement:(NSString *)element
		inOrder:(NSString *)order
{
    NSArray *newArray;
    NSData *sortHint = [[pitem children] sortedArrayHint];
    SBFileItem *citem;
    NSEnumerator *e;
    int (*sorter)(id, id, void *); //pointer to sorting function

	if ([element isEqualToString:@"filename"]){
		sorter = sortByFilename; //func name is pointer to func
	}else if ([element isEqualToString:@"mdate"]){
		sorter = sortByMdate;
	}else{
		sorter = sortBySize;
	}

    //Sort children
    newArray = [[pitem children]
				sortedArrayUsingFunction:sorter
				context:order
				hint:sortHint];
    [pitem setChildren:newArray];

    //Sort descendants of children
    e = [[pitem children] objectEnumerator];
    while (nil != (citem = [e nextObject])){
		if (nil != [citem children]){
			[self sortChildrenOfItem:citem
				   byElement:element
				   inOrder:order];
		}
    }
}

/* Provides entry to recursive sort method defined above */
-(void)sortTreeByElement:(NSString *)element
    inOrder:(NSString *)order
{
    [self sortChildrenOfItem:[self rootItem]
			byElement:element
			inOrder:order];
}

@end
