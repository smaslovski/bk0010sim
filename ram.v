`timescale 1 ns / 1 ps

module ram_ru6_8bit
(
    input	[6:0]	pin_ma,
    input	[7:0]	pin_di,
    output	[7:0]	pin_do,
    input		pin_ras_n,
    input		pin_cas_n,
    input		pin_we_n
);

reg [6:0] row_addr;
reg [6:0] col_addr;
reg [7:0] data;
reg read_ff;

reg [7:0] mem[0:16383];

wire wr_stb_n = pin_ras_n | pin_cas_n | pin_we_n;

always @(*)
    if (pin_ras_n)
	row_addr = ~pin_ma;

always @(*)
    if (pin_cas_n)
	col_addr = ~pin_ma;

always @(negedge pin_cas_n)
    if (~pin_ras_n)
	begin
	    read_ff <= pin_we_n; // 1 - read cycle, 0 - write cycle
	    data <= mem[{col_addr, row_addr}];
	end

always @(negedge wr_stb_n)
    mem[{col_addr, row_addr}] <= ~pin_di;

assign pin_do = (read_ff & ~pin_cas_n) ? ~data : 8'bz;

endmodule
