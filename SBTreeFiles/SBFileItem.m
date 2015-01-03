/*
File SBFileItem.m

 See header file SBFileItem.h for license and interface information.

*/

#import "SBFileItem.h"

@implementation SBFileItem

//----------------------------------------------------------
#pragma mark - ITEM CREATION AND DESTRUCTION
//----------------------------------------------------------

-(instancetype)initWithPath:(NSString *)p
{
	if ((self = [super init])){
		NSFileManager *mgr = [NSFileManager defaultManager];
		NSDictionary *fattrs;
		BOOL isDir, valid;
		NSArray *arr;
        NSError *err;

		p = [[p stringByStandardizingPath] stringByResolvingSymlinksInPath];
		valid = [mgr fileExistsAtPath:p isDirectory:&isDir];

		if (valid){
			fattrs = [mgr attributesOfItemAtPath:p error:&err];
			_path = p;
			_filename = [p lastPathComponent];
			_size = [fattrs fileSize];
			_mdate = [fattrs fileModificationDate];
			arr = isDir ? @[] : nil;
			_children = arr;
		}else{
			self = nil;
		}
	}
	return self;
}

-(instancetype)initWithURL:(NSURL *)url
{
    return [self initWithPath:[url path]];
}

//----------------------------------------------------------
#pragma mark - ACCESSORS
//----------------------------------------------------------

-(NSURL *)URL
{
    return [NSURL fileURLWithPath:[self path]];
}

-(void)setURL:(NSURL *)url
{
    [self setPath:[url path]];
}

//----------------------------------------------------------
#pragma mark - BASIC OBJECT METHODS
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
#pragma mark - PARENTS AND CHILDREN
//----------------------------------------------------------

-(BOOL)addChild:(SBFileItem *)item
{
    if (nil != [self children]){
		[self setChildren:[[self children] arrayByAddingObject:item]];
		return TRUE;
    }
    return FALSE;
}

-(NSInteger)numberOfChildren
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
	if (nil == [self children]) return nil;
	for (SBFileItem *item in [self children]){
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

