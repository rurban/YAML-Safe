#include "perl_libyaml.h"

#define MY_CXT_KEY "YAML::Safe::_cxt"
typedef struct {
  SV *yaml_str;
} my_cxt_t;

START_MY_CXT

static void
init_MY_CXT(pTHX_ my_cxt_t * cxt)
{
  cxt->yaml_str = NULL;
}

MODULE = YAML::Safe		PACKAGE = YAML::Safe

PROTOTYPES: ENABLE

void
Load (...)
  PROTOTYPE: $;$@
  ALIAS:
        Load      = 1
        LoadFile  = 2
        SafeLoad  = 3
        SafeLoadFile = 4
        Dump      = 5
        DumpFile  = 6
        SafeDump  = 7
        SafeDumpFile = 8
  PREINIT:
	YAML *self;
        SV *yaml_arg;
        int ret, old_safe;
        int err = 0;
  PPCODE:
        /* check if called as method or function */
        if ((items == 1 && !SvROK(ST(0)) && SvOK(ST(0))) || /* no self */
            (ix >= 5 && ix <= 6 && SvROK(ST(0)))) {  /* Dump */
          /* default options */
          self = (YAML*)calloc(1, sizeof(YAML));
          old_safe = 0;
          yaml_arg = ST(0);
          /*if (ix >= 5 && ix <= 6 && SvROK(ST(0)))*/
          PL_markstack_ptr++;
        } else if (items >= 2 &&
                   SvOK(ST(1)) &&
                   SvROK(ST(0)) &&
                   SvOBJECT(SvRV(ST(0))) &&
                   sv_derived_from (ST(0), "YAML::Safe")) {
          self = (YAML*)SvPVX(SvRV(ST(0)));
          if (!self)
            self = (YAML*)calloc(1, sizeof(YAML));
          old_safe = self->flags & F_SAFEMODE;
          yaml_arg = ST(1);
          PL_markstack_ptr++;
        } else {
          err = 1;
        }
        /* set or unset safemode */
        switch (ix) {
        case 1: self->flags &= ~F_SAFEMODE;
                if (err)
                  croak ("Usage: Load(YAML::Safe*, str) or Load(str)");
                ret = Load(self, yaml_arg);
                break;
        case 2: self->flags &= ~F_SAFEMODE;
                if (err)
                  croak ("Usage: LoadFile(YAML::Safe*, str|io) or LoadFile(str|io)");
                ret = LoadFile(self, yaml_arg);
                break;
        case 3: self->flags |=  F_SAFEMODE;
                if (err)
                  croak ("Usage: SafeLoad(YAML::Safe*, str|io)");
                ret = Load(self, yaml_arg);
                break;
        case 4: self->flags |=  F_SAFEMODE;
                if (err)
                  croak ("Usage: SafeLoadFile(YAML::Safe*, str|io)");
                ret = LoadFile(self, yaml_arg);
                break;
        case 5: self->flags &= ~F_SAFEMODE;
                if (err)
                  croak ("Usage: Dump(YAML::Safe*, ...) or Dump(ref)");
                ret = Dump(self);
                break;
        case 6: self->flags &= ~F_SAFEMODE;
                if (err)
                  croak ("Usage: DumpFile(YAML::Safe*, str|io, ...) or DumpFile(str|io, ...)");
                ret = DumpFile(self, yaml_arg);
                break;
        case 7: self->flags |=  F_SAFEMODE;
                if (err)
                  croak ("Usage: SafeDump(YAML::Safe*, ...)");
                ret = Dump(self);
                break;
        case 8: self->flags |=  F_SAFEMODE;
                if (err)
                  croak ("Usage: SafeDumpFile(YAML::Safe*, str|io, ...)");
                ret = DumpFile(self, yaml_arg);
                break;
        }
        /* restore old safemode */
        if (old_safe) self->flags |=  F_SAFEMODE;
        else          self->flags &= ~F_SAFEMODE;
        if (!ret)
            XSRETURN_UNDEF;
        else
            return;

SV *
libyaml_version()
    CODE:
    {
        const char *v = yaml_get_version_string();
        RETVAL = newSVpv(v, strlen(v));
    }
    OUTPUT: RETVAL

BOOT:
{
        MY_CXT_INIT;
        init_MY_CXT(aTHX_ &MY_CXT);
}

#ifdef USE_ITHREADS

void CLONE (...)
    PPCODE:
        MY_CXT_CLONE; /* possible declaration */
        init_MY_CXT(aTHX_ &MY_CXT);
	/* skip implicit PUTBACK, returning @_ to caller, more efficient*/
        return;

#endif

void xxxEND(...)
    PREINIT:
        dMY_CXT;
        SV * sv;
    PPCODE:
        sv = MY_CXT.yaml_str;
        MY_CXT.yaml_str = NULL;
        if (sv)
            SvREFCNT_dec_NN(sv);
	/* skip implicit PUTBACK, returning @_ to caller, more efficient*/
        return;

void DESTROY (YAML *self)
    CODE:
        if (!self)
          return;
        if (self->anchors)
            SvREFCNT_dec_NN (self->anchors);
        if (self->shadows)
            SvREFCNT_dec_NN (self->shadows);
        if (self->perlio)
            SvREFCNT_dec_NN (self->perlio);
        if (self->filename)
            Safefree (self->filename);
        if (self->parser)
            yaml_parser_delete (self->parser);
        if (self->event)
            yaml_event_delete (self->event);
        if (self->emitter)
            yaml_emitter_delete (self->emitter);

SV* new (char *klass)
    CODE:
        dMY_CXT;
        SV *pv = NEWSV (0, sizeof (YAML));
        SvPOK_only (pv);
        Zero (SvPVX (pv), 1, YAML);
        RETVAL = sv_bless (newRV (pv), gv_stashpv (klass, 1));
    OUTPUT: RETVAL

SV* unicode (YAML *self, int enable = 1)
    ALIAS:
        unicode         = F_UNICODE
        disableblessed  = F_DISABLEBLESSED
        enablecode      = F_ENABLECODE
        nonstrict       = F_NONSTRICT
        loadcode        = F_LOADCODE
        dumpcode        = F_DUMPCODE
        quotenum        = F_QUOTENUM
        noindentmap     = F_NOINDENTMAP
        canonical       = F_CANONICAL
        openended       = F_OPENENDED
    CODE:
        if (enable)
          self->flags |=  ix;
        else
          self->flags &= ~ix;
    OUTPUT: self

SV* get_unicode (YAML *self)
    ALIAS:
        get_unicode         = F_UNICODE
        get_disableblessed  = F_DISABLEBLESSED
        get_enablecode      = F_ENABLECODE
        get_nonstrict       = F_NONSTRICT
        get_loadcode        = F_LOADCODE
        get_dumpcode        = F_DUMPCODE
        get_quotenum        = F_QUOTENUM
        get_noindentmap     = F_NOINDENTMAP
        get_canonical       = F_CANONICAL
        get_openended       = F_OPENENDED
        get_safemode        = F_SAFEMODE
    CODE:
        RETVAL = boolSV (self->flags & ix);
    OUTPUT: RETVAL

SV*
get_boolean (YAML *self)
    CODE:
        if (self->boolean == YAML_BOOLEAN_JSONPP)
          RETVAL = newSVpvn("JSON::PP", sizeof("JSON::PP")-1);
        else if (self->boolean == YAML_BOOLEAN_BOOLEAN)
          RETVAL = newSVpvn("boolean", sizeof("boolean")-1);
        else if (self->boolean == YAML_BOOLEAN_TYPES_SERIALISER)
          RETVAL = newSVpvn("Types::Serialiser", sizeof("Types::Serialiser")-1);
        else
          RETVAL = &PL_sv_undef;
    OUTPUT: RETVAL

SV*
boolean (YAML *self, SV *value)
    CODE:
        if (SvPOK(value)) {
          if (strEQc(SvPVX(value), "JSON::PP")) {
            self->boolean = YAML_BOOLEAN_JSONPP;
          }
          else if (strEQc(SvPVX(value), "boolean")) {
            self->boolean = YAML_BOOLEAN_BOOLEAN;
          }
          else if (strEQc(SvPVX(value), "Types::Serialiser")) {
            self->boolean = YAML_BOOLEAN_TYPES_SERIALISER;
          }
          else if (strEQc(SvPVX(value), "false")) {
            self->boolean = YAML_BOOLEAN_NONE;
          }
          else {
            croak("Invalid YAML::Safe->boolean value %s", SvPVX(value));
          }
        } else if (SvOK(value) && !SvTRUE(value)) {
          self->boolean = YAML_BOOLEAN_NONE;
        } else {
          croak("Invalid YAML::Safe->boolean value");
        }
    OUTPUT: self

char*
get_encoding (YAML *self, SV *value)
    CODE:
        switch (self->encoding) {
        case YAML_ANY_ENCODING:     RETVAL = "any"; break;
        case YAML_UTF8_ENCODING:    RETVAL = "utf8"; break;
        case YAML_UTF16LE_ENCODING: RETVAL = "utf16le"; break;
        case YAML_UTF16BE_ENCODING: RETVAL = "utf16be"; break;
        default: RETVAL = "utf8"; break;
        }
    OUTPUT: RETVAL

# for parser and emitter
SV*
encoding (YAML *self, char *value)
    CODE:
          if (strEQc(value, "any")) {
            self->encoding = YAML_ANY_ENCODING;
          }
          else if (strEQc(value, "utf8")) {
            self->encoding = YAML_UTF8_ENCODING;
          }
          else if (strEQc(value, "utf16le")) {
            self->encoding = YAML_UTF16LE_ENCODING;
          }
          else if (strEQc(value, "utf16be")) {
            self->encoding = YAML_UTF16BE_ENCODING;
          }
          else {
            croak("Invalid YAML::Safe->encoding value %s", value);
          }
    OUTPUT: self

char*
get_linebreak (YAML *self, SV *value)
    CODE:
        if (!self->emitter) {
          XSRETURN_UNDEF;
        }
        switch (self->emitter->line_break) {
        case YAML_ANY_BREAK:   RETVAL = "any"; break;
        case YAML_CR_BREAK:    RETVAL = "cr"; break;
        case YAML_LN_BREAK:    RETVAL = "ln"; break;
        case YAML_CRLN_BREAK:  RETVAL = "crln"; break;
        default:               RETVAL = "any"; break;
        }
    OUTPUT: RETVAL

SV*
linebreak (YAML *self, char *value)
    CODE:
        if (!self->emitter) {
          Newx(self->emitter,1,yaml_emitter_t);
          yaml_emitter_initialize(self->emitter);
          set_emitter_options(self, self->emitter);
        }
        if (strEQc(value, "any")) {
          yaml_emitter_set_break(self->emitter, YAML_ANY_BREAK);
        }
        else if (strEQc(value, "cr")) {
          yaml_emitter_set_break(self->emitter, YAML_CR_BREAK);
        }
        else if (strEQc(value, "ln")) {
          yaml_emitter_set_break(self->emitter, YAML_LN_BREAK);
        }
        else if (strEQc(value, "crln")) {
          yaml_emitter_set_break(self->emitter, YAML_CRLN_BREAK);
        }
        else {
          croak("Invalid YAML::Safe->linebreak value %s", value);
        }
    OUTPUT: self

UV
get_indent (YAML *self)
    ALIAS:
        get_indent          = 1
        get_wrapwidth       = 2
    CODE:
        # both are for the dumper only
        RETVAL = ix == 1 ? (self->emitter ?
                            self->emitter->best_indent : 2)
               : ix == 2 ? (self->emitter ?
                            self->emitter->best_width : 80)
               : 0;
    OUTPUT: RETVAL

SV*
indent (YAML *self, UV uv)
    ALIAS:
        indent          = 1
        wrapwidth       = 2
    CODE:
        if (!self->emitter) {
          Newx(self->emitter,1,yaml_emitter_t);
          yaml_emitter_initialize(self->emitter);
          set_emitter_options(self, self->emitter);
        }
        if (ix == 1)
          yaml_emitter_set_indent(self->emitter, uv);
        else if (ix == 2)
          yaml_emitter_set_width(self->emitter, uv);
    OUTPUT: self

