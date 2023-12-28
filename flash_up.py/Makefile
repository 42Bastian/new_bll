CFLAGS=-Os -fomit-frame-pointer

.SUFFIXES: .asc .obj .S .asm

%.o: %.asm
	lyxass  $<

.obj.asc:
	bin2asc < $*.obj >$@

%.o: %.c
	$(CC) $(CFLAGS) -c $<
%.o: %.S
	$(CC) -c $< -o $@

all: flashcard.o

clean:
	rm -f *.o
	rm -f *~
