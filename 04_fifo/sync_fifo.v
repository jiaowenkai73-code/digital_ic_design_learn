module sync_fifo(
    input  wire       clk,
    input  wire       rst,
    input  wire       wr_en,
    input  wire       rd_en,
    input  wire [7:0] data_in,
    output reg  [7:0] data_out,
    output wire       empty,
    output wire       full
);

reg [7:0] data [0:7];
reg [2:0] wr_pointer;
reg [2:0] rd_pointer;
reg [3:0] count;

always@ (posedge clk) begin
    if (rst)  begin

        wr_pointer <= 0;
        rd_pointer <= 0;
        data_out   <= 0;
        count      <= 0;
    end

//write_data
    else   begin
          if ((wr_en) && (!full)) begin
              data[wr_pointer] <= data_in;
              wr_pointer <= wr_pointer + 1;

          end

//read_data
          if ((rd_en) && (!empty)) begin
              data_out <= data[rd_pointer];
              rd_pointer <= rd_pointer + 1;
          end

//count
          case ({wr_en && !full , rd_en && !empty})

     2'b00:
            count <= count;

     2'b01:
            count <= count -1;

     2'b10:
            count <= count +1;

     2'b11:
            count <= count;
           endcase
     end
end

assign empty = (count == 0);
assign full  = (count == 8);


endmodule
