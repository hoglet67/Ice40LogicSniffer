//--------------------------------------------------------------------------------
// meta.v
//
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
// Details:
//   http://www.dangerousprototypes.com/ols
//   http://www.gadgetfactory.net/gf/project/butterflylogic
//   http://www.mygizmos.org/ols
//
// Inserts META data into spi_transmitter datapath upon command...
//
`timescale 1ns/100ps

module meta_handler(
  clock, extReset,
  query_metadata, xmit_idle,
  // outputs...
  writeMeta, meta_data);

input clock;
input extReset;
input query_metadata;
input xmit_idle;

output writeMeta;
output [7:0] meta_data;

reg [5:0] metasel, next_metasel;
reg writeMeta;

`define ADDBYTE(cmd) meta_rom[i]<=cmd; i=i+1
`define ADDSHORT(cmd,b0) meta_rom[i]<=cmd; meta_rom[i+1]<=b0; i=i+2
`define ADDLONG(cmd,b0,b1,b2,b3) meta_rom[i]<=cmd; meta_rom[i+1]<=b0; meta_rom[i+2]<=b1; meta_rom[i+3]<=b2; meta_rom[i+4]<=b3; i=i+5


// Create meta data ROM...
reg [5:0] METADATA_LEN;

(* mem2reg *)
reg [7:0] meta_rom[63:0];

wire [7:0] meta_data = meta_rom[metasel];
initial
begin : meta
  integer i;

   for (i=0; i<64; i=i+1) meta_rom[i]<=0; // Padding

  i=0;
  `ADDLONG(8'h01, "O", "p", "e", "n"); // Device name string...
  `ADDLONG(" ", "L", "o", "g", "i");
  `ADDLONG("c", " ", "S", "n", "i");
  `ADDLONG("f", "f", "e", "r", " ");
  `ADDLONG("v", "1", ".", "0", "1");
  `ADDBYTE(0);

  `ADDLONG(8'h02, "3", ".", "0", "8"); // FPGA firmware version string
  `ADDBYTE(0);

  `ADDLONG(8'h21,8'h00,8'h00,8'h40,8'h00); // Amount of sample memory (16K)
  `ADDLONG(8'h23,8'h05,8'hF5,8'hE1,8'h00); // Max sample rate (100Mhz)

  `ADDSHORT(8'h40,8'h20); // Max # of probes
  `ADDSHORT(8'h41,8'h02); // Protocol version

  `ADDBYTE(0); // End of data flag
  METADATA_LEN = i;

end


//
// Control FSM for sending meta data...
//
parameter [1:0] IDLE = 0, METASEND = 1, METAPOLL = 2;
reg [1:0] state, next_state;

initial state = IDLE;
always @(posedge clock or posedge extReset)
begin
  if (extReset)
    begin
      state = IDLE;
      metasel = 3'h0;
    end
  else
    begin
      state = next_state;
      metasel = next_metasel;
    end
end

always @*
begin
  #1;
  next_state = state;
  next_metasel = metasel;

  writeMeta = 1'b0;
  case (state)
    IDLE :
      begin
        next_metasel = 0;
        next_state = (query_metadata && xmit_idle) ? METASEND : IDLE;
      end

    METASEND : // output contents of META data rom - IED
      begin
        writeMeta = 1'b1;
        next_metasel = metasel+1'b1;
        next_state = METAPOLL;
      end

    METAPOLL :
      begin
        if (xmit_idle)
          next_state = (metasel==METADATA_LEN) ? IDLE : METASEND;
      end

    default : next_state = IDLE;
  endcase
end
endmodule
