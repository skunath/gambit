
%{
/* $Id$ */
#include <ctype.h>
#include "gmisc.h"
#include "gambitio.h"
#include "glist.h"
#include "rational.h"
#include "nfg.h"

%}

%name NfgFileReader

%define MEMBERS      gInput &infile;  \
                     gString last_name;  gRational last_rational; \
                     gString title; \
                     Nfg<double> *& Ndbl;  \
                     Nfg<gRational> *& Nrat; \
                     int ncont, pl, cont; \
                     gList<gString> names; \
                     gList<gRational> numbers; \
                     gList<gString> stratnames; \
                     \
                     virtual bool CreateNfg(const gList<gString> &, \
					    const gList<gRational> &, \
					    const gList<gString> &) = 0; \
                     virtual void SetPayoff(int cont, int pl, \
					    const gRational &) = 0; \
                     virtual ~NfgFileReader();

%define CONSTRUCTOR_PARAM     gInput &f, Nfg<double> *& Nd, Nfg<gRational> *& Nr

%define CONSTRUCTOR_INIT      : infile(f), Ndbl(Nd), Nrat(Nr)

%token LBRACE
%token RBRACE
%token SLASH
%token NAME
%token NUMBER

%%

nfgfile:      header 
              { if (!CreateNfg(names, numbers, stratnames))  return 1;
		names.Flush();  numbers.Flush();  stratnames.Flush();
	        if (Ndbl)
                  Ndbl->GameForm().SetTitle(title);
                else
                  Nrat->GameForm().SetTitle(title);
              }              
              body  { return 0; }

header:       NAME { title = last_name; pl = 0; }  playerlist  stratlist

playerlist:   LBRACE players RBRACE

players:      player
       |      players player

player:       NAME   { names.Append(last_name); }

stratlist:    dimensionality
         |    stratnamelist

stratnamelist:  LBRACE playerstrlist RBRACE

playerstrlist:   playerstrats
             |   playerstrlist playerstrats

playerstrats:  LBRACE { pl++; numbers.Append(0); } stratnames RBRACE

stratnames:   stratname
          |   stratnames stratname

stratname:    NAME  { stratnames.Append(last_name); numbers[pl] += 1; }


dimensionality:   LBRACE intlist RBRACE

intlist:      integer
       |      intlist integer

integer:      NUMBER  { numbers.Append(last_rational); }


body:         { cont = 1;
                pl = 1; }
              payofflist

payofflist:   payoff
          |   payofflist payoff

payoff:       NUMBER
              { if (Ndbl)   {
                  if (pl > Ndbl->NumPlayers())   {
		    cont++;
		    if (cont <= ncont)  
	              Ndbl->GameForm().NewOutcome();
		    pl = 1;
                  }
                }
                else  {
                  if (pl > Nrat->NumPlayers())   {
		    cont++;
		    if (cont <= ncont)  
	              Nrat->GameForm().NewOutcome();
		    pl = 1;
		  }
                } 
		if (cont > ncont)  YYERROR;
		SetPayoff(cont, pl, last_rational);
		pl++;
	      }

%%

void NfgFileReader::yyerror(char *)    { }

int NfgFileReader::yylex(void)
{
  char c, d;

  while (1)  {
    do  {
      infile >> c;
    }  while (isspace(c));
 
    if (c == '/')   {
      infile >> d;
      if (d == '/')  {
	do  {
	  infile >> d;
	}  while (d != '\n');
      }
      else if (d == '*')  {
	int done = 0;
	while (!done)  {
	  do {
	    infile >> d;
	  }  while (d != '*');
	  infile >> d;
	  if (d == '/')   done = 1;
	}
      }
      else  {
	infile.unget(d);
	return SLASH;
      }
    }
    else
      break;
  }

  if (isalpha(c))   return c;

  if (c == '"')  {
    infile.unget(c);
    infile >> last_name;

    return NAME;
  }
  else if (isdigit(c) || c == '-')   {
    infile.unget(c);
    infile >> last_rational;
    return NUMBER;
  }
  
  switch (c)   {
    case '{':  return LBRACE;
    case '}':  return RBRACE;
    default:   return c;
  }
}


NfgFileReader::~NfgFileReader()   { }

void NfgFileType(gInput &f, bool &valid, DataType &type)
{
  f.seekp(0);
  static char *prologue = { "NFG 1 " };
  char c;
  for (unsigned int i = 0; i < strlen(prologue); i++)   {
    f.get(c);
    if (c != prologue[i])   {
      valid = false;
      return;
    }
  }

  f.get(c);
  switch (c)   {
    case 'D':
      valid = true;
      type = DOUBLE;
      return;
    case 'R':
      valid = true;
      type = RATIONAL;
      return;
    default:
      valid = false;
      return;
  }
}

// for NfgFile<T>
#include "readnfg.imp"

int ReadNfgFile(gInput &f, Nfg<double> *& Ndbl, Nfg<gRational> *& Nrat)
{
  assert(!Ndbl && !Nrat);

  bool valid;
  DataType type;
  NfgFileType(f, valid, type);

  if (!valid)   return 0;

  if (type == DOUBLE)   {
    NfgFile<double> R(f, Ndbl);

    if (R.Parse())   {
      if (Ndbl)   { delete Ndbl;  Ndbl = 0; }
      return 0;
    }
  }
  else  {
    NfgFile<gRational> R(f, Nrat);

    if (R.Parse())   {
      if (Nrat)   { delete Nrat;  Nrat = 0; }
      return 0;
    }
  }
   
  return 1;
}

