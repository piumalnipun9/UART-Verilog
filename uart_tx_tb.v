`timescale 1ns/1ps
module uart_tx_tb;
    // Parameters
    parameter CLK_RATE = 50000000;
    parameter BAUD_RATE = 115200;
    parameter CLOCKS_PER_BIT = CLK_RATE / BAUD_RATE;
    parameter BIT_PERIOD = 20 * CLOCKS_PER_BIT; // 1 bit period in ns
    
    // DUT inputs
    reg clk = 0;
    reg rstn = 0;
    reg [7:0] data_in = 0;
    reg data_valid = 0;
    
    // DUT outputs
    wire tx;
    wire busy;
    wire [1:0] state_bits;
    
    // Instantiate the UART TX module
    uart_tx #(
        .CLK_RATE(CLK_RATE),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .data_in(data_in),
        .data_valid(data_valid),
        .tx(tx),
        .busy(busy),
        .state_bits(state_bits)
    );
    
    // Clock generation (50 MHz)
    always #10 clk = ~clk; // 20ns period -> 50MHz
    
    // Task to transmit a byte via UART
    task transmit_byte;
        input [7:0] data;
        begin
            // Wait until transmitter is not busy
            wait(!busy);
            
            @(posedge clk);
            data_in = data;
            data_valid = 1;
            
            @(posedge clk);
            data_valid = 0;
            
            // Wait until the transmission completes
            wait(!busy);
            @(posedge clk);
        end
    endtask
    
    // Task to verify a complete byte transmission
    task verify_transmission;
        input [7:0] data;
        integer i;
        reg [9:0] frame; // Start bit + 8 data bits + Stop bit
        begin
            // Construct the expected frame (LSB first)
            frame = {1'b1, data, 1'b0}; // {stop_bit, data[7:0], start_bit}
            
            // Wait for start bit
            wait(tx == 1'b0);
            $display("Time: %0t - Start bit detected", $time);
            #(BIT_PERIOD/2); // Move to middle of start bit
            
            if (tx != 1'b0) begin
                $display("Error: Start bit not detected properly");
            end
            
            // Check data bits
            for (i = 0; i < 8; i = i + 1) begin
                #BIT_PERIOD;
                if (tx !== data[i]) begin
                    $display("Error: Data bit %0d mismatch. Expected: %b, Got: %b", 
                            i, data[i], tx);
                end else begin
                    $display("Time: %0t - Data bit %0d correct: %b", $time, i, tx);
                end
            end
            
            // Check stop bit
            #BIT_PERIOD;
            if (tx !== 1'b1) begin
                $display("Error: Stop bit not detected properly");
            end else begin
                $display("Time: %0t - Stop bit correct", $time);
            end
            
            // Wait a bit after the stop bit
            #(BIT_PERIOD/2);
        end
    endtask
    
    // Monitor state bits changes
    always @(state_bits) begin
        case(state_bits)
            2'b00: $display("Time: %0t - TX State: IDLE", $time);
            2'b01: $display("Time: %0t - TX State: START", $time);
            2'b11: $display("Time: %0t - TX State: DATA", $time);
            2'b10: $display("Time: %0t - TX State: STOP", $time);
            default: $display("Time: %0t - TX State: UNKNOWN", $time);
        endcase
    end
    
    // Stimulus and testing process
    initial begin
        $display("Starting UART TX Testbench...");
        $dumpfile("uart_tx_tb.vcd");
        $dumpvars(0, uart_tx_tb);
        
        // Reset sequence
        #100;
        rstn = 1;
        #100;
        
        // Test case 1: Send 0x55 (alternating 0/1)
        $display("\nTest Case 1: Sending 0x55");
        fork
            transmit_byte(8'h55);
            verify_transmission(8'h55);
        join
        #(BIT_PERIOD);
        
        // Test case 2: Send 0xFF (all 1s)
        $display("\nTest Case 2: Sending 0xFF");
        fork
            transmit_byte(8'hFF);
            verify_transmission(8'hFF);
        join
        #(BIT_PERIOD);
        
        // Test case 3: Send 0x00 (all 0s)
        $display("\nTest Case 3: Sending 0x00");
        fork
            transmit_byte(8'h00);
            verify_transmission(8'h00);
        join
        #(BIT_PERIOD);
        
        // Test case 4: Send 0xF0 (half 1s, half 0s)
        $display("\nTest Case 4: Sending 0xF0");
        fork
            transmit_byte(8'hF0);
            verify_transmission(8'hF0);
        join
        #(BIT_PERIOD);
        
        // Test case 5: Send 0xA5 (10100101)
        $display("\nTest Case 5: Sending 0xA5");
        fork
            transmit_byte(8'hA5);
            verify_transmission(8'hA5);
        join
        #(BIT_PERIOD * 2);
        
        $display("\nUART TX Testbench completed successfully");
        $finish;
    end
endmodule