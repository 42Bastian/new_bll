DEMO=overlay
DEMO_EXT=
INC=

$(DEMO).lnx: $(DEMO).asm

$(DEMO).bin $(DEMO).o: $(INC)

%.o: %.asm
	lyxass -v $(ASFLAGS) $<

.PHONY: lnx
lnx: $(DEMO)$(DEMO_EXT).lnx

$(DEMO)$(DEMO_EXT).lnx: $(DEMO).asm $(INC)
	lyxass -sh -d $(ASFLAGS) -D LNX=1 -o $@ $(DEMO).asm

include Rules.launch

clean:
	@rm -f  *~ *.equ

real-clean: clean
	@rm -f  *.lnx
