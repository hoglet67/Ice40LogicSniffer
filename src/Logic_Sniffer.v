//--------------------------------------------------------------------------------
// Logic_Sniffer.vhd
//
// Copyright (C) 2006 Michael Poppitz
// 
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin St, Fifth Floor, Boston, MA 02110, USA
//
//--------------------------------------------------------------------------------
//
// Details: http://www.sump.org/projects/analyzer/
//
// Logic Analyzer top level module. It connects the core with the hardware
// dependend IO modules and defines all inputs and outputs that represent
// phyisical pins of the fpga.
//
// It defines two constants FREQ and RATE. The first is the clock frequency 
// used for receiver and transmitter for generating the proper baud rate.
// The second defines the speed at which to operate the serial port.
//
//--------------------------------------------------------------------------------
//
// 12/29/2010 - Verilog Version + cleanups created by Ian Davis (IED) - mygizmos.org
//

`timescale 1ns/100ps

//`define COMM_TYPE_SPI 1		// comment out for UART mode

module Logic_Sniffer(
  bf_clock,
  extClockIn,
  extClockOut,
  extTriggerIn,
  extTriggerOut,
  indata,
`ifdef COMM_TYPE_SPI
  miso, mosi, sclk, cs,
`else
  rx, tx,
`endif
  dataReady,
  armLEDnn,
  triggerLEDnn);

parameter [31:0] MEMORY_DEPTH=6;
parameter [31:0] CLOCK_SPEED=50;
parameter [1:0] SPEED=2'b00;

// Sets the speed for UART communications
// SYSTEM_JITTER = "1000 ps"
input bf_clock;
input extClockIn;
output extClockOut;
input extTriggerIn;
output extTriggerOut;
inout [31:0] indata;
output dataReady;
output armLEDnn;
output triggerLEDnn;

`ifdef COMM_TYPE_SPI
  output miso;
  input mosi;
  input sclk;
  input cs;
`else
  input rx;
  output tx;
`endif


parameter FREQ = 100000000;  // limited to 100M by onboard SRAM
parameter TRXSCALE = 28;  // 100M / 28 / 115200 = 31 (5bit)  --If serial communications are not working then try adjusting this number.
parameter RATE = 921600;  // maximum & base rate

wire extReset = 1'b0;
wire [39:0] cmd;
wire [31:0] sram_wrdata;
wire [35:0] sram_rddata; 
wire [3:0] sram_rdvalid;
wire [31:0] stableInput;

wire [7:0] opcode;
wire [31:0] config_data; 
assign {config_data,opcode} = cmd;


// Instantiate PLL...
pll_wrapper pll_wrapper ( .clkin(bf_clock), .clk0(clock));


// Output dataReady to PIC (so it'll enable our SPI CS#)...
dly_signal dataReady_reg (clock, busy, dataReady);


// Use DDR output buffer to isolate clock & avoid skew penalty...
ddr_clkout extclock_pad (.pad(extClockOut), .clk(extclock));



//
// Configure the probe pins...
//
reg [10:0] test_counter, next_test_counter;
always @ (posedge clock) 
begin
  test_counter = next_test_counter;
end
always @*
begin
  #1;
  next_test_counter = test_counter+1'b1;
end

wire [15:0] test_pattern = {
    test_counter[10], test_counter[4],
    test_counter[10], test_counter[4],
    test_counter[10], test_counter[4],
    test_counter[10], test_counter[4],
    test_counter[10], test_counter[4],
    test_counter[10], test_counter[4],
    test_counter[10], test_counter[4],
    test_counter[10], test_counter[4]};

outbuf io_indata31 (.pad(indata[31]), .clk(clock), .outsig(test_pattern[15]), .oe(extTestMode));
outbuf io_indata30 (.pad(indata[30]), .clk(clock), .outsig(test_pattern[14]), .oe(extTestMode));
outbuf io_indata29 (.pad(indata[29]), .clk(clock), .outsig(test_pattern[13]), .oe(extTestMode));
outbuf io_indata28 (.pad(indata[28]), .clk(clock), .outsig(test_pattern[12]), .oe(extTestMode));
outbuf io_indata27 (.pad(indata[27]), .clk(clock), .outsig(test_pattern[11]), .oe(extTestMode));
outbuf io_indata26 (.pad(indata[26]), .clk(clock), .outsig(test_pattern[10]), .oe(extTestMode));
outbuf io_indata25 (.pad(indata[25]), .clk(clock), .outsig(test_pattern[9]), .oe(extTestMode));
outbuf io_indata24 (.pad(indata[24]), .clk(clock), .outsig(test_pattern[8]), .oe(extTestMode));
outbuf io_indata23 (.pad(indata[23]), .clk(clock), .outsig(test_pattern[7]), .oe(extTestMode));
outbuf io_indata22 (.pad(indata[22]), .clk(clock), .outsig(test_pattern[6]), .oe(extTestMode));
outbuf io_indata21 (.pad(indata[21]), .clk(clock), .outsig(test_pattern[5]), .oe(extTestMode));
outbuf io_indata20 (.pad(indata[20]), .clk(clock), .outsig(test_pattern[4]), .oe(extTestMode));
outbuf io_indata19 (.pad(indata[19]), .clk(clock), .outsig(test_pattern[3]), .oe(extTestMode));
outbuf io_indata18 (.pad(indata[18]), .clk(clock), .outsig(test_pattern[2]), .oe(extTestMode));
outbuf io_indata17 (.pad(indata[17]), .clk(clock), .outsig(test_pattern[1]), .oe(extTestMode));
outbuf io_indata16 (.pad(indata[16]), .clk(clock), .outsig(test_pattern[0]), .oe(extTestMode));



//
// Instantiate serial interface....
//
`ifdef COMM_TYPE_SPI

spi_slave spi_slave (
  .clock(clock), 
  .extReset(extReset),
  .sclk(sclk), 
  .cs(cs), 
  .mosi(mosi),
  .dataIn(stableInput),
  .send(send), 
  .send_data(sram_rddata[31:0]), 
  .send_valid(sram_rdvalid),
  // outputs...
  .cmd(cmd), .execute(execute), 
  .busy(busy), .miso(miso));

`else 

serial #(.FREQ(FREQ), .RATE(RATE)) serial (
  .clock(clock), 
  .extReset(extReset),
  .rx(rx),
  .dataIn(stableInput),
  .send(send), 
  .send_data(sram_rddata[31:0]), 
  .send_valid(sram_rdvalid),
  // outputs...
  .cmd(cmd), .execute(execute), 
  .busy(busy), .tx(tx));

`endif 


//
// Instantiate core...
//
core #(.MEMORY_DEPTH(MEMORY_DEPTH)) core (
  .clock(clock),
  .extReset(extReset),
  .extClock(extClockIn),
  .extTriggerIn(extTriggerIn),
  .opcode(opcode),
  .config_data(config_data),
  .execute(execute),
  .indata(indata),
  .outputBusy(busy),
  // outputs...
  .sampleReady50(),
  .stableInput(stableInput),
  .outputSend(send),
  .memoryWrData(sram_wrdata),
  .memoryRead(read),
  .memoryWrite(write),
  .memoryLastWrite(lastwrite),
  .extTriggerOut(extTriggerOut),
  .extClockOut(extclock), 
  .armLEDnn(armLEDnn),
  .triggerLEDnn(triggerLEDnn),
  .wrFlags(wrFlags),
  .extTestMode(extTestMode));


//
// Instantiate the memory...
//
sram_interface sram_interface (
  .clk(clock),
  .wrFlags(wrFlags), 
  .config_data(config_data[5:2]),
  .write(write), .lastwrite(lastwrite), .read(read),
  .wrdata({4'h0,sram_wrdata}),
  // outputs...
  .rddata(sram_rddata),
  .rdvalid(sram_rdvalid));

endmodule

