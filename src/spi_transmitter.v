//--------------------------------------------------------------------------------
// transmitter.v
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
// Takes 32bit (one sample) and sends it out on the SPI interface
// End of transmission is signalled by taking back the busy flag.
//
//--------------------------------------------------------------------------------
//
// 12/29/2010 - Verilog Version + cleanups created by Ian Davis (IED) - mygizmos.org
// 01/22/2011 - IED - Tweaked to accept meta data write requests.
//

`timescale 1ns/100ps

module spi_transmitter(
  clock, sclk, extReset,
  send, send_data, send_valid,
  writeMeta, meta_data,
  cs, query_id, query_dataIn, dataIn,
  // outputs...
  tx, busy, byteDone);

input clock;
input sclk;
input extReset;

input send;
input [31:0] send_data;
input [3:0] send_valid;
input writeMeta;
input [7:0] meta_data;
input cs;
input query_id;
input query_dataIn;
input [31:0] dataIn;
output tx;
output busy;
output byteDone;

reg [31:0] sampled_send_data, next_sampled_send_data;
reg [3:0] sampled_send_valid, next_sampled_send_valid;
reg [2:0] bits, next_bits;
reg [1:0] bytesel, next_bytesel;
reg byteDone, next_byteDone;
reg dly_sclk, next_dly_sclk; 
reg busy, next_busy;

reg [7:0] txBuffer, next_txBuffer;
reg tx, next_tx;
//wire tx = txBuffer[7];

reg writeReset, writeByte; 


//
// Byte select mux...   Revised for better synth. - IED
//
reg [7:0] byte;
reg disabled;
always @*
begin
  #1;
  byte = 0;
  disabled = 0;
  case (bytesel)
    2'h0 : begin byte = sampled_send_data[7:0]; disabled = !sampled_send_valid[0]; end
    2'h1 : begin byte = sampled_send_data[15:8]; disabled = !sampled_send_valid[1]; end
    2'h2 : begin byte = sampled_send_data[23:16]; disabled = !sampled_send_valid[2]; end
    2'h3 : begin byte = sampled_send_data[31:24]; disabled = !sampled_send_valid[3]; end
  endcase
end



//
// Send one byte synchronized to falling edge of SPI clock...
//
always @(posedge clock)
begin
  dly_sclk = next_dly_sclk;
  bits = next_bits;
  byteDone = next_byteDone;
  txBuffer = next_txBuffer;
  tx = next_tx;
end

always @*
begin
  #1;
  next_dly_sclk = sclk;
  next_bits = bits;
  next_byteDone = byteDone;
  next_txBuffer = txBuffer;
  next_tx = tx;

  if (writeReset) // simulation clean up - IED
    begin
      next_bits = 0;
      next_byteDone = 1'b1;
      next_txBuffer = 8'hFF;
    end
  else if (writeByte) 
    begin
      next_bits = 0;
      next_byteDone = disabled;
      next_txBuffer = byte;
    end
  else if (writeMeta)
    begin
      next_bits = 0;
      next_byteDone = 0;
      next_txBuffer = meta_data;
    end
 
  // The PIC microcontroller asserts CS# in response to FPGA 
  // asserting dataReady (busy signal from this module actually).
  // Until CS# asserts though keep the bits counter reset...
  if (cs) next_bits = 0;

  // Output on falling edge of sclk when cs asserted...
  if (!cs && dly_sclk && !sclk && !byteDone)
    begin
//      next_txBuffer = {txBuffer,1'b1};
      next_bits = bits + 1'b1;
      next_byteDone = &bits;
    end

  next_tx = (cs || byteDone) ? 1'b1 : next_txBuffer[~bits];
end


//
// Control FSM for sending 32 bit words out SPI interface...
//
parameter [1:0] INIT = 0, IDLE = 1, SEND = 2, POLL = 3;
reg [1:0] state, next_state;

initial state = INIT;
always @(posedge clock or posedge extReset) 
begin
  if (extReset) 
    begin
      state = INIT;
      sampled_send_data = 32'h0;
      sampled_send_valid = 4'h0;
      bytesel = 3'h0;
      busy = 1'b0;
    end 
  else 
    begin
      state = next_state;
      sampled_send_data = next_sampled_send_data;
      sampled_send_valid = next_sampled_send_valid;
      bytesel = next_bytesel;
      busy = next_busy;
    end
end

always @*
begin
  #1;
  next_state = state;
  next_sampled_send_data = sampled_send_data;
  next_sampled_send_valid = sampled_send_valid;
  next_bytesel = bytesel;

  next_busy = (state != IDLE) || send || !byteDone;

  writeReset = 1'b0;
  writeByte = 1'b0;

  case (state) // when write is '1', data will be available with next cycle
    INIT :
      begin
	writeReset = 1'b1;
        next_sampled_send_data = 32'h0;
        next_sampled_send_valid = 4'hF;
        next_bytesel = 3'h0;
        next_busy = 1'b0;
	next_state = IDLE;
      end

    IDLE : 
      begin
        next_sampled_send_data = send_data;
        next_sampled_send_valid = send_valid;
	next_bytesel = 0;

        if (send) 
          next_state = SEND;
        else if (query_id) // output dword containing "SLA1" signature
	  begin
            next_sampled_send_data = 32'h534c4131; // "SLA1"
            next_sampled_send_valid = 4'hF;
            next_state = SEND;
          end
        else if (query_dataIn)
	  begin
            next_sampled_send_data = dataIn;
            next_sampled_send_valid = 4'hF;
            next_state = SEND;
	  end
      end

    SEND : // output dword send by controller...
      begin
        writeByte = 1'b1;
        next_bytesel = bytesel + 1'b1;
	next_state = POLL;
      end

    POLL : 
      begin
        if (byteDone)
	  next_state = (~|bytesel) ? IDLE : SEND;
      end

    default : next_state = INIT;
  endcase
end
endmodule

