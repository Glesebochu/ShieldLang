/* Definitions Section */
%{
#include <iostream> // Include iostream for input/output operations
#include <cstdlib>  // Include cstdlib for general-purpose functions (e.g., atoi, atof)
#include <cstdio>   // Include cstdio for file input/output functions
using namespace std;

// Declare stuff from Flex that Bison needs to know about
void yyerror(const char *s); // Function for error handling
extern int yylex();          // Function generated by Flex to tokenize input
extern int linenum;          // Variable to keep track of line numbers
extern FILE *yyin;           // Variable to point to the input file
%}

// Define YYSTYPE to include different types
%union {
    int ival;
    float fval;
    char *sval;
}

/* Declare tokens to be used by Bison */
%token <ival> INTEGER 
%token <fval> FLOAT 
%token <sval> STRING 
%token TEST
%token NEWLINE 
%token UNKNOWN
%token IDENTIFIER

// Keywords
%token KEHONE
%token KALHONE
%token ESKEHONE
%token DELTA
%token MELS
%token AQUM
%token QETEL
%token SIRA
%token YEMIQEYER
%token YEMAYQEYER
%token EWNET
%token HASET

// Operators
%token EQ
%token ASSIGN
%token PLUS
%token MINUS
%token MULTIPLY
%token DIVIDE

// Punctuation
%token SEMICOLON
%token COMMA
%token LPAREN
%token RPAREN
%token LBRACE
%token RBRACE

/* Rules Section */
%%
/* The input rule matches the entire input. It consists of zero or more lines. */
input:
      /* empty */
    | input line   // Input can be empty or can contain multiple lines
    ;

/* The line rule matches a single line. */
line:
    statement    // A line contains a statement
     
    ;

/* Define the statement rule for different types of statements. */
statement:
      expression SEMICOLON 
    | INTEGER { 
          cout << "Integer value: " << $1 << endl; 
      }
    | FLOAT { 
          cout << "Float value: " << $1 << endl; 
      }
    | TEST { 
          cout << "Test command detected." << endl; 
      }
    | STRING { 
          cout << "String detected: " << $1 << endl; 
      }
    | UNKNOWN {
        cout << "Unknown Character detected" << endl;
      }
    ;

/* Define what expressions should look like */
expression:
      IDENTIFIER ASSIGN num operator num
    | IDENTIFIER ASSIGN num
    | IDENTIFIER ASSIGN IDENTIFIER operator num
    | IDENTIFIER ASSIGN num operator IDENTIFIER
    | IDENTIFIER ASSIGN IDENTIFIER operator IDENTIFIER
    | stmt
    ;

/* Define what a number can be */
num:
      INTEGER
    | FLOAT
    ;

/* Define operators */
operator:
      PLUS
    | MINUS
    | MULTIPLY
    | DIVIDE
    ;

/* Define what a statement should look like */
stmt:
      if_stmt{
        cout << "If statement executed successfully" <<endl;
      }
    | loop_stmt{
        cout << "Loop statement executed successfully" <<endl;
      }
    ;

/* Define what an if statement should look like */
if_stmt:
      KEHONE LPAREN operand logical_operator operand RPAREN definition
    ;

/* Define what a loop should look like */
loop_stmt:
      while_loop
    | for_loop
    ;

/* Define what a while loop should look like */
while_loop:
      ESKEHONE LPAREN operand logical_operator operand RPAREN definition
    ;

/* Define what a for loop should look like */
for_loop:
      DELTA LPAREN operand logical_operator operand RPAREN definition
    ;

/* Define what a definition should look like for a loop and an if statement */
definition:
      LBRACE body RBRACE
    ;

/* Define what a body should look like */
body:
      statement body
    | /* empty */
    ;

/* Define what an operand can be */
operand:
      INTEGER
    | FLOAT
    | IDENTIFIER
    | STRING
    ;

/* Define logical operators */
logical_operator:
      EQ
    ;

%%

/* User Code Section */

/* Function for handling errors, called by Bison when a syntax error is encountered */
void yyerror(const char *s)
{
    cerr << "Error: " << s << " at line " << linenum << endl;
}

/* Main function */
int main(int argc, char **argv)
{
    // If a filename is provided as a command-line argument, open the file
    if (argc > 1)
    {
        FILE *file = fopen(argv[1], "r");
        if (!file)
        {
            // If the file cannot be opened, print an error message and exit
            cerr << "Could not open file: " << argv[1] << endl;
            return 1;
        }
        // Set yyin to the file pointer so Flex reads from the file
        yyin = file;
    }
    else
    {
        // If no file is provided, read from standard input (e.g., keyboard)
        yyin = stdin;
    }
    // Call yyparse to start parsing the input
    int result = yyparse();
    if(result == 0){
        cout<<"File parsed successfully"<<endl;
    }
    return 0;
}
