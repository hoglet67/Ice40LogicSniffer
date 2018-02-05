

module BRAM10k9bit(CLK, ADDR, WE, EN, DIN, DINP, DOUT, DOUTP);
input CLK;
input WE;
input EN;
input [13:0] ADDR;
input [7:0] DIN;
input DINP;
output [7:0] DOUT;
output DOUTP;

wire [7:0] ram0_DOUT, ram1_DOUT, ram2_DOUT, ram3_DOUT, ram4_DOUT;
wire ram0_DOUTP, ram1_DOUTP, ram2_DOUTP, ram3_DOUTP, ram4_DOUTP;

reg [7:0] ram_EN;
always @*
begin
  #1;
  ram_EN = 0;
  ram_EN[ADDR[13:11]] = EN;
end


//
// Output mux...
//
reg [2:0] dly_ADDR, next_dly_ADDR;
always @(posedge CLK)
begin
  dly_ADDR = next_dly_ADDR;
end

always @*
begin
  #1;
  next_dly_ADDR = ADDR[13:11];
end

reg [7:0] DOUT;
reg DOUTP;
always @*
begin
  #1;
  DOUT = 8'h0;
  DOUTP = 1'b0;
  case (dly_ADDR)
    3'h0 : begin DOUT = ram0_DOUT; DOUTP = ram0_DOUTP; end
    3'h1 : begin DOUT = ram1_DOUT; DOUTP = ram1_DOUTP; end
    3'h2 : begin DOUT = ram2_DOUT; DOUTP = ram2_DOUTP; end
    3'h3 : begin DOUT = ram3_DOUT; DOUTP = ram3_DOUTP; end
    3'h4 : begin DOUT = ram4_DOUT; DOUTP = ram4_DOUTP; end
  endcase
end


//
// Instantiate the 2Kx8 RAM's...
//
RAMB16_S9 ram0 (
  .CLK(CLK), .ADDR(ADDR[10:0]),
  .DI(DIN), .DIP(DINP), 
  .DO(ram0_DOUT), .DOP(ram0_DOUTP),
  .EN(ram_EN[0]), .SSR(1'b0), .WE(WE)); 


RAMB16_S9 ram1 (
  .CLK(CLK), .ADDR(ADDR[10:0]),
  .DI(DIN), .DIP(DINP), 
  .DO(ram1_DOUT), .DOP(ram1_DOUTP),
  .EN(ram_EN[1]),
  .SSR(1'b0),
  .WE(WE));

RAMB16_S9 ram2 (
  .CLK(CLK), .ADDR(ADDR[10:0]),
  .DI(DIN), .DIP(DINP), 
  .DO(ram2_DOUT), .DOP(ram2_DOUTP),
  .EN(ram_EN[2]),
  .SSR(1'b0),
  .WE(WE));

RAMB16_S9 ram3 (
  .CLK(CLK), .ADDR(ADDR[10:0]),
  .DI(DIN), .DIP(DINP), 
  .DO(ram3_DOUT), .DOP(ram3_DOUTP),
  .EN(ram_EN[3]),
  .SSR(1'b0),
  .WE(WE));

RAMB16_S9 ram4 (
  .CLK(CLK), .ADDR(ADDR[10:0]),
  .DI(DIN), .DIP(DINP), 
  .DO(ram4_DOUT), .DOP(ram4_DOUTP),
  .EN(ram_EN[4]),
  .SSR(1'b0),
  .WE(WE));

endmodule

