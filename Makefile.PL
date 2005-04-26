#! /usr/bin/perl -w
# Makefile.PL: Installation configuration for ExtUtils::MakeMaker
use 5.7.2;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Check if there is any old files
use vars qw(@old_version);
@old_version = qw();
foreach (qw(/usr/sbin/reslog.pl
            /usr/share/man/man8/reslog.pl.8
            /usr/local/sbin/reslog.pl
            /usr/local/share/man/man8/reslog.pl.8)) {
    push @old_version, $_ if -e $_;
}
if (@old_version > 0) {
    $_ = join " ", @old_version;
    warn << "EOT";
================
  Look like you are upgrading from an old version.
  Remove the following files after "make install":

  $_
  
  Refer to UPGRADE for more information..
================
EOT
}

WriteMakefile(
    AUTHOR		=> 'imacat <imacat@mail.imacat.idv.tw>',
    ABSTRACT		=> 'Reverse-resolve IP in Apache log files',
    NAME                => 'reslog',
    VERSION_FROM        => 'reslog',
    PREREQ_PM		=> { },
    
    EXE_FILES		=> [ "reslog" ],
    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
    clean		=> {
        FILES		=> 't/logs/working/*',
    },
);



__END__
