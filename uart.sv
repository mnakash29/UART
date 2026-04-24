module uart_top
#(
  parameter clk_freq = 1000000,
  parameter baud_rate = 9600
)
(
  input clk, rst, 
  input rx,
  input [7:0] dintx,
  input newd,
  output tx, 
  output [7:0] doutrx,
  output donetx,
  output donerx
);
    
  uarttx #(clk_freq, baud_rate) utx (
    .clk(clk), 
    .rst(rst), 
    .newd(newd), 
    .tx_data(dintx), 
    .tx(tx), 
    .donetx(donetx)
  );   

  uartrx #(clk_freq, baud_rate) rtx (
    .clk(clk), 
    .rst(rst), 
    .rx(rx), 
    .done(donerx), 
    .rxdata(doutrx)
  );      
    
endmodule

//////////////////////////////////////////////////////////////////
// 2. UART TRANSMITTER
//////////////////////////////////////////////////////////////////
module uarttx
#(
  parameter clk_freq = 1000000,
  parameter baud_rate = 9600
)
(
  input clk, rst,
  input newd,
  input [7:0] tx_data,
  output reg tx,
  output reg donetx
);

  localparam clkcount = (clk_freq/baud_rate); 
  
  integer count = 0;
  integer counts = 0;
  reg uclk = 0;
  reg [7:0] din;
  
  enum bit[1:0] {idle = 2'b00, start = 2'b01, transfer = 2'b10, done = 2'b11} state;

  // UART Baud Clock Generator
  always@(posedge clk) begin
    if(count < (clkcount/2) - 1)
      count <= count + 1;
    else begin
      count <= 0;
      uclk <= ~uclk;
    end 
  end
  
  // TX State Machine
  always@(posedge uclk) begin
    if(rst) begin
      state <= idle;
      tx <= 1'b1;
      donetx <= 1'b0;
      counts <= 0;
    end else begin
      case(state)
        idle: begin
          counts <= 0;
          tx <= 1'b1;
          donetx <= 1'b0;
          
          if(newd) begin
            state <= transfer;
            din <= tx_data;
            tx <= 1'b0; // Send Start Bit
          end else begin
            state <= idle;        
          end
        end
        
        transfer: begin
          if(counts <= 7) begin
             tx <= din[counts]; // Send Data Bits
             counts <= counts + 1;
             state <= transfer;
          end else begin
             counts <= 0;
             tx <= 1'b1; // Send Stop Bit
             state <= done;
             donetx <= 1'b1;
          end
        end
        
        done: begin
          donetx <= 1'b0;
          state <= idle;
        end
        
        default : state <= idle;
      endcase
    end
  end

endmodule

//////////////////////////////////////////////////////////////////
// 3. UART RECEIVER
//////////////////////////////////////////////////////////////////
module uartrx
#(
  parameter clk_freq = 1000000, 
  parameter baud_rate = 9600
)
(
  input clk, rst,
  input rx,
  output reg done,
  output reg [7:0] rxdata
);
    
  localparam clkcount = (clk_freq/baud_rate);
  
  integer count = 0;
  integer counts = 0;
  reg uclk = 0;
  reg [7:0] shift_reg = 0; // Private holding register
  
  enum bit[1:0] {idle = 2'b00, start = 2'b01} state;

  // UART Baud Clock Generator
  always@(posedge clk) begin
    if(count < (clkcount/2) - 1)
      count <= count + 1;
    else begin
      count <= 0;
      uclk <= ~uclk;
    end 
  end
  
  // RX State Machine
  always@(posedge uclk) begin
    if(rst) begin
      rxdata <= 8'h00;
      shift_reg <= 8'h00;
      counts <= 0;
      done <= 1'b0;
      state <= idle;
    end else begin
      case(state)
        idle : begin
          counts <= 0;
          done <= 1'b0;
          
          // Wait for Start Bit (rx == 0)
          if(rx == 1'b0)
            state <= start;
          else
            state <= idle;
        end
        
        start: begin
          if(counts <= 7) begin
            counts <= counts + 1;
            // Shift data into private register
            shift_reg <= {rx, shift_reg[7:1]};
          end else begin
            counts <= 0;
            done <= 1'b1;
            // Push fully assembled byte to output port
            rxdata <= shift_reg; 
            state <= idle;
          end
        end
       
        default : state <= idle;
      endcase
    end
  end

endmodule
