/*
 * Copyright 1989, 1990, 1992, John F. Haugh II
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

/*
 * lastlog.h - structure of lastlog file
 *
 *	@(#)lastlog.h	3.1.1.1	13:02:32	7/27/92
 *
 *	This file defines a lastlog file structure which should be sufficient
 *	to hold the information required by login.  It should only be used if
 *	there is no real lastlog.h file.
 */

struct	lastlog	{
	time_t	ll_time;
#ifdef SVR4
	char	ll_line[24];
#else
	char	ll_line[8];
#endif
};
