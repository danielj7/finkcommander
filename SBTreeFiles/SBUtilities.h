
#import <Cocoa/Cocoa.h>
#import "SBString.h"
#import "Debugging.h"


/*
 * Localized Strings Used In Multiple Files
 */
#define LS_CANCEL NSLocalizedStringFromTable(@"Cancel", @"SBTree", @"Cancel button title")
#define LS_ERROR NSLocalizedStringFromTable(@"Error", @"SBTree", @"Error dialog title")
#define LS_OK NSLocalizedStringFromTable(@"OK", @"SBTree", @"OK button title")
#define LS_REMOVE NSLocalizedStringFromTable(@"Remove", @"SBTree", @"Confirm remove button title")
#define LS_SORRY NSLocalizedStringFromTable(@"Sorry", @"SBTree", @"Dialog title")
#define LS_WARNING NSLocalizedStringFromTable(@"Warning", @"SBTree", @"Warning dialog title")

/*
 * Utility Functions
 */
extern BOOL openFileAtPath(NSString *);
extern void alertProblemPaths(NSArray *);

/*
 * Debugging Log
 */
#ifdef DEBUG
void Dprintf(NSString *fmt,...);
#else
inline void Dprintf(NSString *fmt,...);
#endif
