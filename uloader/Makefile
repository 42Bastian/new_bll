all: ml.lnx

ml.lyx: ml_enc.bin demo.bin
	cat ml_enc.bin demo.bin >$@

ml.lnx: ml.lyx
	make_lnx $< -b0 256K -o $@

ml_enc.bin: ml.bin
	lynxenc $< $@

ml.bin: micro_loader.s
	lyxass -d -o $@ $<

demo.bin: demo.s
	lyxass -d -o $@ $<

.PHONY: clean
clean:
	rm -f *.bin
	rm -f ml.lnx ml.lyx
