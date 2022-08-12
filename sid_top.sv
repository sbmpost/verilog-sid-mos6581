module sid_top(
    input SYS_CLK,
    input RSTn_i,
    output [7:0] LED_o,
    output [5:0] dac,
    input GPIO_02
);

wire sysclk;

///*
wire locked;
pll myPLL(
    .clock_in(SYS_CLK),
    .clock_out(sysclk),
    .locked(locked)
);
//*/

//assign sysclk = SYS_CLK;

// Synchronize reset release to sysclk
//
bit n_reset; // = 1'b1;

reset_filter #(.DELAY(3)) rsf(
    .n_reset_in( RSTn_i ),
    .n_reset_out( n_reset ),
    .clk(sysclk)
);


bit     clk_en;     // 1MHz clock (for the SID chip)
//bit     clk_1k;     // 1kHz clock (for SignalTap)

///*
// original speeds based on 50MHZ clock
clk_div #(.DIVISOR(50))     cd1(clk_en, sysclk, n_reset);

// uart replacement clock for programming the sid registers
//clk_div #(.DIVISOR(1000000))  cd2(clk_1k, sysclk, n_reset);
// clk_div #(.DIVISOR(50000))  cd2(clk_1k, sysclk, n_reset);
//*/

// verilator
//clk_div #(.DIVISOR(5)) cd1(clk_en, SYS_CLK, n_reset);
//clk_div #(.DIVISOR(10)) cd2(clk_1k, SYS_CLK, n_reset);

// SID Emulation
//
bit[15:0]   audio_out;
bit[4:0]    sid_addr = 0;
bit[7:0]    sid_data = 0;
bit         sid_n_cs;

mos6581 sid1(
    .audio_out( audio_out ),
    .addr( sid_addr ),
    .data( sid_data ),
    .n_cs( sid_n_cs ),
    .rw  ( 0 ),
    .n_reset( n_reset ),
    .clk( sysclk ),
    .clk_en( clk_en )
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

// UART receiver
//
bit [7:0] tdata;
bit tvalid;
uart_rx rx(
    .clk(sysclk),
    .rst(!n_reset),
    .rxd(GPIO_02),
    .prescale( 55 ),
//    .prescale( (int'(50e6 / (115200 * 8) + 0.5)) ),

    .output_axis_tdata(tdata),
    .output_axis_tvalid(tvalid),
    .output_axis_tready(1)
);

assign LED_o = tdata;

bit rx_state;       // 0=reg, 1=data

always_ff @(posedge sysclk) // or negedge n_reset)
begin
    if (!n_reset) begin
        sid_addr <= 0;
        sid_data <= 0;
        rx_state <= 0;
    end
    else if (tvalid) begin
        sid_n_cs <= 0;
        if (rx_state == 0) begin
            sid_addr <= tdata[4:0];
            if (tdata <= 'h1F)
                rx_state <= 1;
        end
        else begin
            sid_data <= tdata;
            sid_n_cs <= 0;
            rx_state <= 0;
        end
    end
    else begin
        sid_n_cs <= 1;
    end
end

endmodule
