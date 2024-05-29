//
// Вариант BK-0010 с расширениями вроде регистра палитр как у БК-0011М
// и с формирователем кадровых прерываний.
//
// (C) Stanislav Maslovski <stanislav.maslovski@gmail.com>
//

`timescale 1 ns / 1 ps

// Выбор конфигурации с расширениями

`define WITH_PALETTE_REG
`define WITH_FRAME_IRQ
`define BK0011M_CLK

// Дополнительная задержка RPLY

`define RPLY_SYN_CHAIN 1

module bk0010;

reg osc_clk, cpu_clk;
reg dclo_n, aclo_n;

wire [15:0] ad_n;
wire [2:1] sel_n;
wire [3:1] irq_n;
wire rst_n, dout_n, din_n, wtbt_n, sync_n, rply_n, dmr_n, sack_n, dmgo_n, iako_n, bsy_n;

// Резисторы-подтяжки к +5V

assign (highz0, pull1)
    ad_n   = 16'hFFFF,
    sel_n  = 2'b11,
    rst_n  = 1'b1,
    dout_n = 1'b1,
    din_n  = 1'b1,
    wtbt_n = 1'b1,
    sync_n = 1'b1,
    rply_n = 1'b1,
    dmr_n  = 1'b1,
    sack_n = 1'b1;

// Синхронизатор сигнала nRPLY

reg [`RPLY_SYN_CHAIN:0] rply_syn;

always @(negedge cpu_clk)
    rply_syn <= rply_syn << 1 | rply_n;

wire cpu_rply_n;

buf (pull0, pull1) (cpu_rply_n, rply_syn[`RPLY_SYN_CHAIN]);

// Микропроцессор K1801BM1 (синхронная версия)

vm1 CPU (
    .pin_clk(cpu_clk),		// processor clock
    .pin_pa_n(2'b11),		// processor number
    .pin_init_n(rst_n),		// peripheral reset
    .pin_dclo_n(dclo_n),	// processor reset
    .pin_aclo_n(aclo_n),	// power fail notification
    .pin_irq_n(irq_n),		// radial interrupt requests
    .pin_virq_n(1'b1),		// vectored interrupt request
    .pin_ad_n(ad_n),		// inverted address/data bus
    .pin_dout_n(dout_n),	// data output strobe
    .pin_din_n(din_n),		// data input strobe
    .pin_wtbt_n(wtbt_n),	// write/byte status
    .pin_sync_n(sync_n),	// address strobe
    .pin_rply_n(cpu_rply_n),	// transaction reply
    .pin_dmr_n(dmr_n),		// bus request shared line
    .pin_sack_n(sack_n),	// bus acknowlegement
    .pin_dmgi_n(1'b1),		// bus granted input
    .pin_dmgo_n(dmgo_n),	// bus granted output
    .pin_iako_n(iako_n),	// vector interrupt ack
    .pin_sp_n(1'b1),		// peripheral timer input
    .pin_sel_n(sel_n),		// register select outputs
    .pin_bsy_n(bsy_n)		// bus busy flag
);

reg pla_clk;
wire [6:0] m_addr;
wire [1:0] cas_n;
wire ras_n, we_n, e_n, bs_n, wti, wtd, vsync_n;

// Микросхема управления ДОЗУ / отображения экрана К1801ВП037

va_037 PLA (
   .PIN_CLK(pla_clk),
   .PIN_R(~rst_n),
   .PIN_C(1'b0),
   .PIN_nAD(ad_n),
   .PIN_nSYNC(sync_n),
   .PIN_nDIN(din_n),
   .PIN_nDOUT(dout_n),
   .PIN_nWTBT(wtbt_n),
   .PIN_nRPLY(rply_n),
   .PIN_A(m_addr),
   .PIN_nCAS(cas_n),
   .PIN_nRAS(ras_n),
   .PIN_nWE(we_n),
   .PIN_nE(e_n),
   .PIN_nBS(bs_n),
   .PIN_WTI(wti),
   .PIN_WTD(wtd),
   .PIN_nVSYNC(vsync_n)
);

wire [15:0] ram_do;

// ДОЗУ 16 х К565РУ6

ram_ru6_8bit RAM_0 (
    .pin_ma(m_addr),
    .pin_di(ad_n[7:0]),		// low byte
    .pin_do(ram_do[7:0]),
    .pin_ras_n(ras_n),
    .pin_cas_n(cas_n[0]),
    .pin_we_n(we_n)
);

ram_ru6_8bit RAM_1 (
    .pin_ma(m_addr),
    .pin_di(ad_n[15:8]),	// high byte
    .pin_do(ram_do[15:8]),
    .pin_ras_n(ras_n),
    .pin_cas_n(cas_n[1]),
    .pin_we_n(we_n)
);

// Защелка данных ДОЗУ 2 х К589ИР12

reg [15:0] ram_latch;

always @(*)
    if (~wtd)
	ram_latch = ram_do;

assign ad_n = wtd ? ram_latch : 16'bz;

// Регистры сдвига пикселей 2 x К155ИР13

wire [7:0] odd_bits, even_bits;
reg  [7:0] d24, d25;

genvar n;

generate
    for (n = 0; n < 8; n = n + 1) begin
	assign even_bits[n] = ram_do[2*n];
	assign odd_bits[n]  = ram_do[2*n+1];
    end
endgenerate

always @(negedge pla_clk)
    if (wti)
	begin
	    d24 <= even_bits;
	    d25 <= odd_bits;
	end
    else
	begin
	    d24 <= {1'b1, d24[7:1]};
	    d25 <= {1'b1, d25[7:1]};
	end

// Формирователь RGB видеосигнала (выход ЦТВ)

`ifdef WITH_PALETTE_REG

// ПЗУ палитр
// $ od -v -An -tx1 -j 128 -N 64 bk11m_556RT4A.rom | sed -r "s/0([0-9a-f]+)/4'h\1,/g"

reg [0:63] [3:0] pal_rom =
{
 4'hf, 4'h6, 4'h2, 4'h0, 4'hf, 4'hb, 4'h2, 4'h0, 4'hf, 4'h6, 4'hb, 4'h0, 4'h6, 4'h9, 4'h2, 4'h0,
 4'h9, 4'h6, 4'hb, 4'h0, 4'h8, 4'ha, 4'hc, 4'h0, 4'h1, 4'h3, 4'h5, 4'h0, 4'hd, 4'hc, 4'h5, 4'h0,
 4'hb, 4'ha, 4'h3, 4'h0, 4'h9, 4'h8, 4'h1, 4'h0, 4'hf, 4'hf, 4'hf, 4'h0, 4'hf, 4'hd, 4'h6, 4'h0,
 4'hb, 4'h2, 4'h6, 4'h0, 4'hd, 4'h6, 4'h4, 4'h0, 4'h9, 4'hb, 4'hd, 4'h0, 4'h9, 4'h4, 4'h2, 4'h0
};

wire [1:0] vR;
wire vG, vB;

wire [5:0] idx = {pal_reg[3:0], d24[0], d25[0]};
assign {vR[1], vB, vG, vR[0]} = pal_rom[idx];

`else

wire vR = ~( d24[0] |  d25[0]);
wire vG = ~(~d24[0] |  d25[0]);
wire vB = ~( d24[0] | ~d25[0]);

`endif

// Формирователь ЧБ видеосигнала (выход ТВ)

wire vC = ~(d24[0] & ~pla_clk) & ~(d25[0] & pla_clk);

// ПЗУ 1 х К1801РЕ2

rom_re2_16bit ROM (
    .pin_sync_n(sync_n),
    .pin_ad_n(ad_n),
    .pin_din_n(din_n),
    .pin_rply_n(rply_n)
);

// Регистр системного порта

reg [3:0] sys_reg_i;	// 4'b0xxx
reg [3:0] sys_reg_o;

assign ad_n = (~sel_n[1] & ~din_n) ? {8'bz, sys_reg_i, 4'bz} : 16'bz;

always @(*)
    if (~sel_n[1] & ~dout_n)
	sys_reg_o = ad_n[8:4];

// Регистр программируемого порта ввода-вывода

reg [15:0] pp_reg_i;
reg [15:0] pp_reg_o;

assign ad_n = (~sel_n[2] & ~din_n) ? pp_reg_i : 16'bz;

always @(*)
    if (~sel_n[2] & ~dout_n)
	pp_reg_o = ad_n;

`ifdef WITH_PALETTE_REG

// Защелка адреса (на все 16 бит, для пущего удобства)

reg [15:0] addr;

always @(*)
    if (sync_n)
	addr = ~ad_n;

// Регистр управления палитрами

reg [4:0] pal_reg;
wire pal_reg_wr = ~(~addr[1] | bs_n | dout_n);
assign rply_n = pal_reg_wr ? 1'b0 : 1'bz;

always @(posedge pal_reg_wr)
    begin
	pal_reg[3:0] =  ad_n[11:8];	// код палитры
	pal_reg[4]   =  ad_n[14];	// разрешение прерываний таймера
    end

`endif

`ifdef WITH_FRAME_IRQ

//
// Формирователь сигнала кадрового прерывания
//

`ifdef WITH_PALETTE_REG
wire irq2_en = pal_reg[4];
`else
wire irq2_en = 1'b1;
`endif

assign {irq_n[1], irq_n[3]} = 2'b11;

reg d28, d3, d11_q2;
wire c28;

assign irq_n[2] = d11_q2;
assign c28 = ~(d28 | vsync_n);
initial d28 = 1'b0;

always @(negedge c28 or posedge (wti & pla_clk))
begin
   if (wti & pla_clk)
      d28 <= 1'b0;
   else
      d28 <= ~d28;
end

always @(posedge vsync_n or negedge irq2_en)
    d3 <= irq2_en & d28;

always @(posedge cpu_clk)
    d11_q2 <= ~d3;

`endif

// Тактовые сигналы

parameter ToscH = 41.667;
parameter TplaH = 2*ToscH;

`ifdef BK0011M_CLK
parameter TclkH = 2*ToscH;
parameter TclkL = 4*ToscH;
`else
parameter TclkH = 4*ToscH;
parameter TclkL = 4*ToscH;
`endif

parameter Tclk  = TclkH + TclkL;

initial
    begin
	osc_clk = 1'b0;
	pla_clk = 1'b0;
	cpu_clk = 1'b0;
	fork
	    forever
		#(ToscH) osc_clk = ~osc_clk;
	    forever
		#(TplaH) pla_clk = ~pla_clk;
	    forever
		begin
		    #(TclkL) cpu_clk = 1'b1;
		    #(TclkH) cpu_clk = 1'b0;
		end
	join
    end

// Инициализация

parameter time_limit = 3000*Tclk;

parameter code_len = 2842;

integer i;
reg [15:0] code[0:code_len-1];

initial
    begin
        $dumpfile("tb_bk0010.lxt");
	$dumpvars(0);

	// инициализация микропроцессора
	dclo_n = 1'b0;
	aclo_n = 1'b0;

	// содержимое ОЗУ
	for (i = 0; i < 16384; i = i + 1)
	    begin
		RAM_0.mem[i] = 8'b11111111; // красный
		RAM_1.mem[i] = 8'b01010101; // синий
	    end

	$readmemh("pal.hex", code, 0, code_len-1);

	for (i = 0; i < code_len; i = i + 1)
	    begin
		RAM_0.mem[i] = code[i][7:0];
		RAM_1.mem[i] = code[i][15:8];
	    end

	// содержимое ПЗУ
	for (i = 0; i < 4096; i = i + 1)
	    ROM.mem[i] = ~16'b0;

	// программа в ПЗУ
	//ROM.mem[12'd0] = 'o012700;
	//ROM.mem[12'd1] = 'o040000;
	//ROM.mem[12'd2] = 'o012701;
	//ROM.mem[12'd3] = 'o020000;
	//ROM.mem[12'd4] = 'o012720;
	//ROM.mem[12'd5] = 'o125252;
	//ROM.mem[12'd6] = 'o014020;
	//ROM.mem[12'd7] = 'o077104;

	ROM.mem[12'd0] = 'o012706;
	ROM.mem[12'd1] = 'o001000;
	ROM.mem[12'd2] = 'o000137;
	ROM.mem[12'd3] = 'o001000;

	// порты
	sys_reg_i = 4'b0;
	pp_reg_i = 16'b0;
`ifdef WITH_PALETTE_REG
	pal_reg = ~5'b0;
`endif
	// рулон и режим экрана
	PLA.RA = 8'o330;
	PLA.M256 = 1'b1;

	// старт микропроцессора
	#(10*Tclk);
	dclo_n = 1'b1;
	#(10*Tclk);
	aclo_n = 1'b1;

	#(time_limit) $finish;
    end

endmodule
