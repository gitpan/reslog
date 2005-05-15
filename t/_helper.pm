# _helper.pm -- A simple test suite helper

package _helper;
use 5.005;
use strict;
use warnings;
use base qw(Exporter);
use vars qw($VERSION @EXPORT);
$VERSION = "0.03";
@EXPORT = qw(cp rmalldir mkcldir fread fwrite runcmd whereis ftype flist mkrndlog);
# Prototype declaration
sub thisfile();
sub cp(@);
sub rmalldir(@);
sub mkcldir(@);
sub fread($);
sub fwrite($$);
sub runcmd($$$$);
sub whereis($);
sub ftype($);
sub flist($);
sub mkrndlog($);
sub randword();

use ExtUtils::MakeMaker qw();
use Fcntl qw(:seek);
use File::Basename qw(basename);
use File::Copy qw(copy);
use File::Spec::Functions qw(splitdir catdir catfile path);
use File::Temp qw(tmpnam);

use vars qw(%WHEREIS);

# thisfile: Return the name of this file
sub thisfile() { basename($0); }

# cp: Copy a list of files
sub cp(@) {
    local ($_, %_);
    foreach (@_) {
        copy $$_[0], $$_[1]             or die thisfile . ": copy $$_[0], $$_[1]: $!";
    }
}

# rm: Remove a list of files
sub rm(@) {
    local ($_, %_);
    foreach (@_) {
        next if !-e $_;
        unlink $_                       or die thisfile . ": unlink $_: $!";
    }
}

# rmalldir: Remove a whole directory
sub rmalldir(@) {
    local ($_, %_);
    my (@dirs, $DH);
    @dirs = @_;
    foreach my $dir (@dirs) {
        opendir $DH, $dir               or die thisfile . ": $dir: $!";
        while (defined($_ = readdir $DH)) {
            next if $_ eq "." || $_ eq "..";
            $_ = "$dir/$_";
            if (-d $_ && !-l $_) {
                rmalldir $_;
            } else {
                unlink $_               or die thisfile . ": $_: $!";
            }
        }
        closedir $DH                    or die thisfile . ": $dir: $!";
        rmdir $dir                      or die thisfile . ": $dir: $!";
    }
    return;
}

# mkcldir: Create a clean directory
sub mkcldir(@) {
    local ($_, %_);
    my (@dirs, $DH);
    @dirs = @_;
    foreach my $dir (@dirs) {
        # Create the directory if not exists.
        if (!-e $dir) {
            my @parents;
            @_ = splitdir $dir;
            for ($_ = 0, @parents = qw(); $_ < @_; $_++) {
                push @parents, catdir(@_[0..$_]);
            }
            foreach (@parents) {
                if (!-e $_) {
                    mkdir $_            or die thisfile . ": $_: $!";
                }
            }
        
        # Clean the content of the directory if exists
        } else {
            opendir $DH, $dir           or die thisfile . ": $dir: $!";
            while (defined($_ = readdir $DH)) {
                next if $_ eq "." || $_ eq "..";
                $_ = "$dir/$_";
                if (-d $_ && !-l $_) {
                    rmalldir $_;
                } else {
                    unlink $_           or die thisfile . ": $_: $!";
                }
            }
            closedir $DH                or die thisfile . ": $dir: $!";
        }
    }
    return;
}

# fread: A simple reader to read a log file in any supported format
sub fread($) {
    local ($_, %_);
    my ($file, $content);
    $file = $_[0];
    
    # non-existing file
    if (!-e $file) {
        return undef;
    
    # a gzip compressed file
    } elsif ($file =~ /\.gz$/) {
        # Compress::Zlib
        if (eval {  require Compress::Zlib;
                    import Compress::Zlib qw(gzopen);
                    1; }) {
            my ($FH, $gz);
            $content = "";
            open $FH, $file             or die thisfile . ": $file: $!";
            $gz = gzopen($FH, "rb")     or die thisfile . ": $file: $!";
            while (1) {
                ($gz->gzread($_, 10240) != -1)
                                        or die thisfile . ": $file: " . $gz->gzerror;
                $content .= $_;
                last if length $_ < 10240;
            }
            $gz->gzclose                and die thisfile . ": $file: " . $gz->gzerror;
            return $content;
        
        # gzip executable
        } else {
            my ($PH, $CMD);
            $CMD = whereis "gzip";
            $CMD = "\"$CMD\" -cd \"$file\"";
            open $PH, "$CMD |"          or die thisfile . ": $CMD: $!";
            $content = join "", <$PH>;
            close $PH                   or die thisfile . ": $CMD: $!";
            return $content;
        }
    
    # a bzip compressed file
    } elsif ($file =~ /\.bz2$/) {
        # Compress::Bzip2
        if (eval {  require Compress::Bzip2;
                    import Compress::Bzip2 2.00;
                    import Compress::Bzip2 qw(bzopen);
                    1; }) {
            my ($FH, $bz);
            $content = "";
            open $FH, $file             or die thisfile . ": $file: $!";
            $bz = bzopen($FH, "rb")     or die thisfile . ": $file: $!";
            while (1) {
                ($bz->bzread($_, 10240) != -1)
                                        or die thisfile . ": $file: " . $bz->bzerror;
                $content .= $_;
                last if length $_ < 10240;
            }
            $bz->bzclose                and die thisfile . ": $file: " . $bz->bzerror;
            return $content;
        
        # bzip2 executable
        } else {
            my ($PH, $CMD);
            $CMD = whereis "bzip2";
            $CMD = "bzip2 -cd \"$file\"";
            open $PH, "$CMD |"          or die thisfile . ": $CMD: $!";
            $content = join "", <$PH>;
            close $PH                   or die thisfile . ": $CMD: $!";
            return $content;
        }
    
    # a plain file
    } else {
        my $FH;
        open $FH, $file                 or die thisfile . ": $file: $!";
        $content = join "", <$FH>;
        close $FH                       or die thisfile . ": $file: $!";
        return $content;
    }
}

# fwrite: A simple write to write a log file in any supported format
sub fwrite($$) {
    local ($_, %_);
    my ($file, $content);
    ($file, $content) = @_;
    
    # a gzip compressed file
    if ($file =~ /\.gz$/) {
        # Compress::Zlib
        if (eval {  require Compress::Zlib;
                    import Compress::Zlib qw(gzopen);
                    1; }) {
            my ($FH, $gz);
            open $FH, ">$file"          or die thisfile . ": $file: $!";
            $gz = gzopen($FH, "wb9")    or die thisfile . ": $file: $!";
            ($gz->gzwrite($content) == length $content)
                                        or die thisfile . ": $file: " . $gz->gzerror;
            $gz->gzclose                and die thisfile . ": $file: " . $gz->gzerror;
            return;
        
        # gzip executable
        } else {
            my ($PH, $CMD);
            $CMD = whereis "gzip";
            $CMD = "\"$CMD\" -c9f > \"$file\"";
            open $PH, "| $CMD"          or die thisfile . ": $CMD: $!";
            print $PH $content          or die thisfile . ": $CMD: $!";
            close $PH                   or die thisfile . ": $CMD: $!";
            return;
        }
    
    # a bzip compressed file
    } elsif ($file =~ /\.bz2$/) {
        # Compress::Bzip2
        if (eval {  require Compress::Bzip2;
                    import Compress::Bzip2 2.00;
                    import Compress::Bzip2 qw(bzopen);
                    1; }) {
            my ($FH, $bz);
            open $FH, ">$file"          or die thisfile . ": $file: $!";
            $bz = bzopen($FH, "wb9")    or die thisfile . ": $file: $!";
            ($bz->bzwrite($content, length $content) == length $content)
                                        or die thisfile . ": $file: " . $bz->bzerror;
            $bz->bzclose                and die thisfile . ": $file: " . $bz->bzerror;
            return;
        
        # bzip2 executable
        } else {
            my ($PH, $CMD);
            $CMD = whereis "bzip2";
            $CMD = "\"$CMD\" -9f > \"$file\"";
            open $PH, "| $CMD"        or die thisfile . ": $CMD: $!";
            print $PH $content        or die thisfile . ": $CMD: $!";
            close $PH                 or die thisfile . ": $CMD: $!";
            return;
        }
    
    # a plain file
    } else {
        my $FH;
        open $FH, ">$file"              or die thisfile . ": $file: $!";
        print $FH $content              or die thisfile . ": $file: $!";
        close $FH                       or die thisfile . ": $file: $!";
        return;
    }
}

# runcmd: Run a command and return the result
sub runcmd($$$$) {
    local ($_, %_);
    my ($cmd, $retno, $out, $err, $tmpout, $tmperr, $FH);
    ($cmd, $retno, $out, $err) = @_;
    
    if (defined $out) {
        $tmpout = tmpnam                or die thisfile . ": tmpnam: $!";
        $cmd .= " >$tmpout";
    }
    if (defined $err) {
        $tmperr = tmpnam                or die thisfile . ": tmpnam: $!";
        $cmd .= " 2>$tmperr";
    }
    
    # Run the command
    `$cmd`;
    $$retno = $?;
    if (defined $out) {
        open $FH, $tmpout               or die thisfile . ": $tmpout: $!";
        $$out = join "", <$FH>;
        close $FH                       or die thisfile . ": $tmpout: $!";
        unlink $tmpout;
    }
    if (defined $err) {
        open $FH, $tmperr               or die thisfile . ": $tmperr: $!";
        $$err = join "", <$FH>;
        close $FH                       or die thisfile . ": $tmperr: $!";
        unlink $tmperr;
    }
    return;
}

# whereis: Find an executable
#   Code inspired from CPAN::FirstTime
sub whereis($) {
    local ($_, %_);
    my ($file, $path);
    $file = $_[0];
    return $WHEREIS{$file} if exists $WHEREIS{$file};
    foreach my $dir (path) {
        return ($WHEREIS{$file} = $path)
            if defined($path = MM->maybe_command(catfile($dir, $file)));
    }
    return ($WHEREIS{$file} = undef);
}

# ftype: Find the file type
sub ftype($) {
    local ($_, %_);
    my $file;
    $file = $_[0];
    return undef unless -e $file;
    # Use File::MMagic
    if (eval { require File::MMagic; 1; }) {
        $_ = new File::MMagic->checktype_filename($file);
        return "application/x-gzip" if /gzip/;
        return "application/x-bzip2" if /bzip2/;
        # All else are text/plain
        return "text/plain";
    }
    # Use file executable
    if (defined($_ = whereis "file")) {
        $_ = join "", `"$_" "$file"`;
        return "application/x-gzip" if /gzip/;
        return "application/x-bzip2" if /bzip2/;
        # All else are text/plain
        return "text/plain";
    }
    # No type checker available
    return undef;
}

# flist: Obtain the files list in a directory
sub flist($) {
    local ($_, %_);
    my ($dir, $DH);
    $dir = $_[0];
    @_ = qw();
    opendir $DH, $dir                   or die thisfile . ": $dir: $!";
    while (defined($_ = readdir $DH)) {
        next if $_ eq "." || $_ eq "..";
        push @_, $_;
    }
    closedir $DH                        or die thisfile . ": $dir: $!";
    return join " ", sort @_;
}

# mkrndlog: Create a random log file
sub mkrndlog($) {
    local ($_, %_);
    my ($file, $hosts, @host_is_ip, @logs, $t, $tz, $content);
    $file = $_[0];
    
    $hosts = 3 + int rand 3;
    # Host type: 0: IP, 1: domain name
    @host_is_ip = qw();
    push @host_is_ip, 0 while @host_is_ip < $hosts;
    # We need exactly 2 IP
    $host_is_ip[int rand $hosts] = 1
        while grep($_ == 1, @host_is_ip) < 2;
    
    @logs = qw();
    
    # Start from sometime in the past year
    $t = time - int rand(86400*365);
    $tz = -11 + int rand 24;
    
    foreach my $is_ip (@host_is_ip) {
        my ($host, $user, $htver, @hlogs, $hlogs);
        if ($is_ip) {
            # Generate a random IP
            # Always start from 127, not end with 0
            do {
                @_ = (127);
                push @_, int rand 255;
                push @_, int rand 255;
                push @_, 1 + int rand 254;
                $host = join ".", @_;
            } while $host eq "127.0.0.1";
        
        } else {
            # Generate a random domain name
            # 3-5 levels, end with net or com
            $_ = 2 + int rand 3;
            @_ = qw();
            push @_, randword while @_ < $_;
            push @_, (qw(net com))[int rand 2];
            $host = join ".", @_;
        }
        $user = (0, 0, 1)[int rand 3]? "-": randword;
        $htver = (qw(HTTP/1.1 HTTP/1.1 HTTP/1.0))[int rand 3];
        # 3-5 log entries foreach host
        $hlogs = 3 + int rand 3;
        @hlogs = qw();
        while (@hlogs < $hlogs) {
            my (@t, $method, $url, $status, $size);
            $t += 0 + int rand 3;
            @t = localtime $t;
            $t[5] += 1900;
            $t[4] = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$t[4]];
            
            $method = (qw(GET GET GET HEAD POST))[int rand 5];
            @_ = qw(/ /robots.txt /about/ /privacy.html /images/logo.png /images/backgrnd.png /stylesheets/common.css);
            $url = @_[int rand @_];
            $status = (200, 200, 304)[int rand 3];
            if ($status == 304) {
                $size = 0;
            } else {
                $size = 200 + int rand 35000;
            }
            push @hlogs, sprintf "%s - %s [%02d/%s/%04d:%02d:%02d:%02d %+03d00] \"%s %s %s\" %d %d\n",
                $host, $user, @t[3,4,5,2,1,0], $tz, $method, $url, $htver, $status, $size;
        }
        push @logs, @hlogs;
        $t += 0 + rand 5;
    }
    
    # Insert 1-2 malformed lines
    my $malformed;
    $malformed = 1 + int rand 2;
    while ($malformed > 0) {
        my ($line, $pos);
        # Generate the random malformed line
        $_ = 3 + int rand 5;
        @_ = qw();
        push @_, randword while @_ < $_;
        $line = join(" ", @_) . ".\n";
        $line =~ s/^(.)/uc $1/e;
        # The position to insert the line
        $_ = int rand @logs;
        @logs = (@logs[0...$_], $line, @logs[$_+1...$#logs]);
        $malformed--;
    }
    
    # Compose the content
    $content = join "", @logs;
    # Output the file
    fwrite($file, $content);
    # Return the content
    return $content;
}

# randword: Supply a random English word
sub randword() {
    local ($_, %_);
    @_ = qw(
culminates spector thule tamil sages fasten bothers intricately librarian
mist criminate impressive scissor trance standardizing enabler athenians
planers decisions salvation wetness fibers cowardly winning call stockton
bifocal rapacious steak reinserts overhaul glaringly playwrights wagoner
garland hampered effie messy despaired orthodoxy bacterial bernardine driving
danization vapors uproar sects litmus sutton lacrosse);
    return $_[int rand @_];
}

1;

__END__
