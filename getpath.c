/*
 $Id: getpath.c,v 1.1 2002/09/15 04:45:20 sburrious Exp $

 FinkCommander
 
 Graphical user interface for Fink, a software package management system
 that automates the downloading, patching, compilation and installation of
 Unix software on Mac OS X.
 
 getpath.c is used to build the setuid root Launcher tool which runs 
 fink and apt-get commands, terminates those commands at the request of the user and
 writes changes to fink.conf.
 
 This program is free software; you may redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 
 Contact the author at sburrious@users.sourceforge.net.
 
 Change History (most recent first):
 11/14/09				Use _NSGetExecutablePath() only
 
 5/1/02		2.0d2		Improved the reliability of determining the path to the
						executable during self-repair.
                
 12/19/01	2.0d1		First release of self-repair version.
*/


#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <sys/param.h>
#include <stdlib.h>
#include <crt_externs.h>
#include <errno.h>
#include <mach-o/dyld.h>

int
MyGetExecutablePath(char *execPath, uint32_t *execPathSize)
{
	//	return ((NSGetExecutablePathProcPtr) NSAddressOfSymbol(NSLookupAndBindSymbol("__NSGetExecutablePath")))(execPath, execPathSize);
	return _NSGetExecutablePath(execPath, execPathSize);
}

char* getPathToMyself()
{
   uint32_t path_size = MAXPATHLEN;
   char* path = malloc(path_size);

   if (path && MyGetExecutablePath(path, &path_size) == -1)
   {
      /* Try again with actual size */
      path = realloc(path, path_size + 1);
      if (path && MyGetExecutablePath(path, &path_size) != 0)
      {
	 free(path);
	 path = NULL;
      }
   }
   return path;
}
