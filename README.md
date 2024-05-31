This verilog model simulates a part of the schematics of BK-0010/11M computers related to the CPU (K1801VM1) and the video & RAM controller (K1801VP-037).

To compile & run simulation simply do "make wave". I assume that you are on a decent *nix system with GNU make, awk, iverilog, and gtkwave installed.
If you need to modify "pal.asm" code which is in the directory "asm", then you will need a portable "macro11" assembler (https://gitlab.com/Rhialto/macro11)
and the linker script "obj2bin".
