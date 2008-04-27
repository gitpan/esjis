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
# perl510 -  execute perlscript on the perl5.10 without %PATH% settings
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

Find perl.exe ver.5.10 in the computer order by,
  1st, C:\\Perl510\\bin\\perl.exe
  2nd, D:\\Perl510\\bin\\perl.exe
  3rd, E:\\Perl510\\bin\\perl.exe
                :
                :

When found it, then execute perlscript on the its perl.exe.

END
}

# quote by "" if include space
for (@ARGV) {
    $_ = qq{"$_"} if / /;
}

# if this script running under perl5.10
if ($] =~ /^5\.010/) {
    exit system($^X, @ARGV);
}

# get drive list by 'net share' command
# Windows NT, Windows 2000, Windows XP, Windows Server 2003
# maybe also Windows Vista, Windows Server 2008
@harddrive = ();
while (`net share 2>NUL` =~ /\b([A-Z])\$ +\1:\\ +Default share\b/ig) {
    push @harddrive, $1;
}

# if no drive
# Windows 95, Windows 98, Windows Me
unless (@harddrive) {
    eval q{
        #----------------------------------------------------------------------
        # Win32::API module (This part is Perl5)
        #----------------------------------------------------------------------
        use Win32::API;
        $GetDriveType = Win32::API->new('Kernel32', 'GetDriveType', [P], N);
        for $drive ('C'..'Z') {
            # 0 DRIVE_UNKNOWN
            # 1 DRIVE_NO_ROOT_DIR
            # 2 DRIVE_REMOVABLE
            # 3 DRIVE_FIXED
            # 4 DRIVE_REMOTE
            # 5 DRIVE_CDROM
            # 6 DRIVE_RAMDISK
            if ($GetDriveType->Call("$drive:\\") =~ /^(3|4|6)$/) {
                push @harddrive, $drive;
            }
        }
        #----------------------------------------------------------------------
    };
}

# no drive yet
unless (@harddrive) {
    @harddrive = ('C'..'Z');
}

# find perl5.10 in the computer
@drive = ();
for $drive (sort @harddrive) {
    if (-e "$drive:\\perl510\\bin\\perl.exe") {
        push @drive, $drive;
    }
}

# perl5.10 not found
if (@drive == 0) {
    die "perl510: nothing \\Perl510\\bin\\perl.exe anywhere.\n";
}

# only one perl5.10 found
elsif (@drive == 1) {

    # execute perlscript on the its perl.exe.
    exit system("$drive[0]:\\perl510\\bin\\perl.exe", @ARGV);
}

# if many perl5.10 found
elsif (@drive > 1) {

    # select one perl.exe
    print STDERR "This computer has many perl.exe.\n";
    for $drive (@drive) {
        print STDERR "$drive:\\perl510\\bin\\perl.exe\n";
    }
    while (1) {
        print STDERR "Which perl.exe do you use? (exit by [Ctrl]+[C])";
        $drive = <STDIN>;
        $drive = substr($drive,0,1);
        if (grep(/^$drive$/i,@drive)) {

            # execute perlscript on the perl5.10
            exit system("$drive:\\perl510\\bin\\perl.exe", @ARGV);
        }
    }
}

__END__
:endofperl
