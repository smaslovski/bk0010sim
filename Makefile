MODULES = bk0010.v vm1.v vm1_plm.v vm1_tve.v vm1_qbus.v va_037.v ram.v rom.v
PROGRAM = tb_bk0010
VERILOG = iverilog -Wall
WAVEFORMS = tb_bk0010.lxt
GTKWAVEFILE = tb_bk0010.gtkw

############## Comment out next line to disable random seed ###################

DEFS=-Pbk0010plus.RANDOM_SEED=$(shell awk "BEGIN { print int(65536*rand()) }")

###############################################################################

LOGS=

all: $(PROGRAM)

run: $(PROGRAM)
	./$(PROGRAM)

wave: clean $(WAVEFORMS)
	gtkwave $(GTKWAVEFILE)

clean:
	rm -f $(PROGRAM) $(LOGS) $(WAVEFORMS)

$(WAVEFORMS): $(MODULES)
	$(VERILOG) -DGTKWAVE_DUMP $(DEFS) -o $(PROGRAM) $(MODULES)
	./$(PROGRAM) -lxt2

$(PROGRAM): $(MODULES)
	$(VERILOG) $(DEFS) -o $(PROGRAM) $(MODULES)

.PHONY: all run wave clean
