/*
File: FinkConf.m

 See the header file, FinkConf.h, for interface and license information.

*/

#import "FinkConf.h"

//Global variables used throughout FinkCommander source code to set
//user defaults.
NSString *FinkBasePath = @"FinkBasePath";
NSString *FinkBasePathFound = @"FinkBasePathFound";
NSString *FinkUpdateWithFink = @"FinkUpdateWithFink";
NSString *FinkAlwaysChooseDefaults = @"FinkAlwaysChooseDefaults";
NSString *FinkScrollToSelection = @"FinkScrollToSelection";
NSString *FinkSelectedColumnIdentifier = @"FinkSelectedColumnIdentifier";
NSString *FinkSelectedPopupMenuTitle = @"FinkSelectedPopupMenuTitle";
NSString *FinkHTTPProxyVariable = @"FinkHTTPProxyVariable";
NSString *FinkLookedForProxy = @"FinkLookedForProxy";


@implementation FinkConf

-(id)init
{
	defaults = [NSUserDefaults standardUserDefaults];

	if (self = [super init]){
		finkConfDict = [[NSMutableDictionary alloc] initWithCapacity: 15];
		[self readFinkConf];
	}
	return self;
}

-(void)readFinkConf
{
	NSString *fconfString = [NSString stringWithContentsOfFile:
			[[defaults objectForKey: FinkBasePath] stringByAppendingPathComponent: 
				@"/etc/fink.conf"]];
	NSEnumerator *e;
	NSString *line;
	int split;

	e = [[fconfString componentsSeparatedByString: @"\n"] objectEnumerator];
	while(line = [e nextObject]){
		if ([line rangeOfString: @":"].length > 0){
			split = [line rangeOfString: @":"].location;
			[finkConfDict setObject: [line substringFromIndex: split + 2] // eliminate space 
				forKey: [line substringToIndex: split]];
		}
	}
	[finkConfDict setObject: 
						[NSMutableArray arrayWithArray:
							[[finkConfDict objectForKey: @"Trees"] 
								componentsSeparatedByString: @" "]]
				  forKey: @"Trees"];				
}

-(BOOL)useUnstableMain
{
	if ([[finkConfDict objectForKey: @"Trees"] 
		indexOfObject: @"unstable/main"] == NSNotFound){
		return NO;
	}
	return YES;
}

-(void)setUseUnstableMain:(BOOL)shouldUseUnstable
{
	if (shouldUseUnstable){
		if ([[finkConfDict objectForKey: @"Trees"]
			indexOfObject: @"unstable/main"] == NSNotFound){
			[[finkConfDict objectForKey: @"Trees"] addObject: @"unstable/main"];
		}
	}else{
		if ([[finkConfDict objectForKey: @"Trees"]
			indexOfObject: @"unstable/main"] != NSNotFound){
			[[finkConfDict objectForKey: @"Trees"] removeObject: @"unstable/main"];
		}
	}
}

-(BOOL)useUnstableCrypto
{
	if ([[finkConfDict objectForKey: @"Trees"]
		indexOfObject: @"unstable/crypto"] == NSNotFound){
		return NO;
	}
	return YES;
}

-(void)setUseUnstableCrypto:(BOOL)shouldUseUnstable
{
	if (shouldUseUnstable){
		if ([[finkConfDict objectForKey: @"Trees"]
			indexOfObject: @"unstable/crypto"] == NSNotFound){
			[[finkConfDict objectForKey: @"Trees"] addObject: @"unstable/crypto"];
		}
	}else{
		if ([[finkConfDict objectForKey: @"Trees"]
			indexOfObject: @"unstable/crypto"] != NSNotFound){
			[[finkConfDict objectForKey: @"Trees"] removeObject: @"unstable/crypto"];
		}
	}
}

-(BOOL)verboseOutput
{
	if ([[finkConfDict objectForKey: @"Verbose"] isEqualToString: @"true"]){
		return YES;
	}
	return NO;
}

-(void)setVerboseOutput:(BOOL)verboseOutput
{
	if (verboseOutput){
		[finkConfDict setObject: @"true" forKey: @"Verbose"];
	}else{
		[finkConfDict setObject: @"false" forKey: @"Verbose"];
	}
}


-(void)writeToFile
{
	NSLog(@"Stub for writing to file: %@", finkConfDict);
}

@end
