; Jim Dashow: In Winter Shine  CH 1-3	SECTION 1   FILE = ws1.13f
;		   compile i16 + i15 + i13
; this score currently has i13 (reverb) disabled (see below)

f1 0  512   10	 1
f2 0  512   10	 1   -.5    -.25   .1
f3 0  512   10	 1   .05    -.5   .05	 .5    .05   -.3   .05	 1
f4 0  128    7	 0   64       1    64	  0
f5 0  512   10	 1   .05    -.6
f6 0  512   10	 1   -.6     .15
f7 0  17    5	 1   16     50
f8 0  17    5	 1   16     16
f9  0	64    5   .0001   32	.16    5     1	  27	1
f10 0	64    5   1    16    1000    24   1    24    1
f11 50	32    5     20	  32	  1
f9  15	128   5    .001    50	 .16   5    1	 20   .8    7	.001   7   1
20   .8   7    .001    7   1	5    1
f9 31	128   7    0   40   .1	 24   1    40	 .85   24   0
f3 31	512    10    1	  .15	-.6   .2   -.5	 .3    -.4   .3    .3
f9 39.5    64	 7   1	  30	1    2	 0   30   0    2    1
f12  46   64	 7   0	   12	  .05	 20   1    12	.9    20   0
f14  0	 64   -2   7.05   8.06	 9.07	10.08	8.03   9.02    10.04  11.01
7.10	8.11   10.00   10.09   4   6   9   5   1   1   3   2   7  2   1   2   2
9   4	7   3	2   2  4   2   8   3   7   6   5   2   1   1
c
f-1 50
f-5 50
f-9 50
c
i15   .11   2.39  16000 0     .33   0	  .10	8.06  0     0	  2.3807
 .01  1.219 7.01  50	1     0     0	  0	0     0     0	  0
0     0     0	  0
i15   .22   2.28  .	.     .1    .	  .	10.08 .     .	  1.5808
 .    1.208 .     .     0
c
i15   36.11 1.89  .     .     .25   .     .     9.07  .     .     6.8085
 .    1.169 .	  .	1
c
i15   36.22 1.78  .     .     .5    .     .     7.05  .     .     2.7083
 .    1.158 .	  .	0

i15   6.0   6     12000 .     .15   .     .     1.08  .7038 14    6.5808
 .    36.005 7.005 70	1     3.3   .04   13.41 .     14    1	  .08
c
i15   .     .	  .	.     .     .	  .	.     .3078 .	  2.5667
 .    31.005 .	  .	.     .     64.04 31.41 13
c
i15   12    4     .     .     .     .     .     5.08  .     .     .
 .    21.005 .	  .	.     .     .	  .	.     .     0	  0
c
i15   .     .	  .	.     .     .	  .	.     .7038 .	  6.5808
 .    24.005 .    .     .     .     .04   13.41
c
i15   19    6     .     .     .     .     .     5.12  .     .     .
 .    33.005 .    .     .     4.3   .     19.41 .     .     1     .08
c
i15   .     .	  .	.     .     .	  .	.     .3078 .	  2.5667
 .   38.005 .	  .	.     .     64.04 35.41

i15   25    4	  .	.     .     .	  .	9.12  .     .	  .
 .    22.005 .	  .	.     .     .	  .	.     .     0	  0
c
i15   .     .	  .	.     .     .	  .	.     .7038 .	  6.5808
 .    25.005 .	  .	.     .     .04   19.41

i15   50    .     14000 .     .2    .     .     1.12  .8508 .     .
 .    41.005 .	  .	8.2   3.3   .	  0	0     0     1	  .11
c
i15   .     .     .     .     .     .     .     .     .0855 .     .
 .    33.005 .	  .	.     .     64.04
c
i16   .44   13.56 5000  0     .04   .75   1     .09   8.06  0     7.02
 3.5  1.007 8	  70	1     0     0	  0	0     0     0	  0
 0    0     0	  0
i16   .     .     .     .     .     .     .     .     10.08 .     5.06
 .    .     .     .     0
c
i16   15    12    .     .     .     .8    .     .     10.04 .     7.02
c
i16   .     .	  .	.     .     .	  .	.     9.02  .	  7.03
 .    .     .     .     1
c
i16   27    4	  .	.     .     .	  .6	50.09 7.10  .	  .
 .03  .     7	  20
c
i16   27.12 .     .     .     .     .     .     .     10.00 .     .
 .    .     .	  .	0
c
i16   31.12 5.5   .     .     .     .     3     .09   10.09 .     7.02
c
i16   31.0  .     .     .     .     .     .     .     8.11  .     7.03
 .    .     .     .     1
c
i16   36.5  .	  3000	.     -1.00 1.0005 22	.02   9.06  .	  5.02
c
i16   36.62 .	  .	.     .     .	  28	255.06 7.05 .	  5.03
 .    .     .	  .	0
c
i16   38.5  1     .     .     -.07  1.00  1     .07   9.02  .     5.02
c
i16   .     .     .     .     .     .     .     .     8.03  .     .
 .    .     .     .     1
c
i16   39.5  6.75  .	.     .     .	  8	.09   .     .	  5.03
c
i16   .     6.5   .     .     .     .     6.5   .     9.02  .     .
 .    .     .	  .	0
c
i16   42.12 4.65  .     .     .     .     .     .     10.09 .     5.02
c
i16   42    4.88  .     .     .     .     8     .     10.00 .     5.03
 .    .     .     .     1
c
i16   46.88 7.12  5000	.     .04   .8	  6.5	.12   .     .	  7.03
 .    1.4   .     16    .75
c
i16   46.77 7.23  .	.     .     .	  7.8	.     10.09 .	  7.02
 .    .     .     .     .25
c
i16   46    8	  .	.     .     .	  5.5	.     9.02  .	  7.03
 .    .     .	  .	0
c
i16   46.25 7.75  .	.     .     .	  6	.     8.03  .	  .
 .    .     .	  .	1
c
;i13   0     54.1  .63	3     15    -6	  .04	.005  .05   29	  .04
; .02  .02   0	  0	.5    0     0	  0	58    1     0	  0
c
s
f0 1
c end section 1 Ch# 1-3
e
