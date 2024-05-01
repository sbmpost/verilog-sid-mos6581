module sid_top(
    input SYS_CLK,
    // input RSTn_i,
    output bit[1:0] LED_o,
    // input GPIO_02,
    output GPIO_04
);

wire sysclk;
`ifdef VERILATOR
    assign sysclk = SYS_CLK;
`else
    pll myPLL(
        .clock_in(SYS_CLK),
        .clock_out(sysclk),
        .locked(LED_o[0])
);
`endif

// Synchronize reset release to sysclk
bit n_reset = 1'b0;

/*
reset_filter #(.DELAY(3)) rsf(
    .n_reset_in(RSTn_i),
    .n_reset_out(n_reset),
    .clk(sysclk)
);
*/

// original speeds based on 50MHZ clock
bit clk_en; // 1MHz clock (for the SID chip)
clk_div #(.DIVISOR(48)) cd1(clk_en, sysclk, n_reset);

bit clk_mem;
clk_div #(.DIVISOR(4800000)) cd2(clk_mem, sysclk, n_reset);

always_ff @(posedge sysclk, negedge n_reset)
begin
    if (!n_reset) begin
        LED_o[1] <= 0;
    end
    else if (clk_mem) begin
        LED_o[1] <= ~LED_o[1];
    end
end

bit[15:0]   audio_out;
bit[4:0]    sid_addr;
bit[7:0]    sid_data;
bit         sid_n_cs = 1'b1;

mos6581 sid1(
    .audio_out ( audio_out ),
    .addr      ( sid_addr ),
    .data      ( sid_data ),
    .n_cs      ( sid_n_cs ),
    .rw        ( 1'b0 ),
    .n_reset   ( n_reset ),
    .clk       ( sysclk ),
    .clk_en    ( clk_en )
);

sigma_delta  dac1(
    .in      ( audio_out ),
    .out     ( GPIO_04 ),
    .n_reset ( n_reset ),
    .clk     ( sysclk )
);

bit[15:0] data;
bit[12:0] address;
bit[20:0] cycles;

sid_mem16 mem16(
    .clk      ( sysclk ),
    .w_enable ( 1'b0 ),
    .address  ( address ),
    .data_in  ( 16'b0 ),
    .data_out ( data )
);

bit[1:0] mem_state;
always_ff @(posedge sysclk, negedge n_reset)
begin
    $display("time: %d, clk_en: %d, sid_n_cs: %d, audio %d, data: %d, cycles:%d, sid_addr:%d, sid_data:%d, mem_state:%d", $time, clk_en, sid_n_cs, audio_out, data, cycles, sid_addr, sid_data, mem_state);
    if (!n_reset) begin
        mem_state <= 0;
        address <= 0;
        cycles <= 0;
        n_reset <= 1'b1;
    end
    else if (cycles == 0 || mem_state != 0) begin
        if (mem_state == 0) begin
            cycles <= {data,4'b0} + {data,5'b0} - 4;
            address <= address + 1;
            sid_n_cs <= 1;
        end
        else if (mem_state == 2) begin
            sid_addr <= data[4:0];
            sid_data <= data[15:8];
            address <= address + 1;
            sid_n_cs <= 0;
        end
        else begin
            sid_n_cs <= 1;
        end
        mem_state <= mem_state + 1;
    end
    else begin
        cycles <= cycles - 1;
    end
end

endmodule
