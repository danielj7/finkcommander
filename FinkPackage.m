/*  
 File: FinkPackage.m

See the header file, FinkPackage.h, for interface and license information.

*/

#import "FinkPackage.h"

@implementation FinkPackage

// Dealloc

-(void)dealloc
{
	[name release];	
	[version release];
	[installed release];
	[category release];
	[description release];
	[binary release];
	[super dealloc];
}

// Instance variable access methods

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

-(NSString *)description;
{
	return description;
}

-(void)setDescription:(NSString *)s;
{
	[s retain];
	[description release];
	description = s;
}

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

// Comparison methods

-(BOOL)isEqual:(id)anObject
{
	if (![anObject isKindOfClass: [FinkPackage class]]){
		return NO;
	}
	if ([[anObject name] isEqualToString: [self name]] &&
	 [[anObject version] isEqualToString: [self version]]){
		return YES;
	}else{
		return NO;
	}
}

-(NSComparisonResult)normalCompareByName:(FinkPackage *)pkg;
{
	return [[self name] caseInsensitiveCompare: [pkg name]];
}

-(NSComparisonResult)reverseCompareByName:(FinkPackage *)pkg
{
	return (0 - [self normalCompareByName: pkg]);
}

-(NSComparisonResult)normalCompareByVersion:(FinkPackage *)pkg
{
	return [[self version] caseInsensitiveCompare: [pkg version]];
}

-(NSComparisonResult)reverseCompareByVersion:(FinkPackage *)pkg
{
	return (0 - [self normalCompareByVersion: pkg]);
}

-(NSComparisonResult)normalCompareByInstalled:(FinkPackage *)pkg
{
	NSComparisonResult result = [[self installed] caseInsensitiveCompare:
		[pkg installed]];
	if (result == 0) return [self normalCompareByName: pkg];
	return (0 - result);
}

-(NSComparisonResult)reverseCompareByInstalled:(FinkPackage *)pkg
{
	NSComparisonResult result = [[self installed] caseInsensitiveCompare:
		[pkg installed]];
	if (result == 0) return [self normalCompareByName: pkg];
	return (result);
}

-(NSComparisonResult)normalCompareByCategory:(FinkPackage *)pkg
{
	NSComparisonResult result = [[self category] caseInsensitiveCompare:
		[pkg category]];
	if (result == 0) return [self normalCompareByName: pkg];
	return result;
}

-(NSComparisonResult)reverseCompareByCategory:(FinkPackage *)pkg
{
	NSComparisonResult result = [[self category] caseInsensitiveCompare:
		[pkg category]];
	if (result == 0) return [self normalCompareByName: pkg];
	return (0 - result);
}

-(NSComparisonResult)normalCompareByDescription:(FinkPackage *)pkg
{
	return [[self description] caseInsensitiveCompare: [pkg description]];
}

-(NSComparisonResult)reverseCompareByDescription:(FinkPackage *)pkg
{
	return (0 - [self normalCompareByDescription: pkg]);
}

-(NSComparisonResult)normalCompareByBinary:(FinkPackage *)pkg
{
	NSComparisonResult result = [[self binary] caseInsensitiveCompare:
		[pkg binary]];
	if (result == 0) return [self normalCompareByName: pkg];
	return (0 - result);
}

-(NSComparisonResult)reverseCompareByBinary:(FinkPackage *)pkg
{
	NSComparisonResult result = [[self binary] caseInsensitiveCompare:
		[pkg binary]];
	if (result == 0) return [self normalCompareByName: pkg];
	return (result);

}

-(NSComparisonResult)normalCompareByUnstable:(FinkPackage *)pkg
{
	NSComparisonResult result = [[self unstable] caseInsensitiveCompare:
		[pkg unstable]];
	if (result == 0) return [self normalCompareByName: pkg];
	return (0 - result);
}

-(NSComparisonResult)reverseCompareByUnstable:(FinkPackage *)pkg
{
	NSComparisonResult result = [[self unstable] caseInsensitiveCompare:
		[pkg unstable]];
	if (result == 0) return [self normalCompareByName: pkg];
	return (result);

}

@end  