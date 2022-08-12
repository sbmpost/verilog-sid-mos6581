module sid_filter(
    output[15:0]    audio_out,
    input[11:0]     v_0,
    input[11:0]     v_1,
    input[11:0]     v_2,
    input[10:0]     reg_fc,
    input[3:0]      reg_res,
    input[3:0]      reg_en,
    input           reg_off3, reg_hp, reg_bp, reg_lp,
    input[3:0]      reg_vol,
    input           clk, clk_en, n_reset
);

bit[15:0] audio_out = 0;

int low = 0, low_next;
int band = 0, band_next;
int high = 0, high_next;

int out_next;


always_ff @(posedge clk, negedge n_reset)
begin
    if (!n_reset) begin
        low  <= 0;
        band <= 0;
        high <= 0;
        audio_out <= 0;
    end
    else if (clk_en) begin
        low  <= low_next;
        band <= band_next;
        high <= high_next;
        audio_out <= out_next[15:0];
    end
end


always_comb
begin
    int out_filt;
    int fc, res;

    // 3*12 Bit Voice -> 14 bit out_filt/next
    //
    out_filt = 0;
    out_next = 0;

    if (reg_en[0])
        out_filt += {20'b0, v_0};
    else
        out_next += {20'b0, v_0};

    if (reg_en[1])
        out_filt += {20'b0, v_1};
    else
        out_next += {20'b0, v_1};

    if (reg_en[2])
        out_filt += {20'b0, v_2};
    else if (!reg_off3)
        out_next += {20'b0, v_2};

    fc  = {20'b0, reg_fc} + 64;
    res = 256 - reg_res * 10;

    high_next = out_filt - low - ((band * res) >>> 8);
    band_next = band + ((high_next * fc) >>> 16);
    low_next  = low  + ((band_next * fc) >>> 16);

    if (reg_lp)  out_next += low;
    if (reg_bp)  out_next += band;
    if (reg_hp)  out_next += high;

    if (out_next < 0)
        out_next = 0;
    if (out_next > 65535)
        out_next = 65535;

    out_next = (out_next * reg_vol) >> 4;
end


endmodule
