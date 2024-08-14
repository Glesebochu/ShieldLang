#ifndef SYMBOLTABLE_H
#define SYMBOLTABLE_H

#include <unordered_map>
#include <string>
#include <iostream>

// Define the symbol table as a global unordered_map
extern std::unordered_map<std::string, int> symbolTable;

// Function to add a variable to the symbol table
void addToSymbolTable(const std::string &name, int value);

// Function to retrieve a variable's value from the symbol table
int getFromSymbolTable(const std::string &name);

#endif // SYMBOLTABLE_H
