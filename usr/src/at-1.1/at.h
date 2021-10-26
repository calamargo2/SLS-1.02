/* 
 *  at.h -  header for at(1)
 *  Copyright (C) 1993  Thomas Koenig
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */


extern int fcreated;
extern char *namep;
extern char atfile[];

void panic(char *a);
void perr(char *a);
void usage(void);
time_t parsetime(int argc, char **argv);

static char at_h_rcsid[] ="$Id: at.h,v 1.3 1993/01/17 01:07:11 kernel Exp kernel $";
