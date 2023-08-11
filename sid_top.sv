module sid_top(
    input SYS_CLK,
    input RSTn_i,
    output [7:0] LED_o,
    output [5:0] dac,
    input GPIO_02,
    output GPIO_04
);

//`ifdef VERILATOR
`define MEMORY
//`endif

wire sysclk;

`ifdef VERILATOR
  assign sysclk = SYS_CLK;
`else
//  assign sysclk = SYS_CLK;
///*
  wire locked;
  pll myPLL(
      .clock_in(SYS_CLK),
      .clock_out(sysclk),
      .locked(locked)
  );
//*/
`endif

bit slowclk;

`ifdef VERILATOR
  assign slowclk = sysclk;
`else
  assign slowclk = sysclk;
/*
  int count;
  always_ff @(posedge sysclk)
  begin
      if (!RSTn_i) begin
          LED_o[0] <= 0;
          slowclk <= 0;
          count <= 0;
      end
      else begin
          count <= count + 1;
          if (count == 12000000) begin
              count <= 0;
              if (slowclk) begin
                  LED_o[0] <= 0;
                  slowclk <= 0;
              end
              else begin
                  LED_o[0] <= 1;
                  slowclk <= 1;
              end
          end
      end
  end
*/
`endif

// Synchronize reset release to sysclk
//
bit n_reset;

reset_filter #(.DELAY(3)) rsf(
    .n_reset_in( RSTn_i ),
    .n_reset_out( n_reset ),
    .clk(slowclk)
);

// original speeds based on 50MHZ clock
bit     clk_en;     // 1MHz clock (for the SID chip)
clk_div #(.DIVISOR(52))     cd1(clk_en, slowclk, n_reset);

bit     clk_mem;
clk_div #(.DIVISOR(380000)) cd2(clk_mem, slowclk, n_reset);

/*
always_ff @(posedge clk_en, negedge n_reset)
begin
    if (!n_reset) begin
        LED_o[1] <= 0;
    end
    else begin
        LED_o[1] <= ~LED_o[1];
    end
end
*/

// SID Emulation
//
bit[15:0]   audio_out;
bit[4:0]    sid_addr;
bit[7:0]    sid_data;
bit         sid_n_cs;

mos6581 sid1(
    .audio_out( audio_out ),
    .addr( sid_addr ),
    .data( sid_data ),
    .n_cs( sid_n_cs ),
    .rw  ( 0 ),
    .n_reset( n_reset ),
    .clk( slowclk ),
    .clk_en( clk_en )
);

assign dac = audio_out[11:6];
// assign dac = audio_out[5:0];

///*
// Sigma/Delta DAC
//
sigma_delta  dac1(
    .in     ( audio_out ),
    .out    ( GPIO_04 ),
    .n_reset( n_reset ),
    .clk    ( slowclk )
);
//*/

bit tvalid;
bit [7:0] tdata;

`ifdef MEMORY
  bit [11:0] address;
  sid_mem mem(
      .clk      (slowclk),
      .w_enable (0),
      .address  (address),
      .data_in  (0),
      .data_out (tdata)
  );

  bit sending = 0;
  bit[1:0] tx_state = 0;
  always_ff @(posedge slowclk, negedge n_reset)
  begin
      if (!n_reset) begin
          address <= 0;
          tvalid <= 0;
      end
      else if (clk_mem || sending) begin
          if (clk_mem) begin
              sending <= 1;
          end
          if (tx_state == 0 || tx_state == 2) begin
              tvalid <= 1;
          end
          else if (tx_state == 1 || tx_state == 3) begin
              if (address == 12'h0500) begin
                  address <= 0;
              end
              else begin
                  address <= address + 1;
              end

              tvalid <= 0;
              if (tx_state == 3) begin
                  sending <= 0;
              end
          end
          tx_state = tx_state + 1;
      end
  end
`else
  uart_rx rx(
      .clk(sysclk),
      .rst(!n_reset),
      .rxd(GPIO_02),
//      .prescale( 65 ),
      .prescale( 55 ),
//      .prescale( 27 ),
//      .prescale( (int'(50e6 / (115200 * 8) + 0.5)) ),

      .output_axis_tdata(tdata),
      .output_axis_tvalid(tvalid),
      .output_axis_tready(1)
  );

  assign LED_o = tdata;
`endif

bit rx_state;       // 0=reg, 1=data

always_ff @(posedge slowclk, negedge n_reset)
begin
    $display("time: %d, clk_en: %d, sid_n_cs: %d, audio %d, tvalid: %d, rx_state:%d", $time, clk_en, sid_n_cs, audio_out, tvalid, rx_state);
    if (!n_reset) begin
        $display("reset data transfer");
//        LED_o[7:3] <= 0;
        sid_n_cs <= 1;
        rx_state <= 0;
    end
    else if (tvalid) begin
        if (rx_state == 0) begin
            // LED_o[7:3] <= {tdata[0], tdata[1], tdata[2], tdata[3], tdata[4]};
            sid_addr <= tdata[4:0];
            if (tdata <= 'h1F) begin
                rx_state <= 1;
            end
        end
        else begin
            // LED_o[7:4] <= tdata[7:4];
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
