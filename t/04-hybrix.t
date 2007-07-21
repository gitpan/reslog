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
use diagnostics;
use Test;

BEGIN { plan tests => 1 }

use File::Basename qw(basename);
use File::Spec::Functions qw(catdir catfile updir);
use FindBin;
use lib $FindBin::Bin;
use _helper;
use vars qw($WORKDIR $reslog $_ $nofile $nogzip $nobzip2);
use vars qw($dirp $fsp $frp $dirg $fsg $frg $dirb $fsb $frb);

$WORKDIR = catdir($FindBin::Bin, "logs");
$reslog = catfile($FindBin::Bin, updir, "blib", "script", "reslog");

# If we have the file type checker somewhere
$nofile =   eval { require File::MMagic; 1; }
            || defined whereis "file"?
    undef: "File::MMagic or file executable not available";
# If we have gzip support somewhere
$nogzip =   eval { require Compress::Zlib; 1; }
            || defined whereis "gzip"?
    undef: "Compress::Zlib or gzip executable not available";
# If we have bzip2 support somewhere
$nobzip2 =  eval { require Compress::Bzip2; import Compress::Bzip2 2.00; 1; }
            || defined whereis "bzip2"?
    undef: "Compress::Bzip2 v2 or bzip2 executable not available";

$dirp = catdir($WORKDIR, "site_p");
$dirg = catdir($WORKDIR, "site_g");
$dirb = catdir($WORKDIR, "site_b");
$fsp = catfile($dirp, "access_log");
$frp = catfile($dirp, "access_log.resolved");
$fsg = catfile($dirg, "access_log.gz");
$frg = catfile($dirg, "access_log.resolved.gz");
$fsb = catfile($dirb, "access_log.bz2");
$frb = catfile($dirb, "access_log.resolved.bz2");

# 1: Hybrix test: Mixed many type of sources together
$_ = eval {
    return if $nofile || $nogzip || $nobzip2;
    my ($retno, $out, $err);
    my ($flp, $flp1, $csp0, $cep0, $csp1, $crp1, $trp);
    my ($flg, $flg1, $csg0, $ceg0, $csg1, $crg1, $trg);
    my ($flb, $flb1, $csb0, $ceb0, $csb1, $crb1, $trb);
    
    mkcldir $dirp, $dirg, $dirb;
    ($csp0, $cep0) = (mkrndlog $fsp, mkrndlog $frp);
    ($csg0, $ceg0) = (mkrndlog $fsg, mkrndlog $frg);
    ($csb0, $ceb0) = (mkrndlog $fsb, mkrndlog $frb);
    
    ($retno, $out, $err) = runcmd frread $fsg, $reslog, qw(-d -d -d -n 1 -k r -o a), $fsp, "-", $fsb;
    frwrite $frg, $out;
    
    ($flp, $flp1) = (join(" ", sort map basename($_), ($fsp, $frp)), flist $dirp);
    ($flg, $flg1) = (join(" ", sort map basename($_), ($fsg, $frg)), flist $dirg);
    ($flb, $flb1) = (join(" ", sort map basename($_), ($fsb, $frb)), flist $dirb);
    ($csp1, $crp1, $trp) = (fread $fsp, fread $frp, ftype $frp);
    ($csg1, $crg1, $trg) = (fread $fsg, fread $frg, ftype $frg);
    ($csb1, $crb1, $trb) = (fread $fsb, fread $frb, ftype $frb);
    rmalldir $WORKDIR;
    die $err if $retno != 0;
    
    die "result files incorrect.\nGot: $flp1\nExpected: $flp\n"
        if $flp1 ne $flp;
    die "$fsp: source incorrect.\nGot:\n$csp1\nExpected \"\"\n"
        if $csp1 ne "";
    die "$frp: result type incorrect.\nGot: $trp\nExpected: text/plain\n"
        if !$nofile && $trp ne "text/plain";
    die "$frp: result incorrect.\nGot:\n$crp1\nExpected:\n$cep0$csp0\n"
        if $crp1 ne $cep0 . $csp0;
    
    die "result files incorrect.\nGot: $flg1\nExpected: $flg\n"
        if $flg1 ne $flg;
    die "$fsg: source incorrect.\nGot:\n$csg1\nExpected:\n$csg0\n"
        if $csg1 ne $csg0;
    die "$frg: result type incorrect.\nGot: $trb\nExpected: application/x-gzip\n"
        if !$nofile && $trg ne "application/x-gzip";
    die "$frg: result incorrect.\nGot:\n$crg1\nExpected:\n$ceg0\n"
        if $crg1 ne $csg0;
    
    die "result files incorrect.\nGot: $flb1\nExpected: $flb\n"
        if $flb1 ne $flb;
    die "$fsb: source incorrect.\nGot:\n$csb1\nExpected \"\"\n"
        if $csb1 ne "";
    die "$frb: result type incorrect.\nGot: $trb\nExpected: application/x-bzip2\n"
        if !$nofile && $trb ne "application/x-bzip2";
    die "$frb: result incorrect.\nGot:\n$crb1\nExpected:\n$ceb0$csb0\n"
        if $crb1 ne $ceb0 . $csb0;
    
    1;
};
skip($nofile || $nogzip || $nobzip2, $_, 1, $@);
