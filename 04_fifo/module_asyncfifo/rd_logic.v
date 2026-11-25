
module rd_logic#(
    parameter depth = 8
)(
    input  wire                   rd_clk,
    input  wire                   rst_n,
    input  wire                   rd_en,
    input  wire [$clog2(depth):0] wr_domain_gray,
    output wire                   empty,
    output wire                   rd_valid,
    output reg  [$clog2(depth):0] rd_domain_gray,
    output reg  [$clog2(depth):0] rd_pointer
);

localparam pointer_width = $clog2(depth);

wire [pointer_width:0] rd_pointer_next;
wire [pointer_width:0] rd_domain_gray_next;

assign rd_pointer_next = rd_pointer + (!empty && rd_en);
assign rd_domain_gray_next = rd_pointer_next ^ (rd_pointer_next >> 1);
assign empty = (rd_domain_gray == wr_domain_gray);
assign rd_valid = (!empty && rd_en && rst_n);

always @(posedge rd_clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_pointer     <= {(pointer_width+1){1'b0}};
        rd_domain_gray <= {(pointer_width+1){1'b0}};
    end
    else if (!empty && rd_en) begin
        rd_pointer     <= rd_pointer_next;
        rd_domain_gray <= rd_domain_gray_next;
    end
end

endmodule
