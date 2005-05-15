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

BEGIN { plan tests => 14 }

use File::Basename qw(basename);
use File::Spec::Functions qw(splitdir catdir catfile updir);
use FindBin;
use lib $FindBin::Bin;
use _helper;
use vars qw($te $WORKDIR $reslog $nofile);
use vars qw($fs1 $ft1 $fr1 $fs2 $fr2);

$te = "text/plain";
$WORKDIR = catdir($FindBin::Bin, "logs");
@_ = splitdir $FindBin::Bin;
$reslog = catdir(@_[0...$#_-1], "blib", "script", "reslog");

# If we have the file type checker somewhere
$nofile =   eval { require File::MMagic; 1; }
            || defined whereis "file"?
    undef: "File::MMagic or file executable not available";

$fs1 = catfile($WORKDIR, "access_log");
$ft1 = catfile($WORKDIR, "access_log.tmp-reslog");
$fr1 = catfile($WORKDIR, "access_log.resolved");
$fs2 = catfile($WORKDIR, "access_log.ct");
$fr2 = catfile($WORKDIR, "access_log.rsd");

# 1: The default keep behavior
$_ = eval {
    my ($retno, $out, $err);
    my ($fl, $fl1, $cs0, $cr1, $tr1);
    mkcldir $WORKDIR;
    $cs0 = mkrndlog $fs1;
    $reslog =~ s/"/\\"/g;
    runcmd "\"$reslog\" -t 1 \"$fs1\"", \$retno, \$out, \$err;
    ($fl, $fl1) = (join(" ", sort map basename($_), ($fr1)), flist $WORKDIR);
    ($cr1, $tr1) = (fread $fr1, ftype $fr1);
    rmalldir $WORKDIR;
    die $out . $err if $retno != 0;
    die "result files incorrect.\nGot: $fl1\nExpected: $fl\n"
        if $fl1 ne $fl;
    die "$fr1: result type incorrect.\nGot: $tr1\nExpected: $te\n"
        if !$nofile && $tr1 ne $te;
    die "$fr1: result incorrect.\nGot:\n$cr1\nExpected:\n$cs0\n"
        if $cr1 ne $cs0;
    1;
};
ok($_, 1, $@);

# 2: Keep all
$_ = eval {
    my ($retno, $out, $err);
    my ($fl, $fl1, $cs0, $cs1, $cr1, $tr1);
    mkcldir $WORKDIR;
    $cs0 = mkrndlog $fs1;
    runcmd "\"$reslog\" -t 1 -k=a \"$fs1\"", \$retno, \$out, \$err;
    ($fl, $fl1) = (join(" ", sort map basename($_), ($fs1, $fr1)), flist $WORKDIR);
    ($cs1, $cr1, $tr1) = (fread $fs1, fread $fr1, ftype $fr1);
    rmalldir $WORKDIR;
    die $out . $err if $retno != 0;
    die "result files incorrect.\nGot: $fl1\nExpected: $fl\n"
        if $fl1 ne $fl;
    die "$fs1: source incorrect.\nGot:\n$cs1\nExpected:\n$cs0\n"
        if $cs1 ne $cs0;
    die "$fr1: result type incorrect.\nGot: $tr1\nExpected: $te\n"
        if !$nofile && $tr1 ne $te;
    die "$fr1: result incorrect.\nGot:\n$cr1\nExpected:\n$cs0\n"
        if $cr1 ne $cs0;
    1;
};
ok($_, 1, $@);

# 3: Keep restart
$_ = eval {
    my ($retno, $out, $err);
    my ($fl, $fl1, $cs0, $cs1, $cr1, $tr1);
    mkcldir $WORKDIR;
    $cs0 = mkrndlog $fs1;
    runcmd "\"$reslog\" -t 1 -k=r \"$fs1\"", \$retno, \$out, \$err;
    ($fl, $fl1) = (join(" ", sort map basename($_), ($fs1, $fr1)), flist $WORKDIR);
    ($cs1, $cr1, $tr1) = (fread $fs1, fread $fr1, ftype $fr1);
    rmalldir $WORKDIR;
    die $out . $err if $retno != 0;
    die "result files incorrect.\nGot: $fl1\nExpected: $fl\n"
        if $fl1 ne $fl;
    die "$fs1: source incorrect.\nGot:\n$cs1\nExpected \"\"\n"
        if $cs1 ne "";
    die "$fr1: result type incorrect.\nGot: $tr1\nExpected: $te\n"
        if !$nofile && $tr1 ne $te;
    die "$fr1: result incorrect.\nGot:\n$cr1\nExpected:\n$cs0\n"
        if $cr1 ne $cs0;
    1;
};
ok($_, 1, $@);

# 4: Keep delete
$_ = eval {
    my ($retno, $out, $err);
    my ($fl, $fl1, $cs0, $cs1, $cr1, $tr1);
    mkcldir $WORKDIR;
    $cs0 = mkrndlog $fs1;
    runcmd "\"$reslog\" -t 1 -k=d \"$fs1\"", \$retno, \$out, \$err;
    ($fl, $fl1) = (join(" ", sort map basename($_), ($fr1)), flist $WORKDIR);
    ($cr1, $tr1) = (fread $fr1, ftype $fr1);
    rmalldir $WORKDIR;
    die $out . $err if $retno != 0;
    die "result files incorrect.\nGot: $fl1\nExpected: $fl\n"
        if $fl1 ne $fl;
    die "$fr1: result type incorrect.\nGot: $tr1\nExpected: $te\n"
        if !$nofile && $tr1 ne $te;
    die "$fr1: result incorrect.\nGot:\n$cr1\nExpected:\n$cs0\n"
        if $cr1 ne $cs0;
    1;
};
ok($_, 1, $@);

# 5: The default override behavior
$_ = eval {
    my ($retno, $out, $err);
    my ($fl, $fl1, $cs0, $cr0, $cs1, $cr1, $tr1);
    mkcldir $WORKDIR;
    ($cs0, $cr0) = (mkrndlog $fs1, mkrndlog $fr1);
    runcmd "\"$reslog\" -t 1 \"$fs1\"", \$retno, \$out, \$err;
    ($fl, $fl1) = (join(" ", sort map basename($_), ($fs1, $fr1)), flist $WORKDIR);
    ($cs1, $cr1, $tr1) = (fread $fs1, fread $fr1, ftype $fr1);
    rmalldir $WORKDIR;
    die $out . $err if $retno == 0;
    die "result files incorrect.\nGot: $fl1\nExpected: $fl\n"
        if $fl1 ne $fl;
    die "$fs1: source incorrect.\nGot:\n$cs1\nExpected:\n$cs0\n"
        if $cs1 ne $cs0;
    die "$fr1: result type incorrect.\nGot: $tr1\nExpected: $te\n"
        if !$nofile && $tr1 ne $te;
    die "$fr1: result incorrect.\nGot:\n$cr1\nExpected:\n$cr0\n"
        if $cr1 ne $cr0;
    1;
};
ok($_, 1, $@);

# 6: Override overwrite
$_ = eval {
    my ($retno, $out, $err);
    my ($fl, $fl1, $cs0, $cr0, $cs1, $cr1, $tr1);
    mkcldir $WORKDIR;
    ($cs0, $cr0) = (mkrndlog $fs1, mkrndlog $fr1);
    runcmd "\"$reslog\" -t 1 -o=o \"$fs1\"", \$retno, \$out, \$err;
    ($fl, $fl1) = (join(" ", sort map basename($_), ($fr1)), flist $WORKDIR);
    ($cr1, $tr1) = (fread $fr1, ftype $fr1);
    rmalldir $WORKDIR;
    die $out . $err if $retno != 0;
    die "result files incorrect.\nGot: $fl1\nExpected: $fl\n"
        if $fl1 ne $fl;
    die "$fr1: result type incorrect.\nGot: $tr1\nExpected: $te\n"
        if !$nofile && $tr1 ne $te;
    die "$fr1: result incorrect.\nGot:\n$cr1\nExpected:\n$cs0\n"
        if $cr1 ne $cs0;
    1;
};
ok($_, 1, $@);

# 7: Override append
$_ = eval {
    my ($retno, $out, $err);
    my ($fl, $fl1, $cs0, $cr0, $cs1, $cr1, $tr1);
    mkcldir $WORKDIR;
    ($cs0, $cr0) = (mkrndlog $fs1, mkrndlog $fr1);
    runcmd "\"$reslog\" -t 1 -o=a \"$fs1\"", \$retno, \$out, \$err;
    ($fl, $fl1) = (join(" ", sort map basename($_), ($fr1)), flist $WORKDIR);
    ($cr1, $tr1) = (fread $fr1, ftype $fr1);
    rmalldir $WORKDIR;
    die $out . $err if $retno != 0;
    die "result files incorrect.\nGot: $fl1\nExpected: $fl\n"
        if $fl1 ne $fl;
    die "$fr1: result type incorrect.\nGot: $tr1\nExpected: $te\n"
        if !$nofile && $tr1 ne $te;
    die "$fr1: result incorrect.\nGot:\n$cr1\nExpected:\n$cr0$cs0\n"
        if $cr1 ne $cr0 . $cs0;
    1;
};
ok($_, 1, $@);

# 8: Override fail
$_ = eval {
    my ($retno, $out, $err);
    my ($fl, $fl1, $cs0, $cr0, $cs1, $cr1, $tr1);
    mkcldir $WORKDIR;
    ($cs0, $cr0) = (mkrndlog $fs1, mkrndlog $fr1);
    runcmd "\"$reslog\" -t 1 -o=f \"$fs1\"", \$retno, \$out, \$err;
    ($fl, $fl1) = (join(" ", sort map basename($_), ($fs1, $fr1)), flist $WORKDIR);
    ($cs1, $cr1, $tr1) = (fread $fs1, fread $fr1, ftype $fr1);
    rmalldir $WORKDIR;
    die $out . $err if $retno == 0;
    die "result files incorrect.\nGot: $fl1\nExpected: $fl\n"
        if $fl1 ne $fl;
    die "$fs1: source incorrect.\nGot:\n$cs1\nExpected:\n$cs0\n"
        if $cs1 ne $cs0;
    die "$fr1: result type incorrect.\nGot: $tr1\nExpected: $te\n"
        if !$nofile && $tr1 ne $te;
    die "$fr1: result incorrect.\nGot:\n$cr1\nExpected:\n$cr0\n"
        if $cr1 ne $cr0;
    1;
};
ok($_, 1, $@);

# 9: From file to STDOUT
$_ = eval {
    return if $nofile;
    my ($retno, $out, $err);
    my ($fl, $fl1, $cs0, $cs1, $cr1, $tr1);
    mkcldir $WORKDIR;
    $cs0 = mkrndlog $fs1;
    runcmd "\"$reslog\" -t 1 -c \"$fs1\" > \"$fr1\"", \$retno, undef, \$err;
    ($fl, $fl1) = (join(" ", sort map basename($_), ($fs1, $fr1)), flist $WORKDIR);
    ($cs1, $cr1, $tr1) = (fread $fs1, fread $fr1, ftype $fr1);
    rmalldir $WORKDIR;
    die $out . $err if $retno != 0;
    die "result files incorrect.\nGot: $fl1\nExpected: $fl\n"
        if $fl1 ne $fl;
    die "$fs1: source incorrect.\nGot:\n$cs1\nExpected:\n$cs0\n"
        if $cs1 ne $cs0;
    die "$fr1: result type incorrect.\nGot: $tr1\nExpected: $te\n"
        if !$nofile && $tr1 ne $te;
    die "$fr1: result incorrect.\nGot:\n$cr1\nExpected:\n$cs0\n"
        if $cr1 ne $cs0;
    1;
};
skip($nofile, $_, 1, $@);

# 10: From STDIN to STDOUT
$_ = eval {
    return if $nofile;
    my ($retno, $out, $err);
    my ($fl, $fl1, $cs0, $cs1, $cr1, $tr1);
    mkcldir $WORKDIR;
    $cs0 = mkrndlog $fs1;
    runcmd "\"$reslog\" -t 1 < \"$fs1\" > \"$fr1\"", \$retno, undef, \$err;
    ($fl, $fl1) = (join(" ", sort map basename($_), ($fs1, $fr1)), flist $WORKDIR);
    ($cs1, $cr1, $tr1) = (fread $fs1, fread $fr1, ftype $fr1);
    rmalldir $WORKDIR;
    die $out . $err if $retno != 0;
    die "result files incorrect.\nGot: $fl1\nExpected: $fl\n"
        if $fl1 ne $fl;
    die "$fs1: source incorrect.\nGot:\n$cs1\nExpected:\n$cs0\n"
        if $cs1 ne $cs0;
    die "$fr1: result type incorrect.\nGot: $tr1\nExpected: $te\n"
        if !$nofile && $tr1 ne $te;
    die "$fr1: result incorrect.\nGot:\n$cr1\nExpected:\n$cs0\n"
        if $cr1 ne $cs0;
    1;
};
skip($nofile, $_, 1, $@);

# 11: Attach a custom suffix
$_ = eval {
    my ($retno, $out, $err);
    my ($fl, $fl1, $cs0, $cs1, $cr2, $tr2);
    mkcldir $WORKDIR;
    $cs0 = mkrndlog $fs1;
    runcmd "\"$reslog\" -t 1 -s=.rsd \"$fs1\"", \$retno, \$out, \$err;
    ($fl, $fl1) = (join(" ", sort map basename($_), ($fr2)), flist $WORKDIR);
    ($cs1, $cr2, $tr2) = (fread $fs1, fread $fr2, ftype $fr2);
    rmalldir $WORKDIR;
    die $out . $err if $retno != 0;
    die "result files incorrect.\nGot: $fl1\nExpected: $fl\n"
        if $fl1 ne $fl;
    die "$fr2: result type incorrect.\nGot: $tr2\nExpected: $te\n"
        if !$nofile && $tr2 ne $te;
    die "$fr2: result incorrect.\nGot:\n$cr2\nExpected:\n$cs0\n"
        if $cr2 ne $cs0;
    1;
};
ok($_, 1, $@);

# 12: Trim the file name suffix
$_ = eval {
    my ($retno, $out, $err);
    my ($fl, $fl1, $cs0, $cs2, $cr1, $tr1);
    mkcldir $WORKDIR;
    $cs0 = mkrndlog $fs2;
    runcmd "\"$reslog\" -t 1 -t=.ct \"$fs2\"", \$retno, \$out, \$err;
    ($fl, $fl1) = (join(" ", sort map basename($_), ($fr1)), flist $WORKDIR);
    ($cs2, $cr1, $tr1) = (fread $fs2, fread $fr1, ftype $fr1);
    rmalldir $WORKDIR;
    die $out . $err if $retno != 0;
    die "result files incorrect.\nGot: $fl1\nExpected: $fl\n"
        if $fl1 ne $fl;
    die "$fr1: result type incorrect.\nGot: $tr1\nExpected: $te\n"
        if !$nofile && $tr1 ne $te;
    die "$fr1: result incorrect.\nGot:\n$cr1\nExpected:\n$cs0\n"
        if $cr1 ne $cs0;
    1;
};
ok($_, 1, $@);

# 13: Trim and attach our suffix
$_ = eval {
    my ($retno, $out, $err);
    my ($fl, $fl1, $cs0, $cs2, $cr2, $tr2);
    mkcldir $WORKDIR;
    $cs0 = mkrndlog $fs2;
    runcmd "\"$reslog\" -t 1 -t=.ct -s=.rsd \"$fs2\"", \$retno, \$out, \$err;
    ($fl, $fl1) = (join(" ", sort map basename($_), ($fr2)), flist $WORKDIR);
    ($cs2, $cr2, $tr2) = (fread $fs2, fread $fr2, ftype $fr2);
    rmalldir $WORKDIR;
    die $out . $err if $retno != 0;
    die "result files incorrect.\nGot: $fl1\nExpected: $fl\n"
        if $fl1 ne $fl;
    die "$fr2: result type incorrect.\nGot: $tr2\nExpected: $te\n"
        if !$nofile && $tr2 ne $te;
    die "$fr2: result incorrect.\nGot:\n$cr2\nExpected:\n$cs0\n"
        if $cr2 ne $cs0;
    1;
};
ok($_, 1, $@);

# 14: Stop for the temporary working file
$_ = eval {
    my ($retno, $out, $err);
    my ($fl, $fl1, $cs0, $ct0, $cs1, $ct1);
    mkcldir $WORKDIR;
    ($cs0, $ct0) = (mkrndlog $fs1, mkrndlog $ft1);
    runcmd "\"$reslog\" -t 1 -t=.ct -s=.rsd \"$fs2\"", \$retno, \$out, \$err;
    ($fl, $fl1) = (join(" ", sort map basename($_), ($fs1, $ft1)), flist $WORKDIR);
    ($cs1, $ct1) = (fread $fs1, fread $ft1);
    rmalldir $WORKDIR;
    die $out . $err if $retno == 0;
    die "result files incorrect.\nGot: $fl1\nExpected: $fl\n"
        if $fl1 ne $fl;
    die "$fs1: source incorrect.\nGot:\n$cs1\nExpected:\n$cs0\n"
        if $cs1 ne $cs0;
    die "$ft1: temporary working file incorrect.\nGot:\n$ct1\nExpected:\n$ct0\n"
        if $ct1 ne $ct0;
    1;
};
ok($_, 1, $@);
