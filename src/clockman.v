//--------------------------------------------------------------------------------
// clockman.vhd
//
// Author: Michael "Mr. Sump" Poppitz
//
// Details: http://www.sump.org/projects/analyzer/
//
// This is only a wrapper for Xilinx' DCM component so it doesn't
// have to go in the main code and can be replaced more easily.
//
// Creates 100Mhz core clk0 from 32Mhz input reference clock.
//
//--------------------------------------------------------------------------------
//
// 12/29/2010 - Verilog Version created by Ian Davis - mygizmos.org
// 
// 09/08/2013 - Version for Papilio-One by Magnus Karlsson
//

`timescale 1ns/100ps

module pll_wrapper (clkin, clk0);
input clkin; // clock input
output clk0; // double clock rate output

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

wire clkin;
wire clk0;

wire clkfb; 
wire clkfbbuf; 

DCM_SP #(
  .CLKDV_DIVIDE(2.0),
  .CLKFX_DIVIDE(8),
  .CLKFX_MULTIPLY(25),
  .CLKIN_DIVIDE_BY_2("FALSE"),
  .CLKIN_PERIOD(31.250),
  .CLKOUT_PHASE_SHIFT("NONE"),
  .CLK_FEEDBACK("1X"),
  .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
  .DLL_FREQUENCY_MODE("LOW"),
  .DFS_FREQUENCY_MODE("LOW"),
  .DUTY_CYCLE_CORRECTION("TRUE"),
  .PHASE_SHIFT(0),
  .STARTUP_WAIT("FALSE")
  ) DCM_baseClock (
  .CLK0(clkfb),
  .CLKFX(clk0),
  .CLKFB(clkfbbuf),
  .CLKIN(clkin),
  .PSCLK(1'b0),
  .PSEN(1'b0),
  .PSINCDEC(1'b0),
  .RST(1'b0)
);

  BUFG BUFG_clkfb(.I(clkfb), .O(clkfbbuf));
  
endmodule