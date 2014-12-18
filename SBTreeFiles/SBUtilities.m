
#import "SBUtilities.h"

BOOL openFileAtPath(NSString *path)
{
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    BOOL successful, valid, isDir;

	Dprintf(@"Opening:\n %@", path);
    valid = [mgr fileExistsAtPath:path isDirectory:&isDir];
    if (! valid) return NO;
    if ([path contains:@".htm"]){
		NSURL *fileURL = [NSURL fileURLWithPath:path];
		successful = [ws openURL:fileURL];
    }else{
		successful = [ws openFile:path];
		if (! successful){
			successful = [ws openFile:path withApplication:@"TextEdit"];
		}
    }
    return successful;
}

void alertProblemPaths(NSArray *pathArray)
{
    if ([pathArray count] > 0){
		NSRunAlertPanel(LS_ERROR,
				  NSLocalizedStringFromTable(@"The following could not be opened:\n\n%@",
						@"SBTree", @"Error message for failure to open file(s)"),
				  @"OK", nil, nil,
				  [pathArray componentsJoinedByString:@" "]);
    }
}

#ifdef DEBUG
void Dprintf(NSString *fmt,...) {
    va_list ap;
    va_start(ap,fmt);
    NSLogv(fmt,ap);
}
#else
inline void Dprintf(NSString *fmt,...){}
#endif
