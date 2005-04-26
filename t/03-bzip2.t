#! /usr/bin/perl -w
# Test the bzip2 compressed log file

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

BEGIN { plan tests => 30 }

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
use vars qw($r $retno $out $err $hasfile $hasbzip2);
# If we have the file type checker somewhere
eval { require File::MMagic; };
`file --help 2>&1`;
$hasfile = $@ eq "" || $? == 0;
# If we have bzip2 support somewhere
eval { require Compress::Bzip2; import Compress::Bzip2 2.00; };
`bzip2 --help 2>&1`;
$hasbzip2 = $@ eq "" || $? == 0;
$fs = catfile($LOGDIR, "access_log.bz2");
$fr = catfile($LOGDIR, "access_log");
$fe = catfile($LOGDIR, "access_log.resolved.bz2");
$fs1 = catfile($WORKDIR, "access_log.bz2");
$ft1 = catfile($WORKDIR, "access_log.tmp-reslog");
$fr1 = catfile($WORKDIR, "access_log.resolved.bz2");
($cs, $cr, $ce) = (readfile $fs, readfile $fr, readfile $fe)
    if $hasbzip2;

# The default keep behavior
$r = eval {
    return unless $hasbzip2;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "$reslog -t 1 $fs1", \$retno, \$out, \$err;
    ($cs1, $cr1) = (-e $fs1? "exists": "not exists", readfile $fr1);
    #rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 1
skip(!$hasbzip2, $r, 1, $@);
# 2
skip(!$hasbzip2, $cs1, "not exists");
# 3
skip(!$hasbzip2, $cr1, $cr);

# Keep all
$r = eval {
    return unless $hasbzip2;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "$reslog -t 1 -k=a $fs1", \$retno, \$out, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 4
skip(!$hasbzip2, $r, 1, $@);
# 5
skip(!$hasbzip2, $cs1, $cs);
# 6
skip(!$hasbzip2, $cr1, $cr);

# Keep restart
$r = eval {
    return unless $hasbzip2;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "$reslog -t 1 -k=r $fs1", \$retno, \$out, \$err;
    ($cs1, $cr1) = (-s $fs1? readfile $fs1: "", readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 7
skip(!$hasbzip2, $r, 1, $@);
# 8
skip(!$hasbzip2, $cs1, "");
# 9
skip(!$hasbzip2, $cr1, $cr);

# Keep delete
$r = eval {
    return unless $hasbzip2;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "$reslog -t 1 -k=d $fs1", \$retno, \$out, \$err;
    ($cs1, $cr1) = (-e $fs1? "exists": "not exists", readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 10
skip(!$hasbzip2, $r, 1, $@);
# 11
skip(!$hasbzip2, $cs1, "not exists");
# 12
skip(!$hasbzip2, $cr1, $cr);

# The default override behavior
$r = eval {
    return unless $hasbzip2;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1], [$fe, $fr1];
    runcmd "$reslog -t 1 $fs1", \$retno, \$out, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno == 0;
    1;
};
# 13
skip(!$hasbzip2, $r, 1, $@);
# 14
skip(!$hasbzip2, $cs1, $cs);
# 15
skip(!$hasbzip2, $cr1, $ce);

# Override overwrite
$r = eval {
    return unless $hasbzip2;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1], [$fe, $fr1];
    runcmd "$reslog -t 1 -o=o $fs1", \$retno, \$out, \$err;
    ($cs1, $cr1) = (-e $fs1? "exists": "not exists", readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 16
skip(!$hasbzip2, $r, 1, $@);
# 17
skip(!$hasbzip2, $cs1, "not exists");
# 18
skip(!$hasbzip2, $cr1, $cr);

# Override append
$r = eval {
    return unless $hasbzip2;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1], [$fe, $fr1];
    runcmd "$reslog -t 1 -o=a $fs1", \$retno, \$out, \$err;
    ($cs1, $cr1) = (-e $fs1? "exists": "not exists", readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 19
skip(!$hasbzip2, $r, 1, $@);
# 20
skip(!$hasbzip2, $cs1, "not exists");
# 21
skip(!$hasbzip2, $cr1, ($hasbzip2? $ce . $cr: undef));

# Override fail
$r = eval {
    return unless $hasbzip2;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1], [$fe, $fr1];
    runcmd "$reslog -t 1 -o=f $fs1", \$retno, \$out, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno == 0;
    1;
};
# 22
skip(!$hasbzip2, $r, 1, $@);
# 23
skip(!$hasbzip2, $cs1, $cs);
# 24
skip(!$hasbzip2, $cr1, $ce);

# From file to STDOUT
$r = eval {
    return unless $hasbzip2 && $hasfile;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "$reslog -t 1 -c $fs1 > $fr1", \$retno, undef, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 25
skip(!$hasbzip2 || !$hasfile, $r, 1, $@);
# 26
skip(!$hasbzip2 || !$hasfile, $cs1, $cs);
# 27
skip(!$hasbzip2 || !$hasfile, $cr1, $cr);

# From STDIN to STDOUT
$r = eval {
    return unless $hasbzip2 && $hasfile;
    rm $fs1, $ft1, $fr1;
    cp [$fs, $fs1];
    runcmd "$reslog -t 1 < $fs1 > $fr1", \$retno, undef, \$err;
    ($cs1, $cr1) = (readfile $fs1, readfile $fr1);
    rm $fs1, $ft1, $fr1;
    die $out . $err if $retno != 0;
    1;
};
# 28
skip(!$hasbzip2 || !$hasfile, $r, 1, $@);
# 29
skip(!$hasbzip2 || !$hasfile, $cs1, $cs);
# 30
skip(!$hasbzip2 || !$hasfile, $cr1, $cr);
