module wr_logic#(
    parameter depth = 8
)(
    input  wire                   wr_clk,
    input  wire                   rst_n,
    input  wire                   wr_en,
    input  wire [$clog2(depth):0] rd_domain_gray,
    output wire                   full,
    output wire                   wr_valid,
    output reg  [$clog2(depth):0] wr_domain_gray,
    output reg  [$clog2(depth):0] wr_pointer
);
localparam pointer_width = $clog2(depth);

wire [pointer_width:0] wr_pointer_next;
wire [pointer_width:0] wr_domain_gray_next; 

assign wr_pointer_next = wr_pointer + wr_valid;
assign wr_domain_gray_next = wr_pointer_next ^ (wr_pointer_next >> 1);
assign full = (wr_domain_gray == {~rd_domain_gray[pointer_width:pointer_width-1],rd_domain_gray[pointer_width-2:0]});
assign wr_valid = (!full && wr_en && rst_n);

always @(posedge wr_clk or negedge rst_n) begin
     if (!rst_n) begin 
         wr_pointer <= {(pointer_width+1){1'b0}};
         wr_domain_gray <= {(pointer_width+1){1'b0}};
     end
     else if (!full && wr_en) begin
         wr_pointer     <= wr_pointer_next;    
         wr_domain_gray <= wr_domain_gray_next;
     end
end

endmodule
        


