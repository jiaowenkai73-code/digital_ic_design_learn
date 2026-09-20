//输入输出端口声明
module uart_tx(
  input  wire clk,
  input  wire rst_n,
  input  wire [7:0] data,  
  input  wire start_tx,
  output reg tx
);

//状态定义
parameter IDLE      = 2'b00;
parameter START_BIT = 2'b01;
parameter DATA      = 2'b10;
parameter STOP_BIT  = 2'b11;

reg [1:0] current_state;
reg [1:0] next_state;
reg [2:0] data_counter;
reg [8:0] baud_counter;
reg [7:0] data_reg;

//时序逻辑
always@ (posedge clk) begin
   if (!rst_n)
       current_state <= IDLE;
   else 
       current_state <= next_state;
end

//组合逻辑
always@ (*) begin
   next_state = current_state;//默认状态不变
   tx = 1'b1;

   case (current_state)

     IDLE: begin
           if (start_tx) begin
               next_state = START_BIT;
           end
           else
               next_state = IDLE;
     end
     
     START_BIT: begin
           if (baud_counter == 9'd433) begin
               next_state = DATA;
               tx = 0;
           end
           else begin
                next_state = START_BIT;
                tx = 0;  
           end
     end
           
     
     DATA: begin
           tx =data_reg[data_counter];

           if (baud_counter == 9'd433) begin
               if (data_counter == 3'd7) 
                     next_state = STOP_BIT;
               else 
                     next_state = DATA;
           end
           else 
                next_state = DATA;
      end
             
    
     STOP_BIT: begin
               tx = 1'b1;
               if (baud_counter == 9'd433)
                   next_state = IDLE;
               else
                   next_state = STOP_BIT;
     end

    endcase
end

//波特率计数器
always@ (posedge clk) begin
   if (!rst_n)
       baud_counter <= 0;

   else begin     
        if (current_state == IDLE)
            baud_counter <= 0;

        else if (baud_counter == 9'd433)
            baud_counter <= 0;

        else 
            baud_counter <= baud_counter + 1;
    end
end

//数据计数器
always@ (posedge clk) begin 
         if (!rst_n)
             data_counter <= 0;

         else begin
              if (current_state == DATA) begin 

                  if (baud_counter == 9'd433) begin
                      if (data_counter == 3'd7)
                          data_counter <= 0;
                      else 
                      data_counter <= data_counter + 1;
                  end
              end
              else
                  data_counter <= 0;
             
         end
end            

//将数据保存到寄存器
always@(posedge clk) begin
    if (!rst_n)
        data_reg <= 8'b0;
    else if ((current_state == IDLE) && (start_tx == 1'b1))
        data_reg <= data;
end


       
endmodule