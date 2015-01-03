/*  
File: FinkPackage.m

See the header file, FinkPackage.h, for interface and license information.

*/

#import "FinkPackage.h"

@implementation FinkPackage

//================================================================================
#pragma mark - BASIC METHODS
//================================================================================



// String representation of the object in NSLog and debugging
-(NSString *)description
{
	return [NSString stringWithFormat:@"%@-%@", [self name], [self version]];
}

//================================================================================
#pragma mark - ACCESSORS
//================================================================================

//String that may be used repeatedly by all instances
+(NSString *)pathToDists
{
	static NSString *_pathToDists = nil;
	if (nil == _pathToDists){
		_pathToDists = [[[NSUserDefaults standardUserDefaults]
									objectForKey:@"FinkBasePath"]
								stringByAppendingPathComponent: @"/fink/dists"];
	}
	return _pathToDists;
}

//================================================================================
#pragma mark - COMPARISON
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
-(NSComparisonResult)normalCompareByName:(FinkPackage *)pkg
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

//Local
-(NSComparisonResult)normalCompareByLocal:(FinkPackage *)pkg
{
	NSComparisonResult result = [self xExists:[self local] yExists:[pkg local]];
	if (result == 0) return [self normalCompareByName: pkg];
	return (result);
}

-(NSComparisonResult)reverseCompareByLocal:(FinkPackage *)pkg
{
	return (0 - [self normalCompareByLocal:pkg]);
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
#pragma mark - QUERY PACKAGE
//================================================================================

-(NSString *)nameWithoutSplitoff:(BOOL *)changed
{
	if ([[self name] rangeOfString:@"-"].length > 0){
        NSArray *splitoffs = @[@"-bin", @"-dev", @"-shlibs"];
		NSString *pkgname = [self name];
		NSRange r;

		for (NSString *splitoff in splitoffs){
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

// This is slightly fragile. Should get the path from fink itself.
-(NSString *)pathToPackageInTree:(NSString *)tree
			withExtension:(NSString *)ext
			version:(NSString *)fversion
{
	NSFileManager *mgr = [NSFileManager defaultManager];
	BOOL foundSplitoff = NO;
	NSString *fname = [self nameWithoutSplitoff:&foundSplitoff];
	NSString *distPath = [FinkPackage pathToDists];
    NSString *thePath;
    NSArray *components, *nameVariants;
		
	if (nil == fversion){
		fversion = [tree isEqualToString:@"unstable"] ?
					[self unstable] : [self stable];
	}

	nameVariants = @[[NSString stringWithFormat:@"%@-%@.%@", fname, fversion, ext],
						[NSString stringWithFormat:@"%@.%@", fname, ext]];
	for (NSString *pkgFileName in nameVariants)
	{
		if ([[self category] isEqualToString:@"crypto"]){
			components = @[distPath, tree, @"crypto",
				@"finkinfo", pkgFileName];
		}else{
			components = @[distPath, tree, @"main",
				@"finkinfo", [self category], pkgFileName];
		}
		thePath = [[NSString pathWithComponents:components] stringByResolvingSymlinksInPath];
		
		if (! foundSplitoff && 
			[fname rangeOfString:@"-"].length > 0 && 
			! [mgr fileExistsAtPath:thePath]){
			NSMutableString *mutablePath = [thePath mutableCopy];
			NSString *mutatedString;
			NSRange rangeToLastDash = 
				NSMakeRange(0, [fname rangeOfString:@"-" options:NSBackwardsSearch].location);
			NSRange rangeOfName = [thePath rangeOfString:fname];
			
			fname = [fname substringWithRange:rangeToLastDash];
			[mutablePath replaceCharactersInRange:rangeOfName withString:fname];
			mutatedString = [mutablePath stringByResolvingSymlinksInPath];
			if ([mgr fileExistsAtPath:mutablePath]){
				thePath = mutatedString;
			}
		}
		if([mgr fileExistsAtPath:thePath]){
			break;
		}
	}
	
	//Finally, if that failed, fall back to what fink said. Probably best, anyway.
// This breaks the 'tree' parameter! bad!
//	if(![mgr fileExistsAtPath:thePath] && [filename length] > 4)
//	{
//		return filename;
//	}
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
