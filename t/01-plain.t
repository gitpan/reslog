#! /usr/bin/perl -w
# Test the plain text log file

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
use vars qw($r $retno $out $err $hasfile);
# If we have the file type checker somewhere
eval { require File::MMagic; };
`file --help 2>&1`;
$hasfile = $@ eq "" || $? == 0;
$fs = catfile($LOGDIR, "access_log");
$fr = catfile($LOGDIR, "access_log");
$fe = catfile($LOGDIR, "access_log.resolved");
$fs1 = catfile($WORKDIR, "access_log");
$ft1 = catfile($WORKDIR, "access_log.tmp-reslog");
$fr1 = catfile($WORKDIR, "access_log.resolved");
$fs2 = catfile($WORKDIR, "access_log.ct");
$fr2 = catfile($WORKDIR, "access_log.rsd");
($cs, $cr, $ce) = (readfile $fs, readfile $fr, readfile $fe);

# The default keep behavior
$r = eval {
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    $reslog =~ s/"/\\"/g;
    runcmd "\"$reslog\" -t 1 \"$fs1\"", \$retno, \$out, \$err;
    ($cs1, $cr1) = (-e $fs1? "exists": "not exists", readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 1
ok($r, 1, $@);
# 2
ok($cs1, "not exists");
# 3
ok($cr1, $cr);

# Keep all
$r = eval {
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "\"$reslog\" -t 1 -k=a \"$fs1\"", \$retno, \$out, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 4
ok($r, 1, $@);
# 5
ok($cs1, $cs);
# 6
ok($cr1, $cr);

# Keep restart
$r = eval {
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "\"$reslog\" -t 1 -k=r \"$fs1\"", \$retno, \$out, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 7
ok($r, 1, $@);
# 8
ok($cs1, "");
# 9
ok($cr1, $cr);

# Keep delete
$r = eval {
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "\"$reslog\" -t 1 -k=d \"$fs1\"", \$retno, \$out, \$err;
    ($cs1, $cr1) = (-e $fs1? "exists": "not exists", readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 10
ok($r, 1, $@);
# 11
ok($cs1, "not exists");
# 12
ok($cr1, $cr);

# The default override behavior
$r = eval {
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1], [$fe, $fr1];
    runcmd "\"$reslog\" -t 1 \"$fs1\"", \$retno, \$out, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno == 0;
    1;
};
# 13
ok($r, 1, $@);
# 14
ok($cs1, $cs);
# 15
ok($cr1, $ce);

# Override overwrite
$r = eval {
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1], [$fe, $fr1];
    runcmd "\"$reslog\" -t 1 -o=o \"$fs1\"", \$retno, \$out, \$err;
    ($cs1, $cr1) = (-e $fs1? "exists": "not exists", readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 16
ok($r, 1, $@);
# 17
ok($cs1, "not exists");
# 18
ok($cr1, $cr);

# Override append
$r = eval {
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1], [$fe, $fr1];
    runcmd "\"$reslog\" -t 1 -o=a \"$fs1\"", \$retno, \$out, \$err;
    ($cs1, $cr1) = (-e $fs1? "exists": "not exists", readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 19
ok($r, 1, $@);
# 20
ok($cs1, "not exists");
# 21
ok($cr1, $ce . $cr);

# Override fail
$r = eval {
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1], [$fe, $fr1];
    runcmd "\"$reslog\" -t 1 -o=f \"$fs1\"", \$retno, \$out, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno == 0;
    1;
};
# 22
ok($r, 1, $@);
# 23
ok($cs1, $cs);
# 24
ok($cr1, $ce);

# From file to STDOUT
$r = eval {
    return unless $hasfile;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "\"$reslog\" -t 1 -c \"$fs1\" > \"$fr1\"", \$retno, undef, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 25
skip(!$hasfile, $r, 1, $@);
# 26
skip(!$hasfile, $cs1, $cs);
# 27
skip(!$hasfile, $cr1, $cr);

# From STDIN to STDOUT
$r = eval {
    return unless $hasfile;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "\"$reslog\" -t 1 < \"$fs1\" > \"$fr1\"", \$retno, undef, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 28
skip(!$hasfile, $r, 1, $@);
# 29
skip(!$hasfile, $cs1, $cs);
# 30
skip(!$hasfile, $cr1, $cr);

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
