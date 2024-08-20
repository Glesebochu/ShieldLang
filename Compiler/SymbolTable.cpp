#include "SymbolTable.h"

// Initialize the global symbol table
std::unordered_map<std::string, SymbolInfo> symbolTable;

// Add a variable to the symbol table
void addToSymbolTable(const std::string &name, DataType type)
{
    if (symbolTable.find(name) == symbolTable.end())
    {
        SymbolInfo info;
        info.type = type;
        info.intValue = 0; // Default initialization
        symbolTable[name] = info;
    }
    else
    {
        std::cerr << "Error: Variable " << name << " already declared." << std::endl;
    }
}

// Update a variable's integer value in the symbol table
void updateSymbolValue(const std::string &name, int intValue)
{
    if (symbolTable.find(name) != symbolTable.end())
    {
        symbolTable[name].intValue = intValue;
    }
    else
    {
        std::cerr << "Error: Undefined variable " << name << std::endl;
    }
}

// Update a variable's string value in the symbol table
void updateSymbolValue(const std::string &name, const std::string &strValue)
{
    if (symbolTable.find(name) != symbolTable.end())
    {
        symbolTable[name].strValue = strValue;
    }
    else
    {
        std::cerr << "Error: Undefined variable " << name << std::endl;
    }
}

// Retrieve a variable's information from the symbol table
SymbolInfo getFromSymbolTable(const std::string &name)
{
    if (symbolTable.find(name) != symbolTable.end())
    {
        return symbolTable[name];
    }
    else
    {
        std::cerr << "Error: Undefined variable " << name << std::endl;
        return {TYPE_UNDEFINED, 0, ""};
    }
}

// Check if a variable is declared
bool isDeclared(const std::string &name)
{
    return symbolTable.find(name) != symbolTable.end();
}
