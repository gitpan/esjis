use strict;
use FindBin;

# make make.bat
open(MAKEBAT,">$FindBin::Bin/make.bat") || die "Can't open file: $FindBin::Bin/make.bat\n";
print MAKEBAT <DATA>;
close(MAKEBAT);

__END__
@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
#!perl
#line 14

# poor make

undef @rem;
use strict;
use FindBin;
use File::Path;
use File::Copy;
use File::Basename;
use Test::Harness;
use Archive::Tar;
use Compress::Zlib;

unless (@ARGV) {
    die <<END;

usage: make
usage: make test
usage: make install
usage: make dist
usage: make tar.bat

END
}

for my $target (@ARGV) {
    if ($target eq 'test') {
        runtests(<$FindBin::Bin/test.pl $FindBin::Bin/t/*.t>);
    }
    elsif ($target eq 'install') {

        # install *.pm files to /Perl/site/lib
        my($perl_site_lib) = grep(m{/site/}i, @INC);
        while (<$FindBin::Bin/*.pm>) {
            copy($_, $perl_site_lib);
        }

        # install *.pl and *.bat files to /Perl/bin
        my($perl_bin) = $^X =~ /^(.*)\\[^\\]*$/;
        while (<$FindBin::Bin/*.pl $FindBin::Bin/*.bat>) {
            copy($_, $perl_bin);
        }

        # install into perl5.10 directory too
        if (($] < 5.010) and -e 'perl510.bat') {
            system($^X, qw(perl510.bat make.bat install));
        }
    }
    elsif ($target eq 'dist') {

        # get file list
        open(MANIFEST,"$FindBin::Bin/MANIFEST") || die "Can't open $FindBin::Bin/MANIFEST\n";
        chomp(my @file = <MANIFEST>);
        close(MANIFEST);

        # make work directory
        open(SCRIPT,$file[0]) || die "Can't open file: $file[0]\n";
        $_ = join('',<SCRIPT>);
        close(SCRIPT);

        use vars qw($VERSION);
        my($version) = m/(\$VERSION\s*=\s*.+?;)/xms;
        eval $version; # get $VERSION

        my $basename = basename($file[0], '.pm','.pl','.bat');
        my $tardir = "$basename-$VERSION";
        rmtree($tardir,0,0);

        # make *.tar file
        my $tar = Archive::Tar->new;
        for my $file (@file) {
            if (-e $file) {
                mkpath(dirname("$tardir/$file"),0,0777);
                copy($file, "$tardir/$file");
                $tar->add_files("$tardir/$file");
            }
            else {
                die "file: $file is not exists.\n";
            }
        }
        my $tarfile = "$tardir.tar";
        $tar->write($tarfile);
        rmtree($tardir,0,0);

        # make *.tar.gz file
        my $gz = gzopen("$tarfile.gz", 'wb');
        open(TAR, $tarfile) || die "Can't open file: $tarfile\n";
        binmode(TAR);
        $gz->gzwrite(join('',<TAR>));
        close(TAR);
        $gz->gzclose;
        unlink $tarfile;
    }
    elsif ($target eq 'tar.bat') {

        # make tar.bat
        open(TARBAT,">$FindBin::Bin/tar.bat") || die "Can't open file: $FindBin::Bin/tar.bat\n";
        print TARBAT <DATA>;
        close(TARBAT);
    }
    else {
        warn "unknown target: $target.\n";
    }
}

__END__
@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
#!perl
#line 14

# poor tar

undef @rem;
use strict;
use Compress::Zlib;
use Archive::Tar;

if ($ARGV[0] ne 'xzvf') {
    die <<END;

usage: tar xzvf file1.tar.gz file2.tar.gz ...

** This tar supports xzvf option only. **
END
}

for my $gzfile (grep /\.tar\.gz$/i, @ARGV) {

    my $gz = gzopen($gzfile, 'rb');
    (my $tarfile = $gzfile) =~ s/\.gz$//i;
    open(TAR,">$tarfile") || die "Can't open file: $tarfile\n";
    binmode(TAR);
    while ($gz->gzreadline(my $line)) {
        print TAR $line;
    }
    $gz->gzclose;
    close(TAR);

    my $tar = Archive::Tar->new($tarfile,1);
    for my $file ($tar->list_files){
        if (-e $file) {
            print STDERR "skip $file is already exists.\n";
        }
        else {
            print STDERR "x $file\n";
            $tar->extract($file);
        }
    }
    unlink $tarfile;
}

__END__
:endofperl
