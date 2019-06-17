use Test::More;

use YAML::Safe ();

my $libyaml_version = YAML::Safe::LibYAML::libyaml_version();
diag "libyaml version = $libyaml_version";
cmp_ok($libyaml_version, '=~', qr{^\d+\.\d+(?:\.\d+)$}, "libyaml_version ($libyaml_version)");

done_testing;
