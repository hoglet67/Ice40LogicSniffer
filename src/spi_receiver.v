//--------------------------------------------------------------------------------
// spi_receiver.v
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
// Receives commands from the SPI interface. The first byte is the commands
// opcode, the following (optional) four byte are the command data.
// Commands that do not have the highest bit in their opcode set are
// considered short commands without data (1 byte long). All other commands are
// long commands which are 5 bytes long.
//
// After a full command has been received it will be kept available for 10 cycles
// on the op and data outputs. A valid command can be detected by checking if the
// execute output is set. After 10 cycles the registers will be cleared
// automatically and the receiver waits for new data from the serial port.
//
//--------------------------------------------------------------------------------
//
// 12/29/2010 - Verilog Version + cleanups created by Ian Davis (IED) - mygizmos.org
//

`timescale 1ns/100ps

module spi_receiver(
  clock, sclk, extReset, 
  mosi, cs, transmitting,
  // outputs...
  op, data, execute);

input clock;
input sclk;
input extReset;
input mosi;
input cs;
input transmitting;
output [7:0] op;
output [31:0] data;
output execute;

parameter 
  READOPCODE = 1'h0,
  READLONG = 1'h1;

reg state, next_state;			// receiver state
reg [1:0] bytecount, next_bytecount;	// count rxed bytes of current command
reg [7:0] opcode, next_opcode;		// opcode byte
reg [31:0] databuf, next_databuf;	// data dword
reg execute, next_execute;

reg [2:0] bitcount, next_bitcount;	// count rxed bits of current byte
reg [7:0] spiByte, next_spiByte;
reg byteready, next_byteready;

assign op = opcode;
assign data = databuf;


dly_signal mosi_reg (clock, mosi, sampled_mosi);
dly_signal dly_sclk_reg (clock, sclk, dly_sclk);
wire sclk_posedge = !dly_sclk && sclk;

dly_signal dly_cs_reg (clock, cs, dly_cs);
wire cs_negedge = dly_cs && !cs;


//
// Accumulate byte from serial input...
//
initial bitcount = 0;
always @(posedge clock or posedge extReset)
begin
  if (extReset)
    bitcount = 0;
  else bitcount = next_bitcount;
end

always @(posedge clock)
begin
  spiByte = next_spiByte;
  byteready = next_byteready;
end

always @*
begin
  #1;
  next_bitcount = bitcount;
  next_spiByte = spiByte;
  next_byteready = 1'b0;

  if (cs_negedge)
    next_bitcount = 0;

  if (sclk_posedge) // detect rising edge of sclk
    if (cs)
      begin
        next_bitcount = 0;
        next_spiByte = 0;
      end
    else
      begin
        next_bitcount = bitcount + 1'b1;
        next_byteready = &bitcount;
        next_spiByte = {spiByte[6:0],sampled_mosi};
      end
end



//
// Command tracking...
//
initial state = READOPCODE;
always @(posedge clock or posedge extReset) 
begin
  if (extReset)
    state = READOPCODE;
  else state = next_state;
end

initial databuf = 0;
always @(posedge clock) 
begin
  bytecount = next_bytecount;
  opcode = next_opcode;
  databuf = next_databuf;
  execute = next_execute;
end

always @*
begin
  #1;
  next_state = state;
  next_bytecount = bytecount;
  next_opcode = opcode;
  next_databuf = databuf;
  next_execute = 1'b0;

  case (state)
    READOPCODE : // receive byte
      begin
	next_bytecount = 0;
	if (byteready)
	  begin
	    next_opcode = spiByte;
	    if (spiByte[7])
	      next_state = READLONG;
	    else // short command
	      begin
		next_execute = 1'b1;
	  	next_state = READOPCODE;
	      end
	  end
      end

    READLONG : // receive 4 word parameter
      begin
	if (byteready)
	  begin
	    next_bytecount = bytecount + 1'b1;
	    next_databuf = {spiByte,databuf[31:8]};
	    if (&bytecount) // execute long command
	      begin
		next_execute = 1'b1;
	  	next_state = READOPCODE;
	      end
	  end
      end
  endcase
end
endmodule

