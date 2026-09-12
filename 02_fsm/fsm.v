module traffic_light(
    input wire clk,
    input wire rst_n,
    output reg red_light,
    output reg green_light,
    output reg yellow_light
);

parameter RED    = 2'b00;
parameter GREEN  = 2'b01;
parameter YELLOW = 2'b10;

reg [1:0] current_state;
reg [1:0] next_state;
 //状态什么时候切换
always @(posedge clk) begin
    if (!rst_n)
        current_state <= RED;
    else
        current_state <= next_state;
end
 //output logic
always @(*) begin
    // 默认值
    next_state   = RED;
    red_light    = 1'b0;
    green_light  = 1'b0;
    yellow_light = 1'b0;

    case (current_state)
        RED: begin
            red_light  = 1'b1;
 
            if (count == 5'b01001)
                next_state = GREEN;
        end

        GREEN: begin
            green_light = 1'b1;

            if (count == 5'd10011)
                next_state  = YELLOW;
        end

        YELLOW: begin
            yellow_light = 1'b1;

            if (count == 5'b00011)
        end

        default: begin
            next_state = RED;
            red_light  = 1'b1;
        end
    endcase
end

always @(posedge clk) begin
    if (!rst_n)
        count <= 5'd0;
    else if (current_state != next_state)
        count <= 5'd0;
    else
        count <= count + 1'b1;
end
endmodule