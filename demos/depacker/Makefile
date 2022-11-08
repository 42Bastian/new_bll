_256=depacker

$(_256).o: $(_256).asm

ifeq ($(HANDY),1)
ASFLAGS=-D HANDY=1
endif

%.o: %.asm
	lyxass -v $(ASFLAGS) $<

%.bin: %.asm
	lyxass -d $(ASFLAGS) -D LNX=1 -o  $@ $<

$(_256).o: unlz4.asm unzx0.asm untp.asm unlz4_fast.asm unzx0_fast.asm \
	krilldecr.inc krilldecr.var unupkr.var unupkr.asm\
	unupkr_255.var unupkr_255.asm unexo.asm unexo.var

.PHONY: send
send: $(_256).o
	sendobj -b 1000000 -p com7 $<
#	sendobj -b 62500 -p com7 $<

.PHONY: lnx
lnx: $(_256).bin
	lynxenc $< $(_256).lyx
	bzcat allff.lyx.bz2 >> $(_256).lyx
	make_lnx $(_256).lyx -b0 256K -o $(_256).lnx
	@echo

.PHONY: clean
clean:
	rm -f *.lyx *~ *.bin *.o

.PHONY: erase
erase:
	flash_up.exe -p com7 -e

.PHONY: flash
flash: lnx
	flash_up.exe -p com7 -f $(_256).lnx

.PHONY: sram
sram: lnx
	sram_up.exe -p com7 -w $(_256).lnx
