
#import <Cocoa/Cocoa.h>
#import "FinkGlobals.h"

enum {
    REMOVE,
    TERMINATE
};

@interface FinkWarningDialog : NSWindowController 
{
	IBOutlet NSButton *removeWarningButton;
	IBOutlet NSTextField *warningMessageField;
	IBOutlet NSButton *confirmButton;
	IBOutlet NSButton *cancelButton;
	
	NSMutableArray *arguments;
	NSUserDefaults *defaults;
	int command;
}

-(NSMutableArray *)arguments;
-(void)setArguments:(NSMutableArray *)newArguments;

-(void)showRemoveWarningForArguments:(NSMutableArray *)args;
-(void)showTerminateWarning;

-(IBAction)confirmAction:(id)sender;
-(IBAction)cancelAction:(id)sender;

@end
