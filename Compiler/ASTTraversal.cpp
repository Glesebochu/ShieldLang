#include "ASTNode.h"
#include "SymbolTable.h"
#include <iostream>

void generateTASM(ASTNode *node)
{
    if (!node)
        return;

    switch (node->type)
    {
    case NODE_NUMBER:
        std::cout << "MOV AX, " << node->value << std::endl;
        break;

    case NODE_IDENTIFIER:
        std::cout << "MOV AX, [" << node->value << "]" << std::endl;
        break;

    case NODE_OPERATOR:
        generateTASM(node->left);
        std::cout << "PUSH AX" << std::endl;
        generateTASM(node->right);
        std::cout << "POP BX" << std::endl;
        if (node->value == "+")
        {
            std::cout << "ADD AX, BX" << std::endl;
        }
        else if (node->value == "-")
        {
            std::cout << "SUB AX, BX" << std::endl;
        }
        else if (node->value == "*")
        {
            std::cout << "MUL BX" << std::endl;
        }
        else if (node->value == "/")
        {
            std::cout << "DIV BX" << std::endl;
        }
        break;

    case NODE_ASSIGNMENT:
        generateTASM(node->right);                                         // Process the right side first (expression)
        std::cout << "MOV [" << node->left->value << "], AX" << std::endl; // Store the result in the variable
        addToSymbolTable(node->left->value, 0);                            // Optionally add the variable to the symbol table
        break;

    default:
        std::cerr << "Unknown AST node type" << std::endl;
    }
}
