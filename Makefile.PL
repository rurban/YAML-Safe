use strict;
use 5.008;
use ExtUtils::MakeMaker;
use Config;

# update.sh shouldn't be used, needs fix
#if (-d '../.git') {
#    system("./update.sh") == 0
#        or die "update.sh failed";
#}

unlink 'Safe.c'; # avoid duplicates
my $obj_files = join ' ', map {
    my $c = $_;
    $c =~ s/\.c$/$Config::Config{_o}/;
    $c;
} glob("XS/*.c"), 'Safe.c';

my $DEFINE = '';
# https://gcc.gnu.org/onlinedocs/gcc-4.0.0/gcc/Warning-Options.html
if ($Config{gccversion} and $Config{gccversion} =~ /^(\d+\.\d+)\./) {
  my $gccver = $1;
  if ($gccver >= 4.3) {
    $DEFINE = '-Wall -Werror=declaration-after-statement -Wextra -W';
  } elsif ($gccver >= 3.4) {
    $DEFINE = '-Wall -Wdeclaration-after-statement -Wextra -W';
  }
}
$DEFINE .= $^O eq 'MSWin32'
  ? ' -DHAVE_CONFIG_H -DYAML_DECLARE_EXPORT'
  : ' -DHAVE_CONFIG_H';

WriteMakefile(
  NAME => 'YAML::Safe',
  ABSTRACT_FROM => 'Safe.pm',
  VERSION_FROM => 'Safe.pm',
  PREREQ_PM => {
    'constant'   => 0.1,
    'Test::Base' => 0.80,
    'File::Path' => 0.1,
    'lib' => 0.1,
  },
  INC => '-IXS',
  LIBS => [''], # e.g., '-lm'
  DEFINE => $DEFINE,
  AUTHOR => 'Reini Urban <rurban@cpan.org>',
);
