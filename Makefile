NAME=practica
INCLUDE=-I/usr/include/pccts/

all: tree treeD

treeD: $(NAME).c dlgTree
	g++ -ggdb -std=c++11 -w -o $(NAME)D $(NAME).c scan.c err.c $(INCLUDE)

tree: $(NAME).c dlgTree 
	g++ -std=c++11 -O3 -w -o $(NAME) $(NAME).c scan.c err.c $(INCLUDE)

$(NAME).c: $(NAME).g
	antlr -gt $(NAME).g

dlgTree: parser.dlg
	dlg -ci parser.dlg scan.c
	
clean:
	rm *.c *.dlg *.h 
