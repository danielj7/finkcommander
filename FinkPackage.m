/*  
File: FinkPackage.m

See the header file, FinkPackage.h, for interface and license information.

*/

#import "FinkPackage.h"

@implementation FinkPackage

//----------------------------------------------------->Basics

// Dealloc

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


//----------------------------------------------------->Accessors

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


//----------------------------------------------------->Comparison

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
	if (result == 0) return (0 - [self normalCompareByName: pkg]);
	return (0 - result);
}

@end
