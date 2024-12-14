DEMO=dump

dump.o:	dump.asm $(BLL_ROOT)/microfnt/microfnt.o
	lyxass -v dump.asm

$(BLL_ROOT)/microfnt/microfnt.o:
	make -C $(BLL_ROOT)/microfnt

include ../Rules.launch
