@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
exit /b %errorlevel%
goto endofperl
@rem ';
#!perl
#line 15
$VERSION = "1.0.0"; undef @rem;
######################################################################
#
# jperl55 -  execute ShiftJIS perlscript on the perl5.5
#
# Copyright (c) 2008 INABA Hitoshi <ina@cpan.org>
#
######################################################################

# print usage
unless (@ARGV) {
    die <<END;

$0 ver.$VERSION

usage:

C:\\>$0 perlscript.pl ...

END
}

# quote by "" if include space
for (@ARGV) {
    $_ = qq{"$_"} if / /;
}

# compile script
for (@ARGV) {
    next if /^-/; # skip command line option

    if (not -e $_) {
        die "jperl55: script $_ is not exists.";
    }
    else {

        # make temp filename
        do {
            $tmpnam = sprintf('%s.%d.%d', $_, time, rand(10000));
        } while (-e $tmpnam);

        # escape ShiftJIS of script
        if (system(qq{$^X -S esjis.pl $_ > $tmpnam}) == 0) {
            rename($tmpnam,"$_.e") or unlink $tmpnam;
        }
        else {
            unlink $tmpnam;
            die "jperl55: Can't execute script: $_";
        }
    }

    # rewrite script filename
    $_ = "$_.e";
    last;
}

# if this script running under perl5.5
if ($] =~ /^5\.005/) {
    exit system($^X, @ARGV);
}
else {
    die "jperl55: nothing perl5.5.\n";
}

__END__
:endofperl
