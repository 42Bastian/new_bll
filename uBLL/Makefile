ifneq ($(findstring darwin,$(OSTYPE)),)
FLASHER=python3 $(BLL_ROOT)/flash_up.py/flash_up.py -q
COM?=/dev/tty.usbserial-FT63V37G
else
SENDOBJ=sendobj
COM?=COM7
endif
BAUD?=1000000

all: new_bll.lnx

new_bll.lyx: bll_1st_stage_enc.bin bll_2nd_stage.bin
	cat bll_1st_stage_enc.bin bll_2nd_stage.bin >$@
	bzcat allff.lyx.bz2 >> $@

lnx: new_bll.lnx
new_bll.lnx : new_bll.lyx
	make_lnx $< -b0 256K -o $@

bll_1st_stage_enc.bin: bll_1st_stage.bin
	lynxenc $< $@

bll_1st_stage.bin: bll_1st_stage.asm
	lyxass -d -D LNX=1 -o $@ $<

bll_2nd_stage.bin: bll_2nd_stage.asm
	lyxass -d -D LNX=1 -o $@ $<

.PHONY: clean
clean:
	rm -f *.bin *.lyx

.PHONY: erase
erase:
	$(FLASHER) -p $(COM) -e

.PHONY: flash
flash: lnx
	$(FLASHER) -p $(COM) -f new_bll.lnx

.PHONY: sram
sram: lnx
	sram_up.exe -p $(COM) -w new_bll.lnx
