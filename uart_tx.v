`timescale 1ns/1ps
module uart_tx #(
    parameter CLK_RATE = 50000000,
    parameter BAUD_RATE = 115200,
    parameter BITS_PER_WORD = 8
)(
    input clk,
    input rstn,
    input [7:0] data_in,     // Data to transmit
    input data_valid,        // Indicates data_in is valid and ready to transmit
    output reg tx,           // UART TX line
    output reg busy,         // High when transmitter is busy
    output reg [1:0] state_bits  // State bits for debugging
);
    localparam CLOCKS_PER_BIT = CLK_RATE / BAUD_RATE;
    
    // FSM States
    localparam STATE_IDLE  = 2'd0;
    localparam STATE_START = 2'd1;
    localparam STATE_DATA  = 2'd2;
    localparam STATE_STOP  = 2'd3;
    
    reg [1:0] state;
    reg [$clog2(CLOCKS_PER_BIT)-1:0] clk_count;
    reg [$clog2(BITS_PER_WORD)-1:0] bit_index;
    reg [7:0] tx_data;  // Holds the current byte being transmitted
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= STATE_IDLE;
            clk_count <= 0;
            bit_index <= 0;
            tx <= 1'b1;       // Idle state is HIGH
            busy <= 1'b0;
            tx_data <= 8'h00;
            state_bits <= 2'b00;  // IDLE state
        end else begin
            case (state)
                STATE_IDLE: begin
                    state_bits <= 2'b00;  // State bit for IDLE
                    tx <= 1'b1;           // Keep TX line HIGH in idle
                    busy <= 1'b0;         // Not busy
                    clk_count <= 0;
                    bit_index <= 0;
                    
                    if (data_valid) begin
                        tx_data <= data_in;  // Latch the data
                        state <= STATE_START;
                        busy <= 1'b1;        // Now we're busy
                    end
                end
                
                STATE_START: begin
                    state_bits <= 2'b01;  // State bit for START
                    tx <= 1'b0;           // START bit is LOW
                    busy <= 1'b1;
                    
                    if (clk_count < CLOCKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= STATE_DATA;
                    end
                end
                
                STATE_DATA: begin
                    state_bits <= 2'b11;  // State bit for DATA
                    tx <= tx_data[bit_index];  // Transmit LSB first
                    busy <= 1'b1;
                    
                    if (clk_count < CLOCKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        
                        if (bit_index < BITS_PER_WORD - 1) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= STATE_STOP;
                        end
                    end
                end
                
                STATE_STOP: begin
                    state_bits <= 2'b10;  // State bit for STOP
                    tx <= 1'b1;           // STOP bit is HIGH
                    busy <= 1'b1;
                    
                    if (clk_count < CLOCKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= STATE_IDLE;
                    end
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule