# -*- perl -*-
use strict;
use Test::More;

plan skip_all => 'This test is only run for the module author'
  unless -d '.git' || $ENV{AUTHOR_TESTING};

eval "use Pod::Spell::CommonMistakes;";
plan skip_all => "Pod::Spell::CommonMistakes required"
  if $@;
my @files = qw(Safe.pm README);
plan tests => scalar @files;

for my $f (@files) {
  my $r = Pod::Spell::CommonMistakes::check_pod($f);
  if ( keys %$r == 0 ) {
    ok(1, "$f");
  } else {
    ok(0, "$f");
    foreach my $k ( keys %$r ) {
      diag "  Found: '$k' - Possible spelling: '$r->{$k}'?";
    }
  }
}
