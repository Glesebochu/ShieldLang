#include "ASTNode.h"

ASTNode::ASTNode(NodeType t, const std::string &val)
    : type(t), value(val), left(nullptr), right(nullptr) {}

// Destructor implementation
ASTNode::~ASTNode()
{
    // Recursively delete left and right child nodes to avoid memory leaks
    delete left;
    delete right;
}
