/*
 File: FinkWarningDialog.m

 See the header file, FinkWarningDialog.h, for interface and license information.

 */

#import "FinkWarningDialog.h"

@interface FinkWarningDialog ()

@property (nonatomic, readonly) NSUserDefaults *defaults;
@property (nonatomic) FinkWarningCommandType command;

@end

@implementation FinkWarningDialog

-(instancetype)init
{
    self = [super initWithWindowNibName:@"Dialogs"];
    Dprintf(@"Warning window: %@", [self window]);
    [self setWindowFrameAutosaveName: @"WarningDialog"];
    _defaults = [NSUserDefaults standardUserDefaults];
	
    return self;
}


-(void)showRemoveWarningForArguments:(NSMutableArray *)args
{
    NSInteger optcount = 0;
	
	[self setCommand: REMOVE];
    [self setArguments:args];
	
	if ([args indexOfObject:@"-y"] != NSNotFound) optcount++;
	if ([args indexOfObject:@"-f"] != NSNotFound) optcount+=2;
	
    if ([args count] - optcount > 3){
		[[self warningMessageField] setStringValue:NSLocalizedString(@"Are you certain you want to remove the selected packages?", @"Warning dialog message, plural version")];
    }else{
		[[self warningMessageField] setStringValue:NSLocalizedString(@"Are you certain you want to remove the selected package?", @"Warning dialog message, singular version")];
    }
	[[self confirmButton] setTitle:LS_REMOVE];
	[[self cancelButton] setTitle:LS_CANCEL];
    [[self removeWarningButton] 
		setTitle:NSLocalizedString(@"Warn me before removing a package.", 
								   @"Check button title")];
    [[self removeWarningButton] setState:YES];
    [NSApp runModalForWindow:[self window]];
}

-(void)showTerminateWarning
{
    [self setCommand: TERMINATE];
    [[self warningMessageField] 
		setStringValue:NSLocalizedString(@"Are you sure you want to terminate?", 
											@"Warning dialog message")];
	[[self confirmButton] setTitle:NSLocalizedString(@"Terminate", @"Button title")];
	[[self cancelButton] setTitle:LS_CANCEL];
    [[self removeWarningButton]
		setTitle:NSLocalizedString(@"Warn me before terminating a command.", 
									@"Check button title")];
	[[self removeWarningButton] setState:YES];
    [NSApp runModalForWindow:[self window]];
}

-(IBAction)confirmAction:(id)sender
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSDictionary *d;
    switch ([self command]){
		case REMOVE:
			d = @{FinkRunProgressIndicator: [NSNumber numberWithInt:YES]};
			[center postNotificationName:FinkRunCommandNotification
							   object:[self arguments]
							 userInfo:d];
			[[self defaults] setBool:(BOOL)[[self removeWarningButton] state]
					forKey:FinkWarnBeforeRemoving];
			break;
		case TERMINATE:
			[center postNotificationName:FinkTerminateNotification
					object:nil];
			[[self defaults] setBool:(BOOL)[[self removeWarningButton] state]
					  forKey:FinkWarnBeforeTerminating];
    }
    [NSApp stopModal];
    [self close];
}


-(IBAction)cancelAction:(id)sender
{
    switch ([self command]){
		case REMOVE:
			[[self defaults] setBool:(BOOL)[[self removeWarningButton] state]
				forKey:FinkWarnBeforeRemoving];
			break;
		case TERMINATE:
			[[self defaults] setBool:(BOOL)[[self removeWarningButton] state] 
				forKey:FinkWarnBeforeTerminating];
			break;
    }
    [NSApp stopModal];
    [self close];
}



@end
