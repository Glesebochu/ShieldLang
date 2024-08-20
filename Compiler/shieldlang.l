%{
#include <iostream>
#include <cstdlib>
#include "ASTNode.h"
#include "SymbolTable.h"
#include "shieldlang.tab.h" // This includes the Bison-generated header file with all the token definitions
using namespace std;

/* The extern keyword specifies that the yylex function is defined elsewhere 
(in the Flex-generated code), not in the current file. This tells the compiler
that the definition will be found at link time. */
extern int yylex();
extern FILE *yyin; // Declare the external file input pointer
extern int linenum=1; // Declare the external line number variable
%}

%option noyywrap

%%
    /* Rules Section */

    /* Data Types */
"novem"         {return NOVEM;}
"decem"         {return DECEM;}
"duo"           {return DUO;}
"unum"          {return UNUM;}
"verbum"        {return VERBUM;}

    /* Keywords */
"kehone"         { return KEHONE; }
"kalhone"         { return KALHONE; }
"lelakehone"       { return LELAKEHONE; }
"eskehone"       { return ESKEHONE; }
"delta"         { return DELTA; }
"mels"        { return MELS; }
"minem"        { return MINEM; }
"aqum"       { return AQUM; }
"qetel"          { return QETEL; }
"sira"         { return SIRA; }
"yemayqeyer"        { return YEMAYQEYER; }
"ewnet"          { return EWNET; }
"haset"          { return HASET; }

    /* Arithmetic Operators */
"="             { return ASSIGN; }
"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MULTIPLY; }
"/"             { return DIVIDE; }

    /* Comparison Operators */
"=="            { return EQ; }
"!="            { return NE; }
"<"             { return LT; }
">"             { return GT; }
"<="            { return LE; }
">="            { return GE; }

    /* Logical Operators */
"&&"            { return AND; }
"||"            { return OR; }
"!"             { return NOT; }

    /* special symbols */
";"             { return SEMICOLON; }
","             { return COMMA; }
"("             { return LPAREN; }
")"             { return RPAREN; }
"{"             { return LBRACE; }
"}"             { return RBRACE; }

    /* Match newline characters and increment the line number */
[\n] { 
    ++linenum; // This will increment the global newline variable
}



[ \t]+  { /* ignore whitespace */ }

    /* Match floating-point numbers and return a token */
[0-9]+\.[0-9]+ { 
    // Convert the matched text to a floating point and assign it to 
    // yylval.fval, which is a union used to pass values from the scanner to 
    // the parser
    yylval.fval = atof(yytext);
    // Return the float token to the parser
    return FLOAT;
}

    /* Match integers and return a token */
[-]?([1-9][0-9]*|0) { 
    // atoi (ASCII to integer)
    yylval.ival = atoi(yytext); // Convert the matched text to an integer
    return INTEGER;
}



    /* Match the exact string "test" */
test { 
    return TEST;
}
    /* Match identifiers */
[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.sval=strdup(yytext);
    return IDENTIFIER;
}

    /* Match alphanumeric strings and return a token */
\"[^\"]*\" { 
    // strdup(yytext) duplicates the string pointed to by yytext and 
    // returns a pointer to the new copy.
    // By assigning the duplicated string to yylval.sval, we pass the 
    // matched string value from the scanner (Flex) to the parser (Bison).
  yytext[yyleng - 1] = '\0'; // Remove the end quote
    yylval.sval = strdup(yytext + 1); // Duplicate string excluding the start quote
    if (yylval.sval) {
        return STRING;
    } else {
        cout<<"Memory allocation failed"<<endl;
        return 0; // Return 0 to indicate error
    }
}


    /* Comments */
"//".*          { /* Ignore single-line comments */ }
"/*"([^*]|\*[^/])*"*/" { /* Ignore multi-line comments */ }


%%

/* Main function is not needed here as it will be in the Bison file */
