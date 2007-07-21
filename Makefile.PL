#! /usr/bin/perl -w
# Makefile.PL: Installation configuration for ExtUtils::MakeMaker
use 5.8.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Check if there is any old files
use vars qw(@old_version);
@old_version = qw();
foreach (qw(/usr/sbin/reslog.pl
            /usr/share/man/man8/reslog.pl.8
            /usr/local/sbin/reslog.pl
            /usr/local/share/man/man8/reslog.pl.8
            /usr/bin/reslog
            /usr/share/man/man1/reslog.1)) {
    push @old_version, $_ if -e $_;
}
if (@old_version > 0) {
    $_ = join " ", @old_version;
    warn << "EOT";
================
  Look like you are upgrading from an old version.
  Run "make upgrade" to remove the following old files after "make install":

    $_

  Refer to UPGRADE for more information..
================
EOT
}

WriteMakefile(
    NAME                => 'reslog',
    VERSION_FROM        => 'reslog',
    ABSTRACT		=> 'Reverse-resolve IP in Apache log files',
    AUTHOR		=> 'imacat <imacat@mail.imacat.idv.tw>',
    LICENSE		=> "gpl",
    PREREQ_PM		=> { },
    SIGN            => 1,
    
    EXE_FILES		=> [ "reslog" ],
    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
    clean		=> {
        FILES		=> 't/logs/*',
    },
);


package MY;

sub constants : method {
    local ($_, %_);
    my ($self, @args);
    ($self, @args) = @_;
    $_ = $_[0]->SUPER::constants(@_[1...$#_]);
    s/^(INSTALLSCRIPT = .+)\/bin/$1\/sbin/m;
    s/^(INSTALLMAN1DIR = .+)\/man1/$1\/man8/m;
    s/^(INSTALLSITEMAN1DIR = .+)\/man1/$1\/man8/m;
    s/^MAN1EXT = 1/MAN1EXT = 8/m;
    my $old_version = join " ", @main::old_version;
    $_ .= << "EOT";
OLDVERSION = $old_version
EOT
    return $_;
}

sub manifypods : method {
    local ($_, %_);
    $_ = shift->SUPER::manifypods(@_);
    s/ --section=1 / --section=8 /;
    return $_;
}

sub postamble : method {
    return << "EOT";
upgrade ::
	\$(RM_F) \$(OLDVERSION)
EOT
}

__END__
