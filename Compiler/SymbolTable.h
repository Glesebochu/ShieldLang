#ifndef SYMBOLTABLE_H
#define SYMBOLTABLE_H

#include <unordered_map>
#include <string>
#include <iostream>

// Define an enum for different data types
enum DataType
{
    TYPE_INTEGER,
    TYPE_FLOAT,
    TYPE_STRING,
    TYPE_BOOLEAN,
    TYPE_UNDEFINED
};

// Structure to hold symbol information
struct SymbolInfo
{
    DataType type;
    int intValue;         // Can store int, float (as int), and boolean as int
    std::string strValue; // For string literals
};

// Define the symbol table as a global unordered_map
extern std::unordered_map<std::string, SymbolInfo> symbolTable;

// Function to add a variable to the symbol table
void addToSymbolTable(const std::string &name, DataType type);

// Function to update a variable's value in the symbol table
void updateSymbolValue(const std::string &name, int intValue);
void updateSymbolValue(const std::string &name, const std::string &strValue);

// Function to retrieve a variable's value from the symbol table
SymbolInfo getFromSymbolTable(const std::string &name);

// Function to check if a variable is declared in the symbol table
bool isDeclared(const std::string &name);

#endif // SYMBOLTABLE_H
