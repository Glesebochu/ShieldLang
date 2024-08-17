#include "ASTNode.h"
#include "SymbolTable.h"
#include <iostream>
#include <fstream>
#include <set>

void collectIdentifiers(ASTNode *node, std::set<std::string> &identifiers)
{
    if (!node)
        return;

    if (node->type == NODE_IDENTIFIER)
    {
        identifiers.insert(node->value);
    }

    collectIdentifiers(node->left, identifiers);
    collectIdentifiers(node->right, identifiers);
}

void generateDeclarations(const std::set<std::string> &identifiers, std::ofstream &outfile)
{
    outfile << "DATA SEGMENT" << std::endl;
    for (const auto &id : identifiers)
    {
        outfile << id << " DW ?" << std::endl; // Assuming each identifier is a word
    }
    outfile << "DATA ENDS" << std::endl
            << std::endl;
}

void generateTASM(ASTNode *node, std::ofstream &outfile)
{
    if (!node)
        return;

    switch (node->type)
    {
    case NODE_NUMBER:
        outfile << "MOV AX, " << node->value << std::endl;
        break;

    case NODE_IDENTIFIER:
        outfile << "MOV AX, [" << node->value << "]" << std::endl;
        break;
        
    case NODE_STRING:
        outfile << "MOV AX, \"" << node->value << "\"" << std::endl;
        break;

    case NODE_OPERATOR:
        generateTASM(node->left, outfile);
        outfile << "PUSH AX" << std::endl;
        generateTASM(node->right, outfile);
        outfile << "POP BX" << std::endl;
        if (node->value == "+")
        {
            outfile << "ADD AX, BX" << std::endl;
        }
        else if (node->value == "-")
        {
            outfile << "SUB AX, BX" << std::endl;
        }
        else if (node->value == "*")
        {
            outfile << "MUL BX" << std::endl;
        }
        else if (node->value == "/")
        {
            outfile << "DIV BX" << std::endl;
        }
        outfile << "MOV DX, AX" << std::endl;
        outfile << "CALL PrintNumber" << std::endl; // Assuming a PrintNumber function exists
        break;

    case NODE_ASSIGNMENT:
        generateTASM(node->right, outfile);                              // Process the right side first (expression)
        outfile << "MOV [" << node->left->value << "], AX" << std::endl; // Store the result in the variable
        addToSymbolTable(node->left->value, 0);                          // Optionally add the variable to the symbol table
        break;

    case NODE_SEQUENCE:
        generateTASM(node->left, outfile);  // Process the current statement
        generateTASM(node->right, outfile); // Process the next statement in sequence
        break;

    default:
        std::cerr << "Unknown AST node type" << std::endl;
    }
}

void generateTASMFile(ASTNode *root, const std::string &filename)
{
    std::ofstream outfile(filename + ".tasm");
    if (!outfile)
    {
        std::cerr << "Error opening file for writing: " << filename << ".tasm" << std::endl;
        return;
    }

    std::set<std::string> identifiers;
    collectIdentifiers(root, identifiers);

    generateDeclarations(identifiers, outfile);

    outfile << "CODE SEGMENT" << std::endl;
    generateTASM(root, outfile);
    outfile << "CODE ENDS" << std::endl;

    outfile.close();
}
