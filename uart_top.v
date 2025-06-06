`timescale 1ns/1ps
module uart_top #(
    parameter CLK_RATE = 50000000,   // 50MHz FPGA clock
    parameter BAUD_RATE = 115200,    // Standard baud rate
    parameter BITS_PER_WORD = 8      // Standard 8-bit data
)(
    input  wire        clk,          // 50MHz clock input
    input  wire        rst_n,        // Active low reset
    input  wire        uart_rx_pin,  // UART RX pin from external device
    output wire        uart_tx_pin,  // UART TX pin to external device
    output wire [7:0]  rx_data_out,  // Received data (for debug or connection to other modules)
    output wire        rx_data_valid,// Valid received data flag
    output wire        rx_is_valid,  // RX data period indicator
    output wire        tx_busy     // TX busy indicator

    
);

    // Internal signals
    reg  [7:0] tx_data;
    reg        tx_data_valid;
	 wire [1:0]  tx_state;     // TX state machine state
    wire [1:0]  rx_state;     // RX state machine state
    
    // Instantiate UART RX module
    uart_rx #(
        .CLK_RATE(CLK_RATE),
        .BAUD_RATE(BAUD_RATE),
        .BITS_PER_WORD(BITS_PER_WORD)
    ) uart_rx_inst (
        .clk(clk),
        .rstn(rst_n),
        .rx(uart_rx_pin),
        .data_out(rx_data_out),
        .data_valid(rx_data_valid),
        .is_valid(rx_is_valid),
        .state_bits(rx_state)
    );
    
    // Instantiate UART TX module
    uart_tx #(
        .CLK_RATE(CLK_RATE),
        .BAUD_RATE(BAUD_RATE),
        .BITS_PER_WORD(BITS_PER_WORD)
    ) uart_tx_inst (
        .clk(clk),
        .rstn(rst_n),
        .data_in(tx_data),
        .data_valid(tx_data_valid),
        .tx(uart_tx_pin),
        .busy(tx_busy),
        .state_bits(tx_state)
    );
	 
    // Simple loopback functionality - echo received data back
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data <= 8'h09;
            tx_data_valid <= 1'b0;
        end else begin
            tx_data_valid <= 1'b0; // Default state
        end
    end
    

endmodule