#ifndef YYERRCODE
#define YYERRCODE 256
#endif

#define BLIF_MODEL 257
#define BLIF_INPUTS 258
#define BLIF_OUTPUTS 259
#define BLIF_NAMES 260
#define BLIF_END 261
#define NAME 262
#define GATE_COVER 263
#define LINE_CONT 264
#define BLIF_SEQ 265
#define BLIF_FSM 266
typedef union {
  int ival;
  char* sval;
} YYSTYPE;
extern YYSTYPE yylval;
