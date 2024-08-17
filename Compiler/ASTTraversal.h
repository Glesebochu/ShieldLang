#ifndef ASTTRAVERSAL_H
#define ASTTRAVERSAL_H

#include "ASTNode.h"

void generateTASM(ASTNode *node, std::ofstream &outfile);
void generateTASMFile(ASTNode *node, const std::string &filename);

#endif // ASTTRAVERSAL_H
