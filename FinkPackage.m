/*  
File: FinkPackage.m

See the header file, FinkPackage.h, for interface and license information.

*/

#import "FinkPackage.h"

@implementation FinkPackage

//================================================================================
#pragma mark BASIC METHODS
//================================================================================

-(void)dealloc
{
	[name release];
	[status release];
	[version release];
	[installed release];
	[binary release];
	[stable release];
	[unstable release];
	[category release];
	[summary release];
	[fulldesc release];
	[weburl release];
	[maintainer release];
	[email release];
	[super dealloc];
}


// String representation of the object in NSLog and debugging
-(NSString *)description
{
	return [NSString stringWithFormat:@"%@-%@", [self name], [self version]];
}

//================================================================================
#pragma mark ACCESSORS
//================================================================================

//String that may be used repeatedly by all instances
+(NSString *)pathToDists
{
	static NSString *_pathToDists = nil;
	if (nil == _pathToDists){
		_pathToDists = [[[[NSUserDefaults standardUserDefaults]
									objectForKey:@"FinkBasePath"]
								stringByAppendingPathComponent: @"/fink/dists"] retain];
		NSLog(@"Path to dists = %@", _pathToDists);
	}
	return _pathToDists;
}

//Name
-(NSString *)name
{
	return name;
}

-(void)setName:(NSString *)s
{
	[s retain];
	[name release];
	name = s;
}

//Status
-(NSString *)status
{
	return status;
}

-(void)setStatus:(NSString *)s
{
	[s retain];
	[status release];
	status = s;
}

//Version
-(NSString *)version
{
	return version;
}

-(void)setVersion:(NSString *)s
{
	[s retain];
	[version release];
	version = s;
}

//Installed
-(NSString *)installed
{
	return installed;
}

-(void)setInstalled:(NSString *)s
{
	[s retain];
	[installed release];
	installed = s;
}

//Binary
-(NSString *)binary;
{
	return binary;
}

-(void)setBinary:(NSString *)s;
{
	[s retain];
	[binary release];
	binary = s;
}

//Stable
-(NSString *)stable
{
	return stable;
}

-(void)setStable:(NSString *)s
{
	[s retain];
	[stable release];
	stable = s;
}

//Unstable
-(NSString *)unstable;
{
	return unstable;
}

-(void)setUnstable:(NSString *)s;
{
	[s retain];
	[unstable release];
	unstable = s;
}

//Category
-(NSString *)category
{
	return category;
}

-(void)setCategory:(NSString *)s
{
	[s retain];
	[category release];
	category = s;
}

//Summary
-(NSString *)summary;
{
	return summary;
}

-(void)setSummary:(NSString *)s;
{
	[s retain];
	[summary release];
	summary = s;
}

//Fulldesc
-(NSString *)fulldesc
{
	return fulldesc;
}

-(void)setFulldesc:(NSString *)s
{
	[s retain];
	[fulldesc release];
	fulldesc = s;
}

//Weburl
-(NSString *)weburl
{
	return weburl;
}

-(void)setWeburl:(NSString *)s
{
	[s retain];
	[weburl release];
	weburl = s;	
}

//Maintainer
-(NSString *)maintainer
{
	return maintainer;
}

-(void)setMaintainer:(NSString *)s;
{
	[s retain];
	[maintainer release];
	maintainer = s;	
}

//Email
-(NSString *)email
{
	return email;
}

-(void)setEmail:(NSString *)s
{
	[s retain];
	[email release];
	email = s;	
}

//Flagged
-(int)flagged
{
	return flagged;
}

-(void)setFlagged:(int)f
{
	flagged = f;
}

//================================================================================
#pragma mark COMPARISON
//================================================================================

-(BOOL)isEqual:(id)anObject
{
	if (![anObject isKindOfClass: [FinkPackage class]]){
		return NO;
	}
	if ([[anObject description] isEqualToString:[self description]]){
		return YES;
	}else{
		return NO;
	}
}

//Helper: compare soley for some content in version number;
//return opposite from usual order so rows with some value appear at top
-(NSComparisonResult)xExists:(NSString *)x yExists:(NSString *)y
{
	BOOL xIs = [x length] > 1;
	BOOL yIs = [y length] > 1;
	
	if (xIs){
		if (yIs) return NSOrderedSame;
		else return NSOrderedAscending;
	}
	if (yIs) return NSOrderedDescending;  //already know ! xIs
	return NSOrderedSame; // ! xIs && ! yIs
}

//Name
-(NSComparisonResult)normalCompareByName:(FinkPackage *)pkg;
{
	return [[self name] caseInsensitiveCompare: [pkg name]];
}

-(NSComparisonResult)reverseCompareByName:(FinkPackage *)pkg
{
	return (0 - [self normalCompareByName: pkg]);
}

//Status
//Reverse alphabetical is default, because it puts outdated at the top
//in all of the languages for which FinkCommander has been localized so far
//(English, French, German as of 11/10/2002).
-(NSComparisonResult)normalCompareByStatus:(FinkPackage *)pkg
{
	NSComparisonResult result = [[self status] caseInsensitiveCompare:
		[pkg status]];
	if (result == 0) return [self normalCompareByName: pkg];
	return (0 - result);
}

-(NSComparisonResult)reverseCompareByStatus:(FinkPackage *)pkg
{
	NSComparisonResult result = [[self status] caseInsensitiveCompare:
		[pkg status]];
	if (result == 0) return (0 -[self normalCompareByName: pkg]);
	return (result);
}

//Version
-(NSComparisonResult)normalCompareByVersion:(FinkPackage *)pkg
{
	return [[self version] caseInsensitiveCompare: [pkg version]];
}

-(NSComparisonResult)reverseCompareByVersion:(FinkPackage *)pkg
{
	return (0 - [self normalCompareByVersion: pkg]);
}

//Installed
-(NSComparisonResult)normalCompareByInstalled:(FinkPackage *)pkg
{
	NSComparisonResult result = [self xExists:[self installed] yExists:[pkg installed]];
	if (result == 0) return [self normalCompareByName: pkg];
	return (result);
}

-(NSComparisonResult)reverseCompareByInstalled:(FinkPackage *)pkg
{
	return (0 - [self normalCompareByInstalled:pkg]);
}

//Binary
-(NSComparisonResult)normalCompareByBinary:(FinkPackage *)pkg
{
	NSComparisonResult result = [self xExists:[self binary] yExists:[pkg binary]];
	if (result == 0) return [self normalCompareByName: pkg];
	return (result);
}

-(NSComparisonResult)reverseCompareByBinary:(FinkPackage *)pkg
{
	return (0 - [self normalCompareByBinary:pkg]);
}


//Stable
-(NSComparisonResult)normalCompareByStable:(FinkPackage *)pkg
{
	NSComparisonResult result = [self xExists:[self stable] yExists:[pkg stable]];
	if (result == 0) return [self normalCompareByName: pkg];
	return (result);
}

-(NSComparisonResult)reverseCompareByStable:(FinkPackage *)pkg
{
	return (0 - [self normalCompareByStable:pkg]);
}


//Unstable
-(NSComparisonResult)normalCompareByUnstable:(FinkPackage *)pkg
{
	NSComparisonResult result = [self xExists:[self unstable] yExists:[pkg unstable]];
	if (result == 0) return [self normalCompareByName: pkg];
	return (result);
}

-(NSComparisonResult)reverseCompareByUnstable:(FinkPackage *)pkg
{
	return (0 - [self normalCompareByUnstable:pkg]);
}

//Category
-(NSComparisonResult)normalCompareByCategory:(FinkPackage *)pkg
{
	NSComparisonResult result;
	if ([[self category] length] < 2) return NSOrderedDescending; //put blanks at end
	result = [[self category] caseInsensitiveCompare: [pkg category]];
	if (result == 0) return [self normalCompareByName: pkg];
	return result;
}

-(NSComparisonResult)reverseCompareByCategory:(FinkPackage *)pkg
{
	NSComparisonResult result = [[self category] caseInsensitiveCompare:
		[pkg category]];
	if (result == 0) return (0 - [self normalCompareByName: pkg]);
	return (0 - result);
}

//Summary
-(NSComparisonResult)normalCompareBySummary:(FinkPackage *)pkg
{
	return [[self summary] caseInsensitiveCompare: [pkg summary]];
}

-(NSComparisonResult)reverseCompareBySummary:(FinkPackage *)pkg
{
	return (0 - [self normalCompareBySummary: pkg]);
}


//Maintainer
-(NSComparisonResult)normalCompareByMaintainer:(FinkPackage *)pkg
{
	NSComparisonResult result = [[self maintainer] caseInsensitiveCompare: [pkg maintainer]];
	if (result == 0) return [self normalCompareByName: pkg];
	return result;
}

-(NSComparisonResult)reverseCompareByMaintainer:(FinkPackage *)pkg
{
	NSComparisonResult result = [[self maintainer] caseInsensitiveCompare: [pkg maintainer]];
	if (result == 0) return [self reverseCompareByName: pkg];
	return (0 - result);
}

//Flag
-(NSComparisonResult)normalCompareByFlagged:(FinkPackage *)pkg
{
	NSComparisonResult result = [pkg flagged] - [self flagged];
	if (result == 0) return [self normalCompareByName:pkg];
	return result;
}

-(NSComparisonResult)reverseCompareByFlagged:(FinkPackage *)pkg
{
	NSComparisonResult result = [self flagged] - [pkg flagged];
	if (result == 0) return [self reverseCompareByName:pkg];
	return result;
}

//================================================================================
#pragma mark QUERY PACKAGE
//================================================================================

-(NSString *)nameWithoutSplitoff:(BOOL *)changed
{
	if ([[self name] rangeOfString:@"-"].length > 0){
		NSEnumerator *e = [[NSArray arrayWithObjects:@"-bin", @"-dev", @"-shlibs", nil]
			objectEnumerator];
		NSString *pkgname = [self name];
		NSString *splitoff;
		NSRange r;

		while (nil != (splitoff = [e nextObject])){
			r = [pkgname rangeOfString:splitoff];
			if (r.length > 0){
				pkgname = [pkgname substringToIndex:r.location];
				*changed = YES;
				break;
			}
		}
		return pkgname;
	}
	return [self name];
}

-(NSString *)pathToPackageInTree:(NSString *)tree
			withExtension:(NSString *)ext
			version:(NSString *)fversion
{
	NSFileManager *mgr = [NSFileManager defaultManager];
	BOOL foundSplitoff = NO;
	NSString *fname = [self nameWithoutSplitoff:&foundSplitoff];
	NSString *distPath = [FinkPackage pathToDists];
    NSString *pkgFileName, *thePath;
    NSArray *components;
		
	if (nil == fversion){
		fversion = [tree isEqualToString:@"unstable"] ?
					[self unstable] : [self stable];
	}

	pkgFileName = [NSString stringWithFormat:@"%@-%@.%@", fname, fversion, ext];
    if ([[self category] isEqualToString:@"crypto"]){
		components = [NSArray arrayWithObjects:distPath, tree, @"crypto",
			@"finkinfo", pkgFileName, nil];
    }else{
		components = [NSArray arrayWithObjects:distPath, tree, @"main",
			@"finkinfo", [self category], pkgFileName, nil];
    }
	thePath = [[NSString pathWithComponents:components] stringByResolvingSymlinksInPath];
	
	if (! foundSplitoff && 
		[fname rangeOfString:@"-"].length > 0 && 
		! [mgr fileExistsAtPath:thePath]){
		NSMutableString *mutablePath = [[thePath mutableCopy] autorelease];
		NSRange rangeToLastDash = 
			NSMakeRange(0, [fname rangeOfString:@"-" options:NSBackwardsSearch].location);
		NSRange rangeOfName = [thePath rangeOfString:fname];
		
		fname = [fname substringWithRange:rangeToLastDash];
		[mutablePath replaceCharactersInRange:rangeOfName withString:fname];
		mutablePath = [mutablePath stringByResolvingSymlinksInPath];
		if ([mgr fileExistsAtPath:mutablePath]){
			thePath = mutablePath;
		}
	}
	
	return thePath;
}

-(NSString *)pathToPackageInTree:(NSString *)tree
			withExtension:(NSString *)ext
{
	return [self pathToPackageInTree:tree
					withExtension:ext
					version:nil];
}

@end
