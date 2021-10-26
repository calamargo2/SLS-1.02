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
static	char	sccsid[] = "@(#)groupdel.c	3.6	11:32:05	7/28/92";
#endif

#include <sys/types.h>
#include <stdio.h>
#include <grp.h>
#include <ctype.h>
#include <fcntl.h>

#ifdef	BSD
#include <strings.h>
#else
#include <string.h>
#endif

#include "config.h"
#include "shadow.h"

#ifdef	USE_SYSLOG
#include <syslog.h>
#endif

char	group_name[BUFSIZ];
char	*Prog;

#ifdef	NDBM
extern	int	gr_dbm_mode;
extern	int	sg_dbm_mode;
#endif
extern	char	*malloc();

extern	struct	group	*getgrnam();
extern	int	gr_lock();
extern	int	gr_unlock();
extern	int	gr_open();

#ifdef	SHADOWGRP
extern	int	sgr_lock();
extern	int	sgr_unlock();
extern	int	sgr_open();
#endif

/*
 * usage - display usage message and exit
 */

usage ()
{
	fprintf (stderr, "usage: groupdel group\n");
	exit (2);
}

/*
 * grp_update - update group file entries
 *
 *	grp_update() writes the new records to the group files.
 */

void
grp_update ()
{
#ifdef	NDBM
	struct	group	*ogrp;
#endif

	if (! gr_remove (group_name)) {
		fprintf (stderr, "%s: error removing group entry\n", Prog);
		exit (1);
	}
#ifdef	NDBM

	/*
	 * Update the DBM group file
	 */

	if (access ("/etc/group.pag", 0) == 0) {
		if ((ogrp = getgrnam (group_name)) &&
				! gr_dbm_remove (ogrp)) {
			fprintf (stderr, "%s: error removing group dbm entry\n",
				Prog);
			exit (1);
		}
	}
	endgrent ();
#endif	/* NDBM */

#ifdef	SHADOWGRP

	/*
	 * Delete the shadow group entries as well.
	 */

	if (! sgr_remove (group_name)) {
		fprintf (stderr, "%s: error removing shadow group entry\n",
			Prog);
		exit (1);
	}
#ifdef	NDBM

	/*
	 * Update the DBM shadow group file
	 */

	if (access ("/etc/gshadow.pag", 0) == 0) {
		if (! sg_dbm_remove (group_name)) {
			fprintf (stderr,
				"%s: error removing shadow group dbm entry\n",
				Prog);
			exit (1);
		}
	}
	endsgent ();
#endif	/* NDBM */
#endif	/* SHADOWGRP */
#ifdef	USE_SYSLOG
	syslog (LOG_INFO, "remove group `%s'\n", group_name);
#endif	/* USE_SYSLOG */
}

/*
 * close_files - close all of the files that were opened
 *
 *	close_files() closes all of the files that were opened for this
 *	new group.  This causes any modified entries to be written out.
 */

close_files ()
{
	if (! gr_close ()) {
		fprintf (stderr, "%s: cannot rewrite group file\n", Prog);
		exit (1);
	}
	(void) gr_unlock ();
#ifdef	SHADOWGRP
	if (! sgr_close ()) {
		fprintf (stderr, "%s: cannot rewrite shadow group file\n",
			Prog);
		exit (1);
	}
	(void) sgr_unlock ();
#endif	/* SHADOWGRP */
}

/*
 * open_files - lock and open the group files
 *
 *	open_files() opens the two group files.
 */

open_files ()
{
	if (! gr_lock ()) {
		fprintf (stderr, "%s: unable to lock group file\n", Prog);
		exit (1);
	}
	if (! gr_open (O_RDWR)) {
		fprintf (stderr, "%s: unable to open group file\n", Prog);
		exit (1);
	}
#ifdef	SHADOWGRP
	if (! sgr_lock ()) {
		fprintf (stderr, "%s: unable to lock shadow group file\n",
			Prog);
		exit (1);
	}
	if (! sgr_open (O_RDWR)) {
		fprintf (stderr, "%s: unable to open shadow group file\n",
			Prog);
		exit (1);
	}
#endif	/* SHADOWGRP */
}

/*
 * main - groupdel command
 *
 *	The syntax of the groupdel command is
 *	
 *	groupdel group
 *
 *	The named group will be deleted.
 */

main (argc, argv)
int	argc;
char	**argv;
{

	/*
	 * Get my name so that I can use it to report errors.
	 */

	if (Prog = strrchr (argv[0], '/'))
		Prog++;
	else
		Prog = argv[0];

	if (argc != 2)
		usage ();

	strncpy (group_name, argv[1], BUFSIZ);

#ifdef	USE_SYSLOG
	openlog (Prog, LOG_PID|LOG_CONS|LOG_NOWAIT, LOG_AUTH);
#endif	/* USE_SYSLOG */

	/*
	 * The open routines for the DBM files don't use read-write
	 * as the mode, so we have to clue them in.
	 */

#ifdef	NDBM
	gr_dbm_mode = O_RDWR;
#ifdef	SHADOWGRP
	sg_dbm_mode = O_RDWR;
#endif	/* SHADOWGRP */
#endif	/* NDBM */

	/*
	 * Start with a quick check to see if the group exists.
	 */

	if (! getgrnam (group_name)) {
		fprintf (stderr, "%s: group %s does not exist\n",
			Prog, group_name);
		exit (9);
	}

	/*
	 * Do the hard stuff - open the files, delete the group entries,
	 * then close and update the files.
	 */

	open_files ();

	grp_update ();

	close_files ();
	exit (0);
	/*NOTREACHED*/
}
