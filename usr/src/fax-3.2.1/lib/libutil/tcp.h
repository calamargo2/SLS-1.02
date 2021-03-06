/*
  This file is part of the NetFax system.

  (c) Copyright 1989 by David M. Siegel and Sundar Narasimhan.
      All rights reserved.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation.

    This program is distributed in the hope that it will be useful, 
    but WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#ifndef INCtcph
#define INCtcph 1

#include "net.h"

/*
  Prototypes:
*/

int tcp_make_listener(
#ifdef _PROTO
    char *service
#endif
);

int tcp_accept_connection(
#ifdef _PROTO
    int s
#endif
);

int tcp_make_connection(
#ifdef _PROTO
    char *host,
    char *service
#endif
);

#endif
