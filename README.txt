DESCRIPTION

This software provides a GUI frontend to the Fink package manager.  Using it should be fairly intuitive, but basic usage instructions are provided below.

Please note that this software is still in the early stages of development.  It could break your system or even present a security risk (see NOTE ON SECURITY below).  

If you're brave enough to try FinkCommander, the author would very much appreciate your comments at:  

		sburrious@users.sourceforge.net.
		
If you encounter bugs, it would be very helpful to have them reported at the SourceForge Bug Tracker for FinkCommander:  http://sourceforge.net/tracker/?group_id=48896&atid=454467.  
There are instructions for using the Bug Tracker system at: http://sourceforge.net/docman/display_doc.php?docid=791&group_id=1

Unfortunately, I will not be able to provide direct support for FinkCommander.  Software development is my hobby.  I have a pretty demanding "day job," so responding directly to every request for help is just not in the cards.  
		
The source distribution of this software comes in the form of a Project Builder file.  To run it, you will first need to build it with Project Builder from the December 2001 release of Apple's Developer Tools.  


LICENSE

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

A copy of the GPL is included in the file "LICENSE.txt" in the same directory (folder) as this README.

If you have downloaded the binary version of this software but would like the source, it's available at http://sourceforge.net/project/showfiles.php?group_id=48896
I would encourage you to download and tinker with the source code.  


NOTE ON SECURITY

FinkCommander does not yet use Apple's Security Framework to authorize commands requiring administrator privileges.  Instead, it asks you to enter your password in a text field and then passes it along to the sudo command.  This means that YOU ARE GIVING YOUR PASSWORD TO FINKCOMMANDER!  If I were in your shoes, I would think twice about this.  If FinkCommander were evil software, it could use the password do real mischief to your system.

The one protection you have against misuse is that FinkCommander is open source software.  I would encourage you to obtain and look at the source code to see what the program is doing with your password.

FinkCommander should use the Security Framework, which would use the OS X security server to authorize the command without Fink ever seeing it.  I'm working on that, but it's hard (at least for me), and this is the best I could come up with in the meantime.


USAGE

At the risk of stating the obvious, select a package or packages from the table.  (To select more than one, use command or shift click.)   Choose the Fink or apt-get command you want to apply to the package by making a selection from the appropriate menu ("Source" for Fink commands, "Binary" for apt-get).  

The output from the command is displayed asynchronously in a text view below the table, just as it would appear if you were to run the command in the Terminal.

Unless you choose the option to accept all default responses, FinkCommander will display a sheet asking for your input whenever it encounters a request for input from Fink.  See the KNOWN BUGS section below for a problem with the default response option.

You can sort the table by clicking column headers.  Click the same column header twice to reverse sort.

New in 0.1.4:  FinkCommander now has a toolbar, primarily because it was the most logical place to put the new incremental table data filter.  To use the filter, choose the field that you want filter applied to in the popup menu; then start typing in the text field.  After each character addition or deletion, the table will be updated to reflect the filter.

After some commands FinkCommander attempts to update the data in the table manually.  The method for doing this is currently pretty inaccurate.  The trade-off is that it's a lot faster than the Fink updating routine (but that may change soon).  If you want to make sure the table data is accurate, select Update table from the File menu or choose the Always update with Fink option in Preferences.


KNOWN BUGS

User input is occasionally required, even if the accept-Fink-defaults option is selected; this stalls the process, requiring the user to quit and re-run the command after deselecting the option.

The table sometimes becomes unresponsive after a command is finished.  This seems to be related to the filter.  Resizing the split view appears to bring the table back to life.

FinkCommander's error detector sometimes generates false positives.

Install of tcsh hangs when make calls "perl tcsh.man2html".  Again, this requires the user to quit and restart FinkCommander.  I intend to add an option to terminate a hanging command to a future release.


VERSION HISTORY

0.1.4	pending:
	Added toolbar, which includes an incremental filter
	Added warning when user attempts to quit Fink while a command is still running
	Full table update performed after error message detected

0.1.3	04/05/2002:
	First SourceForge release.
	/sw no longer hard-coded as fink directory path; FC now searches for path, sets user defaults to reflect result and writes path into fpkg_list.pl script.
	Interaction with Fink prompts enabled through sheet dialog that appears whenever input is needed.
	Password only entered when needed.
	Added preferences panel:
		accept Fink defaults automatically when running commands; 
		set fink directory path manually, if search method doesn't work;
		always update table data with fink commands;
		scroll to last selection after sort.
	Window position and table column states now saved between sessions.
	Table selection no longer disabled while command is running; no longer necessary for update.
	Message text now signals when a full update of the package data is occurring.
	The table now resorts after a full update of the package data.
	FinkCommander now has its own icon!  Since I'm no artist, it's ugly, but at least it makes identifying FinkCommander easier than the generic application icon.

0.1.2	03/10/2002:
	Added table column showing whether package is unstable.
	Password entry sheet now appears automatically the first time a command is attempted;
		also after invalid password alert is dismissed; basically an improved implementation of the password entry procedure in 0.1.
	FC disables Source and Binary menus and table row selection while command is running.
	Added Selfupdate-cvs to Source menu and Remove to Binary menu.
	Removed commands from the Binary menu that do not appear useful; 
		users should let me know if I went too far!
	System beeps when command finishes.  (Woo woo!)
	Additional documentation:  DESIGN.txt.

0.1.1	03/05/2002:
	Added explicit data encoding to methods sending text to standard input of NSTask; passing
		C string as data may have been cause of a reported user crash.
	Simplified password entry procedures, another possible cause of the crash.  The current
		procedure is in any case a placeholder until I can figure out how to work
		in the Security Framework functions.
	Eliminated error-prone method for determining user's Fink directory, which may have 
		caused a reported failure of the table to load on one user's system.  
	Added documentation (in this file).
	
	
0.1		03/03/2002: 
	Initial release, errors galore reported.
