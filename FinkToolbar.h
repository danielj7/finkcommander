

#import <Cocoa/Cocoa.h>

@interface FinkToolbar: NSToolbar
{
	NSButton *searchButton;
	NSTextField *searchField;
}
-(NSButton *)searchButton;
-(void)setSearchButton:(NSButton *)newSearchButton;
-(NSTextField *)searchField;
-(void)setSearchField:(NSTextField *)newSearchField;
@end
