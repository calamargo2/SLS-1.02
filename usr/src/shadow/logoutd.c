/*
 * Copyright 1991, 1992, John F. Haugh II
 * All rights reserved.
 *
 * Permission is granted to copy and create derivative works for any
 * non-commercial purpose, provided this copyright notice is preserved
 * in all copies of source code, or included in human readable form
 * and conspicuously displayed on all copies of object code or
 * distribution media.
 *
 * This software is provided on an AS-IS basis and the author makes
 * no warrantee of any kind.
 */

#ifndef lint
static	char	sccsid[] = "@(#)logoutd.c	3.4	13:02:38	7/27/92";
#endif

#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <signal.h>
#include <utmp.h>
#include <fcntl.h>
#include "config.h"

#define	HUP_MESG_FILE	"/etc/logoutd.mesg"

#ifndef	UTMP_FILE
#define	UTMP_FILE	"/etc/utmp"
#endif

#ifdef	SVR4
#include <libgen.h>
#include <unistd.h>
#else
#define	basename(s) (strrchr(s, '/') ? strrchr (s, '/') + 1 : s)
#define	SEEK_SET	0
#endif

#ifdef	USE_SYSLOG
#include <syslog.h>

#ifndef	LOG_WARN
#define	LOG_WARN	LOG_WARNING
#endif
#endif

#ifdef	SVR4
#define	signal	sigset
#endif

#ifdef	HUP_MESG_FILE
int	mesg_len;
int	mesg_size;
char	*mesg_buf;

/*
 * reload_mesg - reload the message that is output when killing a process
 */

void
reload_mesg (sig)
int	sig;
{
	int	fd;
	struct	stat	sb;

	signal (SIGHUP, reload_mesg);

	if (stat (HUP_MESG_FILE, &sb))
		return;

	if ((sb.st_mode & S_IFMT) != S_IFREG)
		return;

	if ((fd = open (HUP_MESG_FILE, O_RDONLY)) != -1) {
		if (sb.st_size + 1 > mesg_size) {
			if (mesg_buf)
				free (mesg_buf);

			mesg_len = sb.st_size;
			mesg_size = mesg_len + 1;
			if (! (mesg_buf = malloc (mesg_len + 1)))
				goto end;
		} else
			mesg_len = sb.st_size;

		if (read (fd, mesg_buf, mesg_len) != mesg_len) {
			mesg_len = 0;
			goto end;
		}
	} else
		return;

end:
	close (fd);
}
#endif

void
main (argc, argv)
int	argc;
char	**argv;
{
	int	i;
	struct	utmp	utmp;
	int	fd;
#if defined(BSD) || defined(SUN) || defined(SUN4) || defined(HUP_MESG_FILE)
	char	tty_name[BUFSIZ];
	int	tty_fd;
#endif

	for (i = 0;close (i) == 0;i++)
		;

#ifdef	NDEBUG
#ifdef	USG
	setpgrp ();
#endif	/* USG */
#if defined(BSD) || defined(SUN) || defined(SUN4)
	setpgid (getpid ());
#endif /* BSD || SUN || SUN4 */
#ifdef	HUP_MESG_FILE
	signal (SIGHUP, reload_mesg);
#else
	signal (SIGHUP, SIG_IGN);
#endif	/* HUP_MESG_FILE */

	/*
	 * Put this process in the background.
	 */

	if (i = fork ())
		exit (i < 0 ? 1:0);
#endif	/* NDEBUG */

#ifdef	USE_SYSLOG
	/*
	 * Start syslogging everything
	 */

	openlog (basename (argv[0]), LOG_PID|LOG_CONS|LOG_NOWAIT, LOG_AUTH);
#endif

	/*
	 * Scan the UTMP file once per minute looking for users that
	 * are not supposed to still be logged in.
	 */

	while (1) {
#ifdef	NDEBUG
		sleep (60);
#endif

		/* 
		 * Attempt to re-open the utmp file.  The file is only
		 * open while it is being used.
		 */

		if ((fd = open (UTMP_FILE, 0)) == -1) {
#ifdef	USE_SYSLOG
			syslog (LOG_ERR, "cannot open %s - aborting\n",
				UTMP_FILE);
			closelog ();
#endif
			exit (1);
		}

		/*
		 * Read all of the entries in the utmp file.  The entries
		 * for login sessions will be checked to see if the user
		 * is permitted to be signed on at this time.
		 */

		while (read (fd, &utmp, sizeof utmp) == sizeof utmp) {
#ifdef	USG_UTMP
			if (utmp.ut_type != USER_PROCESS)
				continue;

			if (isttytime (utmp.ut_user, utmp.ut_line, time (0)))
				continue;
#endif
#ifdef BSD_UTMP
			if (utmp.ut_name[0] == '\0')
				continue;
			if (isttytime (utmp.ut_name, utmp.ut_line, time (0)))
				continue;
#endif
#ifdef	HUP_MESG_FILE
			strcat (strcpy (tty_name, "/dev/"), utmp.ut_line);
			if ((tty_fd = open (tty_name,
					O_WRONLY|O_NDELAY)) != -1) {
				write (tty_fd, mesg_buf, mesg_len);
				close (tty_fd);
			}
#endif	/* HUP_MESG_FILE */
#ifdef	USG_UTMP
			kill (- utmp.ut_pid, SIGHUP);
			sleep (10);
			kill (- utmp.ut_pid, SIGKILL);
#endif	/* USG_UTMP */
#if defined(BSD) || defined(SUN) || defined(SUN4)

			/*
			 * vhangup() the line to kill try and kill
			 * whatever is out there using it.
			 */

			strcat (strcpy (tty_name, "/dev/"), utmp.ut_line);
			if ((tty_fd = open (tty_name, O_RDONLY|O_NDELAY)) == -1)
				continue;

			vhangup (tty_fd);
			close (tty_fd);
#endif
		}
#ifdef	USE_SYSLOG
		syslog (LOG_NOTICE,
			"logged off user `%.*s' on `%.*s'\n",
			sizeof utmp.ut_name, utmp.ut_name,
			sizeof utmp.ut_line, utmp.ut_line);
#endif	/* USE_SYSLOG */
		close (fd);
	}
}
