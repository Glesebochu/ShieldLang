#include "ASTNode.h"
#include "SymbolTable.h"
#include <iostream>
#include <fstream>
#include <set>

void collectIdentifiersAndStrings(ASTNode *node, std::set<std::string> &identifiers, std::set<std::string> &strings)
{
    if (!node)
        return;

    if (node->type == NODE_IDENTIFIER)
    {
        identifiers.insert(node->value);
    }
    else if (node->type == NODE_STRING)
    {
        strings.insert(node->value);
    }

    collectIdentifiersAndStrings(node->left, identifiers, strings);
    collectIdentifiersAndStrings(node->right, identifiers, strings);
}

void generateDeclarations(const std::set<std::string> &identifiers, const std::set<std::string> &strings, std::ofstream &outfile)
{
    outfile << "DATA SEGMENT" << std::endl;
    for (const auto &id : identifiers)
    {
        outfile << id << " DW ?" << std::endl; // Assuming each identifier is a word (16-bit)
    }
    for (const auto &str : strings)
    {
        outfile << str << " DB '" << str << "', 0" << std::endl; // Define strings as null-terminated
    }
    outfile << "DATA ENDS" << std::endl
            << std::endl;
}

void generateTASM(ASTNode *node, std::ofstream &outfile)
{
    if (!node)
        return;

    int intValue = 0; // Declare outside the switch statement

    switch (node->type)
    {
    case NODE_NUMBER:
        try
        {
            intValue = static_cast<int>(std::stof(node->value)); // Convert to integer
        }
        catch (const std::exception &e)
        {
            std::cerr << "Error converting number: " << node->value << std::endl;
            return;
        }
        outfile << "MOV AX, " << intValue << std::endl;
        break;

    case NODE_IDENTIFIER:
        outfile << "MOV AX, [" << node->value << "]" << std::endl;
        break;

    case NODE_STRING:
        // Load the address of the string literal
        outfile << "LEA SI, " << node->value << std::endl;
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
        outfile << "CALL PrintNumber" << std::endl;
        break;

    case NODE_ASSIGNMENT:
        generateTASM(node->right, outfile);
        if (node->right->type == NODE_STRING)
        {
            outfile << "MOV [" << node->left->value << "], SI" << std::endl; // Store string address
        }
        else
        {
            outfile << "MOV [" << node->left->value << "], AX" << std::endl; // Store the result in the variable
        }
        addToSymbolTable(node->left->value, 0);
        break;

    case NODE_SEQUENCE:
        generateTASM(node->left, outfile);
        generateTASM(node->right, outfile);
        break;

    default:
        std::cerr << "Unknown AST node type" << std::endl;
    }
}

void generateTASMFile(ASTNode *root, const std::string &filename)
{
    std::ofstream outfile(filename + ".asm");
    if (!outfile)
    {
        std::cerr << "Error opening file for writing: " << filename << ".asm" << std::endl;
        return;
    }

    std::set<std::string> identifiers;
    std::set<std::string> strings;
    collectIdentifiersAndStrings(root, identifiers, strings);

    generateDeclarations(identifiers, strings, outfile);

    outfile << "CODE SEGMENT" << std::endl;
    outfile << "ASSUME CS:CODE, DS:DATA" << std::endl;
    outfile << "START:" << std::endl;
    outfile << "MOV AX, DATA" << std::endl;
    outfile << "MOV DS, AX" << std::endl;

    generateTASM(root, outfile);

    // PrintNumber procedure
    outfile << "PrintNumber PROC" << std::endl;
    outfile << "    PUSH AX" << std::endl;
    outfile << "    PUSH BX" << std::endl;
    outfile << "    PUSH CX" << std::endl;
    outfile << "    PUSH DX" << std::endl;

    outfile << "    MOV CX, 10" << std::endl; // Base 10
    outfile << "    XOR BX, BX" << std::endl; // BX will hold the result string

    outfile << "    CMP DX, 0" << std::endl;
    outfile << "    JZ PrintZero" << std::endl;

    outfile << "ConvertLoop:" << std::endl;
    outfile << "    XOR AX, AX" << std::endl;
    outfile << "    DIV CX" << std::endl;      // Divide DX by 10, quotient in AX, remainder in DX
    outfile << "    ADD DL, '0'" << std::endl; // Convert remainder to ASCII
    outfile << "    PUSH DX" << std::endl;     // Push remainder onto stack
    outfile << "    INC BX" << std::endl;      // Increment BX for string length
    outfile << "    MOV DX, AX" << std::endl;  // Move quotient to DX
    outfile << "    CMP DX, 0" << std::endl;
    outfile << "    JNZ ConvertLoop" << std::endl;

    outfile << "PrintLoop:" << std::endl;
    outfile << "    POP DX" << std::endl;
    outfile << "    MOV AH, 2" << std::endl;
    outfile << "    INT 21H" << std::endl; // Print character in DL
    outfile << "    DEC BX" << std::endl;
    outfile << "    JNZ PrintLoop" << std::endl;

    outfile << "    JMP PrintDone" << std::endl;

    outfile << "PrintZero:" << std::endl;
    outfile << "    MOV DL, '0'" << std::endl;
    outfile << "    MOV AH, 2" << std::endl;
    outfile << "    INT 21H" << std::endl; // Print '0'

    outfile << "PrintDone:" << std::endl;
    outfile << "    POP DX" << std::endl;
    outfile << "    POP CX" << std::endl;
    outfile << "    POP BX" << std::endl;
    outfile << "    POP AX" << std::endl;
    outfile << "    RET" << std::endl;
    outfile << "PrintNumber ENDP" << std::endl;

    outfile << "MOV AH, 4CH" << std::endl; // Terminate program
    outfile << "INT 21H" << std::endl;

    outfile << "CODE ENDS" << std::endl;
    outfile << "END START" << std::endl;

    outfile.close();
}
