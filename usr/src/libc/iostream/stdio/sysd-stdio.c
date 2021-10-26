/* Copyright (C) 1991, 1992 Free Software Foundation, Inc.
This file is part of the GNU C Library.

The GNU C Library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public License as
published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

The GNU C Library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with the GNU C Library; see the file COPYING.LIB.  If
not, write to the Free Software Foundation, Inc., 675 Mass Ave,
Cambridge, MA 02139, USA.  */

#include <ansidecl.h>
#include <errno.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#ifndef linux

/* Read N bytes into BUF from COOKIE.  */
int
DEFUN(__stdio_read, (cookie, buf, n),
      PTR cookie AND register char *buf AND register size_t n)
{
#if	defined (EINTR) && defined (EINTR_REPEAT)
  CONST int fd = *(int *) cookie;
  int save = errno;
  int nread;

 try:;
  errno = 0;
  nread = __read(fd, buf, (int) n);
  if (nread < 0)
    {
      if (errno == EINTR)
	goto try;
      return -1;
    }
  errno = save;
  return nread;

#else	/* No EINTR.  */
  return __read(*(int *) cookie, buf, (int) n);
#endif
}


/* Write N bytes from BUF to COOKIE.  */
int
DEFUN(__stdio_write, (cookie, buf, n),
      PTR cookie AND register CONST char *buf AND register size_t n)
{
  CONST int fd = *(int *) cookie;
  register size_t written = 0;

  while (n > 0)
    {
      int count = __write (fd, buf, (int) n);
      if (count > 0)
	{
	  buf += count;
	  written += count;
	  n -= count;
	}
      else if (count < 0
#if	defined (EINTR) && defined (EINTR_REPEAT)
	       && errno != EINTR
#endif
	       )
	/* Write error.  */
	return -1;
    }

  return (int) written;
}


/* Move COOKIE's file position *POS bytes, according to WHENCE.
   The new file position is stored in *POS.
   Returns zero if successful, nonzero if not.  */
int
DEFUN(__stdio_seek, (cookie, pos, whence),
      PTR cookie AND fpos_t *pos AND int whence)
{
  off_t new;
  new = __lseek(*(int *) cookie, (off_t) *pos, whence);
  if (new < 0)
    return 1;
  *pos = (fpos_t) new;
  return 0;
}


/* Close COOKIE.  */
int
DEFUN(__stdio_close, (cookie), PTR cookie)
{
  return __close(*(int *) cookie);
}


/* Open the given file with the mode given in the __io_mode argument.  */
PTR
DEFUN(__stdio_open, (filename, m, fdptr),
      CONST char *filename AND __io_mode m AND int *fdptr)
{
  int mode;

  if (m.__read && m.__write)
    mode = O_RDWR;
  else
    mode = m.__read ? O_RDONLY : O_WRONLY;

  if (m.__append)
    mode |= O_APPEND;
  if (m.__exclusive)
    mode |= O_EXCL;
  if (m.__truncate)
    mode |= O_TRUNC;

  if (m.__create)
    *fdptr = __open(filename, mode | O_CREAT,
		    S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH|S_IWOTH);
  else
    *fdptr = __open(filename, mode);

  return NULL;

}

/* Write a message to the error output.
   Try hard to make it really get out.  */
void
DEFUN(__stdio_errmsg, (msg, len), CONST char *msg AND size_t len)
{
  while (len > 0)
    {
      register int count = __write(2, msg, (int) len);
      if (count > 0)
	{
	  msg += count;
	  len -= count;
	}
      else if (count < 0
#if	defined (EINTR) && defined (EINTR_REPEAT)
	       && errno != EINTR
#endif
	       )
	break;
    }
}

#endif

/* Return nonzero if DIR is an existent directory.  */
static int
DEFUN(diraccess, (dir), CONST char *dir)
{
  struct stat buf;
  uid_t euid;

  if (__stat(dir, &buf) != 0 || !S_ISDIR(buf.st_mode)) return 0;

  /* That is going to be tough. */

  euid = __geteuid ();
  
  /* super user */
  if (!euid) return 1;

  if (euid == buf.st_uid)
    return ((buf.st_mode & S_IWUSR) && (buf.st_mode & S_IXUSR));

  if (__getegid () == buf.st_gid)
    return ((buf.st_mode & S_IWGRP) && (buf.st_mode & S_IXGRP));

  return ((buf.st_mode & S_IWOTH) && (buf.st_mode & S_IXOTH));
}

/* Return nonzero if FILE exists.  */
static inline int
DEFUN(exists, (file), CONST char *file)
{
  struct stat buf;

  return (__stat(file, &buf) == 0 || errno != ENOENT);
}

/* These are the characters used in temporary filenames.  */
static CONST char letters[] =
  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

/* Generate a temporary filename.
   If DIR_SEARCH is nonzero, DIR and PFX are used as
   described for tempnam.  If not, a temporary filename
   in P_tmpdir with no special prefix is generated.  If LENPTR
   is not NULL, *LENPTR is set the to length (including the
   terminating '\0') of the resultant filename, which is returned.
   This goes through a cyclic pattern of all possible filenames
   consisting of five decimal digits of the current pid and three
   of the characters in `letters'.  Data for tempnam and tmpnam
   is kept separate, but when tempnam is using P_tmpdir and no
   prefix (i.e, it is identical to tmpnam), the same data is used.
   Each potential filename is tested for an already-existing file of
   the same name, and no name of an existing file will be returned.
   When the cycle reaches its end (12345ZZZ), NULL is returned.  */
char *
DEFUN(__stdio_gen_tempname, (dir, pfx, dir_search, lenptr),
      CONST char *dir AND CONST char *pfx AND
      int dir_search AND size_t *lenptr)
{
  static CONST char tmpdir[] = P_tmpdir;
  static struct
    {
      char digits [4];
    } infos[2], *info;
  static char buf[FILENAME_MAX];
  static pid_t oldpid = (pid_t) 0;
  pid_t pid = __getpid();
  register size_t len, plen, dlen;
  int i, carry;

  if (dir_search)
    {
      register CONST char *d = getenv("TMPDIR");
      if (d != NULL && !diraccess(d))
	d = NULL;
      if (d == NULL && dir != NULL && diraccess(dir))
	d = dir;
      if (d == NULL && diraccess(tmpdir))
	d = tmpdir;
      if (d == NULL && diraccess("/tmp"))
	d = "/tmp";
      if (d == NULL)
	{
	  errno = ENOENT;
	  return NULL;
	}
      dir = d;
    }
  else
    dir = tmpdir;

  dlen = strlen (dir);

  /* Remove trailing slashes from the directory name.  */
  while (dlen > 1 && dir[dlen - 1] == '/')
    --dlen;

  if (pfx != NULL && *pfx != '\0')
    {
      plen = strlen(pfx);
      if (plen > 5)
	plen = 5;
    }
  else
    plen = 0;

  if (dir != tmpdir && !strcmp(dir, tmpdir))
    dir = tmpdir;
  info = &infos[(plen == 0 && dir == tmpdir) ? 1 : 0];

  if (pid != oldpid)
    {
      oldpid = pid;
      for (i = 0; i < sizeof (info->digits); i++)
	infos[0].digits[i] = infos[1].digits[i] = 0;
    }

  len = dlen + 1 + plen + 5;
  for (;;)
    {
      if (info->digits [sizeof (info->digits) - 1])
	{
	  errno = EEXIST;
	  return NULL;
	}

      if ((sizeof (buf) - sizeof (info->digits)) < len ||
		sprintf(buf, "%.*s/%.*s%.5d", (int) dlen, dir,
		(int) plen, pfx, pid % 100000) != (int) len)
	return NULL;

      /* Get the last part of string */
      for (i = 0; i < sizeof (info->digits) - 1; i++)
        buf [len++] = letters [info->digits [i]];
      buf [len] = '\0';

      /* Always return a unique string.  */
      carry = ++info->digits [0] / (sizeof (letters) - 1);
      info->digits [0] %= (sizeof (letters) - 1);
      for (i = 1; i < sizeof (info->digits); i++) {
	  info->digits [i] += carry;
	  carry = info->digits [i] / (sizeof (letters) - 1);
	  info->digits [i] %= (sizeof (letters) - 1);
      }

      if (!exists (buf))
	break;
    }

  if (lenptr != NULL)
    *lenptr = len + 1;
  return buf;
}
