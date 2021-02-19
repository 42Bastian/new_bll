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
	flash_up.exe -p com7 -e

.PHONY: flash
flash: lnx
	flash_up.exe -p com7 -f new_bll.lnx

.PHONY: sram
sram: lnx
	sram_up.exe -p com7 -w new_bll.lnx
