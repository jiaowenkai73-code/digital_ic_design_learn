module two_stage_dff #(
    parameter WIDTH = 4
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0] data_out
);

reg [WIDTH-1:0] dff1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dff1     <= {WIDTH{1'b0}};
        data_out <= {WIDTH{1'b0}};
    end
    else begin
        dff1     <= data_in;
        data_out <= dff1;
    end
end

endmodule