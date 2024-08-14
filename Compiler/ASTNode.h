#ifndef ASTNODE_H
#define ASTNODE_H

#include <string>

enum NodeType
{
    NODE_OPERATOR,
    NODE_NUMBER,
    NODE_IDENTIFIER,
    NODE_ASSIGNMENT,
    NODE_SEQUENCE, // New type for sequence of statements
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
