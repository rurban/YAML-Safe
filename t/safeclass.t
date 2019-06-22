use FindBin '$Bin';
use lib $Bin;
use TestYAMLTests tests => 17;
no warnings 'once';
# allow Foo::Bar, disallow Foo::Insecure
my $o = YAML::Safe->new->noindentmap->SafeClass("Foo::Bar");

filters {
    perl => 'eval',
    safeyaml => 'safeload_yaml',
};
my $name = "Blessed Hashes and Arrays";
my $test = get_block_by_name($name);

my $hash = $test->perl;
my $hash2 = $o->SafeLoad($test->{yaml}[0]);

# is_deeply is broken and doesn't check blessings
is_deeply $hash2, $hash, "SafeLoad " . $test->name;

is ref($hash2->{foo}), 'Foo::Bar',
    "Object 'foo' is blessed 'Foo::Bar'";
is ref($hash2->{bar}), 'HASH',
    "Hashref 'bar' is not blessed 'Foo::Insecure'";
is ref($hash2->{one}), 'Foo::Bar',
    "Arrayref 'one' is blessed 'Foo::Bar'";
is ref($hash2->{two}), 'ARRAY',
    "Arrayref 'two' is not blessed 'Foo::Insecure'";

my $yaml = $o->SafeDump($hash2);

is $yaml, $test->yaml_dump, "SafeDump " . $test->name . " works";

######
$name = "Blessed Scalar Ref";
$test = get_block_by_name($name);
my $array = $test->perl;
my $array2 = $o->SafeLoad($test->{yaml}[0]);

# is_deeply is broken and doesn't check blessings
is_deeply $array2, $array, "SafeLoad " . $test->name;

is ref($array2->[0]), 'Foo::Bar',
    "Safe scalar ref is class name 'Foo::Bar'";
like "$array2->[0]", qr/=SCALAR\(/, "Got a safe scalar ref";
is ref($array2->[1]), '', "Unsafe scalar ref got unblessed";
is $array2->[1], 'ho ho', "but kept the value";

$yaml = $o->SafeDump($array2);
is $yaml, $test->yaml_dump, "SafeDump " . $test->name . " works";

######
$name = "Blessed Code Ref";
$test = get_block_by_name($name);
$array = $o->loadcode->Load($test->yaml);
$array2 = $o->loadcode->SafeLoad($test->yaml);

is $array->[0]->(), 'Ho', 'can call safe code';
is $array2->[0]->(), 'Ho', 'can call registered code';
is $array->[1]->(), 'Ha', 'can call unsafe code';
is $array2->[1], undef, 'skipped unsafe code';

$yaml = $o->dumpcode->SafeDump($array);
$yaml =~ s/use strict 'refs';/use strict;/;
is $yaml, $test->yaml_dump, "SafeDump " . $test->name . " works";

__DATA__
=== Blessed Hashes and Arrays
+++ yaml
foo: !!perl/hash:Foo::Bar {}
bar: !!perl/hash:Foo::Insecure
  bass: bawl
one: !!perl/array:Foo::Bar []
two: !!perl/array:Foo::Insecure
- lola
- alol
+++ perl
+{
    foo => (bless {}, "Foo::Bar"),
    bar => (bless {bass => 'bawl'}, "Foo::Bar"),
    one => [],
    two => [lola => 'alol'],
};
+++ yaml_dump
---
bar:
  bass: bawl
foo: !!perl/hash:Foo::Bar {}
one: !!perl/array:Foo::Bar []
two:
- lola
- alol

=== Blessed Scalar Ref
+++ yaml
---
- !!perl/scalar:Foo::Bar hey hey
- !!perl/scalar:Foo::Insecure ho ho
+++ perl
my $x = 'hey hey';
[bless(\$x, 'Foo::Bar'), 'ho ho'];
+++ yaml_dump
---
- !!perl/scalar:Foo::Bar hey hey
- ho ho

=== Blessed Code Ref
+++ yaml
---
- !!perl/code:Foo::Bar |-
  { return "Ho" }
- !!perl/code:Foo::Insecure |-
  { return "Ha" }
+++ yaml_dump
---
- !!perl/code:Foo::Bar |-
  {
      package YAML::Safe;
      use warnings;
      use strict;
      return 'Ho';
  }
- !!perl/code:Foo::Insecure '{ "UNSAFE" }'
