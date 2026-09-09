module counter_4bit(
    input wire clk,
    input wire rst,
    input wire en,
    output reg [3:0] count
);
always@(posedge clk)
begin
    if(rst == 1'b1)
        count <= 4'b0000;
    else if(en)
        count <= count + 1'b1;
end
endmodule