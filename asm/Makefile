all: pal.hex

pal.hex: pal.bin
	od -x -An -v -w32 <pal.bin >pal.hex
	wc -w < pal.hex

pal.bin: pal.obj
	obj2bin --raw --outfile=pal.bin pal.obj

pal.obj: pal.asm
	macro11 -o pal.obj -l pal.lst pal.asm

clean:
	rm -f *.mem *.bin *.obj *.lst

.PHONY: all
