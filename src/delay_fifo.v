
//--------------------------------------------------------------------------------
//
// delay_fifo.v
// Copyright (C) 2011 Ian Davis
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
// Simple delay FIFO.   Input data delayed by parameter "DELAY" numbers of 
// clocks (1 to 16).  Uses shift register LUT's, so takes only one LUT-RAM 
// per bit regardless of delay.
//
module delay_fifo (
  clock, reset,
  validIn, dataIn,
  // outputs
  validOut, dataOut);

parameter DELAY = 3;	// 1 to 16
parameter WIDTH = 32;

input clock, reset;
input validIn;
input [WIDTH-1:0] dataIn;
output validOut;
output [WIDTH-1:0] dataOut;

reg [(WIDTH + 1) * DELAY - 1 : 0] delay;
   
always @(posedge clock) begin
   delay <= {dataIn, validIn, delay[(WIDTH + 1) * DELAY - 1 : WIDTH + 1]};
end
   
assign validOut = delay[WIDTH];
assign dataOut = delay[WIDTH - 1 : 0];

endmodule

