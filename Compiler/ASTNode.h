#ifndef ASTNODE_H
#define ASTNODE_H

#include <string>

enum NodeType
{
    NODE_NUMBER,
    NODE_STRING,
    NODE_BOOLEAN,
    NODE_OPERATOR,
    NODE_IDENTIFIER,
    NODE_ASSIGNMENT,
    NODE_SEQUENCE,
    NODE_IF,    // New node type for if statements
    NODE_ELSE,  // New node type for else statements
    NODE_ELIF,  // New node type for elif statements
    NODE_WHILE, // New node type for while loops
    NODE_FOR,   // New node type for for loops
    NODE_UNKNOWN,
    // ... other types
};

struct ASTNode
{
    NodeType type;
    std::string value;
    ASTNode *left;
    ASTNode *right;

    ASTNode(NodeType t, const std::string &val);
    ~ASTNode();
};

#endif // ASTNODE_H
