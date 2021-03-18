all: ml.lnx

ml.lyx: ml.enc demo.bin
	cat ml.enc demo.bin >$@


ml.lnx: ml.lyx
	bzcat allff.lyx.bz2 >> $<
	make_lnx $< -b0 256K -o $@

ml.enc: ml.bin
	lynxenc $< $@

ml.bin: micro_loader.s
	lyxass -d -o $@ $<

demo.bin: demo.s
	lyxass -d -o $@ $<

.PHONY: clean
clean:
	rm -f *.bin
	rm -f ml.lnx ml.lyx
