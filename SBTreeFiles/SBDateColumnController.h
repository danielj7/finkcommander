
#import <Cocoa/Cocoa.h>
#import "FinkGlobals.h"

@interface SBDateColumnController: NSObject
{
    NSTableColumn * _sbColumn;
    NSString *_sbShortTitle;
    NSString *_sbLongTitle;
}

-(id)initWithColumn:(NSTableColumn *)myColumn;

-(id)initWithColumn:(NSTableColumn *)myColumn
		 shortTitle:(NSString *)stitle;
	/*" The designated initializer "*/
-(id)initWithColumn:(NSTableColumn *)myColumn
		 shortTitle:(NSString *)stitle 
		  longTitle:(NSString *)ltitle;

-(NSTableColumn *)column;
-(void)setColumn:(NSTableColumn *)newColumn;

-(NSString *)shortTitle;
-(void)setShortTitle:(NSString *)newShortTitle;

-(NSString *)longTitle;
-(void)setLongTitle:(NSString *)newLongTitle;

-(void)adjustColumnAndHeaderDisplay:(NSNotification *)n;

@end
