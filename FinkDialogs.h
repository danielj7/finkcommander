

#import <Cocoa/Cocoa.h>
#import "FinkController.h"

@interface FinkDialogs : NSObject 
{
	IBOutlet NSButton *turnOffWarningButton;
	IBOutlet NSTextField *questionTextField;
	
	id controller;
	NSArray *arguments;
}

//init
-(id)initWithController:(FinkController *)c;

//accessors
- (id)controller;
- (void)setController:(id)newController;
- (NSArray *)arguments;
- (void)setArguments:(NSArray *)newArguments;

//show panels
-(void)showRemoveWarningPanelForArguments:(NSArray *)args;

@end
