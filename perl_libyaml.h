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

#if PERL_VERSION < 5
#define sv_peek(pTHX_ sv_file) ""
#endif

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

#define F_UNICODE          0x00000001
#define F_DISABLEBLESSED   0x00000002
#define F_ENABLECODE       0x00000004
#define F_NONSTRICT        0x00000008
#define F_LOADCODE         0x00000010
#define F_DUMPCODE         0x00000020
#define F_QUOTENUM         0x00000040
#define F_NOINDENTMAP      0x00000080
#define F_CANONICAL        0x00000100
#define F_OPENENDED        0x00000200
#define F_SAFEMODE         0x00000400

typedef enum {
    YAML_BOOLEAN_NONE = 0,
    YAML_BOOLEAN_JSONPP,
    YAML_BOOLEAN_BOOLEAN,
    YAML_BOOLEAN_TYPES_SERIALISER,
} yaml_boolean_t;

typedef struct {
    yaml_parser_t *parser;
    yaml_event_t *event;
    yaml_emitter_t *emitter;
    char *filename;
    PerlIO *perlio;
    HV *anchors;
    HV *shadows;
    HV *safeclasses;
    long anchor;
    int document;
    U32 flags;
    yaml_encoding_t encoding;
    yaml_boolean_t boolean;
} YAML;

#if 0
typedef struct {
    YAML yaml; /* common options */
    yaml_parser_t parser;
    yaml_event_t event;
    int document;
    HV *anchors;
} perl_yaml_loader_t;

typedef struct {
    YAML yaml; /* common options */
    yaml_emitter_t emitter;
    long anchor;
    HV *anchors;
    HV *shadows;
} perl_yaml_dumper_t;
#endif

int
Dump(YAML *);

int
DumpFile(YAML *, SV *);

int
Load(YAML *, SV *);

int
LoadFile(YAML *, SV *);

void
set_parser_options(YAML *self, yaml_parser_t *parser);
void
set_emitter_options(YAML *self, yaml_emitter_t *emitter);
