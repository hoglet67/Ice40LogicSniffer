`timescale 1ns / 1ns

module Logic_Sniffer_tb();

   reg clk;
   reg rstn;
   
   reg rx;
   wire tx;

   integer j;
   
   task send_byte;
      input [7:0] byte;
      begin
         #8680 rx = 0;      
         for (j = 0; j < 8; j = j + 1)
           begin
              #8680 rx = byte[j];
           end
         #8680 rx = 1;
      end
   endtask // for
   
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
      
      send_byte(8'h02);

      #1000000; // 1ms
      
      $finish;

   end

   always
     #5 clk = !clk;


endmodule
