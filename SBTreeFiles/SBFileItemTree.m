

#import "SBFileItemTree.h"

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
		}
    }
    return self;
}

-(void)dealloc
{
	[_sbrootItem release];
	[sbLock release];
	NSLog(@"Deallocating %@", [self description]);
	
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

-(NSString *)name { return sbName; }

-(void)setName:(NSString *)newName
{
    [newName retain];
    [sbName release];
    sbName = newName;
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

-(void)buildTreeFromFileList:(NSMutableArray *)flist
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSEnumerator *e;
    NSString *apath;
    SBFileItem *item;

    e = [flist objectEnumerator];
    while (nil != (apath = [e nextObject])){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

		[sbLock lock];

		item = [[SBFileItem alloc] initWithPath:apath]; //retain count = 1
		[self addItemToTree:item];  //adds to array, retain count = 2
		if (nil == [item children]){
			totalSize += [item size];
			itemCount++;
		}
		[item release]; //retain count = 1

		[sbLock unlock];

		[pool release];
    }

    [[NSDistributedNotificationCenter defaultCenter]
			postNotificationName:@"SBTreeCompleteNotification"
			object:[self name]];

    [pool release];
    return;
}

-(SBFileItem *)itemInTreeWithPathArray:(NSArray *)parray
{
    SBFileItem *anItem = [self rootItem];
    NSString *path = @"";
    NSString *fname;
    NSEnumerator *e = [parray objectEnumerator];

    while (nil != anItem && nil != (fname = [e nextObject])){
		path = [path stringByAppendingPathComponent:[anItem path]];
		anItem = [anItem childWithPath:path];
    }
    return anItem;
}

-(SBFileItem *)itemInTreeWithPath:(NSString *)path
{
    NSArray *pathArray = [path pathComponents];

    if ([[pathArray lastObject] length] < 1){
		pathArray = [pathArray subarrayWithRange:NSMakeRange(0, [pathArray count]-1)];
    }
    return [self itemInTreeWithPathArray:pathArray];
}

@end


