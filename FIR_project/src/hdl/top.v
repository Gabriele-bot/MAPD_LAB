`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc
// Engineer: Arthur Brown
// 
// Create Date: 03/23/2018 11:53:54 AM
// Design Name: Arty-A7-100-Pmod-I2S2
// Module Name: top
// Project Name: 
// Target Devices: Arty A7 100
// Tool Versions: Vivado 2017.4
// Description: Implements a volume control stream from Line In to Line Out of a Pmod I2S2 on port JA
// 
// Revision:
// Revision 0.01 - File Created
// 
//////////////////////////////////////////////////////////////////////////////////


module top #(
	parameter NUMBER_OF_SWITCHES = 4,
	parameter RESET_POLARITY = 0
) (
    input wire       clk,
    input wire [NUMBER_OF_SWITCHES-1:0] sw,
    input wire       reset,
    
    output wire tx_mclk,
    output wire tx_lrck,
    output wire tx_sclk,
    output wire tx_data,
    output wire rx_mclk,
    output wire rx_lrck,
    output wire rx_sclk,
    input  wire rx_data
);

    // i2s_2_axis --> fifo --> FIR filter --> fifo -- axis_volume controller --> axis_2_i2s
    
    wire axis_clk;
    
    wire [23:0] axis_tx_data;
    wire axis_tx_valid;
    wire axis_tx_ready;
    wire axis_tx_last;
    
    wire [23:0] axis_ifir_data;
    wire axis_ifir_valid;
    wire axis_ifir_ready;
    wire axis_ifir_last;
    
    wire [23:0] axis_ofir_data;
    wire axis_ofir_valid;
    wire axis_ofir_ready;
    wire axis_ofir_last;
    
    wire [23:0] axis_vol_data;
    wire axis_vol_valid;
    wire axis_vol_ready;
    wire axis_vol_last;
    
    wire [23:0] axis_rx_data;
    wire axis_rx_valid;
    wire axis_rx_ready;
    wire axis_rx_last;

	wire resetn = (reset == RESET_POLARITY) ? 1'b0 : 1'b1;
	
    clk_wiz_1 m_clk (
        .clk_in1(clk),
        .reset(reset),
        .clk_out1(axis_clk)
    );

    axis_i2s2 m_i2s2 (
        .axis_clk       (axis_clk     ),
        .axis_resetn    (resetn       ),
    
        .tx_axis_s_data (axis_tx_data ),
        .tx_axis_s_valid(axis_tx_valid),
        .tx_axis_s_ready(axis_tx_ready),
        .tx_axis_s_last (axis_tx_last ),
    
        .rx_axis_m_data (axis_rx_data ),
        .rx_axis_m_valid(axis_rx_valid),
        .rx_axis_m_ready(axis_rx_ready),
        .rx_axis_m_last (axis_rx_last ),
        
        .tx_mclk (tx_mclk),
        .tx_lrck (tx_lrck),
        .tx_sclk (tx_sclk),
        .tx_sdout(tx_data),
        .rx_mclk (rx_mclk),
        .rx_lrck (rx_lrck),
        .rx_sclk (rx_sclk),
        .rx_sdin (rx_data)
    );
    
    axis_data_fifo_0 fifo_in (
        .s_axis_aclk   (axis_clk           ),
        .s_axis_aresetn(resetn        ),
        
        .s_axis_tdata  (axis_rx_data  ),
        .s_axis_tvalid (axis_rx_valid ),
        .s_axis_tready (axis_rx_ready ),
        .s_axis_tlast  (axis_rx_last  ),
        
        .m_axis_tdata  (axis_ifir_data),
        .m_axis_tvalid(axis_ifir_valid),
        .m_axis_tready(axis_ifir_ready),
        .m_axis_tlast (axis_ifir_last )
    );
    
    FIR_MAC #(
		.AUDIO_DATA_WIDTH(24),
		.DATA_WIDTH(32)
	) FIR (
        .clk          (axis_clk       ),
        .rst          (reset          ),
        
        .s_axis_tdata (axis_ifir_data ),
        .s_axis_tvalid(axis_ifir_valid),
        .s_axis_tready(axis_ifir_ready),
        .s_axis_tlast (axis_ifir_last ),
        
        .m_axis_tdata (axis_ofir_data ),
        .m_axis_tvalid(axis_ofir_valid),
        .m_axis_tready(axis_ofir_ready),
        .m_axis_tlast (axis_ofir_last )
    );
    
    axis_data_fifo_0 fifo_out (
        .s_axis_aclk   (axis_clk            ),
        .s_axis_aresetn(resetn         ),
        
        .s_axis_tdata  (axis_ofir_data ),
        .s_axis_tvalid (axis_ofir_valid),
        .s_axis_tready (axis_ofir_ready),
        .s_axis_tlast  (axis_ofir_last ),
        
        .m_axis_tdata  (axis_vol_data  ),
        .m_axis_tvalid (axis_vol_valid ),
        .m_axis_tready (axis_vol_ready ),
        .m_axis_tlast  (axis_vol_last  )
    );
    
    axis_volume_controller #(
		.SWITCH_WIDTH(NUMBER_OF_SWITCHES),
		.DATA_WIDTH  (24                )
	) m_vc (
        .clk         (axis_clk      ),
        .sw          (sw            ), 
        
        .s_axis_data (axis_vol_data ),
        .s_axis_valid(axis_vol_valid),
        .s_axis_ready(axis_vol_ready),
        .s_axis_last (axis_vol_last ),
        
        .m_axis_data (axis_tx_data  ),
        .m_axis_valid(axis_tx_valid ),
        .m_axis_ready(axis_tx_ready ),
        .m_axis_last (axis_tx_last  )
    );
    
endmodule
