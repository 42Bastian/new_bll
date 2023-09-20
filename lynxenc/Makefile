OS=$(shell uname)
ifeq ($(OS),Darwin)
INC=-I/opt/homebrew/include
LIB=-L/opt/homebrew/lib
else
INC=-I/usr/local/ssl/include
LIB=-L/usr/local/ssl/lib
endif
LIB += -lssl -lcrypto

all: lynxdec lynxenc

lynxdec: lynxdec.c sizes.h keys.h
	gcc $(INC)  -g -O0 lynxdec.c -o lynxdec $(LIB)

lynxenc: lynxenc.c sizes.h keys.h
	gcc $(INC) -g -O0 lynxenc.c -o lynxenc $(LIB)

clean:
	rm -rf lynxdec
	rm -rf lynxenc
	rm -rf *.dSYM
