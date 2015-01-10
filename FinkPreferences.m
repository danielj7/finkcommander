/*
File: FinkPreferences.m

 See the header file, FinkPreferences.h, for interface and license information.

*/

#import "FinkPreferences.h"

/* Radio button tags */
typedef NS_ENUM(NSInteger, FinkDownloaderType) {
	CURL,
	WGET,
	AXEL
};

/* Text field tags */
typedef NS_ENUM(NSInteger, FinkPreferenceFieldType) {
	HTTP_PROXY = 1,
	FTP_PROXY = 2,
	FETCH_ALT_DIR = 3,
	OUTPUT_PATH = 4,
	ENVIRONMENT_SETTING = 5,
	PERL_PATH = 6,
	FINK_BASEPATH = 7
};

@interface FinkPreferences ()
{
    @protected
    BOOL _pathChoiceChanged;
    BOOL _autoExpandChanged;
    BOOL _finkConfChanged;
}

@property (nonatomic, readonly) NSUserDefaults *defaults;
@property (nonatomic, readonly, copy) FinkConf *conf;
@property (nonatomic, readonly, copy) NSMutableArray *environmentArray;

@end

@implementation FinkPreferences

//--------------------------------------------------------------------------------
#pragma mark - STARTUP AND SHUTDOWN
//--------------------------------------------------------------------------------

-(instancetype)init
{
	self = [super initWithWindowNibName:@"Preferences"];
	if (nil != self){
		_defaults = [NSUserDefaults standardUserDefaults];
		_conf = [[FinkConf alloc] init];  //Object representing the user's fink.conf settings
		[self setWindowFrameAutosaveName: @"Preferences"];
		_environmentArray = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)awakeFromNib
{
	//This is a bit anachronistic
	if ([[self conf] extendedVerboseOptions]){
		[[self verboseOutputPopupButton] insertItemWithTitle:NSLocalizedString(@"Low", @"Verbosity level for Fink") atIndex:1];
		[[self verboseOutputPopupButton] insertItemWithTitle:NSLocalizedString(@"Medium", @"Verbosity level for Fink") atIndex:2];
	}
	[[self environmentTableView] setAutosaveName: @"FinkEnvironmentTableView"];
	[[self environmentTableView] setAutosaveTableColumns: YES];
}


//--------------------------------------------------------------------------------
#pragma mark - GENERAL HELPERS
//--------------------------------------------------------------------------------

/* 	Transform environment settings in defaults into series of 
	two-item dictionaries (name/value) and place them in environmentArray */
-(void)readEnvironmentDefaultsIntoArray
{
	NSDictionary *environmentSettings = [[self defaults] objectForKey:FinkEnvironmentSettings];
	NSEnumerator *e = [environmentSettings keyEnumerator];
	NSString *name;
	NSMutableDictionary *setting;
	
	[[self environmentArray] removeAllObjects];
	while (nil != (name = [e nextObject])){
		setting = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				name, @"name", environmentSettings[name], @"value", nil];
		[[self environmentArray] addObject:setting];
	}
}

-(void)addEnvironmentKey:(NSString *)name
	value:(NSString *)value
{
	NSMutableDictionary *newSetting = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		name, @"name", value, @"value", nil];
	NSMutableDictionary *setting;
	NSString *key;
	NSUInteger i, limit = [[self environmentArray] count];

	//Make sure we have no duplicate keys
	for (i=0; i<limit; i++){
		setting = [self environmentArray][i];
		key = setting[@"name"];
		if ([key isEqualToString:name]){
			Dprintf(@"Found setting for %@", name);
			[[self environmentArray] removeObjectAtIndex:i];
			break;
		}
	}
	
	[[self environmentArray] addObject:newSetting];
	[[self environmentTableView] reloadData];
}

/* 	Aggregate the dictionaries in environmentArray into a single dictionary and
	write it to defaults */
-(void)writeEnvironmentArrayIntoDefaults
{
	NSMutableDictionary *environmentSettings = [NSMutableDictionary dictionaryWithCapacity:
													[[self environmentArray] count]];
	NSDictionary *newSettings;
	NSString *name, *value;
	
	for (NSMutableDictionary *setting in [self environmentArray]){
		name = setting[@"name"];
		value = setting[@"value"];
		environmentSettings[name] = value;
	}
	newSettings = [environmentSettings copy];
	[[self defaults] setObject:newSettings forKey:FinkEnvironmentSettings];
}

-(void)validateEnvironmentButtons
{
	//Enable Add button only if both key and value fields have content
	BOOL addEnabled = [[[self nameTextField] stringValue] length] > 0 &&    
						 [[[self valueTextField] stringValue] length] > 0;
	//Enable Delete button whenever a row is selected
	BOOL deleteEnabled = [[self environmentTableView] numberOfSelectedRows] > 0;
	
	[[self addEnvironmentSettingButton] setEnabled:addEnabled];
	[[self deleteEnvironmentSettingButton] setEnabled:deleteEnabled];
}


//Set preferences to reflect existing defaults and fink.conf settings.
//Used on startup and by cancel button.
-(void)resetPreferences
{
	NSString *httpProxy;
	NSString *ftpProxy;
	NSString *fetchAltDir;
	NSString *downloadMethod;
	NSString *basePath;
	NSString *outputPath;
	NSInteger scrollBackLimit;
	
	Dprintf(@"Resetting preferences");
	
	/***  FinkCommander Preferences ***/

	//Commander Tab
	[[self warnBeforeRemovingButton] setState: [[self defaults] boolForKey: FinkWarnBeforeRemoving]];
	[[self warnBeforeTerminatingButton] setState: [[self defaults] boolForKey: FinkWarnBeforeTerminating]];
	[[self alwaysChooseDefaultsButton] setState: [[self defaults] boolForKey: FinkAlwaysChooseDefaults]];
	[[self giveEmailCreditButton] setState: [[self defaults] boolForKey: FinkGiveEmailCredit]];
	
	//Paths Tab
	_pathChoiceChanged = NO;
	basePath = [[self defaults] objectForKey: FinkBasePath];
	if ([basePath isEqualToString: @"/sw"]){
		[[self pathChoiceMatrix] selectCellWithTag: 0];
		[[self basePathTextField] setStringValue: @""];
	}else{
		[[self pathChoiceMatrix] selectCellWithTag: 1];
		[[self basePathTextField] setStringValue: basePath];
	}
	outputPath = [[self defaults] objectForKey: FinkOutputPath];
	[[self outputPathButton] setState: [outputPath length] > 0];
	[[self outputPathTextField] setStringValue: outputPath];
	[[self perlPathTextField] setStringValue:[[self defaults] objectForKey:FinkPerlPath]];
		
	//Display Tab
	_autoExpandChanged = NO;
	[[self scrollToBottomButton] setState: [[self defaults] boolForKey: FinkAlwaysScrollToBottom]];
	[[self showPackagesInTitleButton] setState: [[self defaults] boolForKey: FinkPackagesInTitleBar]];
	[[self autoExpandOutputButton] setState: [[self defaults] boolForKey: FinkAutoExpandOutput]];
	[[self scrollToSelectionButton] setState: [[self defaults] boolForKey: FinkScrollToSelection]];
	[[self allowRegexFilterButton] setState: [[self defaults] boolForKey: FinkAllowRegexFiltering]];

	[[self showRedundantPackagesButton] setState: [[self defaults] boolForKey: FinkShowRedundantPackages]];	
	[self setTitleBarImage: self];  //action method
	scrollBackLimit = [[self defaults] integerForKey:FinkBufferLimit];
	[[self scrollBackLimitButton] setState: scrollBackLimit];
	if (scrollBackLimit){
		[[self scrollBackLimitTextField] setIntegerValue: scrollBackLimit];
	}
	
	/***  Fink Settings in fink.conf ***/

	_finkConfChanged = NO;
	
	//Fink Tab
	[[self useUnstableMainButton] setState: [[self conf] useUnstableMain]];
	[[self useUnstableCryptoButton] setState: [[self conf] useUnstableCrypto]];
	[[self verboseOutputPopupButton] selectItemAtIndex:[[self conf] verboseOutput]];
	if ([[[self conf] rootMethod] isEqualToString: @"sudo"]){
		[[self rootMethodMatrix] selectCellWithTag: 0];
	}else{
		[[self rootMethodMatrix] selectCellWithTag: 1];
	}
	fetchAltDir = [[self conf] fetchAltDir];
	[[self fetchAltDirButton] setState: (fetchAltDir != nil ? YES : NO)];
	[[self fetchAltDirTextField] setStringValue: (fetchAltDir != nil ? fetchAltDir : @"")];
	
	//Download Tab
	[[self passiveFTPButton] setState: [[self conf] passiveFTP]];

	httpProxy = [[self conf] useHTTPProxy];
	[[self httpProxyButton] setState: ([httpProxy length] > 0 ? YES : NO)];
	[[self httpProxyTextField] setStringValue: httpProxy];
	
	ftpProxy = [[self conf] useFTPProxy];
	[[self ftpProxyButton] setState: ([ftpProxy length] > 0 ? YES : NO)];
	[[self ftpProxyTextField] setStringValue: ftpProxy];

	downloadMethod = [[self conf] downloadMethod];
	if ([downloadMethod isEqualToString:@"curl"]){
		[[self downloadMethodMatrix] selectCellWithTag:0];
	}else if ([downloadMethod isEqualToString:@"wget"]){
		[[self downloadMethodMatrix] selectCellWithTag:1];
	}else{
		[[self downloadMethodMatrix] selectCellWithTag:2];
	}

	/***  Environment Tab  ***/
	
	[self readEnvironmentDefaultsIntoArray];
	[[self environmentTableView] reloadData];

	//software update tab
	[[self automaticallyCheckUpdatesButton] setState: [[self defaults] boolForKey: FinkCheckForNewVersion]];
}

//--------------------------------------------------------------------------------
#pragma mark - ACTION HELPERS
//--------------------------------------------------------------------------------

/*** FinkCommander Settings ***/

-(void)setBasePath
{
	if ([[[self pathChoiceMatrix] selectedCell] tag] == 0){
		[[self defaults] setObject: @"/sw" forKey: FinkBasePath];
	}else{
		[[self defaults] setObject: [[self basePathTextField] stringValue] forKey: FinkBasePath];
	}
}

-(void)setScrollBackLimit
{
	int scrollBackLimit = [[self scrollBackLimitButton] state] == NSOnState ?
							[[self scrollBackLimitTextField] intValue] : 0;
							
	[[self defaults] setInteger:scrollBackLimit forKey:FinkBufferLimit];
}

/*** Fink Settings in fink.conf ***/

-(void)setRootMethod
{
	if ([[[self rootMethodMatrix] selectedCell] tag] == 0){
		[[self conf] setRootMethod: @"sudo"];
	}else{
		[[self conf] setRootMethod: @"su"];
	}
}

-(void)setFetchAltDir
{
	if ([[self fetchAltDirButton] state] == NSOnState){
		[[self conf] setFetchAltDir: [[self fetchAltDirTextField] stringValue]];
	}else{
		[[self conf] setFetchAltDir: nil];
	}
}

-(void)setDownloadMethod
{
	switch ((FinkDownloaderType)[[[self downloadMethodMatrix] selectedCell] tag]){
		case CURL: 
			[[self conf] setDownloadMethod:@"curl"];
			break;
		case WGET:
			[[self conf] setDownloadMethod: @"wget"];
			break;
		case AXEL:
			[[self conf] setDownloadMethod: @"axel"];
			break;
	}
}

-(void)setHTTPProxyVariable
{
	if ([[self httpProxyButton] state] == NSOnState){
		NSString *proxy = [[self httpProxyTextField] stringValue];
		[[self conf] setUseHTTPProxy: proxy];
	}else{
		[[self conf] setUseHTTPProxy: nil];
	}
}

-(void)setFTPProxyVariable
{
	if ([[self ftpProxyButton] state] == NSOnState){
		NSString *proxy = [[self ftpProxyTextField] stringValue];
		[[self conf] setUseFTPProxy:proxy];
	}else{
		[[self conf] setUseFTPProxy: nil];
	}
}

//--------------------------------------------------------------------------------
#pragma mark - ACTIONS
//--------------------------------------------------------------------------------

//Apply button
-(IBAction)setPreferences:(id)sender
{
	/*** FinkCommander Preferences ***/

	//Commander Tab
	[[self defaults] setBool: (BOOL)[[self alwaysChooseDefaultsButton] state] 	forKey: FinkAlwaysChooseDefaults];
	[[self defaults] setBool: (BOOL)[[self warnBeforeRemovingButton] state]	 	forKey: FinkWarnBeforeRemoving];
	[[self defaults] setBool: (BOOL)[[self warnBeforeTerminatingButton] state]	forKey: FinkWarnBeforeTerminating];
	[[self defaults] setBool: (BOOL)[[self giveEmailCreditButton] state]		forKey: FinkGiveEmailCredit];
	[[self defaults] setBool: (BOOL)[[self allowRegexFilterButton] state] 	forKey: FinkAllowRegexFiltering];

	//Paths Tab
	[self setBasePath];
	[[self defaults] setObject:[[self outputPathTextField] stringValue] forKey: FinkOutputPath];
	[[self defaults] setObject:[[self perlPathTextField] stringValue] forKey:FinkPerlPath];
		//Give manually set path a chance to work on startup
	if (_pathChoiceChanged){
		[[self defaults] setBool:YES forKey:FinkBasePathFound];
		fixScript();
	}
	
	//Display Tab
	[self setScrollBackLimit];
	[[self defaults] setBool: (BOOL)[[self scrollToSelectionButton] state] 		forKey: FinkScrollToSelection];
	[[self defaults] setBool: (BOOL)[[self scrollToBottomButton] state] 		forKey: FinkAlwaysScrollToBottom];
	[[self defaults] setBool: (BOOL)[[self showPackagesInTitleButton] state] 	forKey: FinkPackagesInTitleBar];
	[[self defaults] setBool: (BOOL)[[self autoExpandOutputButton] state] 		forKey: FinkAutoExpandOutput];
	[[self defaults] setBool: (BOOL)[[self showRedundantPackagesButton] state] 	forKey: FinkShowRedundantPackages];
		//Notify FinkController to collapse output if user chose to
		//automatically expand and collapse
	if (_autoExpandChanged && [[self autoExpandOutputButton] state]){
		[[NSNotificationCenter defaultCenter]
			postNotificationName:FinkCollapseOutputView
						  object:nil];
	}
	
	//Environment Tab
	[self writeEnvironmentArrayIntoDefaults];

	//software update tab
	[[self defaults] setBool: (BOOL)[[self automaticallyCheckUpdatesButton] state] forKey: FinkCheckForNewVersion];

	/***  Fink Settings in fink.conf ***/
	
	if (_finkConfChanged){
		//Set to yes whenever user selects a button or changes a field in the Fink or
		//Downloads tabs

		//Fink Tab
		[[self conf] setUseUnstableCrypto: (BOOL)[[self useUnstableCryptoButton] state]];
		[[self conf] setUseUnstableMain: (BOOL)[[self useUnstableMainButton] state]];
		[[self conf] setVerboseOutput: [[self verboseOutputPopupButton] indexOfSelectedItem]];
		[[self conf] setKeepBuildDir: (BOOL)[[self keepBuildDirectoryButton] state]];
		[[self conf] setKeepRootDir: (BOOL)[[self keepRootDirectoryButton] state]];
		[self setRootMethod];

		//Download Tab
		[self setDownloadMethod];
		[[self conf] setPassiveFTP: (BOOL)[[self passiveFTPButton] state]];
		[self setHTTPProxyVariable];
		[self setFTPProxyVariable];
		[self setFetchAltDir];

		_finkConfChanged = NO;
		[[self conf] writeToFile];
	}
}

//OK Button
-(IBAction)setAndClose:(id)sender
{
	[self setPreferences:nil];
	[self close];
}

//Cancel Button
-(IBAction)cancel:(id)sender
{
	[self resetPreferences];
	[self close];
}

/*** Flags ***/

//Connected to path-to-fink matrix
-(IBAction)setPathChoiceChanged:(id)sender
{
	_pathChoiceChanged = YES;
}

//Connected to all buttons in fink.conf tabs
-(IBAction)setFinkConfChanged:(id)sender
{
	_finkConfChanged = YES;
}

//Connected to use unstable and use unstable crypto buttons
-(IBAction)setFinkTreesChanged:(id)sender
{
	_finkConfChanged = YES;
	[[self conf] setFinkTreesChanged: YES];
}

/*** Display Tab Buttons ***/

//Change image of title bar in preference panel to reflect user's choice
-(IBAction)setTitleBarImage:(id)sender
{
	if ([[self showPackagesInTitleButton] state]){
		[[self titleBarImageView] setImage: [NSImage imageNamed: @"number"]];
	}else{
		[[self titleBarImageView] setImage: [NSImage imageNamed: @"title"]];
	}
}

-(IBAction)setAutoExpandChanged:(id)sender
{
	//Determines whether a notification to collapse the output view
	//is sent to FinkSplitView
	_autoExpandChanged = YES;
}

/*** Dialog Opened by Browse Buttons ***/

-(IBAction)selectDirectory:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	NSString *directory = NSHomeDirectory();
	NSTextField *pathField = nil;

	switch([sender tag]){
		case FINK_BASEPATH: 
			pathField = [self basePathTextField];
			directory = @"/usr";
			break;
		case FETCH_ALT_DIR:
			pathField = [self fetchAltDirTextField];
			break;
		case OUTPUT_PATH:
			pathField = [self outputPathTextField];
			break;
		case PERL_PATH:
			pathField = [self perlPathTextField];
			directory = @"/usr";
			break;
	}
	
	[panel setCanChooseDirectories: YES];
	[panel setCanChooseFiles: NO];
	[panel setAllowsMultipleSelection: NO];
	[panel setPrompt: NSLocalizedString(@"Choose", @"Title for panel asking user to choose a directory")];
    [panel setDirectoryURL:[NSURL fileURLWithPath:directory isDirectory:YES]];
    
    [panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString *path = [[panel URLs][0] path];
            Dprintf(@"Path chosen: %@", path);
            [pathField setStringValue:path];
            Dprintf(@"Text field value: %@", [pathField stringValue]);
            
            //FinkPreferences is registered for this notification to make
            //sure buttons associated with text fields accurately reflect the
            //fields' state
            [[NSNotificationCenter defaultCenter]
             postNotificationName: NSControlTextDidChangeNotification
             object: pathField];
            
            Dprintf(@"Text field value after notification: %@", [pathField stringValue]);
        }
    }];
}
	
/*** Environment Tab Buttons ***/

-(IBAction)addEnvironmentSetting:(id)sender
{
	NSString *name = [[self nameTextField] stringValue];
	NSString *value = [[self valueTextField] stringValue];
	[self addEnvironmentKey:name value:value];
	[[self nameTextField] setStringValue:@""];
	[[self valueTextField] setStringValue:@""];
	[self validateEnvironmentButtons];	
}

-(IBAction)removeEnvironmentSettings:(id)sender
{
    [[[self environmentTableView] selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        [[self environmentArray] removeObjectAtIndex:idx];
    }];
	[[self environmentTableView] reloadData];
	[self validateEnvironmentButtons];
}

-(IBAction)restoreEnvironmentSettings:(id)sender
{
	setInitialEnvironmentVariables();
	[self readEnvironmentDefaultsIntoArray];
	[[self environmentTableView] reloadData];	
	[self validateEnvironmentButtons];
}

//--------------------------------------------------------------------------------
#pragma mark - DELEGATE METHODS
//--------------------------------------------------------------------------------

-(void)windowDidLoad
{
	[self resetPreferences];
	[self validateEnvironmentButtons];
}

//NSTextField delegate method; automatically set button state to match text input
-(void)controlTextDidChange:(NSNotification *)aNotification
{
	NSTextField *tField = [aNotification object];
	FinkPreferenceFieldType textFieldID = [tField tag];
	NSString *tfString = [tField stringValue];

	//Select the button that corresponds to the altered text field.
	//The text fields were given the indicated tag numbers in IB.
	switch(textFieldID){
		case FINK_BASEPATH:
			[[self pathChoiceMatrix] selectCellWithTag:
				([tfString length] > 0 ? 1 : 0)]; //0 == default
			break;
		case HTTP_PROXY:
			[[self httpProxyButton] setState: 
				([[[self httpProxyTextField] stringValue] length] > 0 ? YES : NO)];
			_finkConfChanged = YES;
			break;
		case FTP_PROXY:
			[[self ftpProxyButton] setState:
				([[[self ftpProxyTextField] stringValue] length] > 0 ? YES : NO)];
			_finkConfChanged = YES;
			break;
		case FETCH_ALT_DIR:
			[[self fetchAltDirButton] setState:
				([[[self fetchAltDirTextField] stringValue] length] > 0 ? YES : NO)];
			_finkConfChanged = YES;
			break;
		case OUTPUT_PATH:
			[[self outputPathButton] setState:
				([tfString length] > 0 ? YES : NO)];
			break;
		case ENVIRONMENT_SETTING:
			[self validateEnvironmentButtons];
			break;
        case PERL_PATH:
		default:
			break;
	}
}


//Environment table view delegate
-(void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[self validateEnvironmentButtons];
}


//--------------------------------------------------------------------------------
#pragma mark - ENVIRONMENT TABLE DATA SOURCE METHODS
//--------------------------------------------------------------------------------

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[self environmentArray] count];
}

-(id)tableView:(NSTableView *)aTableView
	objectValueForTableColumn:(NSTableColumn *)aTableColumn
	row:(NSInteger)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	return [self environmentArray][rowIndex][identifier];
}

-(void)tableView:(NSTableView *)aTableView 
		setObjectValue:(id)anObject 
		forTableColumn:(NSTableColumn *)aTableColumn 
		row:(NSInteger)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	[self environmentArray][rowIndex][identifier] = anObject;
}

-(IBAction)checkNow:(id)sender
{
	[[NSNotificationCenter defaultCenter]
		postNotificationName:CheckForUpdate
		object:nil];
}
@end
