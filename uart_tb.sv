module uart_tb;

  reg clk = 0;
  reg rst = 0;
  reg [7:0] dintx;
  reg newd;
  
  wire tx; 
  wire rx;   
  wire [7:0] doutrx;
  wire donetx;
  wire donerx;

  // LOOPBACK: Connect TX directly to RX to test simultaneously
  assign rx = tx;

  // Instantiate DUT (Device Under Test)
  uart_top #(1000000, 9600) dut (
    .clk(clk), 
    .rst(rst), 
    .rx(rx), 
    .dintx(dintx), 
    .newd(newd), 
    .tx(tx), 
    .doutrx(doutrx), 
    .donetx(donetx), 
    .donerx(donerx)
  );
    
  // 1MHz Clock Generation
  always #5 clk = ~clk;  

  integer i;

  initial begin
    // Initialize & Reset
    rst = 1;
    newd = 0;
    dintx = 0;
    
    // Wait on the main system clock to clear unknown (x) states
    repeat(10) @(posedge clk);
    rst = 0;

    // Wait a moment for baud clocks to align
    repeat(100) @(posedge clk);

    // Send 10 Random Packets
    for(i = 0; i < 10; i++) begin
      
      // Setup random data
      dintx = $urandom();
      
      // Pulse 'newd' high for just enough time for the TX to see it
      newd = 1;
      @(posedge dut.utx.uclk); 
      newd = 0; 

      // Wait for the transmission to finish
      wait(donetx == 1);
      wait(donerx == 1);

      // Verify and Print Results
      $display("Packet %0d | Sent: %h | Received: %h", i, dintx, doutrx);
      
      if(dintx === doutrx)
         $display("   --> MATCH ✅");
      else
         $display("   --> MISMATCH ❌");

      // Small delay before sending the next packet
      repeat(500) @(posedge clk);
    end

    $finish;
  end
  endmodule
