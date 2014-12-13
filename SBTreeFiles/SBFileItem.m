/*
File SBFileItem.m

 See header file SBFileItem.h for license and interface information.

*/

#import "SBFileItem.h"

@implementation SBFileItem

//----------------------------------------------------------
#pragma mark ITEM CREATION AND DESTRUCTION
//----------------------------------------------------------

-(instancetype)initWithPath:(NSString *)p
{
	if (nil != (self = [super init])){
		NSFileManager *mgr = [NSFileManager defaultManager];
		NSDictionary *fattrs;
		BOOL isDir, valid;
		NSArray *arr;
        NSError *err;

		p = [[p stringByStandardizingPath] stringByResolvingSymlinksInPath];
		valid = [mgr fileExistsAtPath:p isDirectory:&isDir];

		if (valid){
			fattrs = [mgr attributesOfItemAtPath:p error:&err];
			[self setPath:p];
			[self setFilename:[p lastPathComponent]];
			[self setSize: [fattrs fileSize]];
			[self setMdate:[fattrs fileModificationDate]];
			arr = isDir ? @[] : nil;
			[self setChildren:arr];
		}else{
			self = nil;
		}
	}
	return self;
}



//----------------------------------------------------------
#pragma mark ACCESSORS
//----------------------------------------------------------

-(NSArray *)children { return _sbchildren; }

-(void)setChildren:(NSArray *)c
{
    _sbchildren = c;
}

-(NSString *)path { return _sbpath; }

-(void)setPath:(NSString *)p
{
    _sbpath = p;
}

-(NSString *)filename { return _sbfilename; }

-(void)setFilename:(NSString *)fn
{
    _sbfilename = fn;
}

-(unsigned long)size { return _sbsize; }

-(void)setSize:(unsigned long)n { _sbsize = n; }

/* Not used yet:

- (NSDate *)cdate { return cdate; }

- (void)setCdate:(NSDate *)newCdate{
	[newCdate retain];
	[cdate release];
	cdate = newCdate;
}
*/

-(NSDate *)mdate { return _sbmdate; }

-(void)setMdate:(NSDate *)newMdate{
	_sbmdate = newMdate;
}

//----------------------------------------------------------
#pragma mark BASIC OBJECT METHODS
//----------------------------------------------------------

-(NSString *)description
{
    return [NSString stringWithFormat: @"<%@ --\n\tpath: %@\n\tsize: %lu\n\tmod date: %@\n\tis directory: %@>", [super description], [self path], [self size], [self mdate], 
			(nil != [self children] ? @"YES" : @"NO")];
}

-(BOOL)isEqual:(id)anObject
{
    return [[anObject path] isEqualToString:[self path]];
}

//----------------------------------------------------------
#pragma mark PARENTS AND CHILDREN
//----------------------------------------------------------

-(BOOL)addChild:(SBFileItem *)item
{
    if (nil != [self children]){
		[self setChildren:[[self children] arrayByAddingObject:item]];
		return TRUE;
    }
    return FALSE;
}

-(int)numberOfChildren
{
	return [self children] == nil ? (-1) : [[self children] count];
}

-(BOOL)hasChild:(SBFileItem *)item
{
	if (nil == [self children]) return NO;
	return [[self children] containsObject:item];
}

-(SBFileItem *)childAtIndex:(NSUInteger)n
{
	return [self children][n];
}

//Helper for following methods
-(SBFileItem *)childWithAttribute:(NSString *)attr value:(id)val
{
	NSEnumerator *e;
	SBFileItem *item;
	
	if (nil == [self children]) return nil;
	e = [[self children] objectEnumerator];
	while (nil != (item = [e nextObject])){
		if ([[item valueForKey:attr] isEqual:val]){
			return item;
		}
	}
	return nil;
}

-(SBFileItem *)childWithPath:(NSString *)iPath
{
	return [self childWithAttribute:@"path" value:iPath];
}

-(SBFileItem *)childWithFileName:(NSString *)fname
{
	return [self childWithAttribute:@"filename" value:fname];
}

-(NSString *)pathToParent
{
    return [[self path] stringByDeletingLastPathComponent];
}

@end

