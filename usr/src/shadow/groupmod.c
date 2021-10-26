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
static	char	sccsid[] = "@(#)groupmod.c	3.4	11:32:10	7/28/92";
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
char	group_newname[BUFSIZ];
gid_t	group_id;
gid_t	group_newid;

char	*Prog;

int	oflg;	/* permit non-unique group ID to be specified with -g         */
int	gflg;	/* new ID value for the group                                 */
int	nflg;	/* a new name has been specified for the group                */

#ifdef	NDBM
extern	int	gr_dbm_mode;
extern	int	sg_dbm_mode;
#endif
extern	char	*malloc();

extern	struct	group	*getgrnam();
extern	struct	group	*gr_next();
extern	struct	group	*gr_locate();
extern	int	gr_lock();
extern	int	gr_unlock();
extern	int	gr_rewind();
extern	int	gr_open();

#ifdef	SHADOWGRP
extern	struct	sgrp	*sgr_locate();
extern	int	sgr_lock();
extern	int	sgr_unlock();
extern	int	sgr_open();
#endif

/*
 * usage - display usage message and exit
 */

usage ()
{
	fprintf (stderr, "usage: groupmod [-g gid [-o]] [-n name] group\n");
	exit (2);
}

/*
 * new_grent - updates the values in a group file entry
 *
 *	new_grent() takes all of the values that have been entered and
 *	fills in a (struct group) with them.
 */

void
new_grent (grent)
struct	group	*grent;
{
	if (nflg)
		grent->gr_name = strdup (group_newname);

	if (gflg)
		grent->gr_gid = group_newid;
}

#ifdef	SHADOWGRP
/*
 * new_sgent - updates the values in a shadow group file entry
 *
 *	new_sgent() takes all of the values that have been entered and
 *	fills in a (struct sgrp) with them.
 */

void
new_sgent (sgent)
struct	sgrp	*sgent;
{
	if (nflg)
		sgent->sg_name = strdup (group_newname);
}
#endif	/* SHADOWGRP */

/*
 * grp_update - update group file entries
 *
 *	grp_update() writes the new records to the group files.
 */

void
grp_update ()
{
	struct	group	grp;
	struct	group	*ogrp;
#ifdef	SHADOWGRP
	struct	sgrp	sgrp;
#endif	/* SHADOWGRP */

	/*
	 * Create the initial entries for this new group.
	 */

	grp = *(gr_locate (group_name));
	new_grent (&grp);
#ifdef	SHADOWGRP
	sgrp = *(sgr_locate (group_name));
	new_sgent (&sgrp);
#endif	/* SHADOWGRP */

	/*
	 * Write out the new group file entry.
	 */

	if (! gr_update (&grp)) {
		fprintf (stderr, "%s: error adding new group entry\n", Prog);
		exit (1);
	}
	if (nflg && ! gr_remove (group_name)) {
		fprintf (stderr, "%s: error removing group entry\n", Prog);
		exit (1);
	}
#ifdef	NDBM

	/*
	 * Update the DBM group file with the new entry as well.
	 */

	if (access ("/etc/group.pag", 0) == 0) {
		if (! gr_dbm_update (&grp)) {
			fprintf (stderr, "%s: cannot add new dbm group entry\n",
				Prog);
			exit (1);
		}
		if (nflg && (ogrp = getgrnam (group_name)) &&
				! gr_dbm_remove (ogrp)) {
			fprintf (stderr, "%s: error removing group dbm entry\n",
				Prog);
			exit (1);
		}
		endgrent ();
	}
#endif	/* NDBM */

#ifdef	SHADOWGRP

	/*
	 * Write out the new shadow group entries as well.
	 */

	if (! sgr_update (&sgrp)) {
		fprintf (stderr, "%s: error adding new group entry\n", Prog);
		exit (1);
	}
	if (nflg && ! sgr_remove (group_name)) {
		fprintf (stderr, "%s: error removing group entry\n", Prog);
		exit (1);
	}
#ifdef	NDBM

	/*
	 * Update the DBM shadow group file with the new entry as well.
	 */

	if (access ("/etc/gshadow.pag", 0) == 0) {
		if (! sg_dbm_update (&sgrp)) {
			fprintf (stderr,
				"%s: cannot add new dbm shadow group entry\n",
				Prog);
			exit (1);
		}
		if (nflg && ! sg_dbm_remove (group_name)) {
			fprintf (stderr,
				"%s: error removing shadow group dbm entry\n",
				Prog);
			exit (1);
		}
		endsgent ();
	}
#endif	/* NDBM */
#endif	/* SHADOWGRP */
#ifdef	USE_SYSLOG
	if (nflg)
		syslog (LOG_INFO, "change group `%s' to `%s'\n",
			group_name, group_newname);

	if (gflg)
		syslog (LOG_INFO, "change gid for `%s' to %d\n",
			nflg ? group_name:group_newname, group_newid);
#endif	/* USE_SYSLOG */
}

/*
 * check_new_gid - check the new GID value for uniqueness
 *
 *	check_new_gid() insures that the new GID value is unique.
 */

int
check_new_gid ()
{
	/*
	 * First, the easy stuff.  If the ID can be duplicated, or if
	 * the ID didn't really change, just return.  If the ID didn't
	 * change, turn off those flags.  No sense doing needless work.
	 */

	if (oflg)
		return 0;

	if (group_id == group_newid) {
		gflg = 0;
		return 0;
	}
	if (getgrgid (group_newid))
		return -1;

	return 0;
}

/*
 * process_flags - perform command line argument setting
 *
 *	process_flags() interprets the command line arguments and sets
 *	the values that the user will be created with accordingly.  The
 *	values are checked for sanity.
 */

void
process_flags (argc, argv)
int	argc;
char	**argv;
{
	extern	int	optind;
	extern	char	*optarg;
	char	*end;
	int	arg;

	while ((arg = getopt (argc, argv, "og:n:")) != EOF) {
		switch (arg) {
			case 'g':
				gflg++;
				group_newid = strtol (optarg, &end, 10);
				if (*end != '\0') {
					fprintf (stderr, "%s: invalid group %s\n",
						Prog, optarg);
					exit (3);
				}
				break;
			case 'n':
				if (strcmp (group_name, optarg)) {
					nflg++;
					strncpy (group_newname, optarg, BUFSIZ);
				}
				break;
			case 'o':
				if (! gflg)
					usage ();

				oflg++;
				break;
			default:
				usage ();
		}
	}
	if (optind == argc - 1)
		strcpy (group_name, argv[argc - 1]);
	else
		usage ();
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
 * main - groupmod command
 *
 *	The syntax of the groupmod command is
 *	
 *	groupmod [ -g gid [ -o ]] [ -n name ] group
 *
 *	The flags are
 *		-g - specify a new group ID value
 *		-o - permit the group ID value to be non-unique
 *		-n - specify a new group name
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
	process_flags (argc, argv);

	/*
	 * Start with a quick check to see if the group exists.
	 */

	if (! getgrnam (group_name)) {
		fprintf (stderr, "%s: group %s does not exist\n",
			Prog, group_name);
		exit (9);
	}

	/*
	 * Do the hard stuff - open the files, create the group entries,
	 * then close and update the files.
	 */

	open_files ();

	grp_update ();

	close_files ();
	exit (0);
	/*NOTREACHED*/
}
