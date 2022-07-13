module sid_top (
    input SYS_CLK,
    input RSTn_i,
    output [3:0] LED_o1,
    output [3:0] LED_o2,
    output [5:0] dac,
//    output GPIO_04,
//    input GPIO_02
);

wire sysclk;

///*
wire locked;
pll myPLL (
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
bit     clk_1k;     // 1kHz clock (for SignalTap)

///*
// original speeds based on 50MHZ clock
clk_div #(.DIVISOR(50))     cd1(clk_en, sysclk, n_reset);

// uart replacement clock for programming the sid registers
clk_div #(.DIVISOR(1000000))  cd2(clk_1k, sysclk, n_reset);
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
    .clk_en( clk_en ),

    .debug_out1( LED_o1[3:0] ),
    .debug_out2( LED_o2[3:0] )

    // .debug_out( temp_LED_o[7:0] )
    // .debug_in( SW ),
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
/*
uart_rx  rx(
    .clk(sysclk),
    .rst(!n_reset),
    .rxd(GPIO_02),
//    .prescale( int'(50e6 / (115200 * 8) + 0.5) ),
    .prescale( 12e6 / (115200 * 8) + 0.5 ),

    .output_axis_tdata(tdata),
    .output_axis_tvalid(tvalid),
    .output_axis_tready(1)
);
*/

bit led_state;
always_ff @(posedge clk_1k) begin
    if (!n_reset) begin
    end
    else begin
//        led_state <= ~led_state;
//        tvalid <= led_state;
        tvalid <= ~tvalid;
    end
end

bit rx_state;       // 0=reg, 1=data

bit[3:0] bytes = 0;
always_ff @(posedge clk_1k) // or negedge n_reset)
begin
/*
    if (!n_reset) begin
        sid_addr <= 0; // 'h04;
        sid_data <= 0; // 'h01;
        rx_state <= 0;
    end
    else
*/
    if (tvalid) begin
        sid_n_cs <= 0;
        unique case(bytes)
            4'b0000: begin
// $display("set volume", $time);
                bytes <= 4'b0001;
                sid_addr <= 'h18; // volume
                sid_data <= 8;
            end
            4'b0001: begin
// $display("set attack/decay", $time);
                bytes <= 4'b0010;
                sid_addr <= 'h05; // attack/decay
                sid_data <= 190;
            end
            4'b0010: begin
// $display("set sustain/release", $time);
                bytes <= 4'b0011;
                sid_addr <= 'h06; // sustain/release
                sid_data <= 248;
            end
            4'b0011: begin
// $display("set freq HI", $time);
                bytes <= 4'b0100;
                sid_addr <= 'h01; // note freq_HI
                sid_data <= 17;
            end
            4'b0100: begin
// $display("set freq LO", $time);
                bytes <= 4'b0101;
                sid_addr <= 'h00; // note freq_LO
                sid_data <= 37;
            end
            4'b0101: begin
// $display("set pulse LO", $time);
                bytes <= 4'b0110;
                sid_addr <= 'h02; // pulse width LO
                sid_data <= 0;
            end
            4'b0110: begin
// $display("set pulse HI", $time);
                bytes <= 4'b0111;
                sid_addr <= 'h03; // pulse width HI
                sid_data <= 'h08;
            end
            4'b0111: begin
// $display("set waveform", $time);
                bytes <= 4'b1000;
                sid_addr <= 'h04; // waveform
                sid_data <= 17; // gate bit + 16 = triangle, 32 = saw, 64 = pulse, 128 = noise
            end
            default: begin
            end
        endcase
/*
        if (rx_state == 0) begin
            sid_addr <= tdata;
            if (tdata <= 'h1F)
                rx_state <= 1;
        end
        else begin
            sid_data <= tdata;
            sid_n_cs <= 0;
            rx_state <= 0;
        end
*/
    end
    else begin
// $display("not within tvalid", $time);
        sid_n_cs <= 1;
    end
end

endmodule
