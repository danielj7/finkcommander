

#import "FinkDialogs.h"


@implementation FinkDialogs

-(id)initWithController:(id)c
{
	if (self = [super init]){
		controller = c;
	}
	return self;
}

- (id)controller {
    return controller;
}

- (void)setController:(id)newController 
{
	[newController retain];
	[controller release];
	controller = newController;
}

- (NSArray *)arguments {
    return arguments;
}

- (void)setArguments:(NSArray *)newArguments {
	[newArguments retain];
	[arguments release];
	arguments = newArguments;
}


-(void)showRemoveWarningPanelForArguments:(NSArray *)args
{
	
}


@end
