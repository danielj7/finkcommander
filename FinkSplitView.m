/*
File: FinkSplitView.m

 See the header file, FinkController.h, for interface and license information.

*/

#import "FinkSplitView.h"

@implementation FinkSplitView

-(id)initWithFrame:(NSRect)rect
{
	if (self = [super initWithFrame: rect]){
		defaults = [NSUserDefaults standardUserDefaults];
		//Register for notification that causes output to collapse when
		//user selects the auto expand option
		[self setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
		[self setIsPaneSplitter:YES];
		
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
	[super dealloc];
}

-(void)connectSubviews
{
	tableScrollView = [[self subviews] objectAtIndex:0];
	outputScrollView = [[self subviews] objectAtIndex:1];
}


-(void)collapseOutput:(NSNotification *)n
{
	if (! [self isSubviewCollapsed: outputScrollView]){
		NSRect oFrame = [outputScrollView frame];
		NSRect tFrame = [tableScrollView frame];
		NSRect sFrame = [self frame];
		float divwidth = [self dividerThickness];

		[defaults setFloat: (oFrame.size.height / sFrame.size.height)
								   forKey: FinkOutputViewRatio];
		tFrame.size.height = sFrame.size.height - divwidth;
		oFrame.size.height = 0.0;
		oFrame.origin.y = sFrame.size.height;

		[outputScrollView setFrame: oFrame];
		[tableScrollView setFrame: tFrame];

		[self setNeedsDisplay: YES];
	}
}

-(void)expandOutput
{
	NSRect oFrame = [outputScrollView frame];
	NSRect tFrame = [tableScrollView frame];
	NSRect sFrame = [self frame];
	float divwidth = [self dividerThickness];

	oFrame.size.height = ceil(sFrame.size.height * [defaults floatForKey: FinkOutputViewRatio]);
	tFrame.size.height = sFrame.size.height - oFrame.size.height - divwidth;
	oFrame.origin.y = tFrame.size.height + divwidth;

	[outputScrollView setFrame: oFrame];
	[tableScrollView setFrame: tFrame];

	[self setNeedsDisplay: YES];
}


-(void)mouseDown:(NSEvent *)theEvent
{
    if ([theEvent clickCount] == 2){
		if ([self isSubviewCollapsed:outputScrollView]){
			[self expandOutput];
		}else{
			[self collapseOutput:nil];
		}
    }else{
		[super mouseDown:theEvent];
	}
}

@end
