use FindBin '$Bin';
use lib $Bin;
use TestYAMLTests;

my $yaml = <<'...';
---
boolfalse: false
booltrue: true
stringfalse: 'false'
stringtrue: 'true'
...

unless (eval { require JSON::XS }) {
    plan skip_all => "JSON::XS not installed";
    exit;
}
plan skip_all => "JSON::XS $JSON::XS::VERSION too old"
    if $JSON::XS::VERSION < 3.0;

my $obj = eval { YAML::Safe->new->boolean("JSON::PP") };
if ($@ and $@ =~ m{JSON/PP}) {
    plan skip_all => "JSON::PP also not installed";
    exit;
}

plan tests => 7;

my $hash = $obj->Load($yaml);
isa_ok($hash->{booltrue}, 'JSON::PP::Boolean');
isa_ok($hash->{boolfalse}, 'JSON::PP::Boolean');

cmp_ok($hash->{booltrue}, '==', 1, "boolean true is true");
cmp_ok($hash->{boolfalse}, '==', 0, "boolean false is false");

ok(! ref $hash->{stringtrue}, "string 'true' stays string");
ok(! ref $hash->{stringfalse}, "string 'false' stays string");

my $yaml2 = $obj->Dump($hash);
cmp_ok($yaml2, 'eq', $yaml, "Roundtrip booleans ok");

