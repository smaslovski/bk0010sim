`timescale 1 ns / 1 ps

module rom_re2_16bit
(
    input		pin_sync_n,
    inout	[15:0]	pin_ad_n,
    input		pin_din_n,
    output		pin_rply_n
);

reg [15:1] addr_n;
reg [15:0] mem[0:4095];

always @(*)
    if (pin_sync_n)
	addr_n = ~pin_ad_n[15:1];

wire out_en = (addr_n[15:13] == 3'b100) & ~pin_din_n;

assign pin_ad_n = out_en ? ~mem[addr_n[12:1]] : 16'bz;
assign pin_rply_n = out_en ? 1'b0 : 1'bz;

endmodule
