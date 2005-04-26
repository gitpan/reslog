# MyHelper.pm -- A simple test suite helper

package MyHelper;
use 5.005;
use strict;
use warnings;
use base qw(Exporter);
use vars qw($VERSION @EXPORT);
$VERSION = "0.01";
@EXPORT = qw(cp rm readfile runcmd);
# Prototype declaration
sub cplist(@);
sub rm(@);
sub readfile($);
sub runcmd($$$$);

use Fcntl qw(:seek);
use File::Basename qw(basename);
use File::Copy qw(copy);
use File::Temp qw(tmpnam);

use vars qw($THIS_FILE $ORIGOUT $ORIGERR);
$THIS_FILE = basename($0);

# cp: Copy a list of files
sub cp(@) {
    local ($_, %_);
    foreach (@_) {
        copy $$_[0], $$_[1]             or die "$THIS_FILE: copy $$_[0], $$_[1]: $!";
    }
}

# rm: Remove a list of files
sub rm(@) {
    local ($_, %_);
    foreach (@_) {
        next if !-e $_;
        unlink $_                       or die "$THIS_FILE: unlink $_: $!";
    }
}

# readfile: A simple reader to read a log file in any supported format
sub readfile($) {
    local ($_, %_);
    my ($file, $content);
    $file = $_[0];
    
    # non-existing file
    if (!-e $file) {
        return undef;
    
    # a gzip compressed file
    } elsif ($file =~ /\.gz$/) {
        eval {
            require Compress::Zlib;
            import Compress::Zlib qw(gzopen);
        };
        # Compress::Zlib
        if ($@ eq "") {
            my ($gz, $n);
            $content = "";
            $gz = gzopen($file, "rb")   or die "$THIS_FILE: $file: $!";
            while (($n = $gz->gzreadline($_)) != 0) {
                die "$THIS_FILE: $file: " . $gz->gzerror if $n == -1;
                $content .= $_;
            }
            $gz->gzclose                and die "$THIS_FILE: $file: " . $gz->gzerror;
            return $content;
        
        # gzip executable
        } else {
            my ($PIPE, $CMD);
            $CMD = "gzip -cd $file";
            open $PIPE, "$CMD |"        or die "$THIS_FILE: $CMD: $!";
            $content = join "", <$PIPE>;
            close $PIPE                 or die "$THIS_FILE: $CMD: $!";
            return $content;
        }
    
    # a bzip compressed file
    } elsif ($file =~ /\.bz2$/) {
        eval {
            require Compress::Bzip2;
            import Compress::Bzip2 2.00;
            import Compress::Bzip2 qw(bzopen);
        };
        # Compress::Bzip2
        if ($@ eq "") {
            my ($bz, $n);
            $content = "";
            $bz = bzopen($file, "rb")   or die "$THIS_FILE: $file: $!";
            while (($n = $bz->bzreadline($_)) != 0) {
                die "$THIS_FILE: $file: " . $bz->bzerror if $n == -1;
                $content .= $_;
            }
            $bz->bzclose                and die "$THIS_FILE: $file: " . $bz->bzerror;
            return $content;
        
        # bzip2 executable
        } else {
            my ($PIPE, $CMD);
            $CMD = "bzip2 -cd $file";
            open $PIPE, "$CMD |"        or die "$THIS_FILE: $CMD: $!";
            $content = join "", <$PIPE>;
            close $PIPE                 or die "$THIS_FILE: $CMD: $!";
            return $content;
        }
    
    # a plain file
    } else {
        my $FH;
        open $FH, $file                 or die "$THIS_FILE: $file: $!";
        $content = join "", <$FH>;
        close $FH                       or die "$THIS_FILE: $file: $!";
        return $content;
    }
}

# runcmd: Run a command and return the result
sub runcmd($$$$) {
    local ($_, %_);
    my ($cmd, $retno, $out, $err, $tmpout, $tmperr, $FH);
    ($cmd, $retno, $out, $err) = @_;
    
    if (defined $out) {
        $tmpout = tmpnam                or die "$THIS_FILE: tmpnam: $!";
        $cmd .= " >$tmpout";
    }
    if (defined $err) {
        $tmperr = tmpnam                or die "$THIS_FILE: tmpnam: $!";
        $cmd .= " 2>$tmperr";
    }
    
    # Run the command
    `$cmd`;
    $$retno = $?;
    if (defined $out) {
        open $FH, $tmpout               or die "$THIS_FILE: $tmpout: $!";
        $$out = join "", <$FH>;
        close $FH                       or die "$THIS_FILE: $tmpout: $!";
        unlink $tmpout;
    }
    if (defined $err) {
        open $FH, $tmperr               or die "$THIS_FILE: $tmperr: $!";
        $$err = join "", <$FH>;
        close $FH                       or die "$THIS_FILE: $tmperr: $!";
        unlink $tmperr;
    }
    return;
}
