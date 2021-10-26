#!/bin/csh -f
# Provide VERY minimal support for mail generated by Sun's Openwindows mailtool.
# Basically, this lets you see the text part, but not much else...

set TMPFILE=/tmp/suntomime.$$
echo "Content-type: multipart/mixed; boundary=--------" > $TMPFILE
echo "" >> $TMPFILE
sed -e 's/X-Sun-Data-Type:/Content-type:/' >> $TMPFILE < $1
echo "------------" >> $TMPFILE
metamail -d -z $TMPFILE
