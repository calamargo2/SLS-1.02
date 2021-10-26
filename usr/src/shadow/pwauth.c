/*
 * Copyright 1992, John F. Haugh II
 * All rights reserved.
 *
 * Permission is granted to copy and create derivative works for any
 * non-commercial purpose, provided this copyright notice is preserved
 * in all copies of source code, or included in human readable form
 * and conspicuously displayed on all copies of object code or
 * distribution media.
 *
 * This software is provided on an AS-IS basis and the author makes
 * not warrantee of any kind.
 */

#include <signal.h>
#include <fcntl.h>
#include "config.h"
#include "pwauth.h"

#ifndef	lint
static	char	sccsid[] = "@(#)pwauth.c	3.3	10:52:13	10/10/92";
#endif

/*
 * pw_auth - perform alternate password authentication
 *
 *	pw_auth executes the alternate password authentication method
 *	described in the user's password entry.  _pw_auth does the real
 *	work, pw_auth splits the authentication string into individual
 *	command names.
 */

static int
_pw_auth (command, user, reason, input)
char	*command;
char	*user;
int	reason;
char	*input;
{
	SIGTYPE (*sigint)();
	SIGTYPE (*sigquit)();
#ifdef	SIGTSTP
	SIGTYPE	(*sigtstp)();
#endif
	int	pid;
	int	status;
	int	i;
	char	*argv[5];
	int	argc = 0;
	int	pipes[2];

	/*
	 * Start with a quick sanity check.  ALL command names must
	 * be fully-qualified path names.
	 */

	if (command[0] != '/')
		return -1;

	/*
	 * Set the keyboard signals to be ignored.  When the user kills
	 * the child we don't want the parent dying as well.
	 */

	sigint = signal (SIGINT, SIG_IGN);
	sigquit = signal (SIGQUIT, SIG_IGN);
#ifdef	SIGTSTP
	sigtstp = signal (SIGTSTP, SIG_IGN);
#endif

	/* 
	 * FTP and REXEC reasons don't give the program direct access
	 * to the user.  This means that the program can only get input
	 * from this function.  So we set up a pipe for that purpose.
	 */

	if (reason == PW_FTP || reason == PW_REXEC)
		if (pipe (pipes))
			return -1;

	/*
	 * The program will be forked off with the parent process waiting
	 * on the child to tell it how successful it was.
	 */

	switch (pid = fork ()) {

		/*
		 * The fork() failed completely.  Clean up as needed and
		 * return to the caller.
		 */

		case -1:
			if (reason == PW_FTP || reason == PW_REXEC) {
				close (pipes[0]);
				close (pipes[1]);
			}
			return -1;
		case 0:

			/*
			 * Let the child catch the SIGINT and SIGQUIT
			 * signals.  The parent, however, will continue
			 * to ignore them.
			 */

			signal (SIGINT, SIG_DFL);
			signal (SIGQUIT, SIG_DFL);

			/*
			 * Set up the command line.  The first argument is
			 * the name of the command being executed.  The
			 * second is the command line option for the reason,
			 * and the third is the user name.
			 */

			argv[argc++] = command;
			switch (reason) {
				case PW_SU:	argv[argc++] = "-s"; break;
				case PW_LOGIN:	argv[argc++] = "-l"; break;
				case PW_ADD:	argv[argc++] = "-a"; break;
				case PW_CHANGE:	argv[argc++] = "-c"; break;
				case PW_DELETE:	argv[argc++] = "-d"; break;
				case PW_TELNET:	argv[argc++] = "-t"; break;
				case PW_RLOGIN:	argv[argc++] = "-r"; break;
				case PW_FTP:	argv[argc++] = "-f"; break;
				case PW_REXEC:	argv[argc++] = "-x"; break;
			}
			argv[argc++] = user;
			argv[argc] = (char *) 0;

			/*
			 * The FTP and REXEC reasons use a pipe to communicate
			 * with the parent.  The other standard I/O descriptors
			 * are closed and re-opened as /dev/null.
			 */

			if (reason == PW_FTP || reason == PW_REXEC) {
				close (0);
				close (1);
				close (2);

				if (dup (pipes[0]) != 0)
					exit (1);

				close (pipes[0]);
				close (pipes[1]);

				if (open ("/dev/null", O_WRONLY) != 1)
					exit (1);

				if (open ("/dev/null", O_WRONLY) != 2)
					exit (1);
			}

			/*
			 * Now we execute the command directly.
			 */

			execv (command, argv);
			_exit (255);

			/*NOTREACHED*/
		default:

			/* 
			 * FTP and REXEC cause a single line of text to be
			 * sent to the child over a pipe that was set up
			 * earlier.
			 */

			if (reason == PW_FTP || reason == PW_REXEC) {
				close (pipes[0]);

				if (input)
					write (pipes[1], input, strlen (input));

				write (pipes[1], "\n", 1);
				close (pipes[1]);
			}

			/*
			 * Wait on the child to die.  When it does you will
			 * get the exit status and use that to determine if
			 * the authentication program was successful.
			 */

			while ((i = wait (&status)) != pid && i != -1)
				;

			/*
			 * Re-set the signals to their earlier values.
			 */

			signal (SIGINT, sigint);
			signal (SIGQUIT, sigquit);
#ifdef	SIGTSTP
			signal (SIGTSTP, sigtstp);
#endif

			/*
			 * Make sure we found the right process!
			 */

			if (i == -1)
				return -1;

			if (status == 0)
				return 0;
			else
				return -1;
	}
	/*NOTREACHED*/
}

/*
 * This function does the real work.  It splits the list of program names
 * up into individual programs and executes them one at a time.
 */

int
/*VARARGS3*/
pw_auth (command, user, reason, input)
char	*command;
char	*user;
int	reason;
char	*input;
{
	char	buf[256];
	char	*cmd, *end;
	int	rc;

	/* 
	 * Quick little sanity check ...
	 */

	if (strlen (command) >= sizeof buf)
		return -1;

	strcpy (buf, command);

	/*
	 * Find each command and make sure it is NUL-terminated.  Then
	 * invoke _pw_auth to actually run the program.  The first
	 * failing program ends the whole mess.
	 */

	for (cmd = buf;cmd;cmd = end) {
		if (end = strchr (cmd, ';'))
			*end++ = '\0';

		if (rc = _pw_auth (cmd, user, reason, input))
			return rc;
	}
	return 0;
}
