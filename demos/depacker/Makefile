DEMO=depacker

$(DEMO).o: $(DEMO).asm

ifeq ($(HANDY),1)
ASFLAGS=-D HANDY=1
endif

%.o: %.asm
	lyxass -v $(ASFLAGS) $<

%.bin: %.asm
	lyxass -d $(ASFLAGS) -D LNX=1 -o  $@ $<

$(DEMO).o: unlz4.asm unzx0.asm untp.asm unlz4_fast.asm unzx0_fast.asm \
	krilldecr.inc krilldecr.var unupkr.var unupkr.asm\
	unupkr_255.var unupkr_255.asm unexo.asm unexo.var \
	untsc.asm untsc.var

.PHONY: lnx
lnx: $(DEMO).bin
	lynxenc $< $(DEMO).lyx
	bzcat allff.lyx.bz2 >> $(DEMO).lyx
	make_lnx $(DEMO).lyx -b0 256K -o $(DEMO).lnx
	@echo

.PHONY: clean
clean:
	rm -f *.lyx *~ *.bin *.o

include ../Rules.launch
