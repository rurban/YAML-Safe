use FindBin '$Bin';
use lib $Bin;
use TestYAMLTests tests => 6;

my ($a, $b, $c, $d) = (42, "42", 42, "42");
my $e = ">$c<";
my $f = $d + 3;

{
is Dump($a, $b, $c, $d), <<'...', "Dumping Integers and Strings";
--- 42
--- '42'
--- 42
--- 42
...

my ($num, $float, $str) = Load(<<'...');
--- 42
--- 0.333
--- '02134'
...

is Dump($num, $float, $str), <<'...', "Round tripping integers and strings";
--- 42
--- 0.333
--- '02134'
...

}

{
  my $obj = YAML::Safe->new->quotenum;

  is $obj->Dump($a, $b, $c, $d), <<'...', "Dumping Integers and Strings";
--- 42
--- '42'
--- 42
--- 42
...

  my ($num, $float, $str) = $obj->Load(<<'...');
--- 42
--- 0.333
--- '02134'
...

  is $obj->Dump($num, $float, $str), <<'...', "Round tripping integers and strings";
--- 42
--- 0.333
--- '02134'
...

}

{
  my $obj = YAML::Safe->new->quotenum(0);

is $obj->Dump($a, $b, $c, $d), <<'...', "Dumping Integers and Strings";
--- 42
--- 42
--- 42
--- 42
...

my ($num, $float, $str) = $obj->Load(<<'...');
--- 42
--- 0.333
--- '02134'
...

is $obj->Dump($num, $float, $str), <<'...', "Round tripping integers and strings";
--- 42
--- 0.333
--- 02134
...

}

