`timescale 1ns/1ps
module uart_rx #(
    parameter CLK_RATE = 50000000,
    parameter BAUD_RATE = 115200,
    parameter BITS_PER_WORD = 8
)(
    input clk,
    input rstn,
    input rx,
    output reg [7:0] data_out,
    output reg data_valid,
    output reg is_valid,     // Signal to indicate valid data period
    output reg [1:0] state_bits // New output to show state bits
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
    reg [7:0] rx_shift;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= STATE_IDLE;
            clk_count <= 0;
            bit_index <= 0;
            rx_shift <= 0;
            data_out <= 0;
            data_valid <= 0;
            is_valid <= 0;        // Initialize is_valid
            state_bits <= 2'b00;  // Initialize state_bits
        end else begin
            data_valid <= 0;      // data_valid is only high for one clock cycle
            
            case (state)
                STATE_IDLE: begin
                    is_valid <= 0;  // Clear is_valid when in IDLE state
                    state_bits <= 2'b00; // State bit for IDLE
                    if (rx == 0) begin
                        state <= STATE_START;
                        clk_count <= CLOCKS_PER_BIT / 2;
                    end
                end
                STATE_START: begin
                    state_bits <= 2'b01; // State bit for START
                    if (clk_count == CLOCKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        state <= STATE_DATA;
                        bit_index <= 0;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                STATE_DATA: begin
                    is_valid <= 1;  // Set is_valid high during DATA state
                    state_bits <= 2'b10; // State bit for DATA (high)
                    if (clk_count == CLOCKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        rx_shift <= {rx,rx_shift[7:1]};
                        if (bit_index == BITS_PER_WORD - 1) begin
                            state <= STATE_STOP;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                STATE_STOP: begin
                    is_valid <= 1;  // Keep is_valid high during STOP state
                    state_bits <= 2'b11; // State bit for STOP
                    if (clk_count == CLOCKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        state <= STATE_IDLE;
                        // Simply assign rx_shift to data_out (no need to flip again)
                        data_out <= rx_shift[7:0];
                        data_valid <= 1;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
            endcase
        end
    end
endmodule