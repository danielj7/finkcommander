
#import <Cocoa/Cocoa.h>
#import "SBString.h"
#import "Debugging.h"

/*
 * Localized Strings Used In Multiple Files
 */
#define LS_CANCEL NSLocalizedString(@"Cancel", @"Cancel button title")
#define LS_ERROR NSLocalizedString(@"Error", @"Error dialog title")
#define LS_OK NSLocalizedString(@"OK", @"OK button title")
#define LS_REMOVE NSLocalizedString(@"Remove", @"Confirm remove button title")
#define LS_SORRY NSLocalizedString(@"Sorry", @"Dialog title")
#define LS_WARNING NSLocalizedString(@"Warning", @"Warning dialog title")

/*
 * Utility Functions
 */
extern BOOL openFileAtPath(NSString *);
extern void alertProblemPaths(NSArray *);

/*
 * Debugging Log
 */
#ifdef DEBUGGING
void Dprintf(NSString *fmt,...);
#else
inline void Dprintf(NSString *fmt,...);
#endif

