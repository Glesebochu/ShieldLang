%{
#include <iostream>
#include "y.tab.h" //This will include the Bison generated eader file with all 
                    //the token definitions
using namespace std;
    /*  The extern keyword specifies that the yylex function is defined elsewhere 
    (in the Flex-generated code), not in the current file. This tells the compiler
    that the definition will be found at link time.  */
extern int yylex();
extern FILE *yyin;
// Global variable to keep track of line numbers
int linenum = 1;
%}
%option noyywrap

%%
    // Rules Section

    /* Match newline characters and increment the line number */
[\n] { 
    ++linenum; //This will increment the global newline variable
    return NEWLINE;

}

    /* Match tab characters and print a message */
[\t] { 
    return TAB;
}

    /* Match floating-point numbers and print their value and length */
[0-9]+\.[0-9]+ { 
    //Convert the matched text to a floating point and assign it to 
    //yylval.fval, which is a union used to pass values from the scanner to 
    //the parser
    yylval.fval=atof(yytex);
    //Return the float token to the parser
    return FLOAT;
}

    /* Match integers and print their value */
[1-9][0-9]* { 
    //atoi (ASCII to integer) or atof (ASCII to float)
    yylval.ival = atoi(yytext);//Converts to integer instead
    return INTEGER;
}

    /* Match the exact string "echo" and print a message */
    /* Note that we have to place both echo and test above the string pattern
    otherwise there will be an error since these patterns are included in 
    the string pattern
    */
(echo) { 
    return ECHO;
}

    /* Match the exact string "test" and print a message */
test { 
    return TEST;
}

    /* Match alphanumeric strings and print their value */
[a-zA-Z0-9]+ { 
    //strdup(yytext) duplicates the string pointed to by yytext and 
    //returns a pointer to the new copy.
    //By assigning the duplicated string to yylval.sval, we pass the 
    //matched string value from the scanner (Flex) to the parser (Bison).
    yylval.sval = strdup(yytext);
    return STRING;
}

    /* Match any other single character and print it as an unrecognized token */
. { 
    cout << "Unrecognized token: " << yytext << endl; 
}
%%

