module uart_rx(
    input wire clk,
    input wire rst_n,
    input wire rx,
    output reg [7:0] data_out,
    output reg data_valid
);

parameter IDLE      = 2'b00;
parameter START_BIT = 2'b01;
parameter DATA      = 2'b10;
parameter STOP_BIT  = 2'b11;

reg [1:0] current_state;
reg [1:0] next_state;
reg [2:0] data_counter;
reg [8:0] baud_counter;


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
   data_valid = 1'b0;

   case (current_state)

     IDLE: begin
           if (!rx) begin
               next_state = START_BIT;
           end
           else
               next_state = IDLE;
     end
     
     START_BIT: begin
           if ((baud_counter == 9'd217)) begin
                 if (!rx)
                    next_state = START_BIT;
                 else
                    next_state = IDLE;
           end

           if (baud_counter == 9'd433) 
                    next_state = DATA;
           
     end
           
     
     DATA: begin
           

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
               if ((baud_counter == 9'd217) && (rx)) 
                   data_valid = 1'b1;
               
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
        data_out <= 8'b0;
    else if ((current_state == DATA) && (baud_counter == 9'd217))
        data_out[data_counter] <= rx;
end


       
endmodule