`timescale 1ns / 1ns

module Logic_Sniffer_tb();

   parameter BITTIME = (1000000000/115200);
   parameter BYTETIME = BITTIME * 10;

   reg clk;
   reg rstn;

   reg rx;
   wire tx;

   integer j;

   task send_byte;
      input [7:0] byte;
      begin
         #BITTIME rx = 0;
         for (j = 0; j < 8; j = j + 1)
           begin
              #BITTIME rx = byte[j];
           end
         #BITTIME rx = 1;
      end
   endtask

   task send_short;
      input [7:0] cmd;
      begin
         send_byte(cmd);
      end
   endtask

   task send_long;
      input [7:0] cmd;
      input [31:0] data;
      begin
         send_byte(cmd);
         send_byte(data[31:24]);
         send_byte(data[23:16]);
         send_byte(data[15: 8]);
         send_byte(data[ 7: 0]);
      end
   endtask

Logic_Sniffer
   DUT
     (
      .bf_clock(clk),
      .extResetn(rstn),
      .extClockIn(1'b0),
      .extClockOut(),
      .extTriggerIn(1'b0),
      .extTriggerOut(),
      .indata(32'h12345678),
      .rx(rx),
      .tx(tx),
      .dataReady(),
      .armLEDnn(),
      .triggerLEDnn()
      );

   initial begin
      $dumpvars;

      // initialize 100MHz clock
      clk = 1'b0;
      rstn = 1'b1;

      rx = 1'b1;

      #1000 rstn = 1'b0;
      #1000 rstn = 1'b1;
      #1000 ;

      send_short(8'h02);
      #(BYTETIME * 5);
      send_short(8'h04);
      #(BYTETIME * 64);
      send_short(8'h00);
      send_short(8'h00);
      send_short(8'h00);
      send_short(8'h00);
      send_short(8'h00);
      send_short(8'h02);
      #(BYTETIME * 5);
      send_long(8'hc0, 32'h00000000);
      send_long(8'hc1, 32'h00000000);
      send_long(8'hc2, 32'h00000008);
      send_long(8'hc3, 32'h00000000);
      send_long(8'h80, 32'h00000000);
      send_long(8'h81, 32'hff00ff00);
      send_long(8'h82, 32'h00000000);
      send_short(8'h01);

      #1000000; // 1ms

      $finish;

   end

   always
     #5 clk = !clk;


endmodule
