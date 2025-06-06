`timescale 1ns/1ps
module uart_full_tb;
    // Parameters
    parameter CLK_RATE = 50000000;
    parameter BAUD_RATE = 115200;
    parameter CLOCKS_PER_BIT = CLK_RATE / BAUD_RATE;
    parameter BIT_PERIOD = 20 * CLOCKS_PER_BIT; // 1 bit period in ns
    
    // Shared signals
    reg clk = 0;
    reg rstn = 0;
    
    // TX signals
    reg [7:0] tx_data_in = 0;
    reg tx_data_valid = 0;
    wire tx_busy;
    wire [1:0] tx_state_bits;
    
    // RX signals
    wire [7:0] rx_data_out;
    wire rx_data_valid;
    wire rx_is_valid;
    wire [1:0] rx_state_bits;
    
    // Loopback connection
    wire serial_line;
    
    // Instantiate the UART TX module
    uart_tx #(
        .CLK_RATE(CLK_RATE),
        .BAUD_RATE(BAUD_RATE)
    ) tx_module (
        .clk(clk),
        .rstn(rstn),
        .data_in(tx_data_in),
        .data_valid(tx_data_valid),
        .tx(serial_line),
        .busy(tx_busy),
        .state_bits(tx_state_bits)
    );
    
    // Instantiate the UART RX module
    uart_rx #(
        .CLK_RATE(CLK_RATE),
        .BAUD_RATE(BAUD_RATE)
    ) rx_module (
        .clk(clk),
        .rstn(rstn),
        .rx(serial_line),
        .data_out(rx_data_out),
        .data_valid(rx_data_valid),
        .is_valid(rx_is_valid),
        .state_bits(rx_state_bits)
    );
    
    // Clock generation (50 MHz)
    always #10 clk = ~clk; // 20ns period -> 50MHz
    
    // Task to transmit a byte via UART
    task transmit_byte;
        input [7:0] data;
        begin
            // Wait until transmitter is not busy
            wait(!tx_busy);
            
            @(posedge clk);
            tx_data_in = data;
            tx_data_valid = 1;
            
            @(posedge clk);
            tx_data_valid = 0;
            
            // Optional: Wait until the transmission completes
            wait(!tx_busy);
            @(posedge clk);
        end
    endtask
    
    // Task to verify received data
    task verify_reception;
        input [7:0] expected_data;
        begin
            // Wait for data_valid from receiver
            @(posedge rx_data_valid);
            
            if (rx_data_out !== expected_data) begin
                $display("Error: Data mismatch! Expected: 0x%h, Received: 0x%h", 
                         expected_data, rx_data_out);
            end else begin
                $display("Success: Received data 0x%h matches expected data", rx_data_out);
            end
        end
    endtask
    
    // Monitor TX state changes
    always @(tx_state_bits) begin
        case(tx_state_bits)
            2'b00: $display("Time: %0t - TX State: IDLE", $time);
            2'b01: $display("Time: %0t - TX State: START", $time);
            2'b11: $display("Time: %0t - TX State: DATA", $time);
            2'b10: $display("Time: %0t - TX State: STOP", $time);
            default: $display("Time: %0t - TX State: UNKNOWN", $time);
        endcase
    end
    
    // Monitor RX state changes
    always @(rx_state_bits) begin
        case(rx_state_bits)
            2'b00: $display("Time: %0t - RX State: IDLE", $time);
            2'b01: $display("Time: %0t - RX State: START", $time);
            2'b11: $display("Time: %0t - RX State: DATA", $time);
            2'b10: $display("Time: %0t - RX State: STOP", $time);
            default: $display("Time: %0t - RX State: UNKNOWN", $time);
        endcase
    end
    
    // Monitor data reception
    always @(posedge clk) begin
        if (rx_data_valid) begin
            $display("Time: %0t - Data received: 0x%h", $time, rx_data_out);
        end
    end
    
    // Stimulus and loopback testing
    initial begin
        $display("Starting UART Loopback Test...");
        $dumpfile("uart_loopback_tb.vcd");
        $dumpvars(0, uart_full_tb);
        
        // Reset sequence
        #100;
        rstn = 1;
        #100;
        
        // Test with various data patterns
        $display("\nTest 1: Transmitting 0x55");
        fork
            transmit_byte(8'h55);
            verify_reception(8'h55);
        join
        #(BIT_PERIOD);
        
        $display("\nTest 2: Transmitting 0xFF");
        fork
            transmit_byte(8'hFF);
            verify_reception(8'hFF);
        join
        #(BIT_PERIOD);
        
        $display("\nTest 3: Transmitting 0x00");
        fork
            transmit_byte(8'h00);
            verify_reception(8'h00);
        join
        #(BIT_PERIOD);
        
        $display("\nTest 4: Transmitting 0xA5");
        fork
            transmit_byte(8'hA5);
            verify_reception(8'hA5);
        join
        #(BIT_PERIOD);
        
        // Additional tests for rapid transmission
        $display("\nTest 5: Rapid sequential transmission");
        fork
            begin
                transmit_byte(8'h12);
                transmit_byte(8'h34);
                transmit_byte(8'h56);
                transmit_byte(8'h78);
            end
            begin
                verify_reception(8'h12);
                verify_reception(8'h34);
                verify_reception(8'h56);
                verify_reception(8'h78);
            end
        join
        
        #(BIT_PERIOD * 2);
        $display("\nUART Loopback Test completed successfully");
        $finish;
    end
endmodule