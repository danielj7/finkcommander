DESCRIPTION

This software provides a GUI frontend to the Fink package manager.  It allows the user to select a package or packages from a table and then to apply various Fink or apt-get commands by making a selection from a menu.  The output from the command is displayed asynchronously in a text view below the table.

Please note that this software is in the very earliest stages of development.  It could break your system or even present a security risk (see the TODO file).  If you're brave enough to try it, the author would very much appreciate your comments at:  

		sburr@mac.com.

The softwared comes in the form of a Project Builder file.  To run it, you will first need to build it with PB.  If the software breaks on your system, there will likely be some useful information in the text view under the "Build" tab.  If you have the opportunity, please send that information along with as many other details about the problem as you can think of to the author.


LICENSE

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

A copy of the GPL is included in this Project Builder file under "Documentation"
in "LICENSE.txt."


VERSION HISTORY

0.1.3	pending:
	First SourceForge release
	/sw no longer hard-coded as fink directory path; FC now searches for path, sets user defaults to reflect result and writes path into fpkg_list.pl script
	Added preferences panel:  
		set fink directory path manually, if search method doesnt work
		update table data with fink commands
	Window position now saved between sessions (easy)
	Table selection no longer disabled while command is running; no longer necessary for update
	Message text now signals when a full update of the package data is occurring

0.1.2	03/10/2002:
	Added table column showing whether package is unstable
	Password entry sheet now appears automatically the first time a command is attempted;
		also after invalid password alert is dismissed; basically an improved implementation of the password entry procedure in 0.1
	FC disables Source and Binary menus and table row selection while command is running
	Added Selfupdate-cvs to Source menu and Remove to Binary menu
	Removed commands from the Binary menu that do not appear useful; 
		users should let me know if I went too far!
	System beeps when command finishes
	Additional documentation:  DESIGN.txt

0.1.1	03/05/2002:
	Added explicit data encoding to methods sending text to standard input of NSTask; passing
		C string as data may have been cause of a reported user crash
	Simplified password entry procedures, another possible cause of the crash.  The current
		procedure is in any case a placeholder until I can figure out how to work
		in the Security Framework functions.
	Eliminated error-prone method for determining user's Fink directory, which may have 
		caused a reported failure of the table to load on one user's system.  If this
		software is ever distributed, this will probably need to be taken care of with
		a configuration script.	
	Added documentation (in this file).
	
	
0.1		03/03/2002: 
	Initial release, errors galore reported


KNOWN BUGS

Install of tcsh hangs when make calls "perl tcsh.man2html"
Binary Install command doesn't always work when dependencies need to be installed;
	as of 3/20/02 haven't encountered this in a while
Reported crash when download as part of install command failed; unable to reproduce
Reported doubling of table contents on sorting; unable to reproduce

