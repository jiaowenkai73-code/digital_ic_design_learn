module sync_fifo_param # (
    parameter fifo_depth = 16,
    parameter data_width = 10
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       wr_en,
    input  wire       rd_en,
    input  wire [data_width - 1:0] data_in,
    output reg  [data_width - 1:0] data_out,
    output wire       empty,
    output wire       full
);



localparam depth_bit = $clog2 (fifo_depth);

reg [data_width - 1:0] data [0:fifo_depth - 1];
reg [depth_bit :0] wr_pointer;
reg [depth_bit :0] rd_pointer;

always@ (posedge clk) begin
    if (rst)  begin

        wr_pointer <= 0;
        rd_pointer <= 0;
        data_out   <= 0;

    end

//write_data
    else   begin
          if ((wr_en) && (!full)) begin
              data[wr_pointer[depth_bit - 1:0]] <= data_in;
              wr_pointer <= wr_pointer + 1;

          end

//read_data
          if ((rd_en) && (!empty)) begin
              data_out <= data[rd_pointer[depth_bit - 1:0]];
              rd_pointer <= rd_pointer + 1;
          end


     end
end

assign empty = (rd_pointer == wr_pointer);
assign full  =
     (rd_pointer[depth_bit - 1:0] == wr_pointer[depth_bit - 1:0]) &&
     (rd_pointer[depth_bit] != wr_pointer[depth_bit]);


endmodule
