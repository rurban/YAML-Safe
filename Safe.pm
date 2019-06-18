use strict; use warnings;

package YAML::Safe;
our $VERSION = '0.80';
our $XS_VERSION = $VERSION;
# $VERSION = eval $VERSION;

use base 'Exporter';
@YAML::Safe::EXPORT = qw(Load Dump LoadFile DumpFile);
#@YAML::Safe::EXPORT_OK = qw();
%YAML::Safe::EXPORT_TAGS = (
    all => [qw(Dump Load LoadFile DumpFile)],
);
our ($UseCode, $DumpCode, $LoadCode, $Boolean, $LoadBlessed, $Indent);
# $YAML::Safe::NonStrict = 1; # for Load
# $YAML::Safe::UseCode = 0;   # for Dump
# $YAML::Safe::DumpCode = 0;  # for Dump
# $YAML::Safe::LoadCode = 0;  # for Load. ignored

$YAML::Safe::QuoteNumericStrings = 1;

use XSLoader;
use Scalar::Util qw/ openhandle /;

sub _DumpFile {
    my $OUT;
    my $filename = shift;
    if (openhandle $filename) {
        $OUT = $filename;
    }
    else {
        my $mode = '>';
        if ($filename =~ /^\s*(>{1,2})\s*(.*)$/) {
            ($mode, $filename) = ($1, $2);
        }
        open $OUT, $mode, $filename
          or die "Can't open '$filename' for output:\n$!";
    }
    local $/ = "\n"; # reset special to "sane"
    print $OUT YAML::Safe::_Dump(@_);
}

sub _LoadFile {
    my $IN;
    my $filename = shift;
    if (openhandle $filename) {
        $IN = $filename;
    }
    else {
        open $IN, $filename
          or die "Can't open '$filename' for input:\n$!";
    }
    return YAML::Safe::_Load(do { local $/; local $_ = <$IN> });
}


# XXX The following code should be moved from Perl to C.
$YAML::Safe::coderef2text = sub {
    my $coderef = shift;
    require B::Deparse;
    my $deparse = B::Deparse->new();
    my $text;
    eval {
        local $^W = 0;
        $text = $deparse->coderef2text($coderef);
    };
    if ($@) {
        warn "YAML::Safe failed to dump code ref:\n$@";
        return;
    }
    $text =~ s[BEGIN \{\$\{\^WARNING_BITS\} = "UUUUUUUUUUUU\\001"\}]
              [use warnings;]g;

    return $text;
};

$YAML::Safe::glob2hash = sub {
    my $hash = {};
    for my $type (qw(PACKAGE NAME SCALAR ARRAY HASH CODE IO)) {
        my $value = *{$_[0]}{$type};
        $value = $$value if $type eq 'SCALAR';
        if (defined $value) {
            if ($type eq 'IO') {
                my @stats = qw(device inode mode links uid gid rdev size
                               atime mtime ctime blksize blocks);
                undef $value;
                $value->{stat} = {};
                map {$value->{stat}{shift @stats} = $_} stat(*{$_[0]});
                $value->{fileno} = fileno(*{$_[0]});
                {
                    local $^W;
                    $value->{tell} = tell(*{$_[0]});
                }
            }
            $hash->{$type} = $value;
        }
    }
    return $hash;
};

use constant _QR_MAP => {
    '' => sub { qr{$_[0]} },
    x => sub { qr{$_[0]}x },
    i => sub { qr{$_[0]}i },
    s => sub { qr{$_[0]}s },
    m => sub { qr{$_[0]}m },
    ix => sub { qr{$_[0]}ix },
    sx => sub { qr{$_[0]}sx },
    mx => sub { qr{$_[0]}mx },
    si => sub { qr{$_[0]}si },
    mi => sub { qr{$_[0]}mi },
    ms => sub { qr{$_[0]}sm },
    six => sub { qr{$_[0]}six },
    mix => sub { qr{$_[0]}mix },
    msx => sub { qr{$_[0]}msx },
    msi => sub { qr{$_[0]}msi },
    msix => sub { qr{$_[0]}msix },
};

sub __qr_loader {
    if ($_[0] =~ /\A  \(\?  ([\^uixsm]*)  (?:-  (?:[ixsm]*))?  : (.*) \)  \z/x) {
        my ($flags, $re) = ($1, $2);
        $flags =~ s/^\^//;
        $flags =~ tr/u//d;
        my $sub = _QR_MAP->{$flags} || _QR_MAP->{''};
        my $qr = &$sub($re);
        return $qr;
    }
    return qr/$_[0]/;
}

sub __code_loader {
    my ($string) = @_;
    my $sub = eval "sub $string";
    if ($@) {
        warn "YAML::Safe failed to load sub: $@";
        return sub {};
    }
    return $sub;
}

XSLoader::load 'YAML::Safe', $XS_VERSION;

1;
__END__
=encoding UTF-8

=head1 Name

YAML::Safe - Safe Perl YAML Serialization using XS and libyaml

=for html
<a href="https://travis-ci.org/rurban/YAML-Safe"><img src="https://travis-ci.org/rurban/YAML-Safe.png" alt="YAML-Safe"></a>

=head1 Synopsis

    use YAML::Safe;

    my $yaml = Dump [ 1..4 ];
    my $array = Load $yaml;

    my $yaml = DumpFile ("my.yml", [ 1..4 ]);
    my $array = LoadFile "my.yml";

    my $yaml = new YAML::Safe;
    $yaml->NonStrict(1);
    $yaml->Encoding("any");
    $yaml->SafeClass("DateTime");
    my $array = $yaml->SafeLoadFile("META.yml");

    my $yaml = new YAML::Safe;
    $yaml->Canonical(1);
    $yaml->Unicode(1);
    $yaml->SafeClass("DateTime");
    my $array = $yaml->SafeDumpFile("META.yml");

=head1 Description

Kirill Siminov's C<libyaml> is a good YAML library implementation. The C
library is written precisely to the YAML 1.1 specification, and offers YAML
1.2 support. It was originally bound to Python and was later bound to Ruby.
C<libsyck> is written a bit more elegant, has less bugs, is not as strict as
libyaml, but misses some YAML features. It can only do YAML 1.0

This module is a refactoring of L<YAML::XS>, the old Perl XS binding to
libyaml which offers Perl somewhat acceptable YAML support to date.
YAML::XS never produced code which could be read from YAML, and thus
was unsuitable to be used as YAML replacement for core and CPAN.

This module exports the functions C<Dump>, C<Load>, C<DumpFile> and
C<LoadFile>. These functions are intended to work exactly like L<YAML::XS>
and C<YAML.pm>'s corresponding functions.

There are also new Safe variants of Load and Dump methods, and the
possibility to create a YAML object, set options as setter methods and
call the Safe methods.

If you set the option C<$YAML::Safe::IndentlessMap> to 0 or undef,
C<YAML::Safe> will behave like with version E<lt> 0.70, which creates
yml files which cannot be read by C<YAML.pm>

However the loader is stricter than C<YAML>, C<YAML::Syck> and
C<CPAN::Meta::YAML> i.e. C<YAML::Tiny> as used in core. Set the variable
C<$YAML::Safe::NonStrict> to allow certain reader errors to pass the
C<CPAN::Meta> validation testsuite.

=head1 FUNCTIONS

=over

=item Load

=item LoadFile

=item Dump

=item DumpFile

=back

=head1 METHODS

=over

=item new "classname", option => value, ...

Create a YAML loader or dumper object with some options.

=item SafeClass "classname", ...

Add a string or list of strings to the list of allowed classes to the
C<Safe{Load,Dump}> methods. Without any SafeClass added, no custom C<!>
classes are allow in the YAML.

=item SafeLoad

Restrict the loader to the registered safe classes only.

=item SafeLoadFile

=item SafeDump

Restrict the dumper to the registered safe classes only.

=item SafeDumpFile

and all the loader and dumper options as getter and setter methods.

=back

=head1 Configuration

=head2 Loader Options

via getter and setter methods.

=over

=item C<nonstrict>

Permit certain reader errors to loosely match other YAML module semantics. In
detail: Allow B<"control characters are not allowed">. Note that any error is
stored and returned, just not immediately.

However the reader error B<"invalid trailing UTF-8 octet"> and all other utf8
strictness violations are still fatal.

And if the structure of the YAML document cannot be parsed, i.e. a required
value consists only of invalid control characters, the loader returns an
error, unlike with non-strict YAML modules.

=item C<load_code>

Ignored. If enabled supports deparsing and evaling of code blocks.

=back

=head2 Dumper Options

via globals variables or as optional getter and setter methods.

=over

=item C<$YAML::Safe::UseCode>

If enabled supports Dump of CV code blocks via C<YAML::Safe::coderef2text()>.

=item C<$YAML::Safe::DumpCode>

If enabled supports Dump of CV code blocks via C<YAML::Safe::coderef2text()>.

=item C<$YAML::Safe::QuoteNumericStrings>

When true (the default) strings that look like numbers but have not been
numified will be quoted when dumping.

This ensures leading that things like leading zeros and other formatting are
preserved.

=item C<$YAML::Safe::IndentlessMap>

Default 0

Set to 1 or a true value to fallback to the old C<YAML::Safe> behavior to omit
the indentation of map keys, which arguably violates the YAML spec, is
different to all other YAML libraries and causes C<YAML.pm> to fail.

With 0

     authors:
       - this author

With 1

     authors:
     - this author

=item C<$YAML::Safe::Indent>

Default 2

=item C<$YAML::Safe::BestWidth>

Default 80

Control text wrapping.

=item C<$YAML::Safe::Canonical>

Default 1

Set to undef or 0 to disable sorting map keys.

=item C<$YAML::Safe::Unicode>

Default 1

Set to undef or 0 to disallow unescaped non-ASCII characters.

=item C<$YAML::Safe::Encoding>

Default utf8

Set to any, utf8, utf16le or utf16be

=item C<$YAML::Safe::LineBreak>

Default ln

Set to any, cr, ln or crln.

=item C<$YAML::Safe::OpenEnded>

Default 0

Set to 1 or a true value to embed the yaml into "...". If an explicit document
end is required.

=item C<$YAML::Safe::SafeMode>

Default 0

Set to 1 or a true value to restrict the allowed classed only the set of
registered classes or tags starting with "perl/".

=back

=head1 Using YAML::Safe with Unicode

Handling unicode properly in Perl can be a pain. YAML::Safe only deals with
streams of utf8 octets. Just remember this:

    $perl = Load($utf8_octets);
    $utf8_octets = Dump($perl);

There are many, many places where things can go wrong with unicode. If you are
having problems, use Devel::Peek on all the possible data points.

=head1 See Also

=over

=item L<YAML>.pm

=item L<YAML::XS>

=item L<YAML::Syck>

=item L<YAML::Tiny>

=item L<CPAN::Meta::YAML>

=back

=head1 Author

Reini Urban <rurban@cpan.org>, 
based on YAML::XS by Ingy döt Net <ingy@cpan.org>

=head1 Copyright and License

Copyright 2007-2016. Ingy döt Net.
Copyright 2015-2019. Reini Urban.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

