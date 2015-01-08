/*
File: FinkSplitView.m

 See the header file, FinkController.h, for interface and license information.

*/

#import "FinkSplitView.h"

@interface FinkSplitView ()

@property (nonatomic) NSUserDefaults *defaults;
@property (nonatomic) NSScrollView *tableScrollView;
@property (nonatomic) NSScrollView *outputScrollView;

@end

@implementation FinkSplitView

-(instancetype)initWithFrame:(NSRect)rect
{
	if ((self = [super initWithFrame:rect])){
		_defaults = [NSUserDefaults standardUserDefaults];
		[self setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
		[self setDelegate:self];
		//Register for notification that causes output to collapse when
		//user selects the auto expand option
		[[NSNotificationCenter defaultCenter] 
						addObserver: self
						selector: @selector(collapseOutput:)
						name: FinkCollapseOutputView
						object: nil];
	}
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

-(void)connectSubviews
{
	[self setTableScrollView: [self subviews][0]];
	[self setOutputScrollView: [self subviews][1]];
}

//Delegate method:
//preserve user's adjustment of splitview for future use,
//such as the expandOutputToMinimumRatio: method, 
//unless the output view height after the adjustment is 0
-(void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
	NSRect oFrame = [[self outputScrollView] frame];
	NSRect sFrame = [self frame];
	
	if (oFrame.size.height > 0.0){
		[[self defaults] setFloat:(float)(oFrame.size.height / sFrame.size.height)
				  forKey:FinkOutputViewRatio];
		[[self collapseExpandMenuItem] setTitle:LS_COLLAPSE];
	}else{
		[[self collapseExpandMenuItem] setTitle:LS_EXPAND];
	}	
}

-(void)collapseOutput:(NSNotification *)n
{
	if (! [self isSubviewCollapsed:[self outputScrollView]]){
		NSRect oFrame = [[self outputScrollView] frame];
		NSRect tFrame = [[self tableScrollView] frame];
		NSRect sFrame = [self frame];
		CGFloat divwidth = [self dividerThickness];

		tFrame.size.height = sFrame.size.height - divwidth;
		oFrame.size.height = 0.0;
		oFrame.origin.y = sFrame.size.height;

		[[self outputScrollView] setFrame: oFrame];
		[[self tableScrollView] setFrame: tFrame];

		[self splitViewDidResizeSubviews:nil];

		[self setNeedsDisplay: YES];
	}
}

//pass 0.0 as argument to expand output to last height stored in user defaults
-(void)expandOutputToMinimumRatio:(CGFloat)r
{
	NSRect oFrame = [[self outputScrollView] frame];
	NSRect tFrame = [[self tableScrollView] frame];
	NSRect sFrame = [self frame];
	CGFloat divwidth = [self dividerThickness];
	CGFloat hratio = [[self defaults] floatForKey: FinkOutputViewRatio];
	
	if (r > 0.0){
		hratio = MAX(hratio, r);
		Dprintf(@"Output view ratio: %f", hratio);
	}

	oFrame.size.height = ceil(sFrame.size.height * hratio);
	tFrame.size.height = sFrame.size.height - oFrame.size.height - divwidth;
	oFrame.origin.y = tFrame.size.height + divwidth;

	[[self outputScrollView] setFrame: oFrame];
	[[self tableScrollView] setFrame: tFrame];

	[self splitViewDidResizeSubviews:nil];

	[self setNeedsDisplay: YES];
}

//Connected to First Responder
-(IBAction)collapseExpandOutput:(id)sender
{
	if ([[self outputScrollView] bounds].size.height > 1.0){
		[self collapseOutput:nil];
	}else{
		[self expandOutputToMinimumRatio:0.0];
	}
}

-(void)mouseDown:(NSEvent *)theEvent
{
    if ([theEvent clickCount] == 2){
		NSRect oFrame = [[self outputScrollView] frame];
		if (oFrame.size.height < 1.0){
			[self expandOutputToMinimumRatio:0.0]; //use value from user defaults
		}else{
			[self collapseOutput:nil];
		}
    }else{
		[super mouseDown:theEvent];
	}
}


@end
