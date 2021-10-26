/* This program is derived from 4.3 BSD software and is
   subject to the copyright notice below.

   The port to HP-UX has been motivated by the incapability
   of 'rlogin'/'rlogind' as per HP-UX 6.5 (and 7.0) to transfer window sizes.

   Changes:

   - General HP-UX portation. Use of facilities not available
     in HP-UX (e.g. setpriority) has been eliminated.
     Utmp/wtmp handling has been ported.

   - The program uses BSD command line options to be used
     in connection with e.g. 'rlogind' i.e. 'new login'.

   - HP features left out:          logging of bad login attempts in /etc/btmp,
				    they are sent to syslog

				    password expiry

				    '*' as login shell, add it if you need it

   - BSD features left out:         quota checks
				    password expiry
				    analysis of terminal type (tset feature)

   - BSD features thrown in:        Security logging to syslogd.
                                    This requires you to have a (ported) syslog
				    system -- 7.0 comes with syslog
				    
				    'Lastlog' feature.

   - A lot of nitty gritty details has been adjusted in favour of
     HP-UX, e.g. /etc/securetty, default paths and the environment
     variables assigned by 'login'.

   - We do *nothing* to setup/alter tty state, under HP-UX this is
     to be done by getty/rlogind/telnetd/some one else.

   Michael Glad (glad@daimi.dk)
   Computer Science Department
   Aarhus University
   Denmark

   1990-07-04

   1991-09-24 glad: HP-UX 8.0 port:
              - now explictly sets non-blocking mode on descriptors
	      - strcasecmp is now part of HP-UX
   1992-02-05 poe: Ported the stuff to Linux 0.12
*/
   
/*
 * Copyright (c) 1980, 1987, 1988 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * advertising materials, and other materials related to such
 * distribution and use acknowledge that the software was developed
 * by the University of California, Berkeley.  The name of the
 * University may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

#ifndef lint
char copyright[] =
"@(#) Copyright (c) 1980, 1987, 1988 The Regents of the University of California.\n\
 All rights reserved.\n";
#endif /* not lint */

#ifndef lint
static char sccsid[] = "@(#)login.c	5.40 (Berkeley) 5/9/89";
#endif /* not lint */

/*
 * login [ name ]
 * login -h hostname	(for telnetd, etc.)
 * login -f name	(for pre-authenticated login: datakit, xterm, etc.)
 */

/* #define TESTING */

#ifdef TESTING
#include "param.h"
#else
#include <sys/param.h>
#endif

#include <ctype.h>
#include <unistd.h>
#include <getopt.h>
#include <memory.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/file.h>
#include <termios.h>
#include <string.h>
#define index strchr
#define rindex strrchr
#include <sys/ioctl.h>

#ifdef TESTING
#include "utmp.h"
#else
#include <utmp.h>
#endif

#include <signal.h>
#include <errno.h>
#include <grp.h>
#include <pwd.h>
#include <setjmp.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#ifndef linux
#include <tzfile.h>
#include <lastlog.h>
#else
struct  lastlog
  { long ll_time;
    char ll_line[12];
    char ll_host[16];
  };
#endif

#include "pathnames.h"

#ifdef	KERBEROS
#include <kerberos/krb.h>
#include <sys/termios.h>
char	realm[REALM_SZ];
int	kerror = KSUCCESS, notickets = 1;
#endif

#ifndef linux
#define	TTYGRPNAME	"tty"		/* name of group to own ttys */
#else
#  define TTYGRPNAME      "other"
#  ifndef MAXPATHLEN
#    define MAXPATHLEN 1024
#  endif
#endif

/*
 * This bounds the time given to login.  Not a define so it can
 * be patched on machines where it's too small.
 */
#ifndef linux
int	timeout = 300;
#else
int     timeout = 60;
#endif

struct	passwd *pwd;
int	failures;
char	term[64], *hostname, *username, *tty;

char	thishost[10];

#ifndef linux
struct	sgttyb sgttyb;
struct	tchars tc = {
	CINTR, CQUIT, CSTART, CSTOP, CEOT, CBRK
};
struct	ltchars ltc = {
	CSUSP, CDSUSP, CRPRNT, CFLUSH, CWERASE, CLNEXT
};
#endif

char *months[] =
	{ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug",
	  "Sep", "Oct", "Nov", "Dec" };

main(argc, argv)
	int argc;
	char **argv;
{
	extern int errno, optind;
	extern char *optarg, **environ;
	struct timeval tp;
	struct tm *ttp;
	struct group *gr;
	register int ch;
	register char *p;
	int ask, fflag, hflag, pflag, cnt;
	int quietlog, passwd_req, ioctlval;
	char *domain, *salt, *envinit[1], *ttyn, *pp;
	char tbuf[MAXPATHLEN + 2], tname[sizeof(_PATH_TTY) + 10];
	char *ctime(), *ttyname(), *stypeof(), *crypt();
	time_t time();
	void timedout();
	char termenv[20];

#ifdef linux
	char tmp[100];
	/* Just as arbitrary as mountain time: */
        (void)setenv("TZ", "MET-1DST",0); 
#endif

	(void)signal(SIGALRM, timedout);
	(void)alarm((unsigned int)timeout);
	(void)signal(SIGQUIT, SIG_IGN);
	(void)signal(SIGINT, SIG_IGN);
	(void)signal(SIGHUP, SIG_IGN); /* so vhangup() wont kill us */
#ifndef linux
	(void)setpriority(PRIO_PROCESS, 0, 0);
	(void)quota(Q_SETUID, 0, 0, 0);
#endif

	/*
	 * -p is used by getty to tell login not to destroy the environment
 	 * -f is used to skip a second login authentication 
	 * -h is used by other servers to pass the name of the remote
	 *    host to login so that it may be placed in utmp and wtmp
	 */
	(void)gethostname(tbuf, sizeof(tbuf));
	(void)strcpy(thishost, tbuf);
	domain = index(tbuf, '.');

	fflag = hflag = pflag = 0;
	passwd_req = 1;
	while ((ch = getopt(argc, argv, "fh:p")) != EOF)
		switch (ch) {
		case 'f':
			fflag = 1;
			break;
#ifndef linux
		case 'h':
			if (getuid()) {
				(void)fprintf(stderr,
				    "login: -h for super-user only.\n");
				exit(1);
			}
			hflag = 1;
			if (domain && (p = index(optarg, '.')) &&
			    strcasecmp(p, domain) == 0)
				*p = 0;
			hostname = optarg;
			break;
#endif
		case 'p':
			pflag = 1;
			break;
		case '?':
		default:
			(void)fprintf(stderr,
			    "usage: login [-fp] [username]\n");
			exit(1);
		}
	argc -= optind;
	argv += optind;
	if (*argv) {
		username = *argv;
		ask = 0;
	} else
		ask = 1;

#ifndef linux
	ioctlval = 0;
	(void)ioctl(0, TIOCLSET, &ioctlval);
	(void)ioctl(0, TIOCNXCL, 0);
	(void)fcntl(0, F_SETFL, ioctlval);
	(void)ioctl(0, TIOCGETP, &sgttyb);
	sgttyb.sg_erase = CERASE;
	sgttyb.sg_kill = CKILL;
	(void)ioctl(0, TIOCSLTC, &ltc);
	(void)ioctl(0, TIOCSETC, &tc);
	(void)ioctl(0, TIOCSETP, &sgttyb);

	/*
	 * Be sure that we're in
	 * blocking mode!!!
	 * This is really for HPUX
	 */
        ioctlval = 0;
        (void)ioctl(0, FIOSNBIO, &ioctlval);
#endif

	for (cnt = getdtablesize(); cnt > 2; cnt--)
		close(cnt);

	ttyn = ttyname(0);
	if (ttyn == NULL || *ttyn == '\0') {
		(void)sprintf(tname, "%s??", _PATH_TTY);
		ttyn = tname;
	}

	setpgrp();
	if((chown(ttyn, 0, 0) == 0) && (chmod(ttyn, 0622) == 0))
		vhangup();

	setsid();
	/* re-open stdin,stdout,stderr after vhangup() closed them */
	open(ttyn, O_RDWR); open(ttyn, O_RDWR); open(ttyn, O_RDWR); 

	if (tty = rindex(ttyn, '/'))
		++tty;
	else
		tty = ttyn;

#ifndef linux
	openlog("login", LOG_ODELAY, LOG_AUTH);
#endif

	for (cnt = 0;; ask = 1) {
		ioctlval = 0;
#ifndef linux
		(void)ioctl(0, TIOCSETD, &ioctlval);
#endif

		if (ask) {
			fflag = 0;
			getloginname();
		}
		/*
		 * Note if trying multiple user names;
		 * log failures for previous user name,
		 * but don't bother logging one failure
		 * for nonexistent name (mistyped username).
		 */
		if (failures && strcmp(tbuf, username)) {
			if (failures > (pwd ? 0 : 1))
				badlogin(tbuf);
			failures = 0;
		}
		(void)strcpy(tbuf, username);
		if (pwd = getpwnam(username))
			salt = pwd->pw_passwd;
		else
			salt = "xx";

		/* if user not super-user, check for disabled logins */
		if (pwd == NULL || pwd->pw_uid)
			checknologin();

		/*
		 * Disallow automatic login to root; if not invoked by
		 * root, disallow if the uid's differ.
		 */
		if (fflag && pwd) {
			int uid = getuid();

			passwd_req = pwd->pw_uid == 0 ||
			    (uid && uid != pwd->pw_uid);
		}

		/*
		 * If trying to log in as root, but with insecure terminal,
		 * refuse the login attempt.
		 */
		if (pwd && pwd->pw_uid == 0 && !rootterm(tty)) {
			(void)fprintf(stderr,
			    "%s login refused on this terminal.\n",
			    pwd->pw_name);
#ifndef linux
			if (hostname)
				syslog(LOG_NOTICE,
				    "LOGIN %s REFUSED FROM %s ON TTY %s",
				    pwd->pw_name, hostname, tty);
			else
				syslog(LOG_NOTICE,
				    "LOGIN %s REFUSED ON TTY %s",
				     pwd->pw_name, tty);
#endif
			continue;
		}

		/*
		 * If no pre-authentication and a password exists
		 * for this user, prompt for one and verify it.
		 */
		if (!passwd_req || (pwd && !*pwd->pw_passwd))
			break;

#ifndef linux
		setpriority(PRIO_PROCESS, 0, -4);
#endif
		pp = getpass("Password: ");
		p = crypt(pp, salt);
#ifndef linux
		setpriority(PRIO_PROCESS, 0, 0);
#endif

#ifdef	KERBEROS

		/*
		 * If not present in pw file, act as we normally would.
		 * If we aren't Kerberos-authenticated, try the normal
		 * pw file for a password.  If that's ok, log the user
		 * in without issueing any tickets.
		 */

		if (pwd && !krb_get_lrealm(realm,1)) {
			/*
			 * get TGT for local realm; be careful about uid's
			 * here for ticket file ownership
			 */
			(void)setreuid(geteuid(),pwd->pw_uid);
			kerror = krb_get_pw_in_tkt(pwd->pw_name, "", realm,
				"krbtgt", realm, DEFAULT_TKT_LIFE, pp);
			(void)setuid(0);
			if (kerror == INTK_OK) {
				memset(pp, 0, strlen(pp));
				notickets = 0;	/* user got ticket */
				break;
			}
		}
#endif
		(void) memset(pp, 0, strlen(pp));
		if (pwd && !strcmp(p, pwd->pw_passwd))
			break;

		(void)printf("Login incorrect\n");
		failures++;
		/* we allow 10 tries, but after 3 we start backing off */
		if (++cnt > 3) {
			if (cnt >= 10) {
				badlogin(username);
#ifndef linux
				(void)ioctl(0, TIOCHPCL, (struct sgttyb *)NULL);
#endif
				sleepexit(1);
			}
			sleep((unsigned int)((cnt - 3) * 5));
		}
	}

	/* committed to login -- turn off timeout */
	(void)alarm((unsigned int)0);

	/* paranoia... */
	endpwent();

#ifndef linux
	if (quota(Q_SETUID, pwd->pw_uid, 0, 0) < 0 && errno != EINVAL) {
		switch(errno) {
		case EUSERS:
			(void)fprintf(stderr,
		"Too many users logged on already.\nTry again later.\n");
			break;
		case EPROCLIM:
			(void)fprintf(stderr,
			    "You have too many processes running.\n");
			break;
		default:
			perror("quota (Q_SETUID)");
		}
		sleepexit(0);
	}
#endif

	if (chdir(pwd->pw_dir) < 0) {
		(void)printf("No directory %s!\n", pwd->pw_dir);
		if (chdir("/"))
			exit(0);
		pwd->pw_dir = "/";
		(void)printf("Logging in with home = \"/\".\n");
	}

	quietlog = access(_PATH_HUSHLOGIN, 004) == 0;

#ifndef linux
#ifdef KERBEROS
	if (notickets && !quietlog)
		(void)printf("Warning: no Kerberos tickets issued\n");
#endif

#define	TWOWEEKS	(14*24*60*60)
	if (pwd->pw_change || pwd->pw_expire)
		(void)gettimeofday(&tp, (struct timezone *)NULL);
	if (pwd->pw_change)
		if (tp.tv_sec >= pwd->pw_change) {
			(void)printf("Sorry -- your password has expired.\n");
			sleepexit(1);
		}
		else if (tp.tv_sec - pwd->pw_change < TWOWEEKS && !quietlog) {
			ttp = localtime(&pwd->pw_change);
			(void)printf("Warning: your password expires on %s %d, %d\n",
			    months[ttp->tm_mon], ttp->tm_mday, TM_YEAR_BASE + ttp->tm_year);
		}
	if (pwd->pw_expire)
		if (tp.tv_sec >= pwd->pw_expire) {
			(void)printf("Sorry -- your account has expired.\n");
			sleepexit(1);
		}
		else if (tp.tv_sec - pwd->pw_expire < TWOWEEKS && !quietlog) {
			ttp = localtime(&pwd->pw_expire);
			(void)printf("Warning: your account expires on %s %d, %d\n",
			    months[ttp->tm_mon], ttp->tm_mday, TM_YEAR_BASE + ttp->tm_year);
		}

	/* nothing else left to fail -- really log in */
	{
		struct utmp utmp;

		memset((char *)&utmp, 0, sizeof(utmp));
		(void)time(&utmp.ut_time);
		strncpy(utmp.ut_name, username, sizeof(utmp.ut_name));
		if (hostname)
			strncpy(utmp.ut_host, hostname, sizeof(utmp.ut_host));
		strncpy(utmp.ut_line, tty, sizeof(utmp.ut_line));
		login(&utmp);
	}
#else
	/* for linux, write entries in utmp and wtmp */
	{
		struct utmp ut;
		char *ttyabbrev;
		int wtmp;
		
		memset((char *)&ut, 0, sizeof(ut));
		ut.ut_type = USER_PROCESS;
		ut.ut_pid = getpid();
		strncpy(ut.ut_line, ttyn + sizeof("/dev/")-1, sizeof(ut.ut_line));
		ttyabbrev = ttyn + sizeof("/dev/tty") - 1;
		strncpy(ut.ut_id, ttyabbrev, sizeof(ut.ut_id));
		(void)time(&ut.ut_time);
		strncpy(ut.ut_user, username, sizeof(ut.ut_user));
		
		/* fill in host and ip-addr fields when we get networking */
		
		utmpname(_PATH_UTMP);
		setutent();
		pututline(&ut);
		endutent();
		
		if((wtmp = open(_PATH_WTMP, O_APPEND|O_WRONLY)) >= 0) {
			write(wtmp, (char *)&ut, sizeof(ut));
			close(wtmp);
		}
	}
        /* fix_utmp_type_and_user(username, ttyn, LOGIN_PROCESS); */
#endif

	dolastlog(quietlog);
	
#ifndef linux
	if (!hflag) {					/* XXX */
		static struct winsize win = { 0, 0, 0, 0 };

		(void)ioctl(0, TIOCSWINSZ, &win);
	}
#endif
	(void)chown(ttyn, pwd->pw_uid,
	    (gr = getgrnam(TTYGRPNAME)) ? gr->gr_gid : pwd->pw_gid);
#ifndef linux
	(void)chmod(ttyn, 0620);
#else
	(void)chmod(ttyn, 0622);
#endif
	(void)setgid(pwd->pw_gid);

	initgroups(username, pwd->pw_gid);

#ifndef linux
	quota(Q_DOWARN, pwd->pw_uid, (dev_t)-1, 0);
#endif

	if (*pwd->pw_shell == '\0')
		pwd->pw_shell = _PATH_BSHELL;
#ifndef linux
	/* turn on new line discipline for the csh */
	else if (!strcmp(pwd->pw_shell, _PATH_CSHELL)) {
		ioctlval = NTTYDISC;
		(void)ioctl(0, TIOCSETD, &ioctlval);
	}
#endif

	/* preserve TERM even without -p flag */
	{
		char *ep;
		
		if(ep = getenv("TERM"))
			(void)strncpy(termenv, ep, sizeof(termenv) - 1);
		else
			(void)strcpy(termenv, "dumb");
	}

	/* destroy environment unless user has requested preservation */
	if (!pflag)
        {
          environ = (char**)malloc(sizeof(char*));
	  memset(environ, 0, sizeof(char*));
	}

#ifndef linux
	(void)setenv("HOME", pwd->pw_dir, 1);
	(void)setenv("SHELL", pwd->pw_shell, 1);
	if (term[0] == '\0')
		strncpy(term, stypeof(tty), sizeof(term));
	(void)setenv("TERM", term, 0);
	(void)setenv("USER", pwd->pw_name, 1);
	(void)setenv("PATH", _PATH_DEFPATH, 0);
#else
        (void)setenv("HOME", pwd->pw_dir, 0);      /* legal to override */
        if(pwd->pw_uid)
          (void)setenv("PATH", _PATH_DEFPATH, 1);
        else
          (void)setenv("PATH", _PATH_DEFPATH_ROOT, 1);
	(void)setenv("SHELL", pwd->pw_shell, 1);
	(void)setenv("TERM", termenv, 1);

        /* mailx will give a funny error msg if you forget this one */
        (void)sprintf(tmp,"%s/%s",_PATH_MAILDIR,pwd->pw_name);
        (void)setenv("MAIL",tmp,0);

        /* LOGNAME is not documented in login(1) but
	   HP-UX 6.5 does it. We'll not allow modifying it.
	 */
	(void)setenv("LOGNAME", pwd->pw_name, 1);
#endif

#ifndef linux
	if (tty[sizeof("tty")-1] == 'd')
		syslog(LOG_INFO, "DIALUP %s, %s", tty, pwd->pw_name);
	if (pwd->pw_uid == 0)
		if (hostname)
			syslog(LOG_NOTICE, "ROOT LOGIN ON %s FROM %s",
			    tty, hostname);
		else
			syslog(LOG_NOTICE, "ROOT LOGIN ON %s", tty);
#endif
	if (!quietlog) {
		struct stat st;

		motd();
		(void)sprintf(tbuf, "%s/%s", _PATH_MAILDIR, pwd->pw_name);
		if (stat(tbuf, &st) == 0 && st.st_size != 0)
			(void)printf("You have %smail.\n",
			    (st.st_mtime > st.st_atime) ? "new " : "");
	}

	(void)signal(SIGALRM, SIG_DFL);
	(void)signal(SIGQUIT, SIG_DFL);
	(void)signal(SIGINT, SIG_DFL);
	(void)signal(SIGTSTP, SIG_IGN);
	(void)signal(SIGHUP, SIG_DFL);

	tbuf[0] = '-';
	strcpy(tbuf + 1, (p = rindex(pwd->pw_shell, '/')) ?
	    p + 1 : pwd->pw_shell);

	/* discard permissions last so can't get killed and drop core */
	(void)setuid(pwd->pw_uid);

	execlp(pwd->pw_shell, tbuf, (char *)0);
	(void)fprintf(stderr, "login: no shell: %s.\n", strerror(errno));
	exit(0);
}

getloginname()
{
	register int ch;
	register char *p;
	static char nbuf[UT_NAMESIZE + 1];

	for (;;) {
		(void)printf("\n%s login: ", thishost); fflush(stdout);
		for (p = nbuf; (ch = getchar()) != '\n'; ) {
			if (ch == EOF) {
				badlogin(username);
				exit(0);
			}
			if (p < nbuf + UT_NAMESIZE)
				*p++ = ch;
		}
		if (p > nbuf)
			if (nbuf[0] == '-')
				(void)fprintf(stderr,
				    "login names may not start with '-'.\n");
			else {
				*p = '\0';
				username = nbuf;
				break;
			}
	}
}

void timedout()
{
	struct termio ti;
	
	(void)fprintf(stderr, "Login timed out after %d seconds\n", timeout);

	/* reset echo */
	(void) ioctl(0, TCGETA, &ti);
	ti.c_lflag |= ECHO;
	(void) ioctl(0, TCSETA, &ti);
	exit(0);
}

rootterm(ttyn)
	char *ttyn;
#ifndef linux
{
	struct ttyent *t;

	return((t = getttynam(ttyn)) && t->ty_status&TTY_SECURE);
}
#else
{ 
  int fd;
  char buf[100],*p;
  int cnt, more;

  fd = open(SECURETTY, O_RDONLY);
  if(fd < 0) return 1;

  /* read each line in /etc/securetty, if a line matches our ttyline
     then root is allowed to login on this tty, and we should return
     true. */
  for(;;) {
	p = buf; cnt = 100;
	while(--cnt >= 0 && (more = read(fd, p, 1)) == 1 && *p != '\n') p++;
	if(more && *p == '\n') {
		*p = '\0';
	  	if(!strcmp(buf, ttyn)) {
  			close(fd);
  			return 1;
	  	} else
  			continue;
  	} else {
  		close(fd);
  		return 0;
  	}
  }
}
#endif

jmp_buf motdinterrupt;

motd()
{
	register int fd, nchars;
	void (*oldint)(), sigint();
	char tbuf[8192];

	if ((fd = open(_PATH_MOTDFILE, O_RDONLY, 0)) < 0)
		return;
	oldint = signal(SIGINT, sigint);
	if (setjmp(motdinterrupt) == 0)
		while ((nchars = read(fd, tbuf, sizeof(tbuf))) > 0)
			(void)write(fileno(stdout), tbuf, nchars);
	(void)signal(SIGINT, oldint);
	(void)close(fd);
}

void sigint()
{
	longjmp(motdinterrupt, 1);
}

checknologin()
{
	register int fd, nchars;
	char tbuf[8192];

	if ((fd = open(_PATH_NOLOGIN, O_RDONLY, 0)) >= 0) {
		while ((nchars = read(fd, tbuf, sizeof(tbuf))) > 0)
			(void)write(fileno(stdout), tbuf, nchars);
		sleepexit(0);
	}
}

dolastlog(quiet)
	int quiet;
{
	struct lastlog ll;
	int fd;

	if ((fd = open(_PATH_LASTLOG, O_RDWR, 0)) >= 0) {
		(void)lseek(fd, (off_t)pwd->pw_uid * sizeof(ll), L_SET);
		if (!quiet) {
			if (read(fd, (char *)&ll, sizeof(ll)) == sizeof(ll) &&
			    ll.ll_time != 0) {
				(void)printf("Last login: %.*s ",
				    24-5, (char *)ctime(&ll.ll_time));
				if (*ll.ll_host != '\0')
					(void)printf("from %.*s\n",
					    sizeof(ll.ll_host), ll.ll_host);
				else
					(void)printf("on %.*s\n",
					    sizeof(ll.ll_line), ll.ll_line);
			}
			(void)lseek(fd, (off_t)pwd->pw_uid * sizeof(ll), L_SET);
		}
		memset((char *)&ll, 0, sizeof(ll));
		(void)time(&ll.ll_time);
		strncpy(ll.ll_line, tty, sizeof(ll.ll_line));
		if (hostname)
			strncpy(ll.ll_host, hostname, sizeof(ll.ll_host));
		(void)write(fd, (char *)&ll, sizeof(ll));
		(void)close(fd);
	}
}

badlogin(name)
	char *name;
{
	if (failures == 0)
		return;
#ifndef linux
	if (hostname)
		syslog(LOG_NOTICE, "%d LOGIN FAILURE%s FROM %s, %s",
		    failures, failures > 1 ? "S" : "", hostname, name);
	else
		syslog(LOG_NOTICE, "%d LOGIN FAILURE%s ON %s, %s",
		    failures, failures > 1 ? "S" : "", tty, name);
#endif
}

#undef	UNKNOWN
#define	UNKNOWN	"su"

#ifndef linux
char *
stypeof(ttyid)
	char *ttyid;
{
	struct ttyent *t;

	return(ttyid && (t = getttynam(ttyid)) ? t->ty_type : UNKNOWN);
}
#endif 

getstr(buf, cnt, err)
	char *buf, *err;
	int cnt;
{
	char ch;

	do {
		if (read(0, &ch, sizeof(ch)) != sizeof(ch))
			exit(1);
		if (--cnt < 0) {
			(void)fprintf(stderr, "%s too long\r\n", err);
			sleepexit(1);
		}
		*buf++ = ch;
	} while (ch);
}

sleepexit(eval)
	int eval;
{
	sleep((unsigned int)5);
	exit(eval);
}

