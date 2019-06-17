/* These definitions affect -pedantic warnings...

#define PERL_GCC_BRACE_GROUPS_FORBIDDEN 1
#define __STRICT_ANSI__ 1
#define PERL_GCC_PEDANTIC 1
*/

#include "EXTERN.h"
#include "perl.h"
#define NO_XSLOCKS
#include "XSUB.h"
#define NEED_newRV_noinc
#define NEED_sv_2pv_nolen
#define NEED_sv_2pvbyte
#include "ppport.h"
#include <yaml.h>
#include <ppport_sort.h>

/* from cperl */
#ifndef strEQc
/* the buffer ends with \0, includes comparison of the \0.
   better than strEQ as it uses memcmp, word-wise comparison. */
# define strEQc(s, c) memEQ(s, ("" c ""), sizeof(c))
#endif

#define TAG_PERL_PREFIX "tag:yaml.org,2002:perl/"
#define TAG_PERL_REF TAG_PERL_PREFIX "ref"
#define TAG_PERL_STR TAG_PERL_PREFIX "str"
#define TAG_PERL_GLOB TAG_PERL_PREFIX "glob"
#define ERRMSG "YAML::Safe Error: "
#define LOADERRMSG "YAML::Safe::Load Error: "
#define LOADFILEERRMSG "YAML::Safe::LoadFile Error: "
#define DUMPERRMSG "YAML::Safe::Dump Error: "

typedef struct {
    yaml_parser_t parser;
    yaml_event_t event;
    HV *anchors;
    int load_code;
    int load_bool_jsonpp;
    int load_bool_boolean;
    int load_blessed;
    int document;
    char *filename;
    PerlIO *perlio;
} perl_yaml_loader_t;

typedef struct {
    yaml_emitter_t emitter;
    long anchor;
    HV *anchors;
    HV *shadows;
    int dump_code;
    int dump_bool_jsonpp;
    int dump_bool_boolean;
    int quote_number_strings;
    char *filename;
    PerlIO *perlio;
} perl_yaml_dumper_t;

int
Dump();

int
DumpFile(SV *);

int
Load(SV *);

int
LoadFile(SV *);

