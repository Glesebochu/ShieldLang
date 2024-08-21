#include "ASTNode.h"
#include "SymbolTable.h"
#include <iostream>
#include <fstream>
#include <set>
#include <algorithm>

// Utility function to remove spaces from string labels
std::string removeSpaces(const std::string &str)
{
    std::string result = str;
    result.erase(std::remove(result.begin(), result.end(), ' '), result.end());
    return result;
}

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
        outfile << id << " DW ?" << std::endl;                             // Declare the identifier
        outfile << "msg_" << id << " DB '" << id << " is $'" << std::endl; // Define messages for each identifier
    }
    for (const auto &str : strings)
    {
        std::string sanitizedLabel = removeSpaces(str);
        outfile << sanitizedLabel << " DB '" << str << " $' , 0" << std::endl; // Declare the string with spaces removed from the label
    }
    outfile << "new_line DB 0Dh, 0Ah, '$'" << std::endl; // New line characters
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
    case NODE_IF:
    {
        static int ifCount = 0;
        int currentIf = ifCount++;
        std::string elseLabel = "ELSE_" + std::to_string(currentIf);
        std::string endIfLabel = "ENDIF_" + std::to_string(currentIf);

        // Generate code for the condition
        generateTASM(node->left, outfile);
        outfile << "CMP AX, 0" << std::endl;
        outfile << "JE " << elseLabel << std::endl;

        // Generate code for the if body
        generateTASM(node->right->left, outfile);
        outfile << "JMP " << endIfLabel << std::endl;

        // Generate code for the else body if it exists
        outfile << elseLabel << ":" << std::endl;
        if (node->right->right)
        {
            generateTASM(node->right->right, outfile);
        }
        outfile << endIfLabel << ":" << std::endl;
        break;
    }
    case NODE_ELSE:
    {
        // Handle else body generation
        generateTASM(node->left, outfile);
        break;
    }
    case NODE_WHILE:
    {
        static int whileCount = 0;
        int currentWhile = whileCount++;
        std::string startWhileLabel = "WHILE_START_" + std::to_string(currentWhile);
        std::string endWhileLabel = "WHILE_END_" + std::to_string(currentWhile);

        outfile << startWhileLabel << ":" << std::endl;
        generateTASM(node->left, outfile); // Generate condition
        outfile << "CMP AX, 0" << std::endl;
        outfile << "JE " << endWhileLabel << std::endl;

        generateTASM(node->right, outfile); // Generate loop body
        outfile << "JMP " << startWhileLabel << std::endl;
        outfile << endWhileLabel << ":" << std::endl;
        break;
    }
    case NODE_FOR:
    {
        static int forCount = 0;
        int currentFor = forCount++;
        std::string startForLabel = "FOR_START_" + std::to_string(currentFor);
        std::string endForLabel = "FOR_END_" + std::to_string(currentFor);

        // Assuming left->left is initialization, left->right is condition, and right is the increment
        generateTASM(node->left->left, outfile); // Initialization
        outfile << startForLabel << ":" << std::endl;

        generateTASM(node->left->right, outfile); // Condition
        outfile << "CMP AX, 0" << std::endl;
        outfile << "JE " << endForLabel << std::endl;

        generateTASM(node->right, outfile);              // Body
        generateTASM(node->left->right->right, outfile); // Increment
        outfile << "JMP " << startForLabel << std::endl;
        outfile << endForLabel << ":" << std::endl;
        break;
    }
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
    {
        // Load the address of the string literal and print it
        std::string sanitizedLabel = removeSpaces(node->value);
        outfile << "LEA DX, " << sanitizedLabel << std::endl;
        outfile << "CALL print_string" << std::endl;
        outfile << "LEA DX, new_line" << std::endl; // Print a new line after each string
        outfile << "CALL print_string" << std::endl;
    }
    break;

    case NODE_OPERATOR:
        // Evaluate the left operand (this should be the dividend)
        generateTASM(node->left, outfile);
        outfile << "PUSH AX" << std::endl; // Save the dividend in AX

        // Evaluate the right operand (this should be the divisor)
        generateTASM(node->right, outfile);
        outfile << "MOV BX, AX" << std::endl; // Move the divisor into BX

        // Retrieve the dividend back into AX
        outfile << "POP AX" << std::endl;

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
            outfile << "XOR DX, DX" << std::endl; // Clear DX before division
            outfile << "DIV BX" << std::endl;     // Divide AX by BX (dividend in AX, divisor in BX)
        }
        break;

    case NODE_ASSIGNMENT:
        if (node->right->type == NODE_STRING)
        {
            std::string sanitizedLabel = removeSpaces(node->right->value);
            outfile << "LEA SI, " << sanitizedLabel << std::endl;
            outfile << "MOV [" << node->left->value << "], SI" << std::endl; // Store string address

            // Print the variable name, then the string value
            outfile << "LEA DX, msg_" << node->left->value << std::endl;
            outfile << "CALL print_string" << std::endl;
            outfile << "LEA DX, " << sanitizedLabel << std::endl;
            outfile << "CALL print_string" << std::endl;
            outfile << "LEA DX, new_line" << std::endl; // Print a new line after the string
            outfile << "CALL print_string" << std::endl;
        }
        else
        {
            generateTASM(node->right, outfile);
            outfile << "MOV [" << node->left->value << "], AX" << std::endl; // Store the result in the variable

            // Print the variable name and its value after the assignment
            outfile << "LEA DX, msg_" << node->left->value << std::endl;
            outfile << "CALL print_string" << std::endl;
            outfile << "MOV AX, [" << node->left->value << "]" << std::endl;
            outfile << "CALL PrintNumber" << std::endl;
            outfile << "LEA DX, new_line" << std::endl; // Print a new line after the number
            outfile << "CALL print_string" << std::endl;
        }

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

    // PrintString procedure
    outfile << "JMP ProgramEnd" << std::endl;
    outfile << "print_string PROC" << std::endl;
    outfile << "    MOV AH, 09h" << std::endl;
    outfile << "    INT 21h" << std::endl;
    outfile << "    RET" << std::endl;
    outfile << "print_string ENDP" << std::endl;

    // PrintNumber procedure
    outfile << "PrintNumber PROC" << std::endl;
    outfile << "    XOR BX, BX" << std::endl; // Clear BX to be used as a counter
    outfile << "    MOV CX, 10" << std::endl; // Set up base 10 for division

    outfile << "    CMP AX, 0" << std::endl;
    outfile << "    JZ PrintZero" << std::endl;

    outfile << "ConvertLoop:" << std::endl;
    outfile << "    XOR DX, DX" << std::endl;  // Clear DX before division
    outfile << "    DIV CX" << std::endl;      // Divide AX by 10, remainder in DX, quotient in AX
    outfile << "    ADD DL, '0'" << std::endl; // Convert remainder to ASCII
    outfile << "    PUSH DX" << std::endl;     // Push the ASCII digit onto the stack
    outfile << "    INC BX" << std::endl;      // Increment BX (which is used as a loop counter)
    outfile << "    CMP AX, 0" << std::endl;
    outfile << "    JNZ ConvertLoop" << std::endl;

    outfile << "PrintLoop:" << std::endl;
    outfile << "    POP DX" << std::endl;
    outfile << "    MOV AH, 2" << std::endl;
    outfile << "    INT 21H" << std::endl; // Print character in DL
    outfile << "    DEC BX" << std::endl;
    outfile << "    JNZ PrintLoop" << std::endl;
    outfile << "    LEA DX, new_line" << std::endl; // Print a new line
    outfile << "    CALL print_string" << std::endl;

    outfile << "    JMP PrintDone" << std::endl;

    outfile << "PrintZero:" << std::endl;
    outfile << "    MOV DL, '0'" << std::endl;
    outfile << "    MOV AH, 2" << std::endl;
    outfile << "    INT 21H" << std::endl;

    outfile << "PrintDone:" << std::endl;
    outfile << "    RET" << std::endl;
    outfile << "PrintNumber ENDP" << std::endl;

    outfile << "ProgramEnd:" << std::endl;
    outfile << "MOV AH, 4CH" << std::endl; // Terminate program
    outfile << "INT 21H" << std::endl;

    outfile << "CODE ENDS" << std::endl;
    outfile << "END START" << std::endl;

    outfile.close();
}
