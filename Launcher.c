/*
 *  Launcher.c
 *  NMapFE
 *
 *  Created by David Love on Fri Jun 21 2002.
 *  Copyright (c) 2002 Cashmere Software, Inc. All rights reserved.
 *
 * $Id$
 */

#include "Launcher.h"

#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <sys/fcntl.h>
#include <sys/errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <mach-o/dyld.h>
#include <Security/Authorization.h>

static AuthorizationExternalForm extAuth;

// Read the incoming authorization and check to see if it's 
// alright.
//
bool readAuthorization(AuthorizationRef *auth)
{
    bool result = FALSE;

    if (read(0, &extAuth, sizeof(extAuth)) == sizeof(extAuth))
    {
        int err;
        err = AuthorizationCreateFromExternalForm(&extAuth, auth);
        result = err == errAuthorizationSuccess;
    }
    fflush(stdout);
    return result;
}


bool authorizedToExecute(AuthorizationRef *auth, const char* cmd)
{
    AuthorizationItem right = { cmd, 0, NULL, 0 } ;
    AuthorizationRights rights = { 1, &right };
    AuthorizationFlags flags =
        kAuthorizationFlagDefaults | kAuthorizationFlagExtendRights;
    bool result = getuid() == geteuid();

    if(! result)
    {
        result = AuthorizationCopyRights(*auth, &rights,
                                         kAuthorizationEmptyEnvironment,
                                         flags, NULL) == errAuthorizationSuccess;
    }
    return result;
}

int
perform(const char* cmd, char * const *argv)
{
   int status;
   int result = 1;
   int pid;

   pid = fork();
   if (pid == 0) 
   {
       /* If this is the child process, then try to exec cmd
        */
       if (execvp(cmd, argv) == -1)
       {
           fprintf(stderr, "Execution failed.  errno=%d (%s)\n", errno, strerror(errno));
       } 
   }
   else if (pid == -1)
   {
       fprintf(stderr, "fork() failed.  errno=%d (%s)", errno, strerror(errno));
   }
   else  {
       fflush(stderr);
       waitpid(pid,&status,0);
       if (WIFEXITED(status))
       {
           result = WEXITSTATUS(status);
       }
       else if (WIFSIGNALED(status))
       {
           result = WTERMSIG(status)+32;
       }
   }
   return result;
}


int repair_self()
{
   /*  Self repair code.  We ran ourselves using
       AuthorizationExecuteWithPrivileges() so we need to make
       ourselves setuid root to avoid the need for this the next time
       around. */

    AuthorizationRef auth;
    struct stat st;
    int fd_tool;
    int result = FALSE;

    char* path_to_self = getPathToMyself();
    if (path_to_self != NULL)
    {
        /* Recover the passed in AuthorizationRef. */
        if (AuthorizationCopyPrivilegedReference(&auth, kAuthorizationFlagDefaults)
            == errAuthorizationSuccess)
        {

            /* Open tool exclusively, so noone can change it while we bless it */
            fd_tool = open(path_to_self, O_NONBLOCK|O_RDONLY|O_EXLOCK, 0);

            if ((fd_tool != -1) && (fstat(fd_tool, &st) == 0))
            {
                if (st.st_uid != 0)
                    fchown(fd_tool, 0, st.st_gid);

                /* Disable group and world writability and make setuid root. */
                fchmod(fd_tool, (st.st_mode & (~(S_IWGRP|S_IWOTH))) | S_ISUID);

                close(fd_tool);
                fprintf(stderr, "Tool self-repair done.\n");
                result = TRUE;
            }
        }
        else
        {
            fprintf(stderr, "I need administrator permissions to fix the permissions on this application.\n");
        }
        free(path_to_self);
    }
    return result;
}


// This is take almost directly from Apple's example code and will
// attempt to reset the launcher's setuid permissions if necessary.
//
int launch_to_repair_self(AuthorizationRef* auth)
{
    int status;
    FILE *commPipe = NULL;
    char *arguments[] = { "--self-repair", NULL };
    int result = EXIT_FAILURE;

    char* path_to_self = getPathToMyself();
    if (path_to_self != NULL)
    {
        /* Set our own stdin and stdout to be the communication channel
        * with ourself. */

        fprintf(stderr, "Tool about to self-exec through AuthorizationExecuteWithPrivileges.\n");

        if (AuthorizationExecuteWithPrivileges(*auth, path_to_self, kAuthorizationFlagDefaults, arguments, &commPipe) == errAuthorizationSuccess)
        {
            /* Read from stdin and write to commPipe. */
            fwrite(&extAuth, 1, sizeof(extAuth),commPipe);
            /* Flush any remaining output. */
            fflush(commPipe);

            /* Close the communication pipe to let the child know we are done. */
            fclose(commPipe);

            /* Wait for the child of AuthorizationExecuteWithPrivileges to exit. */
            if (wait(&status) != -1 && WIFEXITED(status))
            {
                fprintf(stderr,"exited with  status %d, WEXITSTATUS(status) %d\n",status,WEXITSTATUS(status));
                result = WEXITSTATUS(status);
            }
        }
        free(path_to_self);
    }

    /* Exit with the same exit code as the child spawned by
        * AuthorizationExecuteWithPrivileges()
        */
    return result;

}


int
main(int argc, char * const *argv)
{
    AuthorizationRef auth;
    int result = 1;
    
    /* The caller *must* pass in a valid AuthorizationExternalForm structure on stdin
     * before they're allowed to go any further.
     */
    if (! readAuthorization(&auth))
    {
        fprintf(stderr,"Failed to read authorization from stdin\n");
        exit(1);
    }
    
    if (argc == 2 && 0 == strcmp(argv[1], "--self-repair"))
    {
        result = repair_self();
    }
	else if (argc == 3 && 0 == strcmp(argv[1], "--kill"))
	{
		pid_t pid = (pid_t)strtol(argv[2], nil, 10);
		fprintf(stdout, "Killing process %s", argv[2]);
		result = killpg(pid, SIGKILL);
	}
    else 
    {
        /* If the effective uid isn't root's (0), then we need to reset 
         * the setuid bit on the executable, if possible.
         */
        if (geteuid() != 0)
        {
            launch_to_repair_self(&auth);
        }
		else
        {
            setuid(geteuid());
        }
		
        if (! authorizedToExecute(&auth, argv[1]))
        {
            /* If the caller isn't authorized to run as root, then reset
             * the effective uid before spawning nmap
             */
            seteuid(getuid());
        }
        /* Run the command. */
        result = perform(argv[1], &argv[1]);
    }

    exit(result);
}


