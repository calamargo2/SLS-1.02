/* pty_sgi4.0.1.c - routines to allocate ptys - silicon graphics version

Written by: Don Libes, NIST, 6/22/91

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.

*/

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/file.h>
#include <sys/fcntl.h>
#include <sys/termio.h>
#include "exp_rename.h"
#include <sys/sysmacros.h>
#include <sys/stat.h>
#include <stdio.h>

void debuglog();

#ifndef TRUE
#define TRUE 1
#define FALSE 0
#endif

char	*line;

static void
pty_stty(s,name)
char *s;		/* args to stty */
char *name;		/* name of pty */
{
#define MAX_ARGLIST 10240
	char buf[MAX_ARGLIST];	/* overkill is easier */

	sprintf(buf,"stty %s < %s > %s",s,name,name);
	system(buf);
}

struct	termio exp_tty_original;

int dev_tty;		/* file descriptor to /dev/tty or -1 if none */
int knew_dev_tty;	/* true if we had our hands on /dev/tty at any time */

#define GET_TTYTYPE	0
#define SET_TTYTYPE	1
static void
ttytype(request,fd,s)
int request;
int fd;
char *s;	/* stty args, used only if request == SET_TTYTYPE */
{
	if (request == GET_TTYTYPE) {
		if (-1 == ioctl(fd, TCGETA, (char *)&exp_tty_original)) {
			knew_dev_tty = FALSE;
			dev_tty = -1;
		}
	} else {	/* type == SET_TTYTYPE */
		if (knew_dev_tty) {
			(void) ioctl(fd, TCSETA, (char *)&exp_tty_original);
		} else {
			/* if running in the background, we have no access */
			/* to a a tty to copy parameters from, so use ones */
			/* supplied by original Makefile */
			debuglog("getptyslave: (default) stty %s\n",DFLT_STTY);
			pty_stty(DFLT_STTY,line);
		}
		if (s) {
			/* give user a chance to override any terminal parms */
			debuglog("getptyslave: (user-requested) stty %s\n",s);
			pty_stty(s,line);
		}
	}
}

void
init_pty()
{
	dev_tty = open("/dev/tty",O_RDWR);
	knew_dev_tty = (dev_tty != -1);
	if (knew_dev_tty) ttytype(GET_TTYTYPE,dev_tty,(char *)0);
}


/* returns fd of master end of pseudotty */
int
getptymaster()
{
   int fd;
   
   line = _getpty(&fd, O_RDWR, 0600, 0);
   if (line == NULL)   return (-1);

   return(fd);
}



int
getptyslave(stty_args)
char *stty_args;
{
	int slave;

	if (0 > (slave = open(line, O_RDWR))) return(-1);

	/* sanity check - if slave not 0, skip rest of this and return */
	/* to what will later be detected as an error in caller */
	if (0 != slave) return(slave);

	fcntl(0,F_DUPFD,1);	/* duplicate 0 onto 1 to prepare for stty */
	ttytype(SET_TTYTYPE,slave,stty_args);
	return(slave);
}

