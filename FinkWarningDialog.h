
#import <Cocoa/Cocoa.h>
#import "FinkGlobals.h"


@interface FinkWarningDialog : NSWindowController 
{
	IBOutlet NSButton *turnOffWarningButton;
	IBOutlet NSTextField *warningMessageField;
	IBOutlet NSTextField *actionTypeField;
	
	NSMutableArray *arguments;
	NSUserDefaults *defaults;
}

-(NSMutableArray *)arguments;
-(void)setArguments:(NSMutableArray *)newArguments;

-(void)showRemoveWarningForArguments:(NSMutableArray *)args;

-(IBAction)confirmAction:(id)sender;
-(IBAction)cancelAction:(id)sender;

@end
