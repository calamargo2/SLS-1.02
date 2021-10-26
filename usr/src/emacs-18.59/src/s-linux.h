/* Definitions file for GNU Emacs running on Linus Torvald's Linux
   Copyright (C) 1985, 1986 Free Software Foundation, Inc.

This file is part of GNU Emacs.

GNU Emacs is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

GNU Emacs is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs; see the file COPYING.  If not, write to
the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.  */

/* this config.h written for Linux 0.98 pl4, gcc 2.2.2d7 and libc 4.1
   by Rick Sladkey <jrs@world.std.com>, your mileage may vary */

/*
 *	Define symbols to identify the version of Unix this is.
 *	Define all the symbols that apply correctly.
 */

#define USG				/* System III, System V, etc */

#define USG5

/* SYSTEM_TYPE should indicate the kind of system you are using.
 It sets the Lisp variable system-type.  */

#define SYSTEM_TYPE "linux"		/* all the best software is free */

/* nomultiplejobs should be defined if your system's shell
 does not have "job control" (the ability to stop a program,
 run some other program, then continue the first one).  */

/* #define NOMULTIPLEJOBS */

/* Default is to set interrupt_input to 0: don't do input buffering within Emacs */

/* #define INTERRUPT_INPUT */

/* Letter to use in finding device name of first pty,
  if system supports pty's.  'p' means it is /dev/ptyp0  */

#define FIRST_PTY_LETTER 'p'

/*
 *	Define HAVE_TERMIO if the system provides sysV-style ioctls
 *	for terminal control.
 */

#define HAVE_TERMIO

/*
 *	Define HAVE_TIMEVAL if the system supports the BSD style clock values.
 *	Look in <sys/time.h> for a timeval structure.
 */

#define HAVE_TIMEVAL
 
/*
 *	Define HAVE_SELECT if the system supports the `select' system call.
 */

#define HAVE_SELECT

/*
 *	Define HAVE_PTYS if the system supports pty devices.
 */

#define HAVE_PTYS

/* Define HAVE_SOCKETS if system supports 4.2-compatible sockets.  */

#define HAVE_SOCKETS

/*
 *	Define NONSYSTEM_DIR_LIBRARY to make Emacs emulate
 *      The 4.2 opendir, etc., library functions.
 */

/* #define NONSYSTEM_DIR_LIBRARY */

/* Define this symbol if your system has the functions bcopy, etc. */

#define BSTRING

/* subprocesses should be defined if you want to
 have code for asynchronous subprocesses
 (as used in M-x compile and M-x shell).
 This is supposed to work now on system V release 2.  */

#define subprocesses

/* If your system uses COFF (Common Object File Format) then define the
   preprocessor symbol "COFF". */

/* #define COFF */

/* define MAIL_USE_FLOCK if the mailer uses flock
   to interlock access to /usr/spool/mail/$USER.
   The alternative is that a lock file named
   /usr/spool/mail/$USER.lock.  */

/* #define MAIL_USE_FLOCK */

/* Define CLASH_DETECTION if you want lock files to be written
   so that Emacs can tell instantly when you try to modify
   a file that someone else has modified in his Emacs.  */

/* #define CLASH_DETECTION */

/* Define SHORTNAMES if the C compiler can distinguish only
   short names.  It means that the stuff in ../shortnames
   must be run to convert the long names to short ones.  */

/* #define SHORTNAMES */


/* Special hacks needed to make Emacs run on this system.  */

/* On USG systems the system calls are interruptable by signals
 that the user program has elected to catch.  Thus the system call
 must be retried in these cases.  To handle this without massive
 changes in the source code, we remap the standard system call names
 to names for our own functions in sysdep.c that do the system call
 with retries. */

#define read sys_read
#define open sys_open
#define write sys_write

#define INTERRUPTABLE_OPEN
#define INTERRUPTABLE_IO

/* let's see, what have we got here */

#define HAVE_TCATTR		/* fixes ^z problems */
#define HAVE_SETSID		/* fixes shell problems */
#define HAVE_DUP2		/* is builtin */
#define HAVE_GETTIMEOFDAY	/* is builtin */
#define HAVE_RENAME		/* is builtin */
#define HAVE_RANDOM		/* is builtin */
#define HAVE_CLOSEDIR		/* we have a closedir */
#define HAVE_GETPAGESIZE	/* we now have getpagesize (0.96) */
#define HAVE_VFORK		/* we now have vfork (0.96) */
#define HAVE_SYS_SIGLIST	/* we have a (non-standard) sys_siglist */
#define HAVE_GETWD		/* cure conflict with getcwd? */

#define BSTRING			/* we now have bcopy, etc. (0.96) */
#define USE_UTIME		/* don't have utimes */
#define NO_SIOCTL_H		/* don't have sioctl.h */
#define SYSV_SYSTEM_DIR		/* use dirent.h */
#define USG_SYS_TIME		/* use sys/time.h, not time.h */
#define SIGNALS_VIA_CHARACTERS	/* cannot do TIOCGPGRP on a pty master */

#ifdef emacs			/* hate to do this but ... */
#include <termios.h>
#undef TIOCSCTTY		/* not implemented */
#include <signal.h>
#undef SIGIO			/* not implemented */
#endif

/* note: system malloc does not work with shared libs */

#if 0				/* choose for yourself */
#define SYSTEM_MALLOC		/* produces smaller binary */
#else
#define ULIMIT_BREAK_VALUE (32*1024*1024) /* ulimit not implemented */
#endif

/* #define rcheck		/* useful for debugging builtin malloc */

#ifdef rcheck
#define botch(msg)	(printf("%s", (msg)), abort())
#endif

/* misc. kludges for linux */

#define const			/* -traditional almost works */

#define MAXNAMLEN NAME_MAX	/* missing SYSV-ism */

#define SIGBUS SIGSEGV		/* rename to harmless work-alike */
#define SIGSYS SIGSEGV		/* rename to harmless work-alike */

/* #define _STDDEF_H		/* defeat NULL problems, no longer needed */

#define VSWTCH VSWTC		/* mis-spelling in termios.h? */
#define CDEL '\0'		/* missing termio-ism */

/* we have non-standard standard I/O (iostream) ... */

#define PENDING_OUTPUT_COUNT(FILE) ((FILE)->_pptr - (FILE)->_pbase)

/* #define LINK_STATICALLY	/* shared libs now working with 0.96c */

/* these settings now work whether or not NO_REMAP is defined */

#define C_COMPILER gcc
#define C_DEBUG_SWITCH -g -traditional
#define C_OPTIMIZE_SWITCH -O2 -fomit-frame-pointer -traditional
#define OLDXMENU_OPTIONS CFLAGS=-O2 EXTRA=insque.o /* seems to work now */
#define START_FILES pre-crt0.o /usr/lib/crt0.o
#define LIBS_DEBUG		/* override in config.h to include -lg */
#define LIBS_TERMCAP -ltermcap	/* save some space with shared libs */
#define LIBS_SYSTEM -lc

#ifndef LINK_STATICALLY
#define VIRT_ADDR_VARIES	/* needed for shared libs */
#define LD_SWITCH_SYSTEM -L/usr/lib/shlib/jump
#endif

/* extend max filesize to 32 Meg */

#define VALBITS 26
#define GCTYPEBITS 5

/* defines for linux in preparation for m-intel386.h */

#define DONT_DEFINE_SIGNAL	/* live with the warnings */
#define DONT_DEFINE_NO_REMAP	/* NO_REMAP works for linux */

/* also note other necessary changes made in the source:
   1) process.c needs a termios flavor of sending signals via chars
	(becuase Linux can't do TIOCGPGRP on a pty master)
   2) unexec.c needs treatment like IRIS for a.out header
   3) sysdep.c adds a new ifdef on HAVE_SYS_SIGLIST becuase most
      USG systems don't have one but Linux does and the signal
      numbers are different than usual.
   4) m-intel386.h needs an #ifndef DONT_DEFINE_NO_REMAP around NO_REMAP.
   */

