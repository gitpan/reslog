#! /usr/bin/perl -w
# Test processing many different log files

# Copyright (c) 2005 imacat
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

use 5.005;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 7 }

use File::Spec::Functions qw(catdir catfile updir);
use FindBin;
use lib $FindBin::Bin;
use MyHelper;
use vars qw($LOGDIR $WORKDIR $reslog);
$LOGDIR = catdir($FindBin::Bin, "logs");
$WORKDIR = catdir($LOGDIR, "working");
mkdir $WORKDIR if ! -e $WORKDIR;
$reslog = catdir($FindBin::Bin, updir, "blib", "script", "reslog");
use vars qw($fsp $fsg $fsb $fr $fep $feg $feb $csp $csg $csb $cr $cep $ceg $ceb);
use vars qw($d1 $d2 $d3 $fs1 $ft1 $fr1 $fs2 $ft2 $fr2 $fs3 $ft3 $fr3);
use vars qw($cs1 $cr1 $cs2 $cr2 $cs3 $cr3);
use vars qw($r $retno $out $err $hasfile $hasgzip $hasbzip2 $skip);
# If we have the file type checker somewhere
eval { require File::MMagic; };
`file --help 2>&1`;
$hasfile = $@ eq "" || $? == 0;
# If we have gzip support somewhere
eval { require Compress::Zlib; };
`gzip --help 2>&1`;
$hasgzip = $@ eq "" || $? == 0;
# If we have bzip2 support somewhere
eval { require Compress::Bzip2; import Compress::Bzip2 2.00; };
`bzip2 --help 2>&1`;
$hasbzip2 = $@ eq "" || $? == 0;
$skip = !$hasfile || !$hasgzip || !$hasbzip2;
$fsp = catfile($LOGDIR, "access_log");
$fsg = catfile($LOGDIR, "access_log.gz");
$fsb = catfile($LOGDIR, "access_log.bz2");
$fr = catfile($LOGDIR, "access_log");
$fep = catfile($LOGDIR, "access_log.resolved");
$feg = catfile($LOGDIR, "access_log.resolved.gz");
$feb = catfile($LOGDIR, "access_log.resolved.bz2");
$d1 = catdir($WORKDIR, "site1");
$d2 = catdir($WORKDIR, "site2");
$d3 = catdir($WORKDIR, "site3");
$fs1 = catfile($d1, "access_log");
$ft1 = catfile($d1, "access_log.tmp-reslog");
$fr1 = catfile($d1, "access_log.resolved");
$fs2 = catfile($d2, "access_log.gz");
$ft2 = catfile($d2, "access_log.tmp-reslog");
$fr2 = catfile($d2, "access_log.resolved.gz");
$fs3 = catfile($d3, "access_log.bz2");
$ft3 = catfile($d3, "access_log.tmp-reslog");
$fr3 = catfile($d3, "access_log.resolved.bz2");
($csp, $cr, $cep) = (readfile $fsp, readfile $fr, readfile $fep);
($csg, $ceg) = (readfile $fsg, readfile $feg)
    if $hasgzip;
($csb, $ceb) = (readfile $fsb, readfile $feb)
    if $hasbzip2;

# 1
$r = eval {
    return if $skip;
    mkdir $d1 if !-e $d1;
    mkdir $d2 if !-e $d2;
    mkdir $d3 if !-e $d3;
    rm $fs1, $ft1, $fr1, $fs2, $ft2, $fr2, $fs3, $ft3, $fr3;
    cp  [$fsp, $fs1], [$feg, $fr2], [$feb, $fr3],
        [$fep, $fr1], [$fsg, $fs2], [$fsb, $fs3];
    runcmd "$reslog -t 1 -k=r -o=a $fs1 - $fs3 < $fs2 > $fr2", \$retno, undef, \$err;
    ($cs1, $cs2, $cs3) = (readfile $fs1, readfile $fs2, readfile $fs3);
    ($cr1, $cr2, $cr3) = (readfile $fr1, readfile $fr2, readfile $fr3);
    rm $fs1, $ft1, $fr1, $fs2, $ft2, $fr2, $fs3, $ft3, $fr3;
    rmdir $d1;
    rmdir $d2;
    rmdir $d3;
    die $err if $retno != 0;
    1;
};
# 1
skip($skip, $r, 1, $@);
# 2
skip($skip, $cs1, "");
# 3
skip($skip, $cs2, $csg);
# 4
skip($skip, $cs3, "");
# 5
skip($skip, $cr1, $cep . $cr);
# 6
skip($skip, $cr2, $cr);
# 7
skip($skip, $cr3, $ceb . $cr);
