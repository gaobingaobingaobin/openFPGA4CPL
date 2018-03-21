module QAM16Tx(
	RST_n,
	CLK_50M,
	ADdata,
	ADCLK,
	DAdata,
	DACLK,
	LED
);
output [3:0]LED;
input  RST_n,CLK_50M;
input  [7:0]ADdata;
output [7:0]DAdata;
output ADCLK,DACLK;

wire [3:0]ADsigSource;
ADSigSour ADSigSourU0(
	.RST_n(RST_n),
	.CLK25kHz(CLK25kHz),
	.ADdata(ADdata), 	//8bit
	.ADCLK(ADCLK),		//25kHz
	.ADsigSource(ADsigSource)  //8bit * 12.5kHz = 100kbps = 4bit * 25kHz
);

LEDSour LEDSourU0(
	.RST_n(RST_n),
	.CLK1Hz(CLK12_5kHz),
	.LED(LED)
);



wire CLK1Hz,CLK12_5kHz,CLK25kHz,CLK50kHz,CLK100kHz,CLK500kHz,CLK5MHz;
CLKgen CLKgenU0(
	.RST_n(RST_n),
	.CLK_50M(CLK_50M),
	.CLK1Hz(CLK1Hz),
	.CLK12_5kHz(CLK12_5kHz),
	.CLK25kHz(CLK25kHz),
	.CLK50kHz(CLK50kHz),
	.CLK100kHz(CLK100kHz),
	.CLK500kHz(CLK500kHz),
	.CLK5MHz(CLK5MHz)
);




wire signed [9:0]fsin,fcos;//2MHz
NCOLOgen NCOLOgenU0 (
	.clk       (CLK_50M),      // clk.clk
	.reset_n   (RST_n),   		// rst.reset_n
	.clken     (1'b1),     		// in.clken
	.phi_inc_i (32'd858993459), // phi_inc_i//400khz
	.fsin_o    (fsin),    		// fsin_o
	.fcos_o    (fcos),   		// fcos_o
);

wire [2:0]QAM_I,QAM_Q;
CodeMap CodeMapU0(
	.RST_n(RST_n),
	.CLK(CLK25kHz),
	.QAMdata(ADsigSource),
	//.QAMdata(LED),
	.I(QAM_I),
	.Q(QAM_Q)
);
 
//相乘
wire signed [12:0]Isin,Qcos;
MULT	MULT_instI (
	.dataa(QAM_I),
	.datab(fsin),
	.result(Isin)
	);
MULT MULT_instQ (
	.dataa(QAM_Q),
	.datab(fcos),
	.result(Qcos)
	);
	
wire signed[12:0]IAddQ;
wire IAddQoverflow_sig;
ADDSUB ADDSUB_inst(
	.dataa(Isin),
	.datab(Qcos),
	.overflow(IAddQoverflow_sig),
	.result(IAddQ)
	);
assign DAdata = IAddQ[12:5] + 8'b1000_0000;
assign DACLK = CLK_50M;

endmodule 
