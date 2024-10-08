/* Definitions Section */
%{
#include <iostream> // Include iostream for input/output operations
#include <cstdlib>  // Include cstdlib for general-purpose functions (e.g., atoi, atof)
#include <cstdio>   // Include cstdio for file input/output functions
#include "ASTNode.h" //Include the AstNode.h
#include "SymbolTable.h" // Include the symbol table
#include "ASTTraversal.h"
#include <unordered_set>
using namespace std;

// Declare stuff from Flex that Bison needs to know about
void yyerror(const char *s); // Function for error handling
extern int yylex();          // Function generated by Flex to tokenize input
extern int linenum;          // Variable to keep track of line numbers
extern FILE *yyin;           // Variable to point to the input file
#define ASTNodePtr ASTNode*

// Declare root globally
ASTNodePtr root = nullptr;

// Declare helper functions
ASTNodePtr createAssignmentNode(const std::string &identifier, ASTNodePtr right);
ASTNodePtr createOperatorNode(const std::string &op, ASTNodePtr left, ASTNodePtr right);
ASTNodePtr createSequenceNode(ASTNodePtr first, ASTNodePtr second);
NodeType convertDataTypeToNodeType(DataType dataType);
std::unordered_set<std::string> conditionalAssignmentIdentifiers;
void removeUnnecessarySequenceNodes(ASTNode* &node);
%}

// Define YYSTYPE to include different types
%union {
    int ival;
    float fval;
    const char *sval;
    ASTNode* node;
    DataType type;  // Add type to the union to hold data types
}


/* Declare tokens to be used by Bison */
%token <ival> INTEGER 
%token <fval> FLOAT 
%token <sval> STRING 
%token <sval> IDENTIFIER
%token TEST

%type <node> expression operator operand
%type <type> data_type
%type <node> conditions definition body statement
%type <node> stmt if_stmt else_stmt elif_stmt elif_chain condition_expression or_expression and_expression
%type <node> not_expression comparison boolean
%type <sval> comparison_operators

// Keywords
%token KEHONE
%token LELAKEHONE
%token KALHONE
%token ESKEHONE
%token DELTA
%token MELS
%token MINEM
%token AQUM
%token QETEL
%token SIRA
%token YEMIQEYER
%token YEMAYQEYER
%token EWNET
%token HASET

// Data types
%token NOVEM
%token DECEM
%token DUO
%token UNUM
%token VERBUM

// Arithmetic Operators
%token ASSIGN
%token PLUS
%token MINUS
%token MULTIPLY
%token DIVIDE

// Comparison Operators
%token EQ
%token NE
%token LT 
%token GT 
%token LE 
%token GE 

// Logical Operators
%token AND 
%token OR 
%token NOT 


// Punctuation
%token SEMICOLON
%token COMMA
%token LPAREN
%token RPAREN
%token LBRACE
%token RBRACE

/* Declare precedence and associativity */
%left OR
%left AND
%right NOT
%nonassoc EQ NE LT GT LE GE
%left PLUS MINUS
%left MULTIPLY DIVIDE
%debug


/* Rules Section */
%%
/* The input rule matches the entire input. It consists of zero or more statements. */
input:
      /* empty */
    | input statement   // Input can be empty or can contain multiple statements
    ;



/* Define the statement rule for different types of statements. */
statement:
    expression SEMICOLON 

    // Error recovery for invalid statements
    | error SEMICOLON {
        std::cerr << "Error: Invalid statement at line " << linenum << ". Skipping to next statement." << std::endl;
        yyerrok; // Recover from the error and continue parsing
    }
    
    | stmt 
    /* | INTEGER { 
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
    | IDENTIFIER {
        cout << "Identifier detected: " << $1 << endl;
      } */
    ;

/* Expression rule with error recovery */
expression:
    IDENTIFIER ASSIGN operand operator operand {
        if (isDeclared($1)) {
            SymbolInfo assignee = getFromSymbolTable($1);
            
            NodeType leftNodeType;
            if ($3->type == NODE_IDENTIFIER) {
                leftNodeType = convertDataTypeToNodeType(getFromSymbolTable($3->value).type);
            } else {
                leftNodeType = $3->type;
            }
            
            NodeType rightNodeType;
            if ($5->type == NODE_IDENTIFIER) {
                rightNodeType = convertDataTypeToNodeType(getFromSymbolTable($5->value).type);
            } else {
                rightNodeType = $5->type;
            }

            if (convertDataTypeToNodeType(assignee.type) == leftNodeType && leftNodeType == rightNodeType) {
                // Perform constant folding if both operands are numbers
                if($3->type == NODE_NUMBER && $5->type == NODE_NUMBER){
                    double operandLeft = std::stod($3->value);
                    double operandRight = std::stod($5->value);
                    double result;

                    // Determine the operation
                    if ($4->value == "+") {
                        result = operandLeft + operandRight;
                    } else if ($4->value == "-") {
                        result = operandLeft - operandRight;
                    } else if ($4->value == "*") {
                        result = operandLeft * operandRight;
                    } else if ($4->value == "/") {
                        if (operandRight != 0) {
                            result = operandLeft / operandRight;
                        } else {
                            std::cerr << "Error: Division by zero at line " << linenum << std::endl;
                            result = 0; // Handle division by zero appropriately
                        }
                    } else {
                        std::cerr << "Error: Unknown operator " << $4->value << " at line " << linenum << std::endl;
                        result = 0; // Handle unknown operator case
                    }

                    // Create a new node with the constant result
                    ASTNodePtr resultNode = new ASTNode(NODE_NUMBER, std::to_string(result));
                    $$ = createAssignmentNode($1, resultNode);
                    root = (root == nullptr) ? $$ : createSequenceNode(root, $$);

                } else {
                    // Regular assignment without constant folding
                    $$ = createAssignmentNode($1, createOperatorNode($4->value, $3, $5));
                    root = (root == nullptr) ? $$ : createSequenceNode(root, $$);
                }
            } else {
                std::cerr << "Error: Type mismatch in operation or assignment to " << $1 << " at line " << linenum << std::endl;
            }
        } else {
            std::cerr << "Error: Variable " << $1 << " is not declared at line " << linenum << "." << std::endl;
        }
    }
    | IDENTIFIER ASSIGN operand {
        if (isDeclared($1)) {
            SymbolInfo assignee = getFromSymbolTable($1);
            
            NodeType operandNodeType;
            if ($3->type == NODE_IDENTIFIER) {
                operandNodeType = convertDataTypeToNodeType(getFromSymbolTable($3->value).type);
            } else {
                operandNodeType = $3->type;
            }

            if (convertDataTypeToNodeType(assignee.type) == operandNodeType) {
                $$ = createAssignmentNode($1, $3);
                root = (root == nullptr) ? $$ : createSequenceNode(root, $$);
            } else {
                std::cerr << "Error: Type mismatch in assignment to " << $1 << " at line " << linenum << std::endl;
            }
        } else {
            std::cerr << "Error: Variable " << $1 << " is not declared at line " << linenum << "." << std::endl;
        }
    }
    | data_type IDENTIFIER ASSIGN operand operator operand {
        if (!isDeclared($2)) {
            addToSymbolTable($2, $1);  // Add identifier with its type
            
            NodeType leftNodeType;
            if ($4->type == NODE_IDENTIFIER) {
                leftNodeType = convertDataTypeToNodeType(getFromSymbolTable($4->value).type);
            } else {
                leftNodeType = $4->type;
            }
            
            NodeType rightNodeType;
            if ($6->type == NODE_IDENTIFIER) {
                rightNodeType = convertDataTypeToNodeType(getFromSymbolTable($6->value).type);
            } else {
                rightNodeType = $6->type;
            }

            if (convertDataTypeToNodeType($1) == leftNodeType && leftNodeType == rightNodeType) {
                // Perform constant folding if both operands are numbers
                if($4->type == NODE_NUMBER && $6->type == NODE_NUMBER){
                    cout<<"constant folding is happening at line: "<<linenum<<endl;
                    double operandLeft = std::stod($4->value);
                    double operandRight = std::stod($6->value);
                    double result;

                    // Determine the operation
                    if ($5->value == "+") {
                        result = operandLeft + operandRight;
                    } else if ($5->value == "-") {
                        result = operandLeft - operandRight;
                    } else if ($5->value == "*") {
                        result = operandLeft * operandRight;
                    } else if ($5->value == "/") {
                        if (operandRight != 0) {
                            result = operandLeft / operandRight;
                        } else {
                            std::cerr << "Error: Division by zero at line " << linenum << std::endl;
                            result = 0; // Handle division by zero appropriately
                        }
                    } else {
                        std::cerr << "Error: Unknown operator " << $4->value << " at line " << linenum << std::endl;
                        result = 0; // Handle unknown operator case
                    }

                    // Create a new node with the constant result
                    ASTNodePtr resultNode = new ASTNode(NODE_NUMBER, std::to_string(result));
                    $$ = createAssignmentNode($2, resultNode);
                    root = (root == nullptr) ? $$ : createSequenceNode(root, $$);
                }
                else{
                    //Create assignment node without constant folding 
                    $$ = createAssignmentNode($2, createOperatorNode($5->value, $4, $6));
                    root = (root == nullptr) ? $$ : createSequenceNode(root, $$);
                }
            } else {
                std::cerr << "Error: Type mismatch in operation or assignment to " << $2 << " at line " << linenum << std::endl;
            }
        } else {
            std::cerr << "Error: Variable " << $2 << " already declared at line " << linenum << "." << std::endl;
        }
    }
    | data_type IDENTIFIER ASSIGN operand {
        if (!isDeclared($2)) {
            addToSymbolTable($2, $1);  // Add identifier with its type
            
            NodeType operandNodeType;
            if ($4->type == NODE_IDENTIFIER) {
                operandNodeType = convertDataTypeToNodeType(getFromSymbolTable($4->value).type);
            } else {
                operandNodeType = $4->type;
            }

            if (convertDataTypeToNodeType($1) == operandNodeType) {
                $$ = createAssignmentNode($2, $4);
                root = (root == nullptr) ? $$ : createSequenceNode(root, $$);
            } else {
                std::cerr << "Error: Type mismatch in assignment to " << $2 << " at line " << linenum << std::endl;
            }
        } else {
            std::cerr << "Error: Variable " << $2 << " already declared at line " << linenum << "." << std::endl;
        }
    }
    // Error recovery for invalid right-hand side expressions
    | IDENTIFIER ASSIGN error {
        std::cerr << "Error: Invalid right-hand side in assignment at line " << linenum << ". Skipping to next statement." << std::endl;
        yyerrok; // Recover from the error and continue parsing
    }
    | data_type IDENTIFIER ASSIGN error {
        std::cerr << "Error: Invalid right-hand side in declaration assignment at line " << linenum << ". Skipping to next statement." << std::endl;
        yyerrok; // Recover from the error and continue parsing
    }
    ;

/* Operand rule */
operand:
      INTEGER {
          $$ = new ASTNode(NODE_NUMBER, std::to_string($1));
      }
    | FLOAT {
          $$ = new ASTNode(NODE_NUMBER, std::to_string($1));
      }
    | IDENTIFIER {
          $$ = new ASTNode(NODE_IDENTIFIER, $1);
      }
    | STRING {
          $$ = new ASTNode(NODE_STRING, $1);  // Assuming strings are treated like identifiers
      }
    ;

/* Number rule */
num:
      INTEGER
    | FLOAT
    ;

/* Define operators */
operator:
    PLUS {
        $$ = new ASTNode(NODE_OPERATOR, "+");
    }
  | MINUS {
        $$ = new ASTNode(NODE_OPERATOR, "-");
    }
  | MULTIPLY {
        $$ = new ASTNode(NODE_OPERATOR, "*");
    }
  | DIVIDE {
        $$ = new ASTNode(NODE_OPERATOR, "/");
    }
  ;

/* Define what a statement should look like */
stmt:
    if_stmt {
        $$ = $1;  // $1 is the entire if_stmt node
        root = (root == nullptr) ? $$ : createSequenceNode(root, $$);
    }
    | if_stmt elif_chain else_stmt {
        ASTNode *ifNode = $1;  // $1 is the entire if_stmt node
        ASTNode *elifNode = $2; // $2 is the elif_chain
        ASTNode *elseNode = $3; // $3 is the else_stmt

        $$ = createSequenceNode(ifNode, createSequenceNode(elifNode, elseNode));
        root = (root == nullptr) ? $$ : createSequenceNode(root, $$);
    }
    | if_stmt else_stmt {
        ASTNode *ifNode = $1;  // $1 is the entire if_stmt node
        ASTNode *elseNode = $2; // $2 is the else_stmt

        $$ = createSequenceNode(ifNode, elseNode);
        root = (root == nullptr) ? $$ : createSequenceNode(root, $$);
    }
    | loop_stmt {
        cout << "Loop statement executed successfully at line: " <<linenum<<endl;
      }
    /* | flow_control */
    | function {
        cout << "Function evaluated at line: " <<linenum<< endl;
    }
    ;

/* Define what a function should look like */
function:
      SIRA return_type IDENTIFIER LPAREN params RPAREN function_definition
    ;

/* Define what parameters should look like */
params:
      data_type IDENTIFIER COMMA params
      | data_type IDENTIFIER
    ;

/* Define what a return type is */
return_type:
      NOVEM
      | DECEM
      | DUO
      | UNUM
      | VERBUM
      | MINEM
    ;

/* Define what a data type is */
data_type:
      NOVEM   { $$ = TYPE_INTEGER; }
    | DECEM   { $$ = TYPE_FLOAT; }
    | DUO     { $$ = TYPE_BOOLEAN; }
    | UNUM    { $$ = TYPE_BOOLEAN; }
    | VERBUM  { $$ = TYPE_STRING; }
    ;

/* Define what an if statement should look like */

if_stmt:
    KEHONE LPAREN conditions RPAREN definition {
        $$ = new ASTNode(NODE_IF, "if");
        $$->left = $3;  // $3 is the condition (conditions)
        $$->right = $5; // $5 is the body (definition)
    }
    ;

elif_stmt:
    LELAKEHONE LPAREN conditions RPAREN definition {
        $$ = new ASTNode(NODE_ELIF, "elif");
        $$->left = $3;  // $3 is the condition (conditions)
        $$->right = $5; // $5 is the body (definition)
    }
    ;

elif_chain:
    elif_stmt {
        $$ = $1;  // $1 is the entire elif_stmt node
    }
    | elif_stmt elif_chain {
        $$ = createSequenceNode($1, $2);  // $1 is the current elif_stmt, $2 is the rest of the elif_chain
    }
    ;

else_stmt:
    KALHONE definition {
        $$ = new ASTNode(NODE_ELSE, "else");
        $$->left = $2; // $2 is the body (definition)
    }

/* Define what a loop should look like */
loop_stmt:
      while_loop
    | for_loop
    ;

/* Define what a while loop should look like */
while_loop:
      ESKEHONE LPAREN conditions RPAREN definition
    ;

/* Define what a for loop should look like */
for_loop:
      DELTA LPAREN for_loop_declaration RPAREN definition
    ;

/* Define flow control */
/* flow_control:
      AQUM SEMICOLON
    | QETEL SEMICOLON
    ; */

/* Define what a for loop declaration should look like */
for_loop_declaration:
      for_loop_initialization SEMICOLON conditions SEMICOLON increment_decrement_list
    ;

/* Define what a for loop initialization should look like */
for_loop_initialization:
      data_type IDENTIFIER ASSIGN num
    | data_type IDENTIFIER ASSIGN num COMMA for_loop_initialization
    ;

/* Define what an increment/decrement list should look like */
increment_decrement_list:
      increment_decrement
    | increment_decrement_list COMMA increment_decrement
    ;

/* Define what an increment/decrement should look like */
increment_decrement:
      IDENTIFIER PLUS PLUS
    | IDENTIFIER MINUS MINUS
    ; 

/* Define what a condition should look like */
/* Define what a condition should look like */
conditions:
      condition_expression {
          $$ = $1;  // Pass the node up from the condition_expression
      }
    ;

/* Define what a condition expression should look like */
condition_expression:
      or_expression {
          $$ = $1;  // Pass the node up from the or_expression
      }
    | LPAREN condition_expression RPAREN {
          $$ = $2;  // Pass the inner expression up, ignoring the parentheses
      }
    ;

/* Handle OR operations */
or_expression:
      or_expression OR and_expression {
          $$ = new ASTNode(NODE_OPERATOR, "||");  // Create an OR node
          $$->left = $1;  // Left operand
          $$->right = $3; // Right operand
      }
    | and_expression {
          $$ = $1;  // Pass the node up from the and_expression
      }
    ;

/* Handle AND operations */
and_expression:
      and_expression AND not_expression {
          $$ = new ASTNode(NODE_OPERATOR, "&&");  // Create an AND node
          $$->left = $1;  // Left operand
          $$->right = $3; // Right operand
      }
    | not_expression {
          $$ = $1;  // Pass the node up from the not_expression
      }
    ;

/* Handle NOT operations */
not_expression:
      NOT not_expression {
          $$ = new ASTNode(NODE_OPERATOR, "!");  // Create a NOT node
          $$->left = $2;  // The expression to negate
          $$->right = nullptr;  // NOT has only one operand
      }
    | comparison {
          $$ = $1;  // Pass the node up from the comparison
      }
    ;

/* Handle comparisons */
comparison:
      operand comparison_operators operand {
          $$ = new ASTNode(NODE_OPERATOR, $2);  // Create a comparison node with the operator
          $$->left = $1;  // Left operand
          $$->right = $3; // Right operand
      }
    | boolean {
         $$ = $1;  // Pass the boolean node up boolean node
      }
    | IDENTIFIER {
          $$ = new ASTNode(NODE_IDENTIFIER, $1);  // Create an identifier node
      }
    ;

/* Define comparison operators */
comparison_operators:
      EQ  { $$ = "=="; }
    | NE  { $$ = "!="; }
    | LT  { $$ = "<"; }
    | GT  { $$ = ">"; }
    | LE  { $$ = "<="; }
    | GE  { $$ = ">="; }
    ;


/* Define what a definition should look like */
definition:
      LBRACE body RBRACE {
          $$ = $2;  // Pass the body node up as the definition
      }
    ;


/* Define what a definition should look like for a function (because functions can have a return statement) */
function_definition:
      LBRACE body RBRACE
    | LBRACE body return_statement RBRACE
    ;

/* Define what a return statement should look like for a function */
return_statement:
      MELS IDENTIFIER SEMICOLON
    | MELS STRING SEMICOLON
    | MELS FLOAT SEMICOLON
    | MELS INTEGER SEMICOLON
    | MELS boolean SEMICOLON
    ;

/* Define what a boolean should look like */
boolean:
      EWNET {
          $$ = new ASTNode(NODE_BOOLEAN, "true");  // Create a boolean node for true
      }
    | HASET {
          $$ = new ASTNode(NODE_BOOLEAN, "false"); // Create a boolean node for false
      }
    ;

/* Define what a body should look like for if statements and loops */
body:
      statement body {
          $$ = createSequenceNode($1, $2);  // Create a sequence of statements
      }
    | statement {
          $$ = $1;  // Single statement case
      }
    | /* empty */ {
          $$ = nullptr;  // Empty body case
      }
    ;
%%

/* User Code Section */

/* Function for handling errors, called by Bison when a syntax error is encountered */
void yyerror(const char *s)
{
    cerr << "Error: " << s << " at line " << linenum << endl;
}

/* Helper functions */
ASTNodePtr createAssignmentNode(const std::string &identifier, ASTNodePtr right) {
    ASTNodePtr assignNode = new ASTNode(NODE_ASSIGNMENT, "=");
    assignNode->left = new ASTNode(NODE_IDENTIFIER, identifier);
    assignNode->right = right;
    return assignNode;
}

ASTNodePtr createOperatorNode(const std::string &op, ASTNodePtr left, ASTNodePtr right) {
    ASTNodePtr opNode = new ASTNode(NODE_OPERATOR, op);
    opNode->left = left;
    opNode->right = right;
    return opNode;
}

ASTNodePtr createSequenceNode(ASTNodePtr first, ASTNodePtr second) {
    ASTNodePtr sequenceNode = new ASTNode(NODE_SEQUENCE, ";");
    sequenceNode->left = first;
    sequenceNode->right = second;
    first->parent=sequenceNode;
    second->parent=sequenceNode;
    return sequenceNode;
}

void printAST(ASTNode* node, int indent = 0) {
    if (!node) return;

    for (int i = 0; i < indent; ++i) std::cout << "  ";
    std::cout << "Node Type: " << node->type << ", Value: " << node->value << std::endl;

    printAST(node->left, indent + 1);
    printAST(node->right, indent + 1);
}

NodeType convertDataTypeToNodeType(DataType dataType) {
    switch (dataType) {
        case TYPE_INTEGER:
            return NODE_NUMBER;
        case TYPE_FLOAT:
            return NODE_NUMBER; // Assuming both integers and floats are treated as numbers in AST
        case TYPE_STRING:
            return NODE_STRING;
        case TYPE_BOOLEAN:
            return NODE_BOOLEAN;
        default:
            return NODE_UNKNOWN; // You can define NODE_UNKNOWN in your `ASTNode.h` or handle this case appropriately
    }
}

void collectConditionalAssignmentIdentifiers(ASTNode* node, bool insideConditional = false) {
    if (!node) return;

    // Check if we are entering a conditional block
    if (node->type == NODE_IF || node->type == NODE_ELIF || node->type == NODE_ELSE) {
        insideConditional = true;
    }

    // Only collect identifiers if we're inside a conditional block
    if (insideConditional && node->type == NODE_ASSIGNMENT && node->left && node->left->type == NODE_IDENTIFIER) {
        conditionalAssignmentIdentifiers.insert(node->left->value);
    }

    // Recursively collect from the left and right children
    collectConditionalAssignmentIdentifiers(node->left, insideConditional);
    collectConditionalAssignmentIdentifiers(node->right, insideConditional);
}

void removeAssignmentsOutsideConditionals(ASTNode* &node, bool insideConditional = false) {
    if (!node) return;

    // Determine if we are entering a new conditional block
    if (node->type == NODE_IF || node->type == NODE_ELIF || node->type == NODE_ELSE) {
        insideConditional = true;
    }

    // Traverse the left child first
    if (node->left) {
        removeAssignmentsOutsideConditionals(node->left, insideConditional);
    }

    // Traverse the right child
    if (node->right) {
        removeAssignmentsOutsideConditionals(node->right, insideConditional);
    }

    // Set the current node to nullptr if it's an assignment node and we're outside of a conditional block
    if (!insideConditional && node && node->type == NODE_ASSIGNMENT &&
        node->left && // Ensure node->left is not null
        conditionalAssignmentIdentifiers.find(node->left->value) != conditionalAssignmentIdentifiers.end()) {
        node = nullptr;
        return;  // Node is set to nullptr, no need to check further
    }


    // Check if this is an empty sequence node (;) and set it to nullptr if necessary
    if (node && node->type == NODE_SEQUENCE && !node->left && !node->right) {
        node = nullptr;
    }
}

void removeUnnecessarySequenceNodes(ASTNode* &node) {
    if (!node) return;

    // Print the current node before processing
    std::cout << "Processing Node: " << node->value << " (Type: " << node->type << ")" << std::endl;

    // Recursively process the left and right children first
    if (node->left) {
        std::cout << "Traversing left child of Node: " << node->value << std::endl;
        removeUnnecessarySequenceNodes(node->left);
    }
    if (node->right) {
        std::cout << "Traversing right child of Node: " << node->value << std::endl;
        removeUnnecessarySequenceNodes(node->right);
    }

    // Handle sequence nodes
    if (node->type == NODE_SEQUENCE) {
        if (!node->left || !node->right) {
            // If either child is missing, remove the sequence node and replace it with its existing child
            std::cout << "Removing sequence node: " << node->value << " (Type: " << node->type << ")" << std::endl;
            ASTNode* child = node->left ? node->left : node->right;
            ASTNode* temp = node;
            node = child;
            delete temp;
        }
    }

    // Print the state of the node after processing
    if (node) {
        std::cout << "Finished processing Node: " << node->value << " (Type: " << node->type << ")" << std::endl;
    } else {
        std::cout << "Node was deleted." << std::endl;
    }
}

/* Main function */
int main(int argc, char **argv)
{
    yydebug = 0;  // Enable debugging when it is 1
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
    if(result == 0 && root!=nullptr) {
        // Step 1: Collect identifiers from assignment nodes inside conditionals
        collectConditionalAssignmentIdentifiers(root);
        cout<<"Here at least"<<endl;
        // Step 2: Remove assignment nodes outside conditionals
        removeAssignmentsOutsideConditionals(root);

        //this simply removes all unnecessary nodes from the tree
        cout<<"Here though!!!"<<endl;
        /* removeUnnecessarySequenceNodes(root); */
        std::cout << "AST Root Node Type: " << root->type << std::endl;
        printAST(root);
        generateTASMFile(root,"TestProgramShieldlang");
        std::cout << "File parsed and TASM generated successfully." << std::endl;
    } else {
        std::cerr << "Parsing failed or root is null." << std::endl;
    }

    return 0;
}
