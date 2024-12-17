all: ml512.enc ml.enc bll.enc bll512.enc demo0006.lnx demo0006_512.lnx\
	demo.lnx

micro_loader512.bin: micro_loader.S
	lyxass -d -D _512K -o $@ $<

bll_loader512.bin: bll_loader.S
	lyxass -d -D _512K -o $@ $<

%.bin: %.s
	lyxass -d -o $@ $<

%.o: %.s
	lyxass -o $@ $<

demo.lnx: demo.s ml.enc
	lyxass -d -D LNX=1 -o $@ $<

ml.enc: micro_loader.bin
	lynxenc $< $@

ml512.enc: micro_loader512.bin
	lynxenc $< $@

bll.enc: ml.enc bll_loader.bin
	cat ml.enc bll_loader.bin >$@

bll512.enc: ml512.enc bll_loader512.bin
	cat ml512.enc bll_loader512.bin >$@

demo0006.lnx: bll.enc
	cat bll.enc ../demos/demo0006.o > demo0006.lyx
	bzcat allff.lyx.bz2 >> demo0006.lyx
	make_lnx demo0006.lyx -b0 256K -o $@
	rm -f demo0006.lyx

demo0006_512.lnx: bll512.enc
	cat bll512.enc ../demos/demo0006.o > demo0006.lyx
	bzcat allff.lyx.bz2 >> demo0006.lyx
	make_lnx demo0006.lyx -b0 512K -o $@
	rm -f demo0006.lyx

.PHONY: clean
clean:
	rm -f *.bin
	rm -f demo.lnx ml.lyx demo0006.lnx demo0006_512.lnx
