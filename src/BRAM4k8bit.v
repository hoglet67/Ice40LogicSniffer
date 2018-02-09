module BRAM4k8bit(CLK, ADDR, WE, EN, DIN, DOUT);
input CLK;
input WE;
input EN;
input [11:0] ADDR;
input [7:0] DIN;
output reg [7:0] DOUT;

//   reg [7:0] mem [4095:0];
   reg [7:0] mem [3583:0];
   
           
   always @(posedge CLK) begin
        if (EN) begin
           if (WE) begin
              mem[ADDR] <= DIN;              
           end
           DOUT <= mem[ADDR];           
        end      
   end
   
endmodule

