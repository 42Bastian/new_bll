all: ml.lnx ml.enc bll.enc demo0006.lnx

%.o: %.s
	lyxass -o $@ $<

%.bin: %.s
	lyxass -d -o $@ $<

ml.lyx: ml.enc demo.bin
	cat ml.enc demo.bin >$@

ml.lnx: ml.lyx
	bzcat allff.lyx.bz2 >> $<
	make_lnx $< -b0 256K -o $@

ml.enc: micro_loader.bin
	lynxenc $< $@

bll.enc: ml.enc bll_loader.bin
	cat ml.enc bll_loader.bin >$@

demo0006.lnx: bll.enc
	cat bll.enc ../demos/demo0006.o > demo0006.lyx
	bzcat allff.lyx.bz2 >> demo0006.lyx
	make_lnx demo0006.lyx -b0 256K -o $@
	rm -f demo0006.lyx

.PHONY: clean
clean:
	rm -f *.bin
	rm -f ml.lnx ml.lyx demo0006.lnx
