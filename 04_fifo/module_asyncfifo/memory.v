module memory#(
    parameter depth = 8,
    parameter width = 8
)(  
    input wire                      rst_n,

    input wire                      wr_clk,
    input wire                      wr_en,
    input wire [$clog2(depth)-1:0]  wr_addr,
    input wire [width-1:0]          data_in,

    input  wire                     rd_clk,
    input  wire                     rd_en,
    input  wire [$clog2(depth)-1:0] rd_addr,
    output reg  [width-1:0]         data_out
);

reg [width-1:0] mem [0:depth-1];

always @(posedge wr_clk ) begin
    if (wr_en && rst_n)   //write is prohibited during reset
        mem[wr_addr] <= data_in;
end

always @(posedge rd_clk or negedge rst_n) begin
    if (!rst_n) 
        data_out <= {width{1'b0}};
    else if (rd_en)
        data_out <= mem[rd_addr];
end

      
endmodule