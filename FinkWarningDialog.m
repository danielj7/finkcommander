

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
    command = REMOVE;
    [self setArguments:args];
    if ([args count] > 3){
		[warningMessageField setStringValue:NSLocalizedString(@"Are you certain you want to remove the selected packages?", nil)];
    }else{
		[warningMessageField setStringValue:NSLocalizedString(@"Are you certain you want to remove the selected package?", nil)];
    }
    [removeWarningButton 
		setTitle:NSLocalizedString(@"Warn me before removing a package.", nil)];
    [removeWarningButton setState:YES];
    [NSApp runModalForWindow:[self window]];
}

-(void)showTerminateWarning
{
    command = TERMINATE;
    [warningMessageField 
		setStringValue:NSLocalizedString(@"Are you sure you want to terminate?", nil)];
    [removeWarningButton
		setTitle:NSLocalizedString(@"Warn me before terminating a command.", nil)];
	[removeWarningButton setState:YES];
    [NSApp runModalForWindow:[self window]];
}

-(IBAction)confirmAction:(id)sender
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSDictionary *d;
    switch (command){
		case REMOVE:
			d = [NSDictionary
			dictionaryWithObject:[NSNumber numberWithInt:NO]
					   forKey:FinkRunProgressIndicator];
			[center postNotificationName:FinkRunCommandNotification
							   object:[self arguments]
							 userInfo:d];
			[defaults setBool:[removeWarningButton state]
					forKey:FinkWarnBeforeRemoving];
			break;
		case TERMINATE:
			[center postNotificationName:FinkTerminateNotification
							   object:nil];
			[defaults setBool:[removeWarningButton state]
					forKey:FinkWarnBeforeTerminating];
    }
    [NSApp stopModal];
    [self close];
}


-(IBAction)cancelAction:(id)sender
{
    switch (command){
		case REMOVE:
			[defaults setBool:[removeWarningButton state] 
				forKey:FinkWarnBeforeRemoving];
			break;
		case TERMINATE:
			[defaults setBool:[removeWarningButton state] 
				forKey:FinkWarnBeforeTerminating];
			break;
    }
    [NSApp stopModal];
    [self close];
}



@end
