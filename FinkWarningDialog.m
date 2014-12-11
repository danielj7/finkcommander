/*
 File: FinkWarningDialog.m

 See the header file, FinkWarningDialog.h, for interface and license information.

 */

#import "FinkWarningDialog.h"

@implementation FinkWarningDialog

-(instancetype)init
{
    self = [super initWithWindowNibName:@"Dialogs"];
    Dprintf(@"Warning window: %@", [self window]);
    [self setWindowFrameAutosaveName: @"WarningDialog"];
    defaults = [NSUserDefaults standardUserDefaults];
	
    return self;
}


-(NSMutableArray *)arguments 
{
    return arguments;
}

-(void)setArguments:(NSMutableArray *)newArguments 
{
    arguments = newArguments;
}

-(void)showRemoveWarningForArguments:(NSMutableArray *)args
{
    int optcount = 0;
	
	command = REMOVE;
    [self setArguments:args];
	
	if ([args indexOfObject:@"-y"] != NSNotFound) optcount++;
	if ([args indexOfObject:@"-f"] != NSNotFound) optcount+=2;
	
    if ([args count] - optcount > 3){
		[warningMessageField setStringValue:NSLocalizedString(@"Are you certain you want to remove the selected packages?", @"Warning dialog message, plural version")];
    }else{
		[warningMessageField setStringValue:NSLocalizedString(@"Are you certain you want to remove the selected package?", @"Warning dialog message, singular version")];
    }
	[confirmButton setTitle:LS_REMOVE];
	[cancelButton setTitle:LS_CANCEL];
    [removeWarningButton 
		setTitle:NSLocalizedString(@"Warn me before removing a package.", 
								   @"Check button title")];
    [removeWarningButton setState:YES];
    [NSApp runModalForWindow:[self window]];
}

-(void)showTerminateWarning
{
    command = TERMINATE;
    [warningMessageField 
		setStringValue:NSLocalizedString(@"Are you sure you want to terminate?", 
											@"Warning dialog message")];
	[confirmButton setTitle:NSLocalizedString(@"Terminate", @"Button title")];
	[cancelButton setTitle:LS_CANCEL];
    [removeWarningButton
		setTitle:NSLocalizedString(@"Warn me before terminating a command.", 
									@"Check button title")];
	[removeWarningButton setState:YES];
    [NSApp runModalForWindow:[self window]];
}

-(IBAction)confirmAction:(id)sender
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSDictionary *d;
    switch (command){
		case REMOVE:
			d = @{FinkRunProgressIndicator: [NSNumber numberWithInt:YES]};
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
