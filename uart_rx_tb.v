`timescale 1ns/1ps
module uart_rx_tb;
    // Parameters
    parameter CLK_RATE = 50000000;
    parameter BAUD_RATE = 115200;
    parameter CLOCKS_PER_BIT = CLK_RATE / BAUD_RATE;
    parameter BIT_PERIOD = CLOCKS_PER_BIT * 20; // 1 bit period in ns
    
    // DUT inputs
    reg clk = 0;
    reg rstn = 0;
    reg rx = 1; // idle state is HIGH
    
    // DUT outputs
    wire [7:0] data_out;
    wire data_valid;
    wire is_valid;      // New signal to monitor
    wire [1:0] state_bits; // New state bits to monitor
    
    // Instantiate the UART RX module with new signals
    uart_rx #(
        .CLK_RATE(CLK_RATE),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .rx(rx),
        .data_out(data_out),
        .data_valid(data_valid),
        .is_valid(is_valid),         // Connect new signal
        .state_bits(state_bits)      // Connect state bits
    );
    
    // Clock generation (50 MHz)
    always #10 clk = ~clk; // 20ns period -> 50MHz
    
    // Task to send a byte in 8N1 format
    task send_uart_byte;
        input [7:0] data;
        integer i;
        begin
            // Start bit (LOW)
            rx = 0;
            #(BIT_PERIOD);
            
            // Send 8 data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(BIT_PERIOD);
            end
            
            // Stop bit (HIGH)
            rx = 1;
            #(BIT_PERIOD);
        end
    endtask
    
    // Monitor task to display reception results
    always @(posedge clk) begin
        if (data_valid) begin
            $display("Time: %0t - Received data: 0x%h", $time, data_out);
        end
    end
    
    // Monitor state bits changes
    always @(state_bits) begin
        case(state_bits)
            2'b00: $display("Time: %0t - State: IDLE", $time);
            2'b01: $display("Time: %0t - State: START", $time);
            2'b11: $display("Time: %0t - State: DATA", $time);
            2'b10: $display("Time: %0t - State: STOP", $time);
            default: $display("Time: %0t - State: UNKNOWN", $time);
        endcase
    end
    
    // Monitor is_valid changes
    always @(is_valid) begin
        if (is_valid)
            $display("Time: %0t - Data reception in progress (is_valid=1)", $time);
        else
            $display("Time: %0t - Data reception complete (is_valid=0)", $time);
    end
    
    // Stimulus
    initial begin
        $display("Starting UART RX Testbench...");
        $dumpfile("uart_rx_tb.vcd");  // For waveform viewing
        $dumpvars(0, uart_rx_tb);
        
        // Reset
        #100;
        rstn = 1;
        #100;
        
        // Send 4 bytes: 0x55, 0xFF, 0x00, 0xF0
        $display("Sending byte: 0x55");
        send_uart_byte(8'h55);
        #(BIT_PERIOD); // Add gap between transmissions
        
        $display("Sending byte: 0xFF");
        send_uart_byte(8'hFF);
        #(BIT_PERIOD);
        
        $display("Sending byte: 0x00");
        send_uart_byte(8'h00);
        #(BIT_PERIOD);
        
        $display("Sending byte: 0xF0");
        send_uart_byte(8'hF0);
        
        // Wait for last transmission to complete
        #(10 * BIT_PERIOD);
        
        $display("Testbench completed");
        $finish;
    end
endmodule