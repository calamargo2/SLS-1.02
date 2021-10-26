#  ppmtog3.sh
#
#   (c) Copyright 1992 by David M. Siegel.
#       All rights reserved.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation.
#
#   This program is distributed in the hope that it will be useful, 
#   but WITHOUT ANY WARRANTY; without even the implied warranty of 
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

set path=(/bin /usr/bin /usr/ucb /usr/local/bin /usr/local/pbmplus)

pnmcut 0 0 1728 2145 $1.ppm.$2 | pbmtog3 > $1.g3.$2

/bin/rm -f $1.ppm.$2
