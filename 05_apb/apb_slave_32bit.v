module apb_slave#(
       parameter data_width = 32,
       parameter address_width = 8
)(
       input  wire pclk,
       input  wire preset_n,
       input  wire [address_width - 1:0] paddr,
       input  wire psel,
       input  wire penable,
       input  wire pwrite,
       input  wire [data_width - 1:0] pwdata,
       output reg  [data_width - 1:0] prdata,
       output wire  pready,
       output wire  pslverr
);

//pwrite = 1 carry out write instead carry out read

//byte addressing 1byte =8 bits
localparam ADD_CTRL   = 8'h00;  //write&read
localparam ADD_DATA   = 8'h04;  //write&read
localparam ADD_STATUS = 8'h08;  //read only
localparam [data_width-1:0] status = 1;

//uart_reg
reg [data_width - 1:0] ctrl_reg;
reg [data_width - 1:0] data_reg;
wire write_enable;
wire read_enable;


assign write_enable = psel && penable && pready && pwrite;
assign read_enable  = psel && penable && pready && !pwrite;
assign pready  = 1'b1;
assign pslverr = 1'b0;

//sequential logic
always @(posedge pclk or negedge preset_n) begin
       if (!preset_n) begin
           ctrl_reg <= 32'h0;
           data_reg <= 32'h0;
       end

       else if (write_enable) begin

          case(paddr)

            ADD_CTRL: ctrl_reg <= pwdata;
            ADD_DATA: data_reg <= pwdata;
            default:;
          endcase
       end

end

//combinational logic
always @(*) begin
    prdata = {data_width{1'b0}};
    if (read_enable) begin
            case(paddr)
                ADD_CTRL: prdata = ctrl_reg;
                ADD_DATA: prdata = data_reg;
                ADD_STATUS: prdata = status;
                default: prdata = 32'h0;
            endcase
       end
end

endmodule
