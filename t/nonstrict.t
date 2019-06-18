use FindBin '$Bin';
use lib $Bin;
use TestYAMLTests tests => 2;

my $obj = YAML::Safe->new;
my $yaml = <<"...";
---
requires:
    Apache::Request:               1.1
    Class::Date:                   
...

ok (! eval{ $obj->Load($yaml) }, "strict yaml fails" );
ok ( $obj->nonstrict->Load($yaml), "nonstrict yaml passes" );

