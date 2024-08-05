%{
#include <iostream>
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
    cout << "The Line Number is " << ++linenum << endl; 
}

    /* Match tab characters and print a message */
[\t] { 
    cout << "Whitespace" << endl; 
}

    /* Match floating-point numbers and print their value and length */
[0-9]+\.[0-9]+ { 
    cout << "A Floating point has been detected with value: " << yytext << " With length: " << yyleng << endl; 
}

    /* Match integers and print their value */
[1-9][0-9]* { 
    cout << "An Integer has been detected with value: " << yytext << endl; 
}

    /* Match the exact string "echo" and print a message */
    /* Note that we have to place both echo and test above the string pattern
    otherwise there will be an error since these patterns are included in 
    the string pattern
    */
(echo) { 
    cout << "Echo pattern matched" << endl; 
}

    /* Match the exact string "test" and print a message */
test { 
    cout << "Test pattern matched" << endl; 
}

    /* Match alphanumeric strings and print their value */
[a-zA-Z0-9]+ { 
    cout << "A string has been detected with value: " << yytext << endl; 
}

    /* Match any other single character and print it as an unrecognized token */
. { 
    cout << "Unrecognized token: " << yytext << endl; 
}
%%

// User Code Section

int main(int, char **)
{
    const char *filename = "inputFile.sl";
    FILE *input = fopen(filename,"r");
    if(!input){
        cout<<"File is invalid"<<endl;
        return -1;
    }
    yyin = input;

    // Call yylex in a loop to process the input
    while (yylex());
    return 0;
}