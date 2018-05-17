#header
<<
#include <string>
#include <iostream>

// struct to store information about tokens
typedef struct {
  std::string kind;
  std::string text;
} Attrib;

// function to fill token information (predeclaration)
void zzcr_attr(Attrib *attr, int type, char *text);

// fields for AST nodes
#define AST_FIELDS std::string kind; std::string text; int type;
#include "ast.h"

// macro to create a new AST node (and function predeclaration)
#define zzcr_ast(as,attr,ttype,textt) as=createASTnode(attr,ttype,textt)
AST* createASTnode(Attrib* attr, int ttype, char *textt);

>>

<<
#include <cstdlib>
#include <cmath>
#include <functional>
// function to fill token information
void zzcr_attr(Attrib *attr, int type, char *text) {
    attr->kind = text;
    attr->text = "";
}

// function to create a new AST node
AST* createASTnode(Attrib* attr, int type, char* text) {  
  AST* as = new AST;
  as->kind = attr->kind; 
  as->text = attr->text;
  as->type = type;
  as->right = NULL; 
  as->down = NULL;
  return as;
}

#define createASTlist #0=new AST;(#0)->kind="list";(#0)->right=NULL;(#0)->down=_sibling;

/// get nth child of a tree. Count starts at 0.
/// if no such child, returns NULL
AST* child(AST *a,int n) {
 AST *c=a->down;
 for (int i=0; c!=NULL && i<n; i++) c=c->right;
 return c;
} 

/// print AST, recursively, with indentation
void ASTPrintIndent(AST *a, std::string s)
{
  if (a==NULL) return;

  std::cout<<a->kind;
  if (a->text!="") std::cout<<"("<<a->text<<")";
  std::cout<<std::endl;

  AST *i = a->down;
  while (i!=NULL && i->right!=NULL) {
    std::cout<<s+"  \\__";
    ASTPrintIndent(i,s+"  |"+std::string(i->kind.size()+i->text.size(),' '));
    i=i->right;
  }
  
  if (i!=NULL) {
      std::cout<<s+"  \\__";
      ASTPrintIndent(i,s+"   "+std::string(i->kind.size()+i->text.size(),' '));
      i=i->right;
  }
}

/// print AST 
void ASTPrint(AST *a)
{
  while (a!=NULL) {
    std::cout<<" ";
    ASTPrintIndent(a,"");
    a=a->right;
  }
}


#include <unordered_map>
struct ListElem
{
  int value;
  ListElem* sublist = nullptr;
  ListElem* next = nullptr;
};

//functions and structures declarations to parse
std::unordered_map<std::string, ListElem*> listsmap;
int evaluate(AST *a);

int main() {
  AST *root = NULL;
  ANTLR(lists(&root), stdin);
  ASTPrint(root);
  std::cout << evaluate(root) << std::endl;
}

ListElem* copy(ListElem* a)
{
  if (a == nullptr) return nullptr;
  ListElem* ret = new ListElem;
  ListElem* cent = ret;
  if (a->sublist == nullptr){
    cent->value = a->value;
    cent->sublist = nullptr;
  } 
  else cent->sublist = copy(a->sublist);

  a = a->next;  
  while(a != nullptr) {
    cent->next = new ListElem;
    cent = cent->next;
    if (a->sublist == nullptr){
      cent->value = a->value;
      cent->sublist = nullptr;
    } 
    else cent->sublist = copy(a->sublist);
    a = a->next;
  }  
  return ret;
}

void printList(ListElem* list)
{
  std::cout << "[";
  if (list == nullptr) {
    std::cout << "]";
    return;
  }
  if (list->sublist == nullptr) {
    std::cout << list->value;
  }
  else {
    printList(list->sublist);
  }
  list = list->next;
  while(list != nullptr) {
    std::cout << ",";
    if (list->sublist == nullptr) {
      std::cout << list->value; 
    }
    else {
      printList(list->sublist);
    }
    list = list->next;
  }
  std::cout << "]";
}

ListElem* head(ListElem* elem)
{
  if (elem == nullptr) return nullptr;
  ListElem* ret = new ListElem;
  ret->next = nullptr;
  if (elem->sublist == nullptr) {
    ret->value = elem->value;
    ret->sublist == nullptr;
  }
  else {
    ret->sublist = copy(elem->sublist);
  }
  return ret;
}

ListElem* parseList(AST* first)
{
  if (first == nullptr) return nullptr;
  ListElem* ret = new ListElem;
  if (first->type == LOPEN) {
      ret->sublist = parseList(first->down);
    }
  else {
    ret->value = stoi(first->kind);
    ret->sublist = nullptr;
  }
  ListElem* cent = ret;
  first = first->right;
  while(first != nullptr) {
    cent->next = new ListElem;
    cent = cent->next;
    cent->next = nullptr;
    if (first->type == LOPEN) {
      cent->sublist = parseList(first->down);
    }
    else {
      cent->value = stoi(first->kind);
      cent->sublist = nullptr;
    }
    first = first->right;
  }
  return ret;
}

ListElem* concat(AST* izq, AST* der)
{
  ListElem* prefix = copy(listsmap[izq->kind]);
  if (prefix == nullptr) {
    if (der->type == CONCAT) prefix = concat(der->down, der->down->right);
    else prefix = copy(listsmap[der->kind]);
  }
  
  ListElem* cent = prefix;
  while (cent->next != nullptr) cent = cent->next;
  if (der->type == CONCAT) cent->next = concat(der->down, der->down->right);
  else cent->next = copy(listsmap[der->kind]);
  return prefix;
}

void clear(ListElem* pred)
{
  if (pred == nullptr) return;
  ListElem* succ;
  while(pred->next != nullptr) {
    succ = pred->next;
    if (pred->sublist == nullptr) delete(pred);
    else {
      clear(pred->sublist);
      delete(pred);
    }
    pred = succ;
  }
  if (pred->sublist == nullptr) delete(pred);
  else {
      clear(pred->sublist);
      delete(pred);
  }
}

ListElem* iFlatten(ListElem* first)
{
  if(first == nullptr) return nullptr;
  ListElem* ret;
  if (first->sublist != nullptr) {
    ret = iFlatten(first->sublist);
  }
  else {
    ret = new ListElem;
    ret->value = first->value;
    ret->sublist = nullptr;
  }
  first = first->next;
  ListElem* cent = ret;
  while(cent->next != nullptr) cent = cent->next;
  while(first != nullptr) {
    if (first->sublist != nullptr) {
      cent->next = iFlatten(first->sublist);
      while(cent->next != nullptr) cent = cent->next;
    }
    else {
      cent->next = new ListElem;
      cent = cent->next;
      cent->value = first->value;
      cent->sublist = nullptr;
    }
    first = first->next;
  }
  return ret;
}

void flatten(AST* a)
{
  std::string listName = a->down->kind;
  ListElem* flattened = iFlatten(listsmap[listName]);
  clear(listsmap[listName]);
  listsmap[listName] = flattened;
}



void print(AST* a)
{
  if (a->down->type == HEAD){
    ListElem* h = head(listsmap[a->down->down->kind]);
    printList(h);
  }
  else {
    printList(listsmap[a->down->kind]);
  }
  std::cout << std::endl;
}

void pop(AST* a)
{
  ListElem* first = listsmap[a->down->kind];
  if (first == nullptr) return;
  listsmap[a->down->kind] = first->next;
  first->next = nullptr;
  clear(first);
}

inline ListElem* iReduce(ListElem* first, std::function<int(int,int)> operation)
{
  if (first == nullptr) return nullptr;
  ListElem* ret = new ListElem;
  ret->sublist = nullptr;
  ret->next = nullptr;
  if (first->sublist == nullptr) {
    ret->value = first->value;
  }
  else {
    ListElem* sub = iReduce(first->sublist, operation);
    if (sub == nullptr) return iReduce(first->next, operation);
    ret->value = sub->value;
  }
  first = first->next;
  while(first != nullptr) {
    if (first->sublist == nullptr) {
      ret->value = operation(ret->value, first->value);
    }
    else {
      ListElem* sub = iReduce(first->sublist, operation);
      if (sub != nullptr) ret->value = operation(ret->value, sub->value);
    }
    first = first->next;
  }
  return ret;
}

std::function<int(int,int)> getOperation(std::string opName)
{
  if (opName == "+")  return std::plus<int>();
  if (opName == "-")  return std::minus<int>();
  if (opName == "*")  return std::multiplies<int>();
  if (opName == "==") return std::equal_to<int>();
  if (opName == "!=") return std::not_equal_to<int>();
  if (opName == ">")  return std::greater<int>();
  if (opName == "<")  return std::less<int>();
  if (opName == ">=") return std::greater_equal<int>();
  if (opName == "<=") return std::less_equal<int>(); 
  return [](int a, int b)->int{return 0;}; //default operation that just return 0
}

ListElem* reduce(AST* list, AST* op)
{
  std::function<int(int,int)> operation = getOperation(op->kind);
  return iReduce(listsmap[list->kind], operation);
}

inline ListElem* iMap(ListElem* first, std::function<int(int,int)> operation, int konst)
{
  if (first == nullptr) return nullptr;
  ListElem* ret = new ListElem;
  if (first->sublist == nullptr) {
    ret->value = operation(first->value, konst);
  }
  else {
    ret->sublist = iMap(first->sublist, operation, konst);
  }
  ListElem* cent = ret;
  first = first->next;
  while(first != nullptr) {
    cent->next = new ListElem;
    cent = cent->next;
    if (first->sublist == nullptr) {
      cent->value = operation(first->value, konst);
    }
    else {
      cent->sublist = iMap(first->sublist, operation, konst);
    }
    first = first->next;
  }
  return ret;
}

ListElem* map(AST* list, AST* op, AST* k)
{
  int konst = atoi(k->kind.c_str());
  std::function<int(int,int)> operation = getOperation(op->kind);
  return iMap(listsmap[list->kind], operation, konst);
}

inline ListElem* iFilter(ListElem* first, std::function<int(int,int)> operation, int konst)
{
  if (first == nullptr) return nullptr;
  ListElem* ret = nullptr;
  ListElem* cent = nullptr;
  if (first->sublist == nullptr) {
    if (operation(first->value, konst)) {
      ret = new ListElem;
      cent = ret;
      cent->value = first->value;
    }  
  }
  else {
    ListElem* sub = iFilter(first->sublist, operation, konst);
    if (sub != nullptr) {
      ret = new ListElem;
      cent = ret;
      cent->sublist = sub;
    }
  }
  first = first->next;
  while(first != nullptr) {
    if (first->sublist == nullptr) {
      if (operation(first->value, konst)) {
        if (ret == nullptr) {
          ret = new ListElem;
          cent = ret;
          cent->value = first->value;
        }
        else {
          cent->next = new ListElem;
          cent = cent->next;
          cent->value = first->value;
        }
      }
    }
    else {
      ListElem* sub = iFilter(first->sublist, operation, konst);
      if (sub != nullptr) {
        if (ret == nullptr) {
          ret = new ListElem;
          cent = ret;
          cent->sublist = sub;
        }
        else {
          cent->next = new ListElem;
          cent = cent->next;
          cent->sublist = sub;
        }
      }
    }
    first = first->next;
  }
  return ret;
}

ListElem* filter(AST* list, AST* op, AST* k)
{
  int konst = atoi(k->kind.c_str());
  std::function<int(int,int)> operation = getOperation(op->kind);
  return iFilter(listsmap[list->kind], operation, konst); 
}

void assign(AST *a)
{
  std::string listName = a->down->kind;
  AST* operation = a->down->right;
  switch(operation->type) {
    case LOPEN:
      listsmap[listName] = parseList(operation->down); //list begining
    break;
    case CONCAT:
      listsmap[listName] = concat(operation->down, operation->down->right); //concat children
    break;
    case LREDUCE:
      listsmap[listName] = reduce(operation->down->right, operation->down);
    break;
    case LMAP:
      listsmap[listName] = map(operation->down->right->right, operation->down, operation->down->right);
    break;
    case LFILTER:
      listsmap[listName] = filter(operation->down->right, operation->down, operation->down->down);
    break;
    default:
    break;
  }
}

bool compare(ListElem* x, ListElem* y,  std::function<int(int,int)> operation)
{
  bool op = false;
  while(x != nullptr and y != nullptr) {
    op |= operation(x->value, y->value);
    x = x->next;
    y = y->next;
  }
  if (!op) {
    if (x == nullptr and y != nullptr) return operation(0,1); //y has more elements than x, we let operation decide how to evaluate
    if (x != nullptr and y == nullptr) return operation(1,0);
  }
  return op;
}

bool evalExpression(AST* op)
{
  switch (op->type) {
    case FILTEROP:
      return compare(listsmap[op->down->kind], listsmap[op->down->right->kind], getOperation(op->kind));
    break;
    case AND:
      return evalExpression(op->down) and evalExpression(op->down->right);
    break;
    case OR:
      return evalExpression(op->down) and evalExpression(op->down->right);
    break;
    case NOT:
      return not evalExpression(op->down);
    break;
    case EMPTY:
      return listsmap[op->down->kind] == nullptr;
    break;
    default:
    break;
  }
}

int evaluate(AST *a) {
  if (a->kind == "list") a = a->down;
  while(a != NULL) {
    switch(a->type) {
      case ASSIGN:
        assign(a);
      break;
      case IF:
        if (evalExpression(a->down)) evaluate(a->down->right);
      break;
      case WHILE:
        while (evalExpression(a->down)) evaluate(a->down->right);
      break;
      case POP:
        pop(a);
      break;
      case FLATTEN:
        flatten(a);
      break;
      case PRINT:
        print(a);
      break;
      default:
      break;
    }

    a = a->right;
  }
  return 0;
}

>>

#lexclass START
#token LID "L[0-9]*"
#token ARITMOP "\+ | \- | \*"
#token FILTEROP "== | != | >= | <= | < | > "
#token ASSIGN "="
#token LOPEN "\["
#token LCLOSE "\]"
#token LPAR "\("
#token RPAR "\)"
#token SEP ","
#token CONCAT "#"
#token IF "if"
#token THEN "then"
#token ENDIF "endif"
#token WHILE "while"
#token DO "do"
#token ENDWHILE "endwhile"
#token LMAP "lmap"
#token LREDUCE "lreduce"
#token LFILTER "lfilter"
#token FLATTEN "flatten"
#token PRINT "print"
#token POP "pop"
#token HEAD "head"
#token EMPTY "empty"
#token NOT "NOT"
#token AND "AND"
#token OR "OR"
#token INTEGER "[0-9]+"
#token SPACE "[\ \n]" << zzskip();>>

lists: (list_oper)* <<#0=createASTlist(_sibling);>> ;
list_oper: assignation | print | flowControl | pop | flatten;

assignation: LID ASSIGN^ (list | concatenation |  function);

  list: LOPEN^ (sequence | ) LCLOSE!;
    sequence: element (SEP! element)*;
      element: INTEGER | list; 

  concatenation: LID CONCAT^ LID (CONCAT^ LID)*;

  function: map | reduce | filter;
    map: LMAP^ ARITMOP INTEGER LID;
    reduce: LREDUCE^ ARITMOP LID;
    filter: LFILTER^ comparison;
      comparison: filterop LID;
        filterop: FILTEROP^ INTEGER;

print: PRINT^ (LID | head);
  head: HEAD^ LPAR! LID RPAR!;

flowControl: possible | loop;
  possible: IF^ LPAR! condition RPAR! THEN! lists ENDIF!;
  loop: WHILE^ LPAR!  condition RPAR! DO! lists ENDWHILE!;
    condition: andCond (OR^ andCond)*;
    	andCond: notCond (AND^ notCond)*;
    		notCond: NOT^ notCond | parCond;
    			parCond: LPAR! condition RPAR! | baseCond; 
    				baseCond: (LID | list) FILTEROP^ (LID | list) | EMPTY^ LPAR! LID RPAR!;

    	 
pop: POP^ LPAR! LID RPAR!;

flatten: FLATTEN^ LID;
