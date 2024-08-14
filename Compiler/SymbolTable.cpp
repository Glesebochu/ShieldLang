#include "SymbolTable.h"

// Initialize the global symbol table
std::unordered_map<std::string, int> symbolTable;

// Add a variable to the symbol table
void addToSymbolTable(const std::string &name, int value)
{
    symbolTable[name] = value;
}

// Retrieve a variable's value from the symbol table
int getFromSymbolTable(const std::string &name)
{
    if (symbolTable.find(name) != symbolTable.end())
    {
        return symbolTable[name];
    }
    else
    {
        std::cerr << "Error: Undefined variable " << name << std::endl;
        return 0;
    }
}
