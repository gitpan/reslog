#! /usr/bin/perl -w
# Test the gzip compressed log file

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

BEGIN { plan tests => 39 }

use File::Spec::Functions qw(catdir catfile updir);
use FindBin;
use lib $FindBin::Bin;
use MyHelper;
use vars qw($LOGDIR $WORKDIR $reslog);
$LOGDIR = catdir($FindBin::Bin, "logs");
$WORKDIR = catdir($LOGDIR, "working");
mkdir $WORKDIR if ! -e $WORKDIR;
$reslog = catdir($FindBin::Bin, updir, "blib", "script", "reslog");
use vars qw($fs $fr $fe $cs $cr $ce $fs1 $ft1 $fr1 $cs1 $cr1);
use vars qw($fs2 $fr2 $cs2 $cr2);
use vars qw($r $retno $out $err $hasfile $hasgzip);
# If we have the file type checker somewhere
eval { require File::MMagic; };
`file --help 2>&1`;
$hasfile = $@ eq "" || $? == 0;
# If we have gzip support somewhere
eval { require Compress::Zlib; };
`gzip --help 2>&1`;
$hasgzip = $@ eq "" || $? == 0;
$fs = catfile($LOGDIR, "access_log.gz");
$fr = catfile($LOGDIR, "access_log");
$fe = catfile($LOGDIR, "access_log.resolved.gz");
$fs1 = catfile($WORKDIR, "access_log.gz");
$ft1 = catfile($WORKDIR, "access_log.tmp-reslog");
$fr1 = catfile($WORKDIR, "access_log.resolved.gz");
$fs2 = catfile($WORKDIR, "access_log.ct.gz");
$fr2 = catfile($WORKDIR, "access_log.rsd.gz");
($cs, $cr, $ce) = (readfile $fs, readfile $fr, readfile $fe)
    if $hasgzip;

# The default keep behavior
$r = eval {
    return unless $hasgzip;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "\"$reslog\" -t 1 \"$fs1\"", \$retno, \$out, \$err;
    ($cs1, $cr1) = (-e $fs1? "exists": "not exists", readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 1
skip(!$hasgzip, $r, 1, $@);
# 2
skip(!$hasgzip, $cs1, "not exists");
# 3
skip(!$hasgzip, $cr1, $cr);

# Keep all
$r = eval {
    return unless $hasgzip;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "\"$reslog\" -t 1 -k=a \"$fs1\"", \$retno, \$out, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 4
skip(!$hasgzip, $r, 1, $@);
# 5
skip(!$hasgzip, $cs1, $cs);
# 6
skip(!$hasgzip, $cr1, $cr);

# Keep restart
$r = eval {
    return unless $hasgzip;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "\"$reslog\" -t 1 -k=r \"$fs1\"", \$retno, \$out, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 7
skip(!$hasgzip, $r, 1, $@);
# 8
skip(!$hasgzip, $cs1, "");
# 9
skip(!$hasgzip, $cr1, $cr);

# Keep delete
$r = eval {
    return unless $hasgzip;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "\"$reslog\" -t 1 -k=d \"$fs1\"", \$retno, \$out, \$err;
    ($cs1, $cr1) = (-e $fs1? "exists": "not exists", readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 10
skip(!$hasgzip, $r, 1, $@);
# 11
skip(!$hasgzip, $cs1, "not exists");
# 12
skip(!$hasgzip, $cr1, $cr);

# The default override behavior
$r = eval {
    return unless $hasgzip;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1], [$fe, $fr1];
    runcmd "\"$reslog\" -t 1 \"$fs1\"", \$retno, \$out, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno == 0;
    1;
};
# 13
skip(!$hasgzip, $r, 1, $@);
# 14
skip(!$hasgzip, $cs1, $cs);
# 15
skip(!$hasgzip, $cr1, $ce);

# Override overwrite
$r = eval {
    return unless $hasgzip;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1], [$fe, $fr1];
    runcmd "\"$reslog\" -t 1 -o=o \"$fs1\"", \$retno, \$out, \$err;
    ($cs1, $cr1) = (-e $fs1? "exists": "not exists", readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 16
skip(!$hasgzip, $r, 1, $@);
# 17
skip(!$hasgzip, $cs1, "not exists");
# 18
skip(!$hasgzip, $cr1, $cr);

# Override append
$r = eval {
    return unless $hasgzip;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1], [$fe, $fr1];
    runcmd "\"$reslog\" -t 1 -o=a \"$fs1\"", \$retno, \$out, \$err;
    ($cs1, $cr1) = (-e $fs1? "exists": "not exists", readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 19
skip(!$hasgzip, $r, 1, $@);
# 20
skip(!$hasgzip, $cs1, "not exists");
# 21
skip(!$hasgzip, $cr1, ($hasgzip? $ce . $cr: undef));

# Override fail
$r = eval {
    return unless $hasgzip;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1], [$fe, $fr1];
    runcmd "\"$reslog\" -t 1 -o=f \"$fs1\"", \$retno, \$out, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno == 0;
    1;
};
# 22
skip(!$hasgzip, $r, 1, $@);
# 23
skip(!$hasgzip, $cs1, $cs);
# 24
skip(!$hasgzip, $cr1, $ce);

# From file to STDOUT
$r = eval {
    return unless $hasgzip && $hasfile;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "\"$reslog\" -t 1 -c \"$fs1\" > \"$fr1\"", \$retno, undef, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 25
skip(!$hasgzip || !$hasfile, $r, 1, $@);
# 26
skip(!$hasgzip || !$hasfile, $cs1, $cs);
# 27
skip(!$hasgzip || !$hasfile, $cr1, $cr);

# From STDIN to STDOUT
$r = eval {
    return unless $hasgzip && $hasfile;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "\"$reslog\" -t 1 < \"$fs1\" > \"$fr1\"", \$retno, undef, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 28
skip(!$hasgzip || !$hasfile, $r, 1, $@);
# 29
skip(!$hasgzip || !$hasfile, $cs1, $cs);
# 30
skip(!$hasgzip || !$hasfile, $cr1, $cr);

# Attach our suffix
$r = eval {
    rm $fs1, $ft1, $fr1, $fr2;
    cp [$fs, $fs1];
    runcmd "\"$reslog\" -t 1 -s=.rsd \"$fs1\"", \$retno, \$out, \$err;
    ($cr1, $cr2) = (-e $fr1? "exists": "not exists", readfile $fr2);
    rm $fs1, $ft1, $fr1, $fr2;
    die $out . $err if $retno != 0;
    1;
};
# 31
ok($r, 1, $@);
# 32
ok($cr1, "not exists");
# 33
ok($cr2, $cr);

# Trim the file name suffix
$r = eval {
    rm $fs1, $ft1, $fr1, $fs2;
    cp [$fs, $fs1], [$fs, $fs2];
    runcmd "\"$reslog\" -t 1 -t=.ct \"$fs2\"", \$retno, \$out, \$err;
    ($cs1, $cs2) = (readfile $fs1, -e $fs2? "exists": "not exists");
    rm $fs1, $ft1, $fr1, $fs2;
    die $out . $err if $retno != 0;
    1;
};
# 34
ok($r, 1, $@);
# 35
ok($cs1, $cs);
# 36
ok($cs2, "not exists");

# Trim and attach our suffix
$r = eval {
    rm $fs2, $ft1, $fr2;
    cp [$fs, $fs2];
    runcmd "\"$reslog\" -t 1 -t=.ct -s=.rsd \"$fs2\"", \$retno, \$out, \$err;
    ($cs2, $cr2) = (-e $fs2? "exists": "not exists", readfile $fr2);
    rm $fs2, $ft1, $fr2;
    die $out . $err if $retno != 0;
    1;
};
# 37
ok($r, 1, $@);
# 38
ok($cs2, "not exists");
# 39
ok($cr2, $cr);
