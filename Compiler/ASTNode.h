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
    NODE_IF,    
    NODE_ELSE,  
    NODE_ELIF,  
    NODE_WHILE, 
    NODE_FOR,   
    NODE_UNKNOWN,
};

struct ASTNode
{
    NodeType type;
    std::string value;
    ASTNode *left;
    ASTNode *right;
    ASTNode *parent;

    ASTNode(NodeType t, const std::string &val);
    ~ASTNode();
};

#endif // ASTNODE_H
