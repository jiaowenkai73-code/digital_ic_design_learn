`timescale 1ns/1ps

module mod_asyncfifo_tb;

reg             rst_n;
reg             wr_clk;
reg             rd_clk;
reg             wr_en;
reg             rd_en;
reg [DATA_WIDTH-1:0] data_in;

reg [DATA_WIDTH-1:0] tempdata;
    
wire [DATA_WIDTH-1:0] data_out;
wire                  full;
wire                  empty;    

parameter DATA_WIDTH   = 8;
parameter MEMORY_DEPTH = 8;

integer i;
integer wi;
integer ri;

asyncfifo_top #(
    .width(DATA_WIDTH),
    .depth(MEMORY_DEPTH)
)mod_dut(
    .rst_n(rst_n),
    .wr_clk(wr_clk),
    .rd_clk(rd_clk),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .full(full),
    .empty(empty)    
);

//write clk 100MHZ
initial begin
   #0 wr_clk = 0;
   forever #5 wr_clk = ~wr_clk;
end

//read clk 71.43MHZ
initial begin
   #0 rd_clk = 0;
   forever #7 rd_clk = ~rd_clk;
end

initial begin
    rst_n = 0;
    wr_en = 0;
    rd_en = 0;
    data_in = {DATA_WIDTH{1'b0}};

    #20;
    rst_n= 1;
end

//simulation
initial begin

    wait(rst_n === 1'b1);

//write until full
    for(i = 0; i < MEMORY_DEPTH ; i = i + 1) begin
        push(8'h10 + i);
    end

//try writing when fifo is full
    push(8'h88);
    push(8'h66);

//read all data
    wait(empty === 1'b0);

    for(i = 0; i < MEMORY_DEPTH ; i = i + 1) begin
         pop(tempdata);
    end

//try reading when fifo is empty
    
    pop(tempdata);
    pop(tempdata);


//write and read at the same time
fork
    begin
        // Write process
        for (wi = 0; wi < 6; wi = wi + 1)
            push(8'h80 + wi);
    end

    begin
        // Read process
        for (ri = 0; ri < 6; ri = ri + 1) begin
            wait(empty === 1'b0);
            pop(tempdata);
        end
    end
join

    #50;
    $finish;
end

initial begin
    #10000;
    $fatal(1, "Simulation timeout!");
end

//write data
task push (input [DATA_WIDTH-1:0] data); begin
     @(negedge wr_clk);
     wr_en = 1'b1;
     data_in = data;

     @(negedge wr_clk);
     wr_en =1'b0;
  end
endtask

//read data
task pop(output[DATA_WIDTH-1:0] data); begin
     @(negedge rd_clk);
     rd_en =1'b1;

     @(posedge rd_clk);
     #1;
     data = data_out;

     @(negedge rd_clk);
     rd_en = 1'b0;
  end
endtask

endmodule