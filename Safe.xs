#include "perl_libyaml.h"

MODULE = YAML::Safe		PACKAGE = YAML::Safe

PROTOTYPES: DISABLE

void
_Load (yaml_string)
        SV *yaml_string
  PPCODE:
        PL_markstack_ptr++;
        if (!Load(yaml_string))
            XSRETURN_UNDEF;
        else
            return;

void
LoadFile (yaml_file)
        SV *yaml_file
  PPCODE:
        PL_markstack_ptr++;
        if (!LoadFile(yaml_file))
            XSRETURN_UNDEF;
        else
            return;

void
_Dump (...)
  PPCODE:
        PL_markstack_ptr++;
        if (!Dump())
            XSRETURN_UNDEF;
        else
            return;

void
DumpFile (yaml_file, ...)
        SV *yaml_file
  PPCODE:
        PL_markstack_ptr++;
        if (!DumpFile(yaml_file))
            XSRETURN_UNDEF;
        else
            XSRETURN_YES;

SV *
libyaml_version()
    CODE:
    {
        const char *v = yaml_get_version_string();
        RETVAL = newSVpv(v, strlen(v));

    }
    OUTPUT: RETVAL
