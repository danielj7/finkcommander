

#import "FinkWarningDialog.h"

@implementation FinkWarningDialog

-(id)init
{
	self = [super initWithWindowNibName:@"Dialogs"];
	Dprintf(@"Warning window: %@", [self window]);
	[self setWindowFrameAutosaveName: @"WarningDialog"];
	defaults = [NSUserDefaults standardUserDefaults];
	
	return self;
}

-(void)dealloc
{
	[arguments release];
}

-(NSMutableArray *)arguments 
{
    return arguments;
}

-(void)setArguments:(NSMutableArray *)newArguments 
{
	[newArguments retain];
	[arguments release];
	arguments = newArguments;
}

-(void)showRemoveWarningForArguments:(NSMutableArray *)args
{
	[self setArguments:args];
	if ([args count] > 3){
		[warningMessageField setStringValue:NSLocalizedString(@"Are you certain you want to remove the selected packages?", nil)];
	}else{
		[warningMessageField setStringValue:NSLocalizedString(@"Are you certain you want to remove the selected package?", nil)];
	}
	[turnOffWarningButton setState:YES];
	[NSApp runModalForWindow:[self window]];
}


-(IBAction)confirmAction:(id)sender
{
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	NSDictionary *d = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NO]
									forKey:FinkRunProgressIndicator];

	[center postNotificationName:FinkRunCommandNotification
			object:[self arguments]
			userInfo:d];
	[defaults setBool:[turnOffWarningButton state] forKey:FinkWarnBeforeRemoving];
	[NSApp stopModal];
	[self close];
}


-(IBAction)cancelAction:(id)sender
{
	[defaults setBool:[turnOffWarningButton state] forKey:FinkWarnBeforeRemoving];
	[NSApp stopModal];
	[self close];
}



@end
