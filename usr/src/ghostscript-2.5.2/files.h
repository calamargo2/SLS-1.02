/* Copyright (C) 1989, 1992 Aladdin Enterprises.  All rights reserved.
   Distributed by Free Software Foundation, Inc.

This file is part of Ghostscript.

Ghostscript is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY.  No author or distributor accepts responsibility
to anyone for the consequences of using it or for whether it serves any
particular purpose or works at all, unless he says so in writing.  Refer
to the Ghostscript General Public License for full details.

Everyone is granted permission to copy, modify and redistribute
Ghostscript, but only under the conditions described in the Ghostscript
General Public License.  A copy of this license is supposed to have been
given to you along with Ghostscript so you can know your rights and
responsibilities.  It should be in a file named COPYING.  Among other
things, the copyright notice and this notice must be preserved on all
copies.  */

/* files.h */
/* Common declarations for zfile.c and zfileio.c */
/* Requires stream.h */

/* File objects store a pointer to a stream in value.pfile. */
/* A file object is valid if its "size" matches the read_id or write_id */
/* (as appropriate) in the stream it points to.  This arrangement */
/* allows us to detect closed files reliably, while allowing us to */
/* reuse closed streams for new files. */
#define fptr(pref) (pref)->value.pfile
#define make_file(pref,a,id,s)\
  make_tasv(pref,t_file,a,id,pfile,s)

/* The standard files.  0 is %stdin, 1 is %stdout. */
extern stream std_files[];
/* An invalid file. */
extern stream invalid_file_entry;

/* Macros for checking file validity */
#define check_file_access(svar,op,acc)\
   {	svar = fptr(op);	/* do first, acc may refer to it */\
	if ( !(acc) ) return e_invalidaccess;\
   }
#define check_file_ref(svar,op,acc)\
   {	if ( !r_has_type(op, t_file) ) return e_typecheck;\
	check_file_access(svar,op,acc);\
   }
#define check_file(svar,op)\
	check_file_ref(svar, op, (svar->read_id | svar->write_id) == r_size(op))
#define check_read_file(svar,op)\
   {	check_read_type(*(op), t_file);\
	check_file_access(svar, op, svar->read_id == r_size(op));\
   }
#define check_write_file(svar,op)\
   {	check_write_type(*(op), t_file);\
	check_file_access(svar, op, svar->write_id == r_size(op));\
   }
