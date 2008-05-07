######################################################################
#
# Esjis - Source code filter to escape ShiftJIS
#
# Copyright (c) 2008 INABA Hitoshi <ina@cpan.org>
#
######################################################################

use strict;
use 5.00503;

use vars qw($VERSION);
$VERSION = sprintf '%d.%02d', q$Revision: 0.15 $ =~ m/(\d+)/oxmsg;

use constant DEBUG => 1;
local $SIG{__WARN__} = sub { die 'esjis: ', @_ } if DEBUG;
local $^W = 1;

$| = 1;

BEGIN {
    if ($^X =~ m/jperl/oxmsi) {
        die "esjis: need perl(not jperl) 5.00503 or later. (\$^X==$^X)";
    }
}

# regexp of character
my $qq_char   = qr/[^\\\x81-\x9F\xE0-\xFC]|[\\\x81-\x9F\xE0-\xFC][\x00-\xFF]|\\[\x81-\x9F\xE0-\xFC][\x00-\xFF]/oxms;
my  $q_char   = qr/[^\x81-\x9F\xE0-\xFC]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]/oxms;
my $sjis_char = q{[^\x81-\x9F\xE0-\xFC]|[\x81-\x9F\xE0-\xFC][\x00-\xFF]};
my $sjis_gap  = q{\G(?:[\x81-\x9F\xE0-\xFC]{2})*?|[^\x81-\x9F\xE0-\xFC](?:[\x81-\x9F\xE0-\xFC]{2})*?};

# regexp of nested parens in qqXX
my $qq_paren   = qr{(?{local $nest=0}) (?>(?:
                    [^\\\x81-\x9F\xE0-\xFC()]  | [\\\x81-\x9F\xE0-\xFC][\x00-\xFF] | \\[\x81-\x9F\xE0-\xFC][\x00-\xFF] |
                                          \(   (?{$nest++}) |
                                          \)   (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $qq_brace   = qr{(?{local $nest=0}) (?>(?:
                    [^\\\x81-\x9F\xE0-\xFC{}]  | [\\\x81-\x9F\xE0-\xFC][\x00-\xFF] | \\[\x81-\x9F\xE0-\xFC][\x00-\xFF] |
                                          \{   (?{$nest++}) |
                                          \}   (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $qq_bracket = qr{(?{local $nest=0}) (?>(?:
                    [^\\\x81-\x9F\xE0-\xFC[\]] | [\\\x81-\x9F\xE0-\xFC][\x00-\xFF] | \\[\x81-\x9F\xE0-\xFC][\x00-\xFF] |
                                          \[   (?{$nest++}) |
                                          \]   (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $qq_angle   = qr{(?{local $nest=0}) (?>(?:
                    [^\\\x81-\x9F\xE0-\xFC<>]  | [\\\x81-\x9F\xE0-\xFC][\x00-\xFF] | \\[\x81-\x9F\xE0-\xFC][\x00-\xFF] |
                                          \<   (?{$nest++}) |
                                          \>   (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $qq_scalar  = qr{(?: \{ (?:$qq_brace)*? \} |
                       (?: ::)? (?:
                             [a-zA-Z_][a-zA-Z_0-9]*
                       (?: ::[a-zA-Z_][a-zA-Z_0-9]* )* (?: \[ (?: \$\[ | \$\] | $qq_char )*? \] | \{ (?:$qq_brace)*? \} )*
                                         (?: (?: -> )? (?: \[ (?: \$\[ | \$\] | $qq_char )*? \] | \{ (?:$qq_brace)*? \} ) )*
                   ))
                 }xms;
my $qq_variable = qr{(?: \{ (?:$qq_brace)*? \} |
                        (?: ::)? (?:
                              [0-9]+            |
                              [^a-zA-Z_0-9\[\]] |
                              ^[A-Z]            |
                              [a-zA-Z_][a-zA-Z_0-9]*
                        (?: ::[a-zA-Z_][a-zA-Z_0-9]* )* (?: \[ (?: \$\[ | \$\] | $qq_char )*? \] | \{ (?:$qq_brace)*? \} )*
                                          (?: (?: -> )? (?: \[ (?: \$\[ | \$\] | $qq_char )*? \] | \{ (?:$qq_brace)*? \} ) )*
                    ))
                  }xms;

# regexp of nested parens in qXX
my $q_paren    = qr{(?{local $nest=0}) (?>(?:
                    [^\x81-\x9F\xE0-\xFC()]  | [\x81-\x9F\xE0-\xFC][\x00-\xFF] |
                                        \(   (?{$nest++}) |
                                        \)   (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $q_brace    = qr{(?{local $nest=0}) (?>(?:
                    [^\x81-\x9F\xE0-\xFC{}]  | [\x81-\x9F\xE0-\xFC][\x00-\xFF] |
                                        \{   (?{$nest++}) |
                                        \}   (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $q_bracket  = qr{(?{local $nest=0}) (?>(?:
                    [^\x81-\x9F\xE0-\xFC[\]] | [\x81-\x9F\xE0-\xFC][\x00-\xFF] |
                                        \[   (?{$nest++}) |
                                        \]   (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $q_angle    = qr{(?{local $nest=0}) (?>(?:
                    [^\x81-\x9F\xE0-\xFC<>]  | [\x81-\x9F\xE0-\xFC][\x00-\xFF] |
                                        \<   (?{$nest++}) |
                                        \>   (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;

my $eof          = 0;     # end of file
my $tr_variable1 = '';    # variable of ($scalar = ...) =~ tr///
my $tr_variable2 = '';    # variable of  $scalar        =~ tr///
my $tr_variable  = '';    # variable of                    tr///
my $slash        = 'm//'; # '/' means regexp match 'm//' and '?' means regexp match '??'
my %heredoc      = ();    # here document
my $heredoc_qq   = 0;     # here document quote type

# When this script is main program
if ($0 eq __FILE__) {

    # show usage
    unless (@ARGV) {
        die <<END;
esjis: usage

perl $0 ShiftJIS_script.pl > Escaped_script.pl.e
END
    }

    # read ShiftJIS script
    $_ = join '', <>;
    if (m/^package Sjis;$/oxms) {
        print $_;
        exit 0;
    }
    else {
        if (m/(.+#line \d+\n)/msgc) {
            my $head = $1;
            $head =~ s/\bjperl\b/perl/gi;
            print $head;
        }

        print <<'END_OF_DECLARE';
#
# ShiftJIS function declare
#
sub Sjis::split(;$$$);
sub Sjis::tr($$$;$);
sub Sjis::chop(;@);
sub Sjis::index($$;$);
sub Sjis::rindex($$;$);
sub Sjis::lc(;@);
sub Sjis::uc(;@);
sub Sjis::ignorecase(@);
sub Sjis::chr(;@);
sub Sjis::ord(;@);
sub Sjis::reverse(@);

END_OF_DECLARE

    }

    # while all script
    while (not /\G \z/oxgc) {
        print &escape;
    }
    if (not $eof) {
        print &package_Sjis();
    }
    exit 0;
}

# escape ShiftJIS script
sub escape() {

# \n output here document
    if (/\G ( \n ) /oxgc) {
        my $heredoc = '';
        if (scalar(keys %heredoc) >= 1) {
            $slash = 'm//';
            my($long_heredoc_delimiter) = sort { length($heredoc{$b}) <=> length($heredoc{$a}) } keys %heredoc;
            if ($heredoc_qq >= 1) {
                $heredoc = &e_heredoc($heredoc{$long_heredoc_delimiter});
            }
            else {
                $heredoc =            $heredoc{$long_heredoc_delimiter};
            }

            # skip here document
            /\G .*? \n $long_heredoc_delimiter \n/xmsgc;

            %heredoc = ();
            $heredoc_qq = 0;
        }
        return "\n" . $heredoc;
    }

# ignore space, comment
    elsif (/\G (\s+|\#.*) /oxgc) { return $1; }

# scalar variable ($scalar = ...) =~ tr///;
    elsif (/\G ( \( \s* (?: local \s+ | my \s+ | our \s+ )? ( \$ $qq_scalar ) ) /oxgc) {
        my $e_string  = &e_string($1);
        $tr_variable1 = &e_string($2);
        $slash = 'div';
        return $e_string;
    }

# scalar variable $scalar =~ tr///;
    elsif (/\G ( \$ $qq_scalar ) /oxgc) {
        $tr_variable2 = &e_string($1);
        my $e_string  = &e_string($1);
        $slash = 'div';
        return $e_string;
    }

# =~ tr ...
    elsif (/\G ( =~ \s* ) (?= (?: tr|y) \b ) /oxgc) {
        $slash = 'm//';
        $tr_variable = ($tr_variable1 || $tr_variable2);
        return ', ';
    }

    # any operator
    elsif (/\G ( [,;] ) /oxgc) {
        $slash = 'm//';

        # clear tr variable
        $tr_variable  = '';
        $tr_variable1 = '';
        $tr_variable2 = '';

        return $1;
    }

# variable or function
    elsif (/\G ( (?: [\$\@\%\&\*] | \$\# | -> | \b sub \b) \s* (?: split|chop|index|rindex|lc|uc|chr|ord|reverse|tr|y|q|qq|qx|qw|m|s|qr) ) \b /oxmsgc) {
        $slash = 'div';
        return $1;
    }
    elsif (/\G ( \$\$ | \$\@ | \$\# | \$\\ | \$\' | \$\" | \$\` | \$\/ | \$\? | \$\( | \$\) | \$\[ | \$\] | \$\< | \$\> ) /oxmsgc) {
        $slash = 'div';
        return $1;
    }

# doit if, doit unless, doit while, doit until, doit for
    elsif (m{\G \b ( if | unless | while | until | for ) \b }oxgc) { $slash = 'm//'; return $1;  }

# functions of package Sjis
    elsif (m{\G \b (CORE::(?:split|chop|index|rindex|lc|uc|chr|ord|reverse)) \b }oxgc) { $slash = 'm//'; return $1;  }
    elsif (m{\G \b split (\s* \( \s*) m\s*(\S)\2          }oxgc) { $slash = 'm//'; return   "Sjis::split$1''";   }
    elsif (m{\G \b split (\s* \( \s*) //                  }oxgc) { $slash = 'm//'; return   "Sjis::split$1''";   }
    elsif (m{\G \b split (\s*)        m\s*(\S)\2          }oxgc) { $slash = 'm//'; return   "Sjis::split$1''";   }
    elsif (m{\G \b split (\s*)        //                  }oxgc) { $slash = 'm//'; return   "Sjis::split$1''";   }
    elsif (m{\G \b split (\s* \( \s*) m\s*([ -?]\+?)\2    }oxgc) { $slash = 'm//'; return   "Sjis::split$1'$2'"; }
    elsif (m{\G \b split (\s* \( \s*) /([ -?]\+?)/        }oxgc) { $slash = 'm//'; return   "Sjis::split$1'$2'"; }
    elsif (m{\G \b split (\s*)        m\s*([ -?]\+?)\2    }oxgc) { $slash = 'm//'; return   "Sjis::split$1'$2'"; }
    elsif (m{\G \b split (\s*)        /([ -?]\+?)/        }oxgc) { $slash = 'm//'; return   "Sjis::split$1'$2'"; }
    elsif (m{\G \b split (\s* \( \s*) m\s*(\\[nrtf]\+?)\2 }oxgc) { $slash = 'm//'; return qq{Sjis::split$1"$2"}; }
    elsif (m{\G \b split (\s* \( \s*) /(\\[nrtf]\+?)/     }oxgc) { $slash = 'm//'; return qq{Sjis::split$1"$2"}; }
    elsif (m{\G \b split (\s*)        m\s*(\\[nrtf]\+?)\2 }oxgc) { $slash = 'm//'; return qq{Sjis::split$1"$2"}; }
    elsif (m{\G \b split (\s*)        /(\\[nrtf]\+?)/     }oxgc) { $slash = 'm//'; return qq{Sjis::split$1"$2"}; }
    elsif (m{\G \b split \b   (?! \s* => )                }oxgc) { $slash = 'm//'; return   'Sjis::split';       }
    elsif (m{\G \b chop \b    (?! \s* => )                }oxgc) { $slash = 'm//'; return   'Sjis::chop';        }
    elsif (m{\G \b index \b   (?! \s* => )                }oxgc) { $slash = 'm//'; return   'Sjis::index';       }
    elsif (m{\G \b rindex \b  (?! \s* => )                }oxgc) { $slash = 'm//'; return   'Sjis::rindex';      }
    elsif (m{\G \b lc \b      (?! \s* => )                }oxgc) { $slash = 'm//'; return   'Sjis::lc';          }
    elsif (m{\G \b uc \b      (?! \s* => )                }oxgc) { $slash = 'm//'; return   'Sjis::uc';          }
    elsif (m{\G \b chr \b     (?! \s* => )                }oxgc) { $slash = 'm//'; return   'Sjis::chr';         }
    elsif (m{\G \b ord \b     (?! \s* => )                }oxgc) { $slash = 'div'; return   'Sjis::ord';         }
    elsif (m{\G \b reverse \b (?! \s* => )                }oxgc) { $slash = 'm//'; return   'Sjis::reverse';     }

# tr/// or y///
    elsif (/\G \b (tr|y) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) ((?:$qq_char)*?) (\#) ([a-z]*) /oxgc) {
            my @tr = ($tr_variable,$2);
            return &e_tr(@tr, '', $4,$6);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?) (\)) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                    }
                    die "esjis: operator $ope can't find delimiter.\n";
                }
                elsif (/\G (\{) ((?:$qq_brace)*?) (\}) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                    }
                    die "esjis: operator $ope can't find delimiter.\n";
                }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                    }
                    die "esjis: operator $ope can't find delimiter.\n";
                }
                elsif (/\G (\<) ((?:$qq_angle)*?) (\>) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                    }
                    die "esjis: operator $ope can't find delimiter.\n";
                }
                elsif (/\G (\|) ((?:$qq_char)*?) (\|) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G      ((?:$qq_char)*?)    (\|) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $1,$3); }
                        elsif (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                    }
                    die "esjis: operator $ope can't find delimiter.\n";
                }
                elsif (/\G (\S) ((?:$qq_char)*?) (\1) /oxgc) {
                    my $end = $1;
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G      ((?:$qq_char)*?)    ($end) ([a-z]*) /xgc ) { return &e_tr(@tr, $e, $1,$3); }
                        elsif (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\))   ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\})   ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\])   ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>)   ([a-z]*) /oxgc) { return &e_tr(@tr, $e, $2,$4); }
                    }
                    die "esjis: operator $ope can't find delimiter.\n";
                }
            }
            die "esjis: operator $ope can't find delimiter.\n";
        }

        # clear tr variable
        $tr_variable  = '';
        $tr_variable1 = '';
        $tr_variable2 = '';
    }

# q//
    elsif (/\G \b (q) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc) {
            return &e_q($ope,$1,$3,$2);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:\\\)|\\\\|$q_paren)*?)   (\)) /oxgc) { return $e . &e_q($ope,$1,$3,$2); }
                elsif (/\G (\{) ((?:\\\}|\\\\|$q_brace)*?)   (\}) /oxgc) { return $e . &e_q($ope,$1,$3,$2); }
                elsif (/\G (\[) ((?:\\\]|\\\\|$q_bracket)*?) (\]) /oxgc) { return $e . &e_q($ope,$1,$3,$2); }
                elsif (/\G (\<) ((?:\\\>|\\\\|$q_angle)*?)   (\>) /oxgc) { return $e . &e_q($ope,$1,$3,$2); }
                elsif (/\G (\') ((?:\\\1|\\\\|$q_char)*?)    (\') /oxgc) { return $e . &e_q($ope,$1,$3,$2); } #'
                elsif (/\G (\S) ((?:\\\1|\\\\|$q_char)*?)    (\1) /oxgc) { return $e . &e_q($ope,$1,$3,$2); }
            }
            die "esjis: operator $ope can't find delimiter.\n";
        }
    }

# qq//
    elsif (/\G \b (qq) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) /oxgc) {
            return &e_qq($ope,$1,$3,$2);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?)   (\)) /oxgc) { return $e . &e_qq($ope,$1,$3,$2); }
                elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) /oxgc) { return $e . &e_qq($ope,$1,$3,$2); }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { return $e . &e_qq($ope,$1,$3,$2); }
                elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) /oxgc) { return $e . &e_qq($ope,$1,$3,$2); }
                elsif (/\G (\') ((?:$qq_char)*?)    (\') /oxgc) { return $e . &e_qq($ope,$1,$3,$2); } #'
                elsif (/\G (\S) ((?:$qq_char)*?)    (\1) /oxgc) { return $e . &e_qq($ope,$1,$3,$2); }
            }
            die "esjis: operator $ope can't find delimiter.\n";
        }
    }

# qx//
    elsif (/\G \b (qx) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) /oxgc) {
            return &e_qx($ope,$1,$3,$2);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?)   (\)) /oxgc) { return $e . &e_qx($ope,$1,$3,$2); }
                elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) /oxgc) { return $e . &e_qx($ope,$1,$3,$2); }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { return $e . &e_qx($ope,$1,$3,$2); }
                elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) /oxgc) { return $e . &e_qx($ope,$1,$3,$2); }
                elsif (/\G (\') ((?:$qq_char)*?)    (\') /oxgc) { return $e . &e_q ($ope,$1,$3,$2); } #'
                elsif (/\G (\S) ((?:$qq_char)*?)    (\1) /oxgc) { return $e . &e_qx($ope,$1,$3,$2); }
            }
            die "esjis: operator $ope can't find delimiter.\n";
        }
    }

# qw//
    elsif (/\G \b (qw) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) (.*?) (\#) /oxmsgc) {
            return &e_qw($ope,$1,$3,$2);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                elsif (/\G (\() (.*?) (\)) /oxmsgc) { return $e . &e_qw($ope,$1,$3,$2); }
                elsif (/\G (\{) (.*?) (\}) /oxmsgc) { return $e . &e_qw($ope,$1,$3,$2); }
                elsif (/\G (\[) (.*?) (\]) /oxmsgc) { return $e . &e_qw($ope,$1,$3,$2); }
                elsif (/\G (\<) (.*?) (\>) /oxmsgc) { return $e . &e_qw($ope,$1,$3,$2); }
                elsif (/\G (\S) (.*?) (\1) /oxmsgc) { return $e . &e_qw($ope,$1,$3,$2); }
            }
            die "esjis: operator $ope can't find delimiter.\n";
        }
    }

# m//
    elsif (/\G \b (m) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) ([a-z]*) /oxgc) {
            return &e_m($ope,$1,$3,$2,$4);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([a-z]*) /oxgc) { return $e . &e_m  ($ope,$1, $3, $2,$4); }
                elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([a-z]*) /oxgc) { return $e . &e_m  ($ope,$1, $3, $2,$4); }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([a-z]*) /oxgc) { return $e . &e_m  ($ope,$1, $3, $2,$4); }
                elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([a-z]*) /oxgc) { return $e . &e_m  ($ope,$1, $3, $2,$4); }
                elsif (/\G (\') ((?:$qq_char)*?)    (\') ([a-z]*) /oxgc) { return $e . &e_m_q($ope,$1, $3, $2,$4); } #'
                elsif (/\G (\|) ((?:$qq_char)*?)    (\|) ([a-z]*) /oxgc) { return $e . &e_m  ($ope,'<','>',$2,$4); }
                elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([a-z]*) /oxgc) { return $e . &e_m  ($ope,$1, $3, $2,$4); }
            }
            die "esjis: operator $ope can't find delimiter.\n";
        }
    }

# s///
    elsif (/\G \b (s) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) ((?:$qq_char)*?) (\#) ([a-z]*) /oxgc) {
            my @s = ($ope,$1,$3,$2);
            return &e_s(@s,$6) . &e_s_qq($ope,'',$5,$4,$6);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?) (\)) /oxgc) {
                    my @s = ($ope,$1,$3,$2);
                    while (not /\G \z/oxgc) {
                        if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_q2($ope,$1,$3,$2,$4); } #'
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                    }
                    die "esjis: operator $ope can't find delimiter.\n";
                }
                elsif (/\G (\{) ((?:$qq_brace)*?) (\}) /oxgc) {
                    my @s = ($ope,$1,$3,$2);
                    while (not /\G \z/oxgc) {
                        if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_q2($ope,$1,$3,$2,$4); } #'
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                    }
                    die "esjis: operator $ope can't find delimiter.\n";
                }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) {
                    my @s = ($ope,$1,$3,$2);
                    while (not /\G \z/oxgc) {
                        if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_q2($ope,$1,$3,$2,$4); } #'
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                    }
                    die "esjis: operator $ope can't find delimiter.\n";
                }
                elsif (/\G (\<) ((?:$qq_angle)*?) (\>) /oxgc) {
                    my @s = ($ope,$1,$3,$2);
                    while (not /\G \z/oxgc) {
                        if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_q2($ope,$1,$3,$2,$4); } #'
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                    }
                    die "esjis: operator $ope can't find delimiter.\n";
                }
                elsif (/\G (\') ((?:$qq_char)*?) (\') /oxgc) { #'
                    my @s = ($ope,$1,$3,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G      ((?:$qq_char)*?)    (\') ([a-z]*) /oxgc) { return &e_s_q(@s,$4) . $e . &e_s_q2($ope,'',$2,$1,$3); }
                        elsif (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([a-z]*) /oxgc) { return &e_s_q(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([a-z]*) /oxgc) { return &e_s_q(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([a-z]*) /oxgc) { return &e_s_q(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([a-z]*) /oxgc) { return &e_s_q(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                    }
                    die "esjis: operator $ope can't find delimiter.\n";
                }
                elsif (/\G (\|) ((?:$qq_char)*?) (\|) /oxgc) {
                    my @s = ($ope,'(',')',$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G      ((?:$qq_char)*?)    (\|) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,'(',')',$1,$3); }
                        elsif (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                    }
                    die "esjis: operator $ope can't find delimiter.\n";
                }
                elsif (/\G (\S) ((?:$qq_char)*?) (\1) /oxgc) {
                    my $end = $1;
                    my @s = ($ope,$1,$3,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G      ((?:$qq_char)*?)    ($end) ([a-z]*) /xgc)  { return &e_s(@s,$4) . $e . &e_s_qq($ope,'',$2,$1,$3); }
                        elsif (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\))   ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\})   ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\])   ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>)   ([a-z]*) /oxgc) { return &e_s(@s,$4) . $e . &e_s_qq($ope,$1,$3,$2,$4); }
                    }
                    die "esjis: operator $ope can't find delimiter.\n";
                }
            }
            die "esjis: operator $ope can't find delimiter.\n";
        }
    }

# qr//
    elsif (/\G \b (qr) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) ([a-z]*) /oxgc) {
            return &e_qr($ope,$1,$3,$2,$4);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([a-z]*) /oxgc) { return $e . &e_qr  ($ope,$1, $3, $2,$4); }
                elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([a-z]*) /oxgc) { return $e . &e_qr  ($ope,$1, $3, $2,$4); }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([a-z]*) /oxgc) { return $e . &e_qr  ($ope,$1, $3, $2,$4); }
                elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([a-z]*) /oxgc) { return $e . &e_qr  ($ope,$1, $3, $2,$4); }
                elsif (/\G (\') ((?:$qq_char)*?)    (\') ([a-z]*) /oxgc) { return $e . &e_qr_q($ope,$1, $3, $2,$4); } #'
                elsif (/\G (\|) ((?:$qq_char)*?)    (\|) ([a-z]*) /oxgc) { return $e . &e_qr  ($ope,'<','>',$2,$4); }
                elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([a-z]*) /oxgc) { return $e . &e_qr  ($ope,$1, $3, $2,$4); }
            }
            die "esjis: operator $ope can't find delimiter.\n";
        }
    }

# ''
    elsif (/\G (?<!\w) (\') ((?:\\\'|\\\\|$q_char)*?) (\') /oxgc) { return &e_q('',$1,$3,$2); } #'

# ""
    elsif (/\G (\") ((?:$qq_char)*?) (\") /oxgc)                  { return &e_qq('',$1,$3,$2); } #"

# ``
    elsif (/\G (\`) ((?:$qq_char)*?) (\`) /oxgc)                  { return &e_qx('',$1,$3,$2); }

# //   --- not divide operator (num / num)
    elsif (($slash eq 'm//') and
           /\G (\/) ((?:$qq_char)*?) (\/) ([a-z]*) /oxgc)         { return &e_m ('', $1,$3,$2,$4); }

# ??   --- not three item operator (condition ? true : false)
    elsif (($slash eq 'm//') and
           /\G (\?) ((?:$qq_char)*?) (\?) ([a-z]*) /oxgc)         { return &e_m ('', $1,$3,$2,$4); }

# << (bit shift)
    elsif (/\G ( << \s* ) (?= [0-9\$\@\&] ) /oxgc)                { $slash = 'm//'; return $1; }

# <<'HEREDOC'
    elsif (/\G ( << '([a-zA-Z_0-9]*)' ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        my $script = substr($_, pos($_));
        $script =~ s/.*?\n//oxm;
        if ($script =~ /\A (.*? \n $delimiter \n) /xms) {
            $heredoc{$delimiter} = $1;
        }
        else {
            die "esjis: here document delimiter $delimiter not found.\n";
        }
        return $here_quote;
    }

# <<\HEREDOC
    elsif (/\G ( << \\([a-zA-Z_0-9]+) ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        my $script = substr($_, pos($_));
        $script =~ s/.*?\n//oxm;
        if ($script =~ /\A (.*? \n $delimiter \n) /xms) {
            $heredoc{$delimiter} = $1;
        }
        else {
            die "esjis: here document delimiter $delimiter not found.\n";
        }
        return $here_quote;
    }

# <<"HEREDOC"
    elsif (/\G ( << "([a-zA-Z_0-9]*)" ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;
        $heredoc_qq++;

        # get here document
        my $script = substr($_, pos($_));
        $script =~ s/.*?\n//oxm;
        if ($script =~ /\A (.*? \n $delimiter \n) /xms) {
            $heredoc{$delimiter} = $1;
        }
        else {
            die "esjis: here document delimiter $delimiter not found.\n";
        }
        return $here_quote;
    }

# <<HEREDOC
    elsif (/\G ( << ([a-zA-Z_0-9]+) ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;
        $heredoc_qq++;

        # get here document
        my $script = substr($_, pos($_));
        $script =~ s/.*?\n//oxm;
        if ($script =~ /\A (.*? \n $delimiter \n) /xms) {
            $heredoc{$delimiter} = $1;
        }
        else {
            die "esjis: here document delimiter $delimiter not found.\n";
        }
        return $here_quote;
    }

# <<`HEREDOC`
    elsif (/\G ( << `([a-zA-Z_0-9]*)` ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;
        $heredoc_qq++;

        # get here document
        my $script = substr($_, pos($_));
        $script =~ s/.*?\n//oxm;
        if ($script =~ /\A (.*? \n $delimiter \n) /xms) {
            $heredoc{$delimiter} = $1;
        }
        else {
            die "esjis: here document delimiter $delimiter not found.\n";
        }
        return $here_quote;
    }

# __DATA__
    elsif (/\G ^ (__DATA__ \n .*) \z /oxmsgc) { $eof = 1; return &package_Sjis() . $1; }

# __END__
    elsif (/\G ^ (__END__  \n .*) \z /oxmsgc) { $eof = 1; return &package_Sjis() . $1; }

    # any operator
    elsif (/\G (

            != | !~ | ! |
            %= | % |
            &&= | && | &= | & |
            -- | -= | -> | -[rwxoRWXOezsfdlpSbctugkTBMAC] | - |
            : |
            <<= | <=> | <= | < |
            == | => | =~ | = |
            >>= | >> | >= | > |
            \*\*= | \*\* | \*= | \* |
            \+\+ | \+= | \+ |
            \.\.\. | \.\. | \.= | \. |
            \/= | \/ |
            \? |
            \\ |
            \^= | \^ |
            \b x= |
            \|\|= | \|\| | \|= | \| |
            ~ |
            \b(?: and | cmp | eq | ge | gt | le | lt | ne | not | or | xor | x )\b |

            [,;\(\{\[]

                       ) /oxgc) { $slash = 'm//'; return $1; }

    # other any character
    elsif (/\G ($q_char) /oxgc) { $slash = 'div'; return $1; }

    # system error
    else {
        die "esjis: Can't rewrite script $0";
    }
}

# escape ShiftJIS string
sub e_string($) {
    my($string) = @_;
    my $e_string = '';

    # without { ... }
    my @char = $string =~ m/ \G ([\\\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC]) /oxmsg;
    if (not (grep(m/\A \{ \z/xms, @char) and grep(m/\A \} \z/xms, @char))) {
        return $string;
    }

E_STRING_LOOP:
    while ($string !~ /\G \z/oxgc) {

# bare word
        if ($string =~ /\G ( \{ \s* (?: tr | index | rindex | reverse ) \s* \} ) /oxmsgc) {
            $e_string .= $1;
        }

# variable
        elsif ($string =~ /\G ( (?: [\$\@\%\&\*] | \$\# | -> ) \s* (?: split | chop | index | rindex | lc | uc | chr | ord | reverse | tr | y | q | qq | qx | qw | m | s | qr ) ) \b /oxmsgc) {
            $e_string .= $1;
        }
        elsif ($string =~ /\G ( \$\$ | \$\@ | \$\# | \$\\ | \$\' | \$\" | \$\` | \$\/ | \$\? | \$\( | \$\) | \$\[ | \$\] | \$\< | \$\> ) /oxmsgc) {
            $e_string .= $1;
        }

# functions of package Sjis
        elsif ($string =~ m{\G \b (CORE::(?:split|chop|index|rindex|lc|uc|chr|ord|reverse)) \b }oxgc) { $e_string .= $1;  }
        elsif ($string =~ m{\G \b split (\s* \( \s*) m\s*(\S)\2          }oxgc) { $e_string .=   "Sjis::split$1''";   }
        elsif ($string =~ m{\G \b split (\s* \( \s*) //                  }oxgc) { $e_string .=   "Sjis::split$1''";   }
        elsif ($string =~ m{\G \b split (\s*)        m\s*(\S)\2          }oxgc) { $e_string .=   "Sjis::split$1''";   }
        elsif ($string =~ m{\G \b split (\s*)        //                  }oxgc) { $e_string .=   "Sjis::split$1''";   }
        elsif ($string =~ m{\G \b split (\s* \( \s*) m\s*([ -?]\+?)\2    }oxgc) { $e_string .=   "Sjis::split$1'$2'"; }
        elsif ($string =~ m{\G \b split (\s* \( \s*) /([ -?]\+?)/        }oxgc) { $e_string .=   "Sjis::split$1'$2'"; }
        elsif ($string =~ m{\G \b split (\s*)        m\s*([ -?]\+?)\2    }oxgc) { $e_string .=   "Sjis::split$1'$2'"; }
        elsif ($string =~ m{\G \b split (\s*)        /([ -?]\+?)/        }oxgc) { $e_string .=   "Sjis::split$1'$2'"; }
        elsif ($string =~ m{\G \b split (\s* \( \s*) m\s*(\\[nrtf]\+?)\2 }oxgc) { $e_string .= qq{Sjis::split$1"$2"}; }
        elsif ($string =~ m{\G \b split (\s* \( \s*) /(\\[nrtf]\+?)/     }oxgc) { $e_string .= qq{Sjis::split$1"$2"}; }
        elsif ($string =~ m{\G \b split (\s*)        m\s*(\\[nrtf]\+?)\2 }oxgc) { $e_string .= qq{Sjis::split$1"$2"}; }
        elsif ($string =~ m{\G \b split (\s*)        /(\\[nrtf]\+?)/     }oxgc) { $e_string .= qq{Sjis::split$1"$2"}; }
        elsif ($string =~ m{\G \b split \b                               }oxgc) { $e_string .=   'Sjis::split';       }
        elsif ($string =~ m{\G \b chop \b                                }oxgc) { $e_string .=   'Sjis::chop';        }
        elsif ($string =~ m{\G \b index \b                               }oxgc) { $e_string .=   'Sjis::index';       }
        elsif ($string =~ m{\G \b rindex \b                              }oxgc) { $e_string .=   'Sjis::rindex';      }
        elsif ($string =~ m{\G \b lc \b                                  }oxgc) { $e_string .=   'Sjis::lc';          }
        elsif ($string =~ m{\G \b uc \b                                  }oxgc) { $e_string .=   'Sjis::uc';          }
        elsif ($string =~ m{\G \b chr \b                                 }oxgc) { $e_string .=   'Sjis::chr';         }
        elsif ($string =~ m{\G \b ord \b                                 }oxgc) { $e_string .=   'Sjis::ord';         }
        elsif ($string =~ m{\G \b reverse \b                             }oxgc) { $e_string .=   'Sjis::reverse';     }

# q//
        elsif ($string =~ /\G \b (q) \b /oxgc) {
            my $ope = $1;
            if ($string =~ /\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc) {
                $e_string .= &e_q($ope,$1,$3,$2);
            }
            else {
                my $e = '';
                while ($string !~ /\G \z/oxgc) {
                    if ($string =~ /\G (\s+|\#.*) /oxgc) { $e .= $1; }
                    elsif ($string =~ /\G (\() ((?:\\\)|\\\\|$q_paren)*?)   (\)) /oxgc) { $e_string .= $e . &e_q($ope,$1,$3,$2); next E_STRING_LOOP; }
                    elsif ($string =~ /\G (\{) ((?:\\\}|\\\\|$q_brace)*?)   (\}) /oxgc) { $e_string .= $e . &e_q($ope,$1,$3,$2); next E_STRING_LOOP; }
                    elsif ($string =~ /\G (\[) ((?:\\\]|\\\\|$q_bracket)*?) (\]) /oxgc) { $e_string .= $e . &e_q($ope,$1,$3,$2); next E_STRING_LOOP; }
                    elsif ($string =~ /\G (\<) ((?:\\\>|\\\\|$q_angle)*?)   (\>) /oxgc) { $e_string .= $e . &e_q($ope,$1,$3,$2); next E_STRING_LOOP; }
                    elsif ($string =~ /\G (\') ((?:\\\1|\\\\|$q_char)*?)    (\') /oxgc) { $e_string .= $e . &e_q($ope,$1,$3,$2); next E_STRING_LOOP; } #'
                    elsif ($string =~ /\G (\S) ((?:\\\1|\\\\|$q_char)*?)    (\1) /oxgc) { $e_string .= $e . &e_q($ope,$1,$3,$2); next E_STRING_LOOP; }
                }
                die "esjis: operator $ope can't find delimiter.\n";
            }
        }

# qq//
        elsif ($string =~ /\G \b (qq) \b /oxgc) {
            my $ope = $1;
            if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) /oxgc) {
                $e_string .= &e_qq($ope,$1,$3,$2);
            }
            else {
                my $e = '';
                while ($string !~ /\G \z/oxgc) {
                    if ($string =~ /\G (\s+|\#.*) /oxgc) { $e .= $1; }
                    elsif ($string =~ /\G (\() ((?:$qq_paren)*?)   (\)) /oxgc) { $e_string .= $e . &e_qq($ope,$1,$3,$2); next E_STRING_LOOP; }
                    elsif ($string =~ /\G (\{) ((?:$qq_brace)*?)   (\}) /oxgc) { $e_string .= $e . &e_qq($ope,$1,$3,$2); next E_STRING_LOOP; }
                    elsif ($string =~ /\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { $e_string .= $e . &e_qq($ope,$1,$3,$2); next E_STRING_LOOP; }
                    elsif ($string =~ /\G (\<) ((?:$qq_angle)*?)   (\>) /oxgc) { $e_string .= $e . &e_qq($ope,$1,$3,$2); next E_STRING_LOOP; }
                    elsif ($string =~ /\G (\') ((?:$qq_char)*?)    (\') /oxgc) { $e_string .= $e . &e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } #'
                    elsif ($string =~ /\G (\S) ((?:$qq_char)*?)    (\1) /oxgc) { $e_string .= $e . &e_qq($ope,$1,$3,$2); next E_STRING_LOOP; }
                }
                die "esjis: operator $ope can't find delimiter.\n";
            }
        }

# qx//
        elsif ($string =~ /\G \b (qx) \b /oxgc) {
            my $ope = $1;
            if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) /oxgc) {
                $e_string .= &e_qx($ope,$1,$3,$2);
            }
            else {
                my $e = '';
                while ($string !~ /\G \z/oxgc) {
                    if ($string =~ /\G (\s+|\#.*) /oxgc) { $e .= $1; }
                    elsif ($string =~ /\G (\() ((?:$qq_paren)*?)   (\)) /oxgc) { $e_string .= $e . &e_qx($ope,$1,$3,$2); next E_STRING_LOOP; }
                    elsif ($string =~ /\G (\{) ((?:$qq_brace)*?)   (\}) /oxgc) { $e_string .= $e . &e_qx($ope,$1,$3,$2); next E_STRING_LOOP; }
                    elsif ($string =~ /\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { $e_string .= $e . &e_qx($ope,$1,$3,$2); next E_STRING_LOOP; }
                    elsif ($string =~ /\G (\<) ((?:$qq_angle)*?)   (\>) /oxgc) { $e_string .= $e . &e_qx($ope,$1,$3,$2); next E_STRING_LOOP; }
                    elsif ($string =~ /\G (\') ((?:$qq_char)*?)    (\') /oxgc) { $e_string .= $e . &e_q ($ope,$1,$3,$2); next E_STRING_LOOP; } #'
                    elsif ($string =~ /\G (\S) ((?:$qq_char)*?)    (\1) /oxgc) { $e_string .= $e . &e_qx($ope,$1,$3,$2); next E_STRING_LOOP; }
                }
                die "esjis: operator $ope can't find delimiter.\n";
            }
        }

# ''
        elsif ($string =~ /\G (?<!\w) (\') ((?:\\\'|\\\\|$q_char)*?) (\') /oxgc) { $e_string .= &e_q('',$1,$3,$2); } #'

# ""
        elsif ($string =~ /\G (\") ((?:$qq_char)*?) (\") /oxgc)                  { $e_string .= &e_qq('',$1,$3,$2); } #"

# ``
        elsif ($string =~ /\G (\`) ((?:$qq_char)*?) (\`) /oxgc)                  { $e_string .= &e_qx('',$1,$3,$2); }

        # other any character
        elsif ($string =~ /\G ($q_char) /oxgc) { $e_string .= $1; }

        # system error
        else {
            die "esjis: Can't rewrite script $0";
        }
    }

    return $e_string;
}

#
# escape transliteration (tr/// or y///)
#
sub e_tr($$$$$) {
    my($tr_variable,$charclass,$e,$charclass2,$option) = @_;
    $option ||= '';

    $slash = 'div';

    # variable
    if ($tr_variable eq '') {
        $tr_variable = q{$_};
    }

    # quote character class 1
    if($charclass !~ m/'/oxms) {
        $charclass = &e_q('',  "'", "'", $charclass);
    }
    elsif($charclass !~ m{/}oxms) {
        $charclass = &e_q('q', '/', '/', $charclass);
    }
    elsif($charclass !~ m/\#/oxms) {
        $charclass = &e_q('q', '#', '#', $charclass);
    }
    elsif($charclass !~ m/[<>]/oxms) {
        $charclass = &e_q('q', '<', '>', $charclass);
    }
    elsif($charclass !~ m/[()]/oxms) {
        $charclass = &e_q('q', '(', ')', $charclass);
    }
    elsif($charclass !~ m/!/oxms) {
        $charclass = &e_q('q', '!', '!', $charclass);
    }
    else {
        $charclass = &e_q('q', '{', '}', $charclass);
    }

    # quote character class 2
    if($charclass2 !~ m/'/oxms) {
        $charclass2 = &e_q('',  "'", "'", $charclass2);
    }
    elsif($charclass2 !~ m{/}oxms) {
        $charclass2 = &e_q('q', '/', '/', $charclass2);
    }
    elsif($charclass2 !~ m/\#/oxms) {
        $charclass2 = &e_q('q', '#', '#', $charclass2);
    }
    elsif($charclass2 !~ m/[<>]/oxms) {
        $charclass2 = &e_q('q', '<', '>', $charclass2);
    }
    elsif($charclass2 !~ m/[()]/oxms) {
        $charclass2 = &e_q('q', '(', ')', $charclass2);
    }
    elsif($charclass2 !~ m/!/oxms) {
        $charclass2 = &e_q('q', '!', '!', $charclass2);
    }
    else {
        $charclass2 = &e_q('q', '{', '}', $charclass2);
    }

    return qq{Sjis::tr($tr_variable,$charclass,$e$charclass2,'$option')};
}

#
# escape q string (q//, '')
#
sub e_q($$$$) {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    my @char = $string =~ m/ \G ([\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC]) /oxmsg;
    for (my $i=0; $i <= $#char-1; $i++) {
        if (($char[$i] =~ m/\A ([\x81-\x9F\xE0-\xFC]) \\ \z/oxms) and
            (($char[$i+1] eq '\\') or ($char[$i+1] eq $end_delimiter))
        ) {
            $char[$i] .= '\\';
        }
    }
    if (defined $char[$#char]) {
        if ($char[$#char] =~ m/\A ([\x81-\x9F\xE0-\xFC]) \\ \z/oxms) {
            $char[$#char] .= '\\';
        }
    }

    return join '', $ope, $delimiter, @char, $end_delimiter;
}

#
# escape qq string (qq//, "")
#
sub e_qq($$$$) {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    my $metachar = {
        'qq' => qr/[\@\\]/oxms,
        ''   => qr/[\@\\]/oxms,
    }->{$ope} || die 'esjis: system error (e_qq)';

    # escape character
    my $left_e  = 0;
    my $right_e = 0;
    my @char = $string =~ m/ \G ([\\\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC]) /oxmsg;
    for (my $i=0; $i <= $#char; $i++) {

        # escape character
        if ($char[$i] =~ m/\A ([\x81-\x9F\xE0-\xFC]) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1.'\\'.$2;
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\\L') {
            $char[$i] = '@{[Sjis::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\U') {
            $char[$i] = '@{[Sjis::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
    }

    # return string
    if ($left_e > $right_e) {
        return join '', $ope, $delimiter, @char, '>]}' x ($left_e - $right_e), $end_delimiter;
    }
    else {
        return join '', $ope, $delimiter, @char, $end_delimiter;
    }
}

#
# escape qx string (qx//)
#
sub e_qx($$$$) {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    my $metachar = {
        'qx' => qr/[\@\\|]/oxms,
        ''   => qr/[\@\\|]/oxms,
    }->{$ope} || die 'esjis: system error (e_qx)';

    # escape character
    my $left_e  = 0;
    my $right_e = 0;
    my @char = $string =~ m/ \G ([\\\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC]) /oxmsg;
    for (my $i=0; $i <= $#char; $i++) {

        # escape character
        if ($char[$i] =~ m/\A ([\x81-\x9F\xE0-\xFC]) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1.'\\'.$2;
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\\L') {
            $char[$i] = '@{[Sjis::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\U') {
            $char[$i] = '@{[Sjis::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
    }

    # return string
    if ($left_e > $right_e) {
        return join '', $ope, $delimiter, @char, '>]}' x ($left_e - $right_e), $end_delimiter;
    }
    else {
        return join '', $ope, $delimiter, @char, $end_delimiter;
    }
}

#
# escape qw string (qw//)
#
sub e_qw($$$$) {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    # return string
    return join '', $ope, $delimiter, $string, $end_delimiter;
}

#
# escape here document (<<"HEREDOC", <<HEREDOC, <<`HEREDOC`)
#
sub e_heredoc($) {
    my($string) = @_;

    $slash = 'm//';

    my $metachar = qr/[\@\\|]/oxms; # '|' is for <<`HEREDOC`

    # escape character
    my $left_e  = 0;
    my $right_e = 0;
    my @char = $string =~ m/ \G ([\\\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC]) /oxmsg;
    for (my $i=0; $i <= $#char; $i++) {

        # escape character
        if ($char[$i] =~ m/\A ([\x81-\x9F\xE0-\xFC]) ($metachar) \z/oxms) {
            $char[$i] = $1.'\\'.$2;
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\\L') {
            $char[$i] = '@{[Sjis::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\U') {
            $char[$i] = '@{[Sjis::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
    }

    # return string
    if ($left_e > $right_e) {
        return join '', @char, '>]}' x ($left_e - $right_e);
    }
    else {
        return join '', @char;
    }
}

#
# escape regexp (m//)
#
sub e_m($$$$$) {
    my($ope,$delimiter,$end_delimiter,$string,$option) = @_;
    $option ||= '';

    $slash = 'div';

    my $metachar = {
        'm' => qr/[\@\\|[\]{]/oxms,
        ''  => qr/[\@\\|[\]{]/oxms,
    }->{$ope} || die 'esjis: system error (e_m)';

    # split regexp
    my @char = $string =~ m{\G(
        \\  [0-7]{2,3}         |
        \\x [0-9A-Fa-f]{2}     |
        \\x \{ [0-9A-Fa-f]+ \} |
        \\c [\x40-\x5F]        |
        \\  (?:[\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC]) |
        [\$\@] $qq_variable |
        \[\^ |
            (?:[\\\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\\\x81-\x9F\xE0-\xFC])
    )}oxmsg;

    # unescape character
    my $left_e  = 0;
    my $right_e = 0;
    for (my $i=0; $i <= $#char; $i++) {
        next if not defined $char[$i];

        # open character class [...]
        if ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die 'esjis: ' . join('',@char[$left..$#char]) . ' unmatched [] in regexp';
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice(@char, $left, $right-$left+1, &charlist_qr(@char[$left+1..$right-1], $option));

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die 'esjis: ' . join('',@char[$left..$#char]) . ' unmatched [] in regexp';
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice(@char, $left, $right-$left+1, &charlist_not_qr(@char[$left+1..$right-1], $option));

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = {
            '.'  => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC])',
            '\D' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC0-9])',
            '\W' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFCa-zA-Z_0-9])',
            '\S' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC\x20\t\n\r\f])',
            }->{$char[$i]}
        ) {
            $char[$i] = $char;
        }

        # unescape for join separated double octet
        #                              LF   CR   $    (    )    *    +    .    ?    [   \   ^   {   |
        elsif ($char[$i] =~ m/\A \\ (?:0?12|0?15|0?44|0?50|0?51|0?52|0?53|0?56|0?77|133|134|136|173|174) \z/oxms) {
        }
        elsif ($char[$i] =~ m/\A \\ ([0-7]{2,3}) \z/oxms) {
            $char[$i] = chr(oct($1));
        }
        #                               LF  CR  $  (  )  *  +  .  ?  [  \  ^  {  |
        elsif ($char[$i] =~ m/\A \\x (?:0?A|0?D|24|28|29|2A|2B|2E|3F|5B|5C|5E|7B|7C) \z/oxmsi) {
        }
        elsif ($char[$i] =~ m/\A \\x ([0-9A-Fa-f]{2}) \z/oxms) {
            $char[$i] = chr(hex($1));
        }
        #                                     LF  CR  $  (  )  *  +  .  ?  [  \  ^  {  |
        elsif ($char[$i] =~ m/\A \\x \{ 0* (?:0?A|0?D|24|28|29|2A|2B|2E|3F|5B|5C|5E|7B|7C) \} \z/oxmsi) {
        }
        elsif ($char[$i] =~ m/\A \\x \{ ([0-9A-Fa-f]+) \} \z/oxms) {
            my $hex = (length($1) % 2) ? ('0' . $1) : $1;
            $char[$i] = quotemeta pack('H*',$hex);
        }
        #                                LF  CR
        elsif ($char[$i] =~ m/\A \\c (?: J | M ) \z/oxmsi) {
        }
        elsif ($char[$i] =~ m/\A \\c ([\x40-\x5F]) \z/oxms) {
            $char[$i] = chr(ord($1) & 0x1F);
        }

        # /i option
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            my $c = $1;
            if ($option =~ m/i/oxms) {
                $char[$i] = '[' . uc($c) . lc($c) . ']';
            }
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\\L') {
            $char[$i] = '@{[Sjis::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\U') {
            $char[$i] = '@{[Sjis::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }

        # $scalar or @array
        elsif ($char[$i] =~ m/\A [\$\@].+ /oxms) {
            if ($option =~ m/i/oxms) {
                $char[$i] = '@{[Sjis::ignorecase(' . &e_string($char[$i]) . ')]}';
            }
            else {
                $char[$i] = &e_string($char[$i]);
            }
        }
    }

    # characterize
    for (my $i=0; $i <= $#char; $i++) {
        next if not defined $char[$i];

        # join separated double octet
        if ($char[$i] =~ m/\A [\x81-\x9F\xE0-\xFC] \z/oxms) {
            if ($i < $#char) {
                $char[$i] .= $char[$i+1];
                splice(@char,$i+1,1);
            }
        }

        # escape second octet of double octet
        if ($char[$i] =~ m/\A \\? ([\x81-\x9F\xE0-\xFC]) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1.'\\'.$2;
        }

        # unescape double octet
        elsif ($char[$i] =~ m/\A \\ ([\x81-\x9F\xE0-\xFC][\x00-\xFF]) \z/oxms) {
            $char[$i] = $1;
        }

        # quote double octet character before ? + * {
        elsif (
            ($i >= 1) and
            ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms) and
            ($char[$i-1] =~ m/\A [\x81-\x9F\xE0-\xFC] (?: \\?[\x00-\xFF] | \\[0-7]{2,3} | \\x[0-9A-Fa-f]{1,2} ) \z/oxms)
        ) {
            $char[$i-1] = '(?:' . $char[$i-1] . ')';
        }
    }

    # make regexp string
    my $re;
    $option =~ tr/i//d;
    if ($left_e > $right_e) {
        $re = join '', $ope, $delimiter, $sjis_gap, @char, '>]}' x ($left_e - $right_e), $end_delimiter, $option;
    }
    else {
        $re = join '', $ope, $delimiter, $sjis_gap, @char,                               $end_delimiter, $option;
    }
    return $re;
}

#
# escape regexp (m'')
#
sub e_m_q($$$$$) {
    my($ope,$delimiter,$end_delimiter,$string,$option) = @_;
    $option ||= '';

    $slash = 'div';

    # split regexp
    my @char = $string =~ m{\G(
        \[\^ |
            (?:[\\\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\\\x81-\x9F\xE0-\xFC])
    )}oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        next if not defined $char[$i];

        # open character class [...]
        if ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die 'esjis: ' . join('',@char[$left..$#char]) . ' unmatched [] in regexp';
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice(@char, $left, $right-$left+1, &charlist_qr(@char[$left+1..$right-1], $option));

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die 'esjis: ' . join('',@char[$left..$#char]) . ' unmatched [] in regexp';
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice(@char, $left, $right-$left+1, &charlist_not_qr(@char[$left+1..$right-1], $option));

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = {
            '.'  => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC])',
            '\D' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC0-9])',
            '\W' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFCa-zA-Z_0-9])',
            '\S' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC\x20\t\n\r\f])',
            }->{$char[$i]}
        ) {
            $char[$i] = $char;
        }

        # /i option
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            my $c = $1;
            if ($option =~ m/i/oxms) {
                $char[$i] = '[' . uc($c) . lc($c) . ']';
            }
        }
    }

    # characterize
    for (my $i=0; $i <= $#char; $i++) {
        next if not defined $char[$i];

        # escape second octet of double octet
        if (($i <= $#char-1) and
            ($char[$i] =~ m/\A ([\x81-\x9F\xE0-\xFC]) \\ \z/oxms) and
            (($char[$i+1] eq '\\') or ($char[$i+1] eq $end_delimiter))
        ) {
            $char[$i] .= '\\';
        }

        # quote double octet character before ? + * {
        elsif (
            ($i >= 1) and
            ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms) and
            ($char[$i-1] =~ m/\A [\x81-\x9F\xE0-\xFC] (?: \\?[\x00-\xFF] | \\[0-7]{2,3} | \\x[0-9A-Fa-f]{1,2} ) \z/oxms)
        ) {
            $char[$i-1] = '(?:' . $char[$i-1] . ')';
        }
    }

    $option =~ tr/i//d;
    return join '', $ope, $delimiter, $sjis_gap, @char, $end_delimiter, $option;
}

#
# escape regexp (s/here//)
#
sub e_s($$$$$) {
    my($ope,$delimiter,$end_delimiter,$string,$option) = @_;
    $option ||= '';

    $slash = 'div';

    my $metachar = {
        's' => qr/[\@\\|[\]{]/oxms,
    }->{$ope} || die 'esjis: system error (e_s)';

    # split regexp
    my @char = $string =~ m{\G(
        \\  [0-7]{1,3}         |
        \\x [0-9A-Fa-f]{2}     |
        \\x \{ [0-9A-Fa-f]+ \} |
        \\c [\x40-\x5F]        |
        \\  (?:[\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC]) |
        [\$\@] $qq_variable |
        \[\^ |
            (?:[\\\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\\\x81-\x9F\xE0-\xFC])
    )}oxmsg;

    # unescape character
    my $left_e  = 0;
    my $right_e = 0;
    for (my $i=0; $i <= $#char; $i++) {
        next if not defined $char[$i];

        # open character class [...]
        if ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die 'esjis: ' . join('',@char[$left..$#char]) . ' unmatched [] in regexp';
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice(@char, $left, $right-$left+1, &charlist_qr(@char[$left+1..$right-1], $option));

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die 'esjis: ' . join('',@char[$left..$#char]) . ' unmatched [] in regexp';
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice(@char, $left, $right-$left+1, &charlist_not_qr(@char[$left+1..$right-1], $option));

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = {
            '.'  => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC])',
            '\D' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC0-9])',
            '\W' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFCa-zA-Z_0-9])',
            '\S' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC\x20\t\n\r\f])',
            }->{$char[$i]}
        ) {
            $char[$i] = $char;
        }

        # unescape for join separated double octet
        #                              LF   CR   $    (    )    *    +    .    ?    [   \   ^   {   |
        elsif ($char[$i] =~ m/\A \\ (?:0?12|0?15|0?44|0?50|0?51|0?52|0?53|0?56|0?77|133|134|136|173|174) \z/oxms) {
        }
        elsif ($char[$i] =~ m/\A \\ (([0-7])[0-7]{0,2}) \z/oxms) {
            if (($2 eq '0') or ($1 >= 40)) {
                $char[$i] = chr(oct($1));
            }
            else {
                $char[$i] = '\\' . ($1 + 1);
            }
        }
        #                               LF  CR  $  (  )  *  +  .  ?  [  \  ^  {  |
        elsif ($char[$i] =~ m/\A \\x (?:0?A|0?D|24|28|29|2A|2B|2E|3F|5B|5C|5E|7B|7C) \z/oxmsi) {
        }
        elsif ($char[$i] =~ m/\A \\x ([0-9A-Fa-f]{2}) \z/oxms) {
            $char[$i] = chr(hex($1));
        }
        #                                     LF  CR  $  (  )  *  +  .  ?  [  \  ^  {  |
        elsif ($char[$i] =~ m/\A \\x \{ 0* (?:0?A|0?D|24|28|29|2A|2B|2E|3F|5B|5C|5E|7B|7C) \} \z/oxmsi) {
        }
        elsif ($char[$i] =~ m/\A \\x \{ ([0-9A-Fa-f]+) \} \z/oxms) {
            my $hex = (length($1) % 2) ? ('0' . $1) : $1;
            $char[$i] = quotemeta pack('H*',$hex);
        }
        #                                LF  CR
        elsif ($char[$i] =~ m/\A \\c (?: J | M ) \z/oxmsi) {
        }
        elsif ($char[$i] =~ m/\A \\c ([\x40-\x5F]) \z/oxms) {
            $char[$i] = chr(ord($1) & 0x1F);
        }

        # /i option
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            my $c = $1;
            if ($option =~ m/i/oxms) {
                $char[$i] = '[' . uc($c) . lc($c) . ']';
            }
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\\L') {
            $char[$i] = '@{[Sjis::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\U') {
            $char[$i] = '@{[Sjis::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }

        # $scalar or @array
        elsif ($char[$i] =~ m/\A [\$\@].+ /oxms) {
            if ($option =~ m/i/oxms) {
                $char[$i] = '@{[Sjis::ignorecase(' . &e_string($char[$i]) . ')]}';
            }
            else {
                $char[$i] = &e_string($char[$i]);
            }
        }
    }

    # characterize
    for (my $i=0; $i <= $#char; $i++) {
        next if not defined $char[$i];

        # join separated double octet
        if ($char[$i] =~ m/\A [\x81-\x9F\xE0-\xFC] \z/oxms) {
            if ($i < $#char) {
                $char[$i] .= $char[$i+1];
                splice(@char,$i+1,1);
            }
        }

        # escape second octet of double octet
        if ($char[$i] =~ m/\A \\? ([\x81-\x9F\xE0-\xFC]) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1.'\\'.$2;
        }

        # unescape double octet
        elsif ($char[$i] =~ m/\A \\ ([\x81-\x9F\xE0-\xFC][\x00-\xFF]) \z/oxms) {
            $char[$i] = $1;
        }

        # quote double octet character before ? + * {
        elsif (
            ($i >= 1) and
            ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms) and
            ($char[$i-1] =~ m/\A [\x81-\x9F\xE0-\xFC] (?: \\?[\x00-\xFF] | \\[0-7]{2,3} | \\x[0-9A-Fa-f]{1,2} ) \z/oxms)
        ) {
            $char[$i-1] = '(?:' . $char[$i-1] . ')';
        }
    }

    # make regexp string
    my $re;
    if ($left_e > $right_e) {
        $re = join '', $ope, $delimiter, qq{\\G((?:$sjis_char)*?)}, @char, '>]}' x ($left_e - $right_e), $end_delimiter;
    }
    else {
        $re = join '', $ope, $delimiter, qq{\\G((?:$sjis_char)*?)}, @char, $end_delimiter;
    }
    return $re;
}

#
# escape regexp (s'here'{})
#
sub e_s_q($$$$$) {
    my($ope,$delimiter,$end_delimiter,$string,$option) = @_;
    $option ||= '';

    $slash = 'div';

    # split regexp
    my @char = $string =~ m{\G(
        \\  [0-7]{1,3} |
        \[\^ |
            (?:[\\\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\\\x81-\x9F\xE0-\xFC])
    )}oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        next if not defined $char[$i];

        # open character class [...]
        if ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die 'esjis: ' . join('',@char[$left..$#char]) . ' unmatched [] in regexp';
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice(@char, $left, $right-$left+1, &charlist_qr(@char[$left+1..$right-1], $option));

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die 'esjis: ' . join('',@char[$left..$#char]) . ' unmatched [] in regexp';
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice(@char, $left, $right-$left+1, &charlist_not_qr(@char[$left+1..$right-1], $option));

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = {
            '.'  => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC])',
            '\D' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC0-9])',
            '\W' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFCa-zA-Z_0-9])',
            '\S' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC\x20\t\n\r\f])',
            }->{$char[$i]}
        ) {
            $char[$i] = $char;
        }

        # unescape for join separated double octet
        elsif ($char[$i] =~ m/\A \\ (([0-7])[0-7]{0,2}) \z/oxms) {
            if (($2 eq '0') or ($1 >= 40)) {
            }
            else {
                $char[$i] = '\\' . ($1 + 1);
            }
        }

        # /i option
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            my $c = $1;
            if ($option =~ m/i/oxms) {
                $char[$i] = '[' . uc($c) . lc($c) . ']';
            }
        }
    }

    # characterize
    for (my $i=0; $i <= $#char; $i++) {
        next if not defined $char[$i];

        # join separated double octet
        if ($char[$i] =~ m/\A [\x81-\x9F\xE0-\xFC] \z/oxms) {
            if ($i < $#char) {
                $char[$i] .= $char[$i+1];
                splice(@char,$i+1,1);
            }
        }

        # escape second octet of double octet
        if (($i <= $#char-1) and
            ($char[$i] =~ m/\A ([\x81-\x9F\xE0-\xFC]) \\ \z/oxms) and
            (($char[$i+1] eq '\\') or ($char[$i+1] eq $end_delimiter))
        ) {
            $char[$i] .= '\\';
        }

        # quote double octet character before ? + * {
        elsif (
            ($i >= 1) and
            ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms) and
            ($char[$i-1] =~ m/\A [\x81-\x9F\xE0-\xFC] (?: \\?[\x00-\xFF] | \\[0-7]{2,3} | \\x[0-9A-Fa-f]{1,2} ) \z/oxms)
        ) {
            $char[$i-1] = '(?:' . $char[$i-1] . ')';
        }
    }
    return join '', $ope, $delimiter, qq{\\G((?:$sjis_char)*?)}, @char, $end_delimiter;
}

#
# escape string (s//here/)
#
sub e_s_qq($$$$$) {
    my($ope,$delimiter,$end_delimiter,$string,$option) = @_;
    $option ||= '';

    $slash = 'div';

    my $metachar = {
        's' => qr/[\@\\]/oxms,
    }->{$ope} || die 'esjis: system error (e_s_qq)';

    # escape character
    my $left_e  = 0;
    my $right_e = 0;
    my @char = $string =~ m/ \G (\$\d+|[\\\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC]) /oxmsg;
    for (my $i=0; $i <= $#char; $i++) {

        # rewrite $1,$2,$3 ... --> $2,$3,$4 ...
        if ($char[$i] =~ m/\A (\$) ((\d)\d*) \z/oxms) {
            if (($3 eq '0') or ($2 >= 40)) {
            }
            else {
                $char[$i] = $1 . ($2 + 1);
            }
        }

        # escape character
        elsif ($char[$i] =~ m/\A ([\x81-\x9F\xE0-\xFC]) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1.'\\'.$2;
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\\L') {
            $char[$i] = '@{[Sjis::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\U') {
            $char[$i] = '@{[Sjis::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
    }

    # return string
    $option =~ tr/i//d;
    if ($left_e > $right_e) {
        return join '', $delimiter, @char, '>]}' x ($left_e - $right_e), $end_delimiter, $option;
    }
    else {
        return join '', $delimiter, @char, $end_delimiter,                               $option;
    }
}

#
# escape q string (s{}'here')
#
sub e_s_q2($$$$$) {
    my($ope,$delimiter,$end_delimiter,$string,$option) = @_;
    $option ||= '';

    $slash = 'div';

    my @char = $string =~ m/ \G ([\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC]) /oxmsg;
    for (my $i=0; $i <= $#char-1; $i++) {
        if (($char[$i] =~ m/\A ([\x81-\x9F\xE0-\xFC]) \\ \z/oxms) and
            (($char[$i+1] eq '\\') or ($char[$i+1] eq $end_delimiter))
        ) {
            $char[$i] .= '\\';
        }
    }

    $option =~ tr/i//d;
    return join '', $ope, $delimiter, @char, $end_delimiter, $option;
}

#
# escape regexp (qr//)
#
sub e_qr($$$$$) {
    my($ope,$delimiter,$end_delimiter,$string,$option) = @_;
    $option ||= '';

    $slash = 'div';

    my $metachar = {
        'qr' => qr/[\@\\|[\]{]/oxms,
    }->{$ope} || die 'esjis: system error (e_qr)';

    # split regexp
    my @char = $string =~ m{\G(
        \\  [0-7]{2,3}         |
        \\x [0-9A-Fa-f]{2}     |
        \\x \{ [0-9A-Fa-f]+ \} |
        \\c [\x40-\x5F]        |
        \\  (?:[\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC]) |
        [\$\@] $qq_variable |
        \[\^ |
            (?:[\\\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\\\x81-\x9F\xE0-\xFC])
    )}oxmsg;

    # unescape character
    my $left_e  = 0;
    my $right_e = 0;
    for (my $i=0; $i <= $#char; $i++) {
        next if not defined $char[$i];

        # open character class [...]
        if ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die 'esjis: ' . join('',@char[$left..$#char]) . ' unmatched [] in regexp';
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice(@char, $left, $right-$left+1, &charlist_qr(@char[$left+1..$right-1], $option));

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die 'esjis: ' . join('',@char[$left..$#char]) . ' unmatched [] in regexp';
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice(@char, $left, $right-$left+1, &charlist_not_qr(@char[$left+1..$right-1], $option));

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = {
            '.'  => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC])',
            '\D' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC0-9])',
            '\W' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFCa-zA-Z_0-9])',
            '\S' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC\x20\t\n\r\f])',
            }->{$char[$i]}
        ) {
            $char[$i] = $char;
        }

        # unescape for join separated double octet
        #                              LF   CR   $    (    )    *    +    .    ?    [   \   ^   {   |
        elsif ($char[$i] =~ m/\A \\ (?:0?12|0?15|0?44|0?50|0?51|0?52|0?53|0?56|0?77|133|134|136|173|174) \z/oxms) {
        }
        elsif ($char[$i] =~ m/\A \\ ([0-7]{2,3}) \z/oxms) {
            $char[$i] = chr(oct($1));
        }
        #                               LF  CR  $  (  )  *  +  .  ?  [  \  ^  {  |
        elsif ($char[$i] =~ m/\A \\x (?:0?A|0?D|24|28|29|2A|2B|2E|3F|5B|5C|5E|7B|7C) \z/oxmsi) {
        }
        elsif ($char[$i] =~ m/\A \\x ([0-9A-Fa-f]{2}) \z/oxms) {
            $char[$i] = chr(hex($1));
        }
        #                                     LF  CR  $  (  )  *  +  .  ?  [  \  ^  {  |
        elsif ($char[$i] =~ m/\A \\x \{ 0* (?:0?A|0?D|24|28|29|2A|2B|2E|3F|5B|5C|5E|7B|7C) \} \z/oxmsi) {
        }
        elsif ($char[$i] =~ m/\A \\x \{ ([0-9A-Fa-f]+) \} \z/oxms) {
            my $hex = (length($1) % 2) ? ('0' . $1) : $1;
            $char[$i] = quotemeta pack('H*',$hex);
        }
        #                                LF  CR
        elsif ($char[$i] =~ m/\A \\c (?: J | M ) \z/oxmsi) {
        }
        elsif ($char[$i] =~ m/\A \\c ([\x40-\x5F]) \z/oxms) {
            $char[$i] = chr(ord($1) & 0x1F);
        }

        # /i option
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            my $c = $1;
            if ($option =~ m/i/oxms) {
                $char[$i] = '[' . uc($c) . lc($c) . ']';
            }
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\\L') {
            $char[$i] = '@{[Sjis::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\U') {
            $char[$i] = '@{[Sjis::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }

        # $scalar or @array
        elsif ($char[$i] =~ m/\A [\$\@].+ /oxms) {
            if ($option =~ m/i/oxms) {
                $char[$i] = '@{[Sjis::ignorecase(' . &e_string($char[$i]) . ')]}';
            }
            else {
                $char[$i] = &e_string($char[$i]);
            }
        }
    }

    # characterize
    for (my $i=0; $i <= $#char; $i++) {
        next if not defined $char[$i];

        # join separated double octet
        if ($char[$i] =~ m/\A [\x81-\x9F\xE0-\xFC] \z/oxms) {
            if ($i < $#char) {
                $char[$i] .= $char[$i+1];
                splice(@char,$i+1,1);
            }
        }

        # escape second octet of double octet
        if ($char[$i] =~ m/\A \\? ([\x81-\x9F\xE0-\xFC]) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1.'\\'.$2;
        }

        # unescape double octet
        elsif ($char[$i] =~ m/\A \\ ([\x81-\x9F\xE0-\xFC][\x00-\xFF]) \z/oxms) {
            $char[$i] = $1;
        }

        # quote double octet character before ? + * {
        elsif (
            ($i >= 1) and
            ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms) and
            ($char[$i-1] =~ m/\A [\x81-\x9F\xE0-\xFC] (?: \\?[\x00-\xFF] | \\[0-7]{2,3} | \\x[0-9A-Fa-f]{1,2} ) \z/oxms)
        ) {
            $char[$i-1] = '(?:' . $char[$i-1] . ')';
        }
    }

    # make regexp string
    my $re;
    $option =~ tr/i//d;
    if ($left_e > $right_e) {
        $re = join '', $ope, $delimiter, $sjis_gap, @char, '>]}' x ($left_e - $right_e), $end_delimiter, $option;
    }
    else {
        $re = join '', $ope, $delimiter, $sjis_gap, @char,                               $end_delimiter, $option;
    }
    return $re;
}

#
# escape regexp (qr'')
#
sub e_qr_q($$$$$) {
    my($ope,$delimiter,$end_delimiter,$string,$option) = @_;
    $option ||= '';

    $slash = 'div';

    # split regexp
    my @char = $string =~ m{\G(
        \[\^ |
            (?:[\\\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\\\x81-\x9F\xE0-\xFC])
    )}oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        next if not defined $char[$i];

        # open character class [...]
        if ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die 'esjis: ' . join('',@char[$left..$#char]) . ' unmatched [] in regexp';
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice(@char, $left, $right-$left+1, &charlist_qr(@char[$left+1..$right-1], $option));

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die 'esjis: ' . join('',@char[$left..$#char]) . ' unmatched [] in regexp';
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice(@char, $left, $right-$left+1, &charlist_not_qr(@char[$left+1..$right-1], $option));

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = {
            '.'  => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC])',
            '\D' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC0-9])',
            '\W' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFCa-zA-Z_0-9])',
            '\S' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC\x20\t\n\r\f])',
            }->{$char[$i]}
        ) {
            $char[$i] = $char;
        }

        # /i option
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            my $c = $1;
            if ($option =~ m/i/oxms) {
                $char[$i] = '[' . uc($c) . lc($c) . ']';
            }
        }
    }

    # characterize
    for (my $i=0; $i <= $#char; $i++) {
        next if not defined $char[$i];

        # escape second octet of double octet
        if (($i <= $#char-1) and
            ($char[$i] =~ m/\A ([\x81-\x9F\xE0-\xFC]) \\ \z/oxms) and
            (($char[$i+1] eq '\\') or ($char[$i+1] eq $end_delimiter))
        ) {
            $char[$i] .= '\\';
        }

        # quote double octet character before ? + * {
        elsif (
            ($i >= 1) and
            ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms) and
            ($char[$i-1] =~ m/\A [\x81-\x9F\xE0-\xFC] (?: \\?[\x00-\xFF] ) \z/oxms)
        ) {
            $char[$i-1] = '(?:' . $char[$i-1] . ')';
        }
    }

    $option =~ tr/i//d;
    return join '', $ope, $delimiter, $sjis_gap, @char, $end_delimiter, $option;
}

#
# ShiftJIS open character list for qr
#
sub charlist_qr(@) {
    my $option = pop @_;
    my @char = @_;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        next if not defined $char[$i];

        # escape - to ...
        if ($char[$i] eq '-') {
            if ((0 < $i) and ($i < $#char)) {
                $char[$i] = '...';
            }
        }
        elsif ($char[$i] =~ m/\A \\ ([0-7]{2,3}) \z/oxms) {
            $char[$i] = chr(oct($1));
        }
        elsif ($char[$i] =~ m/\A \\x ([0-9A-Fa-f]{2}) \z/oxms) {
            $char[$i] = chr(hex($1));
        }
        elsif ($char[$i] =~ m/\A \\x \{ ([0-9A-Fa-f]{1,2}) \} \z/oxms) {
            $char[$i] = pack('H2',$1);
        }
        elsif ($char[$i] =~ m/\A \\x \{ ([0-9A-Fa-f]{3,4}) \} \z/oxms) {
            $char[$i] = pack('H4',$1);
        }
        elsif ($char[$i] =~ m/\A \\c ([\x40-\x5F]) \z/oxms) {
            $char[$i] = chr(ord($1) & 0x1F);
        }
        elsif ($char[$i] =~ m/\A (\\ [0nrtfbaedDwWsS]) \z/oxms) {
            $char[$i] = {
                '\0' => "\0",
                '\n' => "\n",
                '\r' => "\r",
                '\t' => "\t",
                '\f' => "\f",
                '\b' => "\x08", # \b means backspace in character class
                '\a' => "\a",
                '\e' => "\e",
                '\d' => '\d',
                '\w' => '\w',
                '\s' => '\s',
                '\D' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC0-9])',
                '\W' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFCa-zA-Z_0-9])',
                '\S' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC\x20\t\n\r\f])',
            }->{$1};
        }
        elsif ($char[$i] =~ m/\A \\ ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC]) \z/oxms) {
            $char[$i] = $1;
        }
    }

    # open character list
    my @singleoctet = ();
    my @charlist    = ();
    if ((scalar(@char) == 1) or ((scalar(@char) >= 2) and ($char[1] ne '...'))) {
        if ($char[0] =~ m/\A [\x00-\xFF] \z/oxms) {
            push @singleoctet, $char[0];
        }
        else {
            push @charlist, $char[0];
        }
    }
    for (my $i=1; $i <= $#char-1; ) {
        next if not defined $char[$i];

        # escaped -
        if ($char[$i] eq '...') {

            # range of single octet code
            if (
                ($char[$i-1] =~ m/\A [\x00-\xFF] \z/oxms) and
                ($char[$i+1] =~ m/\A [\x00-\xFF] \z/oxms)
            ) {
                my $begin = unpack('C',$char[$i-1]);
                my $end   = unpack('C',$char[$i+1]);
                if ($begin > $end) {
                    die 'esjis: /[\\x'.unpack('H*',$char[$i-1]).'-\\x'.unpack('H*',$char[$i+1]).']/: invalid [] range in regexp';
                }
                else {
                    if ($option =~ m/i/oxms) {
                        my %range = ();
                        for my $c ($begin .. $end) {
                            $range{ord uc chr $c} = 1;
                            $range{ord lc chr $c} = 1;
                        }

                        my @lt = grep {$_ < $begin} sort {$a <=> $b} keys %range;
                        if (scalar(@lt) == 1) {
                            push @singleoctet, sprintf(q{\\x%02X},         $lt[0]);
                        }
                        elsif (scalar(@lt) >= 2) {
                            push @singleoctet, sprintf(q{\\x%02X-\\x%02X}, $lt[0], $lt[-1]);
                        }

                        push @singleoctet, sprintf(q{\\x%02X-\\x%02X},     $begin, $end);

                        my @gt = grep {$_ > $end  } sort {$a <=> $b} keys %range;
                        if (scalar(@gt) == 1) {
                            push @singleoctet, sprintf(q{\\x%02X},         $gt[0]);
                        }
                        elsif (scalar(@gt) >= 2) {
                            push @singleoctet, sprintf(q{\\x%02X-\\x%02X}, $gt[0], $gt[-1]);
                        }
                    }
                    else {
                        push @singleoctet, sprintf(q{\\x%02X-\\x%02X},     $begin, $end);
                    }
                }
            }

            # range of double octet code
            elsif (
                ($char[$i-1] =~ m/\A [\x81-\x9F\xE0-\xFC] [\x00-\xFF] \z/oxms) and
                ($char[$i+1] =~ m/\A [\x81-\x9F\xE0-\xFC] [\x00-\xFF] \z/oxms)
            ) {
                my($begin1,$begin2) = unpack('CC',$char[$i-1]);
                my($end1,  $end2)   = unpack('CC',$char[$i+1]);
                my $begin = $begin1 * 0x100 + $begin2;
                my $end   = $end1   * 0x100 + $end2;
                if ($begin > $end) {
                    die 'esjis: /[\\x'.unpack('H*',$char[$i-1]).'-\\x'.unpack('H*',$char[$i+1]).']/: invalid [] range in regexp';
                }
                elsif ($begin1 == $end1) {
                    push @charlist, sprintf(q{\\x%02X[\\x%02X-\\x%02X]}, $begin1, $begin2, $end2);
                }
                elsif (($begin1 + 1) == $end1) {
                    push @charlist, sprintf(q{\\x%02X[\\x%02X-\\xFF]},   $begin1, $begin2);
                    push @charlist, sprintf(q{\\x%02X[\\x00-\\x%02X]},   $end1,   $end2);
                }
                else {
                    my @middle = ();
                    for my $c ($begin1+1 .. $end1-1) {
                        if ((0x81 <= $c and $c <= 0x9F) or (0xE0 <= $c and $c <= 0xFC)) {
                            push @middle, $c;
                        }
                    }
                    if (scalar(@middle) == 0) {
                        push @charlist, sprintf(q{\\x%02X[\\x%02X-\\xFF]},         $begin1,    $begin2);
                        push @charlist, sprintf(q{\\x%02X[\\x00-\\x%02X]},         $end1,      $end2);
                    }
                    elsif (scalar(@middle) == 1) {
                        push @charlist, sprintf(q{\\x%02X[\\x%02X-\\xFF]},         $begin1,    $begin2);
                        push @charlist, sprintf(q{\\x%02X[\\x00-\\xFF]},           $middle[0]);
                        push @charlist, sprintf(q{\\x%02X[\\x00-\\x%02X]},         $end1,      $end2);
                    }
                    else {
                        push @charlist, sprintf(q{\\x%02X[\\x%02X-\\xFF]},         $begin1,    $begin2);
                        push @charlist, sprintf(q{[\\x%02X-\\x%02X][\\x00-\\xFF]}, $middle[0], $middle[-1]);
                        push @charlist, sprintf(q{\\x%02X[\\x00-\\x%02X]},         $end1,      $end2);
                    }
                }
            }

            # range error
            else {
                die 'esjis: /[\\x'.unpack('H*',$char[$i-1]).'-\\x'.unpack('H*',$char[$i+1]).']/: invalid [] range in regexp';
            }

            $i += 2;
        }

        # /i option
        elsif (($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) and (($i+1 > $#char) or ($char[$i+1] ne '...'))) {
            my $c = $1;
            if ($option =~ m/i/oxms) {
                push @singleoctet, uc($c), lc($c);
            }
            else {
                push @singleoctet, $c;
            }
            $i += 1;
        }

        # single character
        elsif ($char[$i] =~ m/\A (?: [\x00-\xFF] | \\d | \\w | \\s )  \z/oxms) {
            push @singleoctet, $char[$i];
            $i += 1;
        }
        else {
            push @charlist, $char[$i];
            $i += 1;
        }
    }
    if ((scalar(@char) >= 2) and ($char[-2] ne '...')) {
        if ($char[-1] =~ m/\A [\x00-\xFF] \z/oxms) {
            push @singleoctet, $char[-1];
        }
        else {
            push @charlist, $char[-1];
        }
    }

    # quote metachar
    for (@singleoctet) {
        if (m/\A \n \z/oxms) {
            $_ = '\\n';
        }
        elsif (m/\A \r \z/oxms) {
            $_ = '\\r';
        }
        elsif (m/\A ([\x00-\x21\x7F-\xA0\xE0-\xFF]) \z/oxms) {
            $_ = sprintf(q{\\x%02X}, ord $1);
        }
        elsif (m/\A ([\x00-\xFF]) \z/oxms) {
            $_ = quotemeta $1;
        }
    }
    for (@charlist) {
        if (m/\A ([\x81-\x9F\xE0-\xFC]) ([\x00-\xFF]) \z/oxms) {
            $_ = $1 . quotemeta $2;
        }
    }

    # return character list
    if (scalar(@singleoctet) == 0) {
    }
    elsif ((scalar(@singleoctet) == 1) and ($singleoctet[0] !~ m/\A .-. \z/oxms)) {
        push @charlist, $singleoctet[0];
    }
    else {
        push @charlist, '[' . join('',@singleoctet) . ']';
    }
    if(scalar(@charlist) >= 2) {
        return '(?:' . join('|', @charlist) . ')';
    }
    else {
        return @charlist;
    }
}

#
# ShiftJIS open character list for not qr
#
sub charlist_not_qr(@) {
    my $option = pop @_;
    my @char = @_;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        next if not defined $char[$i];

        # escape - to ...
        if ($char[$i] eq '-') {
            if ((0 < $i) and ($i < $#char)) {
                $char[$i] = '...';
            }
        }
        elsif ($char[$i] =~ m/\A \\ ([0-7]{2,3}) \z/oxms) {
            $char[$i] = chr(oct($1));
        }
        elsif ($char[$i] =~ m/\A \\x ([0-9A-Fa-f]{2}) \z/oxms) {
            $char[$i] = chr(hex($1));
        }
        elsif ($char[$i] =~ m/\A \\x \{ ([0-9A-Fa-f]{1,2}) \} \z/oxms) {
            $char[$i] = pack('H2',$1);
        }
        elsif ($char[$i] =~ m/\A \\x \{ ([0-9A-Fa-f]{3,4}) \} \z/oxms) {
            $char[$i] = pack('H4',$1);
        }
        elsif ($char[$i] =~ m/\A \\c ([\x40-\x5F]) \z/oxms) {
            $char[$i] = chr(ord($1) & 0x1F);
        }
        elsif ($char[$i] =~ m/\A (\\ [0nrtfbaedDwWsS]) \z/oxms) {
            $char[$i] = {
                '\0' => "\0",
                '\n' => "\n",
                '\r' => "\r",
                '\t' => "\t",
                '\f' => "\f",
                '\b' => "\x08", # \b means backspace in character class
                '\a' => "\a",
                '\e' => "\e",
                '\d' => '\d',
                '\w' => '\w',
                '\s' => '\s',
                '\D' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC0-9])',
                '\W' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFCa-zA-Z_0-9])',
                '\S' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC\x20\t\n\r\f])',
            }->{$1};
        }
        elsif ($char[$i] =~ m/\A \\ ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC]) \z/oxms) {
            $char[$i] = $1;
        }
    }

    # open character list
    my @singleoctet = ();
    my @charlist    = ();
    if ((scalar(@char) == 1) or ((scalar(@char) >= 2) and ($char[1] ne '...'))) {
        if ($char[0] =~ m/\A [\x00-\xFF] \z/oxms) {
            push @singleoctet, $char[0];
        }
        else {
            push @charlist, $char[0];
        }
    }
    for (my $i=1; $i <= $#char-1; ) {
        next if not defined $char[$i];

        # escaped -
        if ($char[$i] eq '...') {

            # range of single octet code
            if (
                ($char[$i-1] =~ m/\A [\x00-\xFF] \z/oxms) and
                ($char[$i+1] =~ m/\A [\x00-\xFF] \z/oxms)
            ) {
                my $begin = unpack('C',$char[$i-1]);
                my $end   = unpack('C',$char[$i+1]);
                if ($begin > $end) {
                    die 'esjis: /[\\x'.unpack('H*',$char[$i-1]).'-\\x'.unpack('H*',$char[$i+1]).']/: invalid [] range in regexp';
                }
                else {
                    if ($option =~ m/i/oxms) {
                        my %range = ();
                        for my $c ($begin .. $end) {
                            $range{ord uc chr $c} = 1;
                            $range{ord lc chr $c} = 1;
                        }

                        my @lt = grep {$_ < $begin} sort {$a <=> $b} keys %range;
                        if (scalar(@lt) == 1) {
                            push @singleoctet, sprintf(q{\\x%02X},         $lt[0]);
                        }
                        elsif (scalar(@lt) >= 2) {
                            push @singleoctet, sprintf(q{\\x%02X-\\x%02X}, $lt[0], $lt[-1]);
                        }

                        push @singleoctet, sprintf(q{\\x%02X-\\x%02X},     $begin, $end);

                        my @gt = grep {$_ > $end  } sort {$a <=> $b} keys %range;
                        if (scalar(@gt) == 1) {
                            push @singleoctet, sprintf(q{\\x%02X},         $gt[0]);
                        }
                        elsif (scalar(@gt) >= 2) {
                            push @singleoctet, sprintf(q{\\x%02X-\\x%02X}, $gt[0], $gt[-1]);
                        }
                    }
                    else {
                        push @singleoctet, sprintf(q{[\\x%02X-\\x%02X]},   $begin, $end);
                    }
                }
            }

            # range of double octet code
            elsif (
                ($char[$i-1] =~ m/\A [\x81-\x9F\xE0-\xFC] [\x00-\xFF] \z/oxms) and
                ($char[$i+1] =~ m/\A [\x81-\x9F\xE0-\xFC] [\x00-\xFF] \z/oxms)
            ) {
                my($begin1,$begin2) = unpack('CC',$char[$i-1]);
                my($end1,  $end2)   = unpack('CC',$char[$i+1]);
                my $begin = $begin1 * 0x100 + $begin2;
                my $end   = $end1   * 0x100 + $end2;
                if ($begin > $end) {
                    die 'esjis: /[\\x'.unpack('H*',$char[$i-1]).'-\\x'.unpack('H*',$char[$i+1]).']/: invalid [] range in regexp';
                }
                elsif ($begin1 == $end1) {
                    push @charlist, sprintf(q{\\x%02X[\\x%02X-\\x%02X]}, $begin1, $begin2, $end2);
                }
                elsif (($begin1 + 1) == $end1) {
                    push @charlist, sprintf(q{\\x%02X[\\x%02X-\\xFF]},   $begin1, $begin2);
                    push @charlist, sprintf(q{\\x%02X[\\x00-\\x%02X]},   $end1,   $end2);
                }
                else {
                    my @middle = ();
                    for my $c ($begin1+1 .. $end1-1) {
                        if ((0x81 <= $c and $c <= 0x9F) or (0xE0 <= $c and $c <= 0xFC)) {
                            push @middle, $c;
                        }
                    }
                    if (scalar(@middle) == 0) {
                        push @charlist, sprintf(q{\\x%02X[\\x%02X-\\xFF]},         $begin1,    $begin2);
                        push @charlist, sprintf(q{\\x%02X[\\x00-\\x%02X]},         $end1,      $end2);
                    }
                    elsif (scalar(@middle) == 1) {
                        push @charlist, sprintf(q{\\x%02X[\\x%02X-\\xFF]},         $begin1,    $begin2);
                        push @charlist, sprintf(q{\\x%02X[\\x00-\\xFF]},           $middle[0]);
                        push @charlist, sprintf(q{\\x%02X[\\x00-\\x%02X]},         $end1,      $end2);
                    }
                    else {
                        push @charlist, sprintf(q{\\x%02X[\\x%02X-\\xFF]},         $begin1,    $begin2);
                        push @charlist, sprintf(q{[\\x%02X-\\x%02X][\\x00-\\xFF]}, $middle[0], $middle[-1]);
                        push @charlist, sprintf(q{\\x%02X[\\x00-\\x%02X]},         $end1,      $end2);
                    }
                }
            }

            # range error
            else {
                die 'esjis: /[\\x'.unpack('H*',$char[$i-1]).'-\\x'.unpack('H*',$char[$i+1]).']/: invalid [] range in regexp';
            }

            $i += 2;
        }

        # /i option
        elsif (($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) and (($i+1 > $#char) or ($char[$i+1] ne '...'))) {
            my $c = $1;
            if ($option =~ m/i/oxms) {
                push @singleoctet, uc($c), lc($c);
            }
            else {
                push @singleoctet, $c;
            }
            $i += 1;
        }

        # single character
        elsif ($char[$i] =~ m/\A (?: [\x00-\xFF] | \\d | \\w | \\s )  \z/oxms) {
            push @singleoctet, $char[$i];
            $i += 1;
        }
        else {
            push @charlist, $char[$i];
            $i += 1;
        }
    }
    if ((scalar(@char) >= 2) and ($char[-2] ne '...')) {
        if ($char[-1] =~ m/\A [\x00-\xFF] \z/oxms) {
            push @singleoctet, $char[-1];
        }
        else {
            push @charlist, $char[-1];
        }
    }

    # quote metachar
    for (@singleoctet) {
        if (m/\A \n \z/oxms) {
            $_ = '\\n';
        }
        elsif (m/\A \r \z/oxms) {
            $_ = '\\r';
        }
        elsif (m/\A ([\x00-\x21\x7F-\xA0\xE0-\xFF]) \z/oxms) {
            $_ = sprintf(q{\\x%02X}, ord $1);
        }
        elsif (m/\A ([\x00-\xFF]) \z/oxms) {
            $_ = quotemeta $_;
        }
    }
    for (@charlist) {
        if (m/\A ([\x81-\x9F\xE0-\xFC]) ([\x00-\xFF]) \z/oxms) {
            $_ = $1 . quotemeta $2;
        }
    }

    # return character list
    if(scalar(@charlist) >= 1) {
        return '(?!' . join('|', @charlist) . ')(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC'. join('', @singleoctet) . '])';
    }
    else {
        return                                 '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC'. join('', @singleoctet) . '])';
    }
}

#
# put package Sjis
#
sub package_Sjis() {

    return <<'END_OF_PACKAGE_SJIS';
;
package Sjis;

#
# ShiftJIS split
#
sub Sjis::split(;$$$) {

    if (@_ == 0) {
        return CORE::split;
    }
    elsif (@_ == 1) {
        if ($_[0] eq '') {
            if (wantarray) {
                return      m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [\x00-\xFF])/oxmsg;
            }
            else {
                warn 'Use of implicit split to @_ is deprecated' if $^W;
                return @_ = m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [\x00-\xFF])/oxmsg;
            }
        }
        else {
            return CORE::split $_[0];
        }
    }
    elsif (@_ == 2) {
        if ($_[0] eq '') {
            if (wantarray) {
                return      $_[1] =~ m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [\x00-\xFF])/oxmsg;
            }
            else {
                warn 'Use of implicit split to @_ is deprecated' if $^W;
                return @_ = $_[1] =~ m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [\x00-\xFF])/oxmsg;
            }
        }
        else {
            return CORE::split $_[0], $_[1];
        }
    }
    elsif (@_ == 3) {
        if ($_[0] eq '') {
            if ($_[2] == 0) {
                if (wantarray) {
                    return      $_[1] =~ m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [\x00-\xFF])/oxmsg;
                }
                else {
                    warn 'Use of implicit split to @_ is deprecated' if $^W;
                    return @_ = $_[1] =~ m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [\x00-\xFF])/oxmsg;
                }
            }
            elsif ($_[2] == 1) {
                return $_[1];
            }
            else {
                my @split = $_[1] =~ m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [\x00-\xFF])/oxmsg;
                if (scalar(@split) < $_[2]) {
                    if (wantarray) {
                        return      @split, '';
                    }
                    else {
                        warn 'Use of implicit split to @_ is deprecated' if $^W;
                        return @_ = @split, '';
                    }
                }
                elsif (scalar(@split) == $_[2]) {
                    if (wantarray) {
                        return      @split;
                    }
                    else {
                        warn 'Use of implicit split to @_ is deprecated' if $^W;
                        return @_ = @split;
                    }
                }
                else {
                    if (wantarray) {
                        return      @split[0..$_[2]-2], join '', @split[$_[2]-1..$#split];
                    }
                    else {
                        warn 'Use of implicit split to @_ is deprecated' if $^W;
                        return @_ = @split[0..$_[2]-2], join '', @split[$_[2]-1..$#split];
                    }
                }
            }
        }
        else {
            return CORE::split $_[0], $_[1], $_[2];
        }
    }
}

#
# ShiftJIS transliteration (tr///)
#
sub Sjis::tr($$$;$) {

    my @char            = $_[0] =~ m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC]) /oxmsg;
    my $searchlist      = $_[1];
    my $replacementlist = $_[2];
    my $opt             = $_[3] || '';

    my @searchlist = &_charlist_tr($searchlist =~ m{\G(
        \\     [0-7]{2,3}          |
        \\x    [0-9A-Fa-f]{2}      |
        \\x \{ [0-9A-Fa-f]{1,4} \} |
        \\c    [\x40-\x5F]         |
        \\  (?:[\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC]) |
            (?:[\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC])
    )}oxmsg);

    my @replacementlist = &_charlist_tr($replacementlist =~ m{\G(
        \\     [0-7]{2,3}          |
        \\x    [0-9A-Fa-f]{2}      |
        \\x \{ [0-9A-Fa-f]{1,4} \} |
        \\c    [\x40-\x5F]         |
        \\  (?:[\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC]) |
            (?:[\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC])
    )}oxmsg);

    my %tr = ();
    for (my $i=0; $i <= $#searchlist; $i++) {
        if (not exists $tr{$searchlist[$i]}) {
            if (defined $replacementlist[$i] and ($replacementlist[$i] ne '')) {
                $tr{$searchlist[$i]} = $replacementlist[$i];
            }
            elsif ($opt =~ m/d/oxms) {
                $tr{$searchlist[$i]} = '';
            }
            elsif (defined $replacementlist[-1] and ($replacementlist[-1] ne '')) {
                $tr{$searchlist[$i]} = $replacementlist[-1];
            }
            else {
                $tr{$searchlist[$i]} = $searchlist[$i];
            }
        }
    }

    my $tr = 0;
    $_[0] = '';
    if ($opt =~ m/c/oxms) {
        while (defined(my $char = shift @char)) {
            if (not exists $tr{$char}) {
                if (defined $replacementlist[0]) {
                    $_[0] .= $replacementlist[0];
                }
                $tr++;
                if ($opt =~ m/s/oxms) {
                    while (@char and (not exists $tr{$char[0]})) {
                        shift @char;
                        $tr++;
                    }
                }
            }
            else {
                $_[0] .= $char;
            }
        }
    }
    else {
        while (defined(my $char = shift @char)) {
            if (exists $tr{$char}) {
                $_[0] .= $tr{$char};
                $tr++;
                if ($opt =~ m/s/oxms) {
                    while (@char and (exists $tr{$char[0]}) and ($tr{$char[0]} eq $tr{$char})) {
                        shift @char;
                        $tr++;
                    }
                }
            }
            else {
                $_[0] .= $char;
            }
        }
    }
    return $tr;
}

#
# ShiftJIS chop
#
sub Sjis::chop(;@) {

    my $chop;
    if (@_ == 0) {
        my @char = m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC])/oxmsg;
        $chop = pop @char;
        $_ = join '', @char;
    }
    else {
        for my $string (@_) {
            my @char = $string =~ m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC]) /oxmsg;
            $chop = pop @char;
            $string = join '', @char;
        }
    }
    return $chop;
}

#
# ShiftJIS index
#
sub Sjis::index($$;$) {

    my($str,$substr,$position) = @_;
    $position ||= 0;
    my $pos = 0;

    while ($pos < length($str)) {
        if (substr($str,$pos,length($substr)) eq $substr) {
            if ($pos >= $position) {
                return $pos;
            }
        }
        if (substr($str,$pos,1) =~ m/\A [\x81-\x9F\xE0-\xFC] \z/oxms) {
            $pos += 2;
        }
        else {
            $pos += 1;
        }
    }
    return -1;
}

#
# ShiftJIS reverse index
#
sub Sjis::rindex($$;$) {

    my($str,$substr,$position) = @_;
    $position ||= length($str) - 1;
    my $pos = 0;
    my $rindex = -1;

    while (($pos < length($str)) and ($pos <= $position)) {
        if (substr($str,$pos,length($substr)) eq $substr) {
            $rindex = $pos;
        }
        if (substr($str,$pos,1) =~ m/\A [\x81-\x9F\xE0-\xFC] \z/oxms) {
            $pos += 2;
        }
        else {
            $pos += 1;
        }
    }
    return $rindex;
}

#
# ShiftJIS lower case (lc)
#
sub Sjis::lc(;@) {

    my %lc = ();
    @lc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
        qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);

    if (@_ == 0) {
        local $^W = 0;
        return join '', map {$lc{$_}||$_} m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC])/oxmsg;
    }
    elsif (@_ == 1) {
        local $^W = 0;
        return join '', map {$lc{$_}||$_} ($_[0] =~ m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC])/oxmsg);
    }
    else {
        local $^W = 0;
        return join('', map {$lc{$_}||$_} ($_[0] =~ m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC])/oxmsg)), @_[1..$#_];
    }
}

#
# ShiftJIS upper case (uc)
#
sub Sjis::uc(;@) {

    my %uc = ();
    @uc{qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)} =
        qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);

    if (@_ == 0) {
        local $^W = 0;
        return join '', map {$uc{$_}||$_} m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC]) /oxmsg;
    }
    elsif (@_ == 1) {
        local $^W = 0;
        return join '', map {$uc{$_}||$_} ($_[0] =~ m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC]) /oxmsg);
    }
    else {
        local $^W = 0;
        return join('', map {$uc{$_}||$_} ($_[0] =~ m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC]) /oxmsg)), @_[1..$#_];
    }
}

#
# ShiftJIS regexp ignore case option
#
sub Sjis::ignorecase(@) {

    my @string = @_;
    my $metachar = qr/[\@\\|[\]{]/oxms;

    # ignore case of $scalar or @array
    for my $string (@string) {

        # split regexp
        my @char = $string =~ m{\G(
            \[\^ |
                (?:[\\\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\\\x81-\x9F\xE0-\xFC])
        )}oxmsg;

        # unescape character
        for (my $i=0; $i <= $#char; $i++) {
            next if not defined $char[$i];

            # open character class [...]
            if ($char[$i] eq '[') {
                my $left = $i;
                while (1) {
                    if (++$i > $#char) {
                        die 'esjis: ' . join('',@char[$left..$#char]) . ' unmatched [] in regexp';
                    }
                    if ($char[$i] eq ']') {
                        my $right = $i;
                        my @charlist = &charlist_qr(@char[$left+1..$right-1], 'i');

                        # escape character
                        for my $char (@charlist) {

                            # do not use quotemeta here
                            if ($char =~ m/\A ([\x81-\x9F\xE0-\xFC]) ($metachar) \z/oxms) {
                               $char = $1.'\\'.$2;
                            }
                            elsif ($char =~ m/\A [.|)] \z/oxms) {
                                $char = '\\' . $char;
                            }
                        }

                        # [...]
                        splice(@char, $left, $right-$left+1,
                            '(?:' . join('|', @charlist) . ')'
                        );

                        $i = $left;
                        last;
                    }
                }
            }

            # open character class [^...]
            elsif ($char[$i] eq '[^') {
                my $left = $i;
                while (1) {
                    if (++$i > $#char) {
                        die 'esjis: ' . join('',@char[$left..$#char]) . ' unmatched [] in regexp';
                    }
                    if ($char[$i] eq ']') {
                        my $right = $i;
                        my @charlist = &charlist_not_qr(@char[$left+1..$right-1], 'i');

                        # escape character
                        for my $char (@charlist) {

                            # do not use quotemeta here
                            if ($char =~ m/\A ([\x81-\x9F\xE0-\xFC]) ($metachar) \z/oxms) {
                                $char = $1.'\\'.$2;
                            }
                            elsif ($char =~ m/\A [.|)] \z/oxms) {
                                $char = '\\' . $char;
                            }
                        }

                        # [^...]
                        splice(@char, $left, $right-$left+1,
                            '(?!' . join('|', @charlist) . ')(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC])'
                        );

                        $i = $left;
                        last;
                    }
                }
            }

            # rewrite character class or escape character
            elsif (my $char = {
                '.'  => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC])',
                '\D' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC0-9])',
                '\W' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFCa-zA-Z_0-9])',
                '\S' => '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[^\x81-\x9F\xE0-\xFC\x20\t\n\r\f])',
                }->{$char[$i]}
            ) {
                $char[$i] = $char;
            }

            # /i option
            elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
                my $c = $1;
                $char[$i] = '[' . CORE::uc($c) . CORE::lc($c) . ']';
            }
        }

        # characterize
        for (my $i=0; $i <= $#char; $i++) {
            next if not defined $char[$i];

            # join separated double octet
            if ($char[$i] =~ m/\A [\x81-\x9F\xE0-\xFC] \z/oxms) {
                if ($i < $#char) {
                    $char[$i] .= $char[$i+1];
                    splice(@char,$i+1,1);
                }
            }

            # escape second octet of double octet
            if ($char[$i] =~ m/\A ([\x81-\x9F\xE0-\xFC]) ($metachar) \z/oxms) {
                $char[$i] = $1.'\\'.$2;
            }

            # quote double octet character before ? + * {
            elsif (
                ($i >= 1) and
                ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms) and
                ($char[$i-1] =~ m/\A [\x81-\x9F\xE0-\xFC] (?: \\?[\x00-\xFF] ) \z/oxms)
            ) {
                $char[$i-1] = '(?:' . $char[$i-1] . ')';
            }
        }

        $string = join '', @char;
    }

    # make regexp string
    return @string;
}

#
# ShiftJIS order to character (chr)
#
sub Sjis::chr(;@) {

    if (@_ == 0) {
        if ($_ > 0xFF) {
            return pack('CC', int($_ / 0x100), $_ % 0x100);
        }
        else {
            return CORE::chr($_);
        }
    }
    elsif (@_ == 1) {
        if ($_[0] > 0xFF) {
            return pack('CC', int($_[0] / 0x100), $_[0] % 0x100);
        }
        else {
            return CORE::chr($_[0]);
        }
    }
    else {
        if ($_[0] > 0xFF) {
            return pack('CC', int($_[0] / 0x100), $_[0] % 0x100), @_[1..$#_];
        }
        else {
            return CORE::chr($_[0]), @_[1..$#_];
        }
    }
}

#
# ShiftJIS character to order (ord)
#
sub Sjis::ord(;@) {

    if (@_ == 0) {
        if (m/\A [\x81-\x9F\xE0-\xFC] /oxms) {
            my($ord1,$ord2) = unpack('CC', $_);
            return $ord1 * 0x100 + $ord2;
        }
        else {
            return CORE::ord($_);
        }
    }
    elsif (@_ == 1) {
        if ($_[0] =~ m/\A [\x81-\x9F\xE0-\xFC] /oxms) {
            my($ord1,$ord2) = unpack('CC', $_[0]);
            return $ord1 * 0x100 + $ord2;
        }
        else {
            return CORE::ord($_[0]);
        }
    }
    else {
        if ($_[0] =~ m/\A [\x81-\x9F\xE0-\xFC] /oxms) {
            my($ord1,$ord2) = unpack('CC', $_[0]);
            return $ord1 * 0x100 + $ord2, @_[1..$#_];
        }
        else {
            return CORE::ord($_[0]), @_[1..$#_];
        }
    }
}

#
# ShiftJIS reverse
#
sub Sjis::reverse(@) {

    if (wantarray) {
        return CORE::reverse @_;
    }
    else {
        return join '', CORE::reverse(join('',@_) =~ m/\G ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC]) /oxmsg);
    }
}

#
# ShiftJIS open character list for tr
#
sub _charlist_tr(@) {

    my(@char) = @_;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {
        next if not defined $char[$i];

        # escape - to ...
        if ($char[$i] eq '-') {
            if ((0 < $i) and ($i < $#char)) {
                $char[$i] = '...';
            }
        }
        elsif ($char[$i] =~ m/\A \\ ([0-7]{2,3}) \z/oxms) {
            $char[$i] = CORE::chr(oct($1));
        }
        elsif ($char[$i] =~ m/\A \\x ([0-9A-Fa-f]{2}) \z/oxms) {
            $char[$i] = CORE::chr(hex($1));
        }
        elsif ($char[$i] =~ m/\A \\x \{ ([0-9A-Fa-f]{1,4}) \} \z/oxms) {
            $char[$i] = Sjis::chr(hex($1));
        }
        elsif ($char[$i] =~ m/\A \\c ([\x40-\x5F]) \z/oxms) {
            $char[$i] = CORE::chr(CORE::ord($1) & 0x1F);
        }
        elsif ($char[$i] =~ m/\A (\\ [0nrtfbae]) \z/oxms) {
            $char[$i] = {
                '\0' => "\0",
                '\n' => "\n",
                '\r' => "\r",
                '\t' => "\t",
                '\f' => "\f",
                '\b' => "\x08", # \b means backspace in character class
                '\a' => "\a",
                '\e' => "\e",
            }->{$1};
        }
        elsif ($char[$i] =~ m/\A \\ ([\x81-\x9F\xE0-\xFC][\x00-\xFF] | [^\x81-\x9F\xE0-\xFC]) \z/oxms) {
            $char[$i] = $1;
        }
    }

    # join separated double octet
    for (my $i=0; $i <= $#char-1; $i++) {
        if ($char[$i] =~ m/\A [\x81-\x9F\xE0-\xFC] \z/oxms) {
            $char[$i] .= $char[$i+1];
            splice(@char,$i+1,1);
        }
    }

    # open character list
    for (my $i=$#char-1; $i >= 1; ) {

        # escaped -
        if ($char[$i] eq '...') {
            my @range = ();

            # range of single octet code
            if (
                ($char[$i-1] =~ m/\A [\x00-\xFF] \z/oxms) and
                ($char[$i+1] =~ m/\A [\x00-\xFF] \z/oxms)
            ) {
                my $begin = unpack('C',$char[$i-1]);
                my $end   = unpack('C',$char[$i+1]);
                if ($begin <= $end) {
                    for my $c ($begin..$end) {
                        push(@range, pack('C',$c));
                    }
                }
                else {
                    die 'esjis: /[\\x'.unpack('H*',$char[$i-1]).'-\\x'.unpack('H*',$char[$i+1]).']/: invalid [] range in regexp';
                }
            }

            # range of double octet code
            elsif (
                ($char[$i-1] =~ m/\A [\x81-\x9F\xE0-\xFC] [\x00-\xFF] \z/oxms) and
                ($char[$i+1] =~ m/\A [\x81-\x9F\xE0-\xFC] [\x00-\xFF] \z/oxms)
            ) {
                my($begin1,$begin2) = unpack('CC',$char[$i-1]);
                my($end1,$end2)     = unpack('CC',$char[$i+1]);
                my $begin = $begin1 * 0x100 + $begin2;
                my $end   = $end1   * 0x100 + $end2;
                if ($begin <= $end) {
                    for my $cc ($begin..$end) {
                        my $char = pack('CC', int($cc / 0x100), $cc % 0x100);
                        if ($char =~ m/\A [\x81-\x9F\xE0-\xFC] [\x40-\x7E\x80-\xFC] \z/oxms) {
                            push(@range, $char);
                        }
                    }
                }
                else {
                    die 'esjis: /[\\x'.unpack('H*',$char[$i-1]).'-\\x'.unpack('H*',$char[$i+1]).']/: invalid [] range in regexp';
                }
            }

            # range error
            else {
                die 'esjis: /[\\x'.unpack('H*',$char[$i-1]).'-\\x'.unpack('H*',$char[$i+1]).']/: invalid [] range in regexp';
            }

            splice(@char, $i-1, 3, @range);
            $i -= 2;
        }
        else {
            $i -= 1;
        }
    }

    return @char;
}

END_OF_PACKAGE_SJIS

}

1;

__END__
=pod

=head1 NAME

Esjis - Source code filter to escape ShiftJIS

=head1 SYNOPSIS

  C:\>perl esjis.pl ShiftJIS_script.pl > Escaped_script.pl.e

  ShiftJIS_script.pl  --- script written in ShiftJIS
  Escaped_script.pl.e --- escaped script

=head1 ABSTRACT

Let's start with a bit of history: jperl 4.036+1.4 introduced ShiftJIS support.
You could apply chop() and regexps even to complex CJK characters -- so long as
the script was written in ShiftJIS.

Since Perl5.8, Encode module is supported for multilingual processing, and it was
said that jperl became unnecessary. But is it really so?

The UTF-8 is still rare on the Microsoft Windows -- most popular operating systems
we love, so many users hope to write scripts in ShiftJIS encodings; without giving
up a whole new feature of Perl5.8/5.10.

The ShiftJIS was developed in order to maintain backward compatibility. In general,
the operating systems and the programming language keep old interface. To maintain
backward compatibility is a effective solution still now.

Shall we escape from the encode problem?

=head1 DESCRIPTION

JPerl is very useful software.

Because it is Perl interpreter who can handle Japanese on the Microsoft Windows.
However, the last version of JPerl is 5.005_03 and is not maintained now.

So I made this software, I had thought that I wanted to solve the problem.

This software is a source code filter to escape Perl script encoded by ShiftJIS.
It outputs it to STDOUT escaping in the script given from STDIN or command line
parameter. The character code is never converted by escaping the script. Neither
the value of the character nor the length of the character string change even if
it escapes.

This approach is suitable for the following case.

=over 2

=item * To handle raw character string

=item * To handle real length of character string

=item * To don't handle flag and functions not related to programming

=item * Unnecessary internationalization programming

=item * To don't handle program written by C language

=back

This software is still an alpha version for expressing a concept.

=head1 SOFTWARE COMPOSITION

    jperl55.bat  --- jperl emulator by perl5.5 with esjis.pl
    jperl58.bat  --- jperl emulator by perl5.8 with esjis.pl
    perl58.bat   --- find and run perl5.8 without %PATH% settings
    jperl510.bat --- jperl emulator by perl5.10 with esjis.pl
    perl510.bat  --- find and run perl5.10 without %PATH% settings
    pl2ebat      --- escape and wrap ShiftJIS perl code into a batch file
    esjis.pl     --- source code filter to escape ShiftJIS

=head1 SOFTWARE COMBINATION

=over 2

=item * COMBINATION.1

    esjis.pl
    source code filter to escape ShiftJIS

=item * COMBINATION.2

    jperl55.bat + esjis.pl
    jperl emulator by perl5.5 with esjis.pl

=item * COMBINATION.3

    jperl58.bat + perl58.bat + esjis.pl
    jperl emulator by perl5.8 with esjis.pl without %PATH% settings

=item * COMBINATION.4

    jperl510.bat + perl510.bat + esjis.pl
    jperl emulator by perl5.10 with esjis.pl without %PATH% settings

=item * COMBINATION.5

    pl2ebat.bat + esjis.pl
    "pl2bat.bat" for ShiftJIS perl script

=back

=head1 JPerl COMPATIBLE FUNCTIONS

The following functions function as much as JPerl.

=over 2

=item * handle double octet string in single quote

=item * handle double octet regexp in single quote

=item * chop

=item * split

=item * substr

=item * index

=item * rindex

=item * lc

=item * uc

=back

=head1 JPerl UPPER COMPATIBLE FUNCTIONS

The following functions are enhanced more than JPerl.

=over 2

=item * handle double octet string in double quote

\x{XXXX} syntax can also be used.

=item * handle double octet regexp in double quote

\x{XXXX} syntax can also be used.

=item * tr/// or y///

\x{XXXX} syntax can also be used.

=item * chr

double octet code can also be treated.

=item * ord

double octet code can also be treated.

=item * reverse

double octet code can also be treated in scalar context.

=back

=head1 JPerl NOT COMPATIBLE FUNCTIONS

The following functions are not compatible with JPerl. It is the same as
original Perl. 

=over 2

=item * format

It is the same as the function of original Perl.

=item * -B

It is the same as the function of original Perl.

=item * -T

It is the same as the function of original Perl.

=back

=head1 BUGS AND LIMITATIONS

This software is still an alpha version for expressing a concept.
I write test code from now.

Please test code, patches and report problems to author are welcome.

=over 2

=item * LIMITATION.1

When two or more delimiters of here documents are in one line, if any one is
a double quote type(<<"END", <<END or <<`END`), then all here documents will
escape for double quote type.

    ex.1
        print <<'END';
        ============================================================
        Escaped for SINGLE quote document.   --- OK
        ============================================================
        END

    ex.2
        print <<\END;
        ============================================================
        Escaped for SINGLE quote document.   --- OK
        ============================================================
        END

    ex.3
        print <<"END";
        ============================================================
        Escaped for DOUBLE quote document.   --- OK
        ============================================================
        END

    ex.4
        print <<END;
        ============================================================
        Escaped for DOUBLE quote document.   --- OK
        ============================================================
        END

    ex.5
        print <<`END`;
        ============================================================
        Escaped for DOUBLE quote command.   --- OK
        ============================================================
        END

    ex.6
        print <<'END1', <<'END2';
        ============================================================
        Escaped for SINGLE quote document.   --- OK
        ============================================================
        END1
        ============================================================
        Escaped for SINGLE quote document.   --- OK
        ============================================================
        END2

    ex.7
        print <<"END1", <<"END2";
        ============================================================
        Escaped for DOUBLE quote document.   --- OK
        ============================================================
        END1
        ============================================================
        Escaped for DOUBLE quote document.   --- OK
        ============================================================
        END2

    ex.8
        print <<'END1', <<"END2", <<'END3';
        ============================================================
        Escaped for DOUBLE quote document 'END1', "END2", 'END3'.
        'END1' and 'END3' see string rewritten for "END2".
        ============================================================
        END1
        ============================================================
        Escaped for DOUBLE quote document "END2", 'END3'.
        'END3' see string rewritten for "END2".
        ============================================================
        END2
        ============================================================
        Escaped for DOUBLE quote document "END3".
        'END3' see string rewritten for "END2".
        ============================================================
        END3

    ex.9
        print <<"END1", <<'END2', "END3";
        ============================================================
        Escaped for DOUBLE quote document "END1", 'END2', "END3".
        'END2' see string rewritten for "END1" and "END3".
        ============================================================
        END1
        ============================================================
        Escaped for DOUBLE quote document 'END2', "END3".
        'END2' see string rewritten for "END3".
        ============================================================
        END2
        ============================================================
        Escaped for DOUBLE quote document.   --- OK
        ============================================================
        END3

=back

=head1 HISTORY

This esjis.pl software first appeared in ActivePerl Build 522 Built under
MSWin32 Compiled at Nov 2 1999 09:52:28

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.
For any questions, use E<lt>ina@cpan.orgE<gt> so we can share
this file.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 ShiftJIS IN WIKIPEDIA

Shift JIS (2008.02.15 15:02:00 JST). In Wikipedia: The Free Encyclopedia.
Retrieved from
L<http://en.wikipedia.org/wiki/Shift_JIS>

Shift JIS (also SJIS, MIME name Shift_JIS) is a character encoding
for the Japanese language originally developed by a Japanese company
called ASCII Corporation in conjunction with Microsoft and standardized
as JIS X 0208 Appendix 1. It is based on character sets defined within
JIS standards JIS X 0201:1997 (for the single-byte characters) and
JIS X 0208:1997 (for the double byte characters). The lead bytes for
the double byte characters are "shifted" around the 64 halfwidth katakana
characters in the single-byte range 0xA1 to 0xDF. The single-byte
characters 0x00 to 0x7F match the ASCII encoding, except for a yen sign
at 0x5C and an overline at 0x7E in place of the ASCII character set's
backslash and tilde respectively. On the web, 0x5C is still used as the
Perl Script escape character. The single-byte characters from 0xA1 to 0xDF
map to the half-width katakana characters found in JIS X 0201. 

Shift JIS requires an 8-bit medium for transmission. It is fully backwards
compatible with the legacy JIS X 0201 single-byte encoding, meaning it
supports half-width katakana and that any valid JIS X 0201 string is also
a valid Shift JIS string. However Shift JIS only guarantees that the first
byte will be in the upper ASCII range; the value of the second byte can be
either high or low. This makes reliable Shift JIS detection difficult.
On the other hand, the competing 8-bit format EUC-JP, which does not
support single-byte halfwidth katakana, allows for a much cleaner and
direct conversion to and from JIS X 0208 codepoints, as all upper-ASCII
bytes are part of a double-byte character and all lower-ASCII bytes are
part of a single-byte character.

Many different versions of Shift JIS exist. There are two areas for
expansion: Firstly, JIS X 0208 does not fill the whole 94x94 space encoded
for it in Shift JIS, therefore there is room for more characters here ?
these are really extensions to JIS X 0208 rather than to Shift JIS itself.
The most popular extension here is to the Windows-31J (otherwise known as
Code page 932) encoding popularized by Microsoft, although Microsoft
itself does not recognize the Windows-31J name and instead calls that
variation "shift_jis". Secondly, Shift JIS has more encoding space than is
needed for JIS X 0201 and JIS X 0208, and this space can and is used for
yet more characters. The space with lead bytes 0xF5 to 0xF9 is used by
Japanese mobile phone operators for pictographs for use in E-mail, for
example (KDDI goes further and defines hundreds more in the space with
lead bytes 0xF3 and 0xF4).

Beyond even this there have been numerous minor variations made on Shift
JIS, with individual characters here and there altered. Most of these
extensions and variants have no IANA registration, so there is much scope
for confusion if the extensions are used. Microsoft Code Page 932 is
registered separately from Shift JIS.
IBM CCSID 943 has the same extensions as Code Page 932.
As with most code pages and encodings it is recommended that Unicode be
used instead.

=head1 "ShiftJIS" IN THIS SOFTWARE

 The "ShiftJIS" in this software means widely codeset than general
ShiftJIS. This software used two algorithms to handle ShiftJIS.

=over 2

=item * ALGORITHM.1

 When the character is taken out of the octet string, it is necessary to
distinguish a single octet character and the double octet character.
The distinction is done only by first octet.

    Single octet code is:
      0x00-0x80, 0xA0-0xDF and 0xFD-0xFF

    Double octet code is:
      First octet   0x81-0x9F and 0xE0-0xFC
      Second octet  0x00-0xFF (All octet)

    MALFORMED single octet code is:
      0x81-0x9F and 0xE0-0xFC
      * Final octet of string like first octet of double octet code

 So this "ShiftJIS" can handle any code of ShiftJIS based code without
Informix Ascii 'INFORMIX V6 ALS' is triple octet code.
(I'm sorry, Informix Ascii users.)

See also code table:

         Single octet code

   0 1 2 3 4 5 6 7 8 9 A B C D E F 
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 0|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x00-0x80
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 1|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 2|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 3|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 4|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 5|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 6|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 7|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 8|*| | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 9| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 A|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0xA0-0xDF
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 B|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 C|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 D|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 E| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 F| | | | | | | | | | | | | |*|*|*| 0xFD-0xFF
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


                                 Double octet code
            First octet                                     Second octet

   0 1 2 3 4 5 6 7 8 9 A B C D E F                 0 1 2 3 4 5 6 7 8 9 A B C D E F 
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 0| | | | | | | | | | | | | | | | |              0|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x00-0xFF
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 1| | | | | | | | | | | | | | | | |              1|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 2| | | | | | | | | | | | | | | | |              2|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 3| | | | | | | | | | | | | | | | |              3|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 4| | | | | | | | | | | | | | | | |              4|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 5| | | | | | | | | | | | | | | | |              5|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 6| | | | | | | | | | | | | | | | |              6|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 7| | | | | | | | | | | | | | | | |              7|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 8| |*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x81-0x9F    8|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 9|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|              9|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 A| | | | | | | | | | | | | | | | |              A|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 B| | | | | | | | | | | | | | | | |              B|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 C| | | | | | | | | | | | | | | | |              C|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 D| | | | | | | | | | | | | | | | |              D|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 E|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0xE0-0xFC    E|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 F|*|*|*|*|*|*|*|*|*|*|*|*|*| | | |              F|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


    *MALFORMED* Single octet code

Final octet of string like first octet of double octet code

Even if malformed, it is not ignored and not deleted automatically.
For example, Sjis::chop function returns this octet.

   0 1 2 3 4 5 6 7 8 9 A B C D E F 
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 0| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 1| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 2| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 3| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 4| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 5| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 6| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 7| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 8| |M|M|M|M|M|M|M|M|M|M|M|M|M|M|M| 0x81-0x9F
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 9|M|M|M|M|M|M|M|M|M|M|M|M|M|M|M|M|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 A| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 B| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 C| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 D| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 E|M|M|M|M|M|M|M|M|M|M|M|M|M|M|M|M|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 F|M|M|M|M|M|M|M|M|M|M|M|M|M| | | |  0xE0-0xFC
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


The ShiftJIS list via vendors:
L<http://home.m05.itscom.net/numa/cde/sjis-euc/sjis.html>

 DEC PC                         0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)
 DEC WS                         0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)
 Fujitsu TrueType font (PC)     0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)
 Fujitsu FontCity font (PC)     0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)
 Hitachi PC                     0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)
 Hitachi WS                     0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)
 IBM                            0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)
 NEC Windows (PC)               0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)
 NEC DOS (PC)                   0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)
 SONY NEWS-OS                   0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)
 Sun Wabi                       0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)
 Unisys PC                      0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)
 HP Japan Japanese HP-15        0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)
 AT&T Japan                     0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)
 Mitsubishi Electric FONTRUNNER 0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)
 Concurrent Japan               0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)
 Informix ASCII INFORMIX V6 ALS 0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC), (0xFD)(0xA1-0xFE)(0xA1-0xFE)
 Oracle Oracle7 (Release 7.1.3) 0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x00-0xFF)
 Sybase SQL Server, Open Server 0x00-0x7F, 0xA1-0xDF, (0x81-0x9F, 0xE0-0xFC)(0x40-0x7E, 0x80-0xFC)

=item * ALGORITHM.2

Against algorithm.1, when the range of the character is specified, only the following
character codes are effective.

    Single octet code is:
      0x00-0x80, 0xA0-0xDF and 0xFD-0xFF

    Double octet code is:
      First octet   0x81-0x9F and 0xE0-0xFC
      Second octet  0x40-0x7E and 0x80-0xFC

For instance, [\x81\x00-\x82\xFF] in script means [\x81\x82][\x40-\x7E\x80-\xFC].

See also code table:

         Single octet code

   0 1 2 3 4 5 6 7 8 9 A B C D E F 
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 0|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x00-0x80
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 1|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 2|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 3|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 4|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 5|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 6|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 7|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 8|*| | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 9| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 A|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0xA0-0xDF
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 B|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 C|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 D|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 E| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 F| | | | | | | | | | | | | |*|*|*| 0xFD-0xFF
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


                                 Double octet code
            First octet                                     Second octet

   0 1 2 3 4 5 6 7 8 9 A B C D E F                 0 1 2 3 4 5 6 7 8 9 A B C D E F 
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 0| | | | | | | | | | | | | | | | |              0| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 1| | | | | | | | | | | | | | | | |              1| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 2| | | | | | | | | | | | | | | | |              2| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 3| | | | | | | | | | | | | | | | |              3| | | | | | | | | | | | | | | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 4| | | | | | | | | | | | | | | | |              4|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x40-0x7E
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 5| | | | | | | | | | | | | | | | |              5|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 6| | | | | | | | | | | | | | | | |              6|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 7| | | | | | | | | | | | | | | | |              7|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 8| |*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x81-0x9F    8|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0x80-0xFC
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 9|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|              9|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 A| | | | | | | | | | | | | | | | |              A|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 B| | | | | | | | | | | | | | | | |              B|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 C| | | | | | | | | | | | | | | | |              C|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 D| | | | | | | | | | | | | | | | |              D|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 E|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*| 0xE0-0xFC    E|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 F|*|*|*|*|*|*|*|*|*|*|*|*|*| | | |              F|*|*|*|*|*|*|*|*|*|*|*|*|*| | | |
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


=back

=head1 GOAL

=over 2

=item Goal #1:

Old byte-oriented programs should not spontaneously break on the old
byte-oriented data they used to work on.

=item Goal #2:

Old byte-oriented programs should magically start working on the new
character-oriented data when appropriate.

=item Goal #3:

Programs should run just as fast in the new character-oriented mode
as in the old byte-oriented mode.

=item Goal #4:

Perl should remain one language, rather than forking into a
byte-oriented Perl and a character-oriented Perl.

=back

=head1 SEE ALSO

C<Programming Perl, Third Edition>
By Larry Wall, Tom Christiansen, Jon Orwant
Third Edition  July 2000
Pages: 1104
ISBN 10: 0-596-00027-8 | ISBN 13:9780596000271
L<http://www.oreilly.com/catalog/pperl3/index.html>

C<CJKV Information Processing>
Chinese, Japanese, Korean & Vietnamese Computing
By Ken Lunde
First Edition  January 1999
Pages: 1128
ISBN 10: 1-56592-224-7 | ISBN 13:9781565922242
L<http://www.oreilly.com/catalog/cjkvinfo/index.html>

C<Mastering Regular Expressions, Third Edition>
By Jeffrey E. F. Friedl
Third Edition  August 2006
Pages: 542
ISBN 10: 0-596-52812-4 | ISBN 13:9780596528126
L<http://www.oreilly.com/catalog/regex3/index.html>

=head1 ACKNOWLEDGEMENTS

This software was made, thanks to the following hackers or persons.
Especially this POD was written referring from the Encode module.
I am thankful to all persons.

Rick Yamashita, ShiftJIS
http://furukawablog.spaces.live.com/Blog/cns!1pmWgsL289nm7Shn7cS0jHzA!2225.entry

Larry Wall, Perl
L<http://www.perl.org/>

Kazumasa Utashiro, jcode.pl
L<http://www.srekcah.org/jcode/>

Jeffrey E. F. Friedl, Mastering Regular Expressions
L<http://www.oreilly.com/catalog/regex/index.html>

SADAHIRO Tomoyuki, The right way of using ShiftJIS
L<http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm>

jscripter, For jperl users
L<http://homepage1.nifty.com/kazuf/jperl.html>

Hizumi, Perl5.8/Perl5.10 is not useful on the Windows.
L<http://www.aritia.org/hizumi/perl/perlwin.html>

SUZUKI Norio, Jperl
L<http://homepage2.nifty.com/kipp/perl/jperl/>

Hirofumi Watanabe, Jperl
L<http://search.cpan.org/~watanabe/>

Dan Kogai, Encode module
L<http://search.cpan.org/dist/Encode/>

=cut

