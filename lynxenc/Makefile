INC=-I/usr/local/ssl/include
LIB=-L/usr/local/ssl/lib -lssl -lcrypto
all: lynxdec lynxenc

lynxdec: lynxdec.c sizes.h keys.h
	gcc $(INC)  -g -O0 lynxdec.c -o lynxdec $(LIB)

lynxenc: lynxenc.c sizes.h keys.h
	gcc $(INC) -g -O0 lynxenc.c -o lynxenc $(LIB)

clean:
	rm -rf lynxdec
	rm -rf lynxenc
