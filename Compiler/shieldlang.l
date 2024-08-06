%{
#include <iostream>
#include <cstdlib>
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

    /* Match newline characters and increment the line number */
[\n] { 
    ++linenum; // This will increment the global newline variable
    return NEWLINE;
}

    /*Define regular expressions for operators */
[+\-*/] {
    return OPERATOR;
}
    /*Match an Equal to sign*/
= {
    return EQ;
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
[1-9][0-9]* { 
    // atoi (ASCII to integer)
    yylval.ival = atoi(yytext); // Convert the matched text to an integer
    return INTEGER;
}


    /* Match the exact string "test" */
test { 
    return TEST;
}

    /* Match alphanumeric strings and return a token */
[a-zA-Z0-9]+ { 
    // strdup(yytext) duplicates the string pointed to by yytext and 
    // returns a pointer to the new copy.
    // By assigning the duplicated string to yylval.sval, we pass the 
    // matched string value from the scanner (Flex) to the parser (Bison).
    yylval.sval = strdup(yytext);
    return STRING;
}
    /* Match identifiers */
[a-zA-Z_][a-zA-Z0-9_]+ {
    return IDENTIFIER;
}

    /* Match any other single character and print it as an unrecognized token */
. { 
    return UNKNOWN; 
}
%%

/* Main function is not needed here as it will be in the Bison file */
