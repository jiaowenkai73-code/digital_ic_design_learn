module asyncfifo_top#(
    parameter width = 8, //data width
    parameter depth = 8  //memory depth
)(
    input wire             rst_n,
    input wire             wr_clk,
    input wire             rd_clk,
    input wire             wr_en,
    input wire             rd_en,
    input wire [width-1:0] data_in,
    
    output wire [width-1:0] data_out,
    output wire             full,
    output wire             empty        
);

localparam pointer_width = $clog2(depth);

//the lines between the different module

//delete the most higher bit 
wire [$clog2(depth)-1:0] wr_addr_line;
wire [$clog2(depth)-1:0] rd_addr_line;

//the complete pointer
wire [$clog2(depth):0] wr_pointer_line;
wire [$clog2(depth):0] rd_pointer_line;

wire                    wr_valid_line;
wire                    rd_valid_line;

wire [$clog2(depth):0] wr_domain_gray_line;
wire [$clog2(depth):0] rd_domain_gray_line;

//2_dff output
wire [pointer_width:0] wr_gray_synced_line;
wire [pointer_width:0] rd_gray_synced_line;

//assignment addr
assign wr_addr_line = wr_pointer_line[pointer_width-1:0];
assign rd_addr_line = rd_pointer_line[pointer_width-1:0];

//instantiation
memory #(
    .depth(depth),
    .width(width)
)memory_dut(
    .rst_n(rst_n),
    .wr_clk(wr_clk),
    .wr_en(wr_valid_line),
    .wr_addr(wr_addr_line),
    .data_in(data_in),
    
    .rd_clk(rd_clk),
    .rd_en(rd_valid_line),
    .rd_addr(rd_addr_line),
    .data_out(data_out)
);

wr_logic #(
    .depth(depth)
)wr_logic_dut(
    .wr_clk(wr_clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .wr_domain_gray(wr_domain_gray_line),
    .rd_domain_gray(rd_gray_synced_line),
    .full(full),
    .wr_valid(wr_valid_line),
    .wr_pointer(wr_pointer_line)
);

rd_logic #(
    .depth(depth)
)rd_logic_dut(
    .rd_clk(rd_clk),
    .rst_n(rst_n),
    .rd_en(rd_en),
    .rd_domain_gray(rd_domain_gray_line),
    .wr_domain_gray(wr_gray_synced_line),
    .empty(empty),
    .rd_valid(rd_valid_line),
    .rd_pointer(rd_pointer_line)
);

//the graycode transmit from rd to wr domain
two_stage_dff #(
    .WIDTH(pointer_width+1)
)two_stage_dff_wrdomain(
    .clk(wr_clk),
    .rst_n(rst_n),
    .data_in(rd_domain_gray_line),
    .data_out(rd_gray_synced_line)
);

//the graycode transmit from wr to rd domain
two_stage_dff #(
    .WIDTH(pointer_width+1)
)two_stage_dff_rddomain(
    .clk(rd_clk),
    .rst_n(rst_n),
    .data_in(wr_domain_gray_line),
    .data_out(wr_gray_synced_line)
);

endmodule