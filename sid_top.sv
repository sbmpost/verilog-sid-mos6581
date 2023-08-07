module sid_top(
    input SYS_CLK,
    input RSTn_i,
    output [7:0] LED_o,
    output [5:0] dac,
    input GPIO_02
);

wire sysclk;

/*
wire locked;
pll myPLL(
    .clock_in(SYS_CLK),
    .clock_out(sysclk),
    .locked(locked)
);
*/

assign sysclk = SYS_CLK;

// Synchronize reset release to sysclk
//
bit n_reset;

reset_filter #(.DELAY(3)) rsf(
    .n_reset_in( RSTn_i ),
    .n_reset_out( n_reset ),
    .clk(sysclk)
);

// original speeds based on 50MHZ clock
bit     clk_en;     // 1MHz clock (for the SID chip)
clk_div #(.DIVISOR(50))     cd1(clk_en, sysclk, n_reset);

// SID Emulation
//
bit[15:0]   audio_out;
bit[4:0]    sid_addr;
bit[7:0]    sid_data;
bit         sid_n_cs;

bit LED_0;
mos6581 sid1(
    .audio_out( audio_out ),
    .addr( sid_addr ),
    .data( sid_data ),
    .n_cs( sid_n_cs ),
    .rw  ( 0 ),
    .n_reset( n_reset ),
    .clk( sysclk ),
    .clk_en( clk_en )
//,.led(LED_o[0])
,.led(LED_0)
);

assign dac = audio_out[11:6];

/*
// Sigma/Delta DAC
//
sigma_delta  dac1(
    .in     ( audio_out ),
    .out    ( GPIO_04 ),
    .n_reset( n_reset ),
    .clk    ( sysclk )
);
*/

bit tvalid = 0;
bit [7:0] tdata;
/*
// UART receiver
uart_rx rx(
    .clk(sysclk),
    .rst(!n_reset),
    .rxd(GPIO_02),
//    .prescale( 65 ),
    .prescale( 55 ),
//    .prescale( 27 ),
//    .prescale( (int'(50e6 / (115200 * 8) + 0.5)) ),

    .output_axis_tdata(tdata),
    .output_axis_tvalid(tvalid),
    .output_axis_tready(1)
);

// assign LED_o = tdata;
*/

bit rx_state = 0;       // 0=reg, 1=data

/*
sigma_delta  dac1(
    .in     ( audio_out ),
    .out    ( GPIO_04 ),
    .n_reset( n_reset ),
    .clk    ( sysclk )
);
*/

bit [11:0] address;
sid_mem mem(
    .clk      (sysclk),
    .w_enable (0),
    .address  (address),
    .data_in  (0),
    .data_out (tdata)
);

always_ff @(posedge sysclk, negedge n_reset)
begin
    $display("clk_en: %d, audio %d, tvalid: %d", clk_en, audio_out, tvalid);
    if (!n_reset) begin
        $display("reset data transfer");
        sid_addr <= 0;
        sid_data <= 0;
        rx_state <= 0;
        sid_n_cs <= 1;
        address <= 0;
    end
    else if (tvalid) begin
        if (rx_state == 0) begin
            if (tdata <= 'h1F) begin
                LED_o[7:3] <= tdata[4:0];
                sid_addr <= tdata[4:0];
                rx_state <= 1;
                tvalid <= 0;
                address <= address + 1;
            end
        end
        else begin
            // LED_o[7:4] <= tdata[7:4];
            sid_data <= tdata;
            rx_state <= 0;
            sid_n_cs <= 0;
            tvalid <= 0;
            address <= address + 1;
        end
    end
    else begin
        sid_n_cs <= 1;
        tvalid <= 1;
    end
end

endmodule
