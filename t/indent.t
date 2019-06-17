use FindBin '$Bin';
use lib $Bin;
use TestYAMLTests tests => 2;

$YAML::Safe::Indent = 4;
is Dump([{a => 1, b => 2, c => 3}]), <<'...',
---
-   a: 1
    b: 2
    c: 3
...
'Dumped with indent 4';

$YAML::Safe::Indent = 8;
is Dump([{a => 1, b => 2, c => 3}]), <<'...',
---
-       a: 1
        b: 2
        c: 3
...
'Dumped with indent 8';