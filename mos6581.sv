module mos6581 (
    output[15:0] audio_out,
    input[4:0]   addr,
    input[7:0]   data, // TODO: inout
    input        n_cs,
    input        rw,
    input        clk,
    input        clk_en,
    input        n_reset
);

bit[15:0]   r_0_freq;
bit[11:0]   r_0_pw;
bit         r_0_noise, r_0_pulse, r_0_saw, r_0_triangle;
bit         r_0_test, r_0_ring, r_0_sync, r_0_gate;
bit[3:0]    r_0_atk, r_0_dcy, r_0_stn, r_0_rls;

bit[15:0]   r_1_freq;
bit[11:0]   r_1_pw;
bit         r_1_noise, r_1_pulse, r_1_saw, r_1_triangle;
bit         r_1_test, r_1_ring, r_1_sync, r_1_gate;
bit[3:0]    r_1_atk, r_1_dcy, r_1_stn, r_1_rls;

bit[15:0]   r_2_freq;
bit[11:0]   r_2_pw;
bit         r_2_noise, r_2_pulse, r_2_saw, r_2_triangle;
bit         r_2_test, r_2_ring, r_2_sync, r_2_gate;
bit[3:0]    r_2_atk, r_2_dcy, r_2_stn, r_2_rls;

typedef struct packed {
    bit[10:0]   fc;
    bit[3:0]    res;
    bit[3:0]    filt;
    bit         off3, hp, bp, lp;
    bit[3:0]    vol;
} filter_t;

filter_t filter;

always_ff @(posedge clk, negedge n_reset)
begin
    if (!n_reset) begin
        $display("reset sid");
        // TODO: reset all registers
    end 
    else if (!n_cs && !rw) begin
        $display("write sid: reg %x, byte %x", addr, data);
        unique case(addr)
        'h00:   r_0_freq[7:0]  <= data;
        'h01:   r_0_freq[15:8] <= data;
        'h02:   r_0_pw[7:0]    <= data;
        'h03:   r_0_pw[11:8]   <= data[3:0];
        'h04:   { r_0_noise, r_0_pulse, r_0_saw, r_0_triangle,
                  r_0_test,  r_0_ring,  r_0_sync, r_0_gate } <= data;
        'h05:   { r_0_atk, r_0_dcy } <= data;
        'h06:   { r_0_stn, r_0_rls } <= data;

        'h07:   r_1_freq[7:0]  <= data;
        'h08:   r_1_freq[15:8] <= data;
        'h09:   r_1_pw[7:0]    <= data;
        'h0A:   r_1_pw[11:8]   <= data[3:0];
        'h0B:   { r_1_noise, r_1_pulse, r_1_saw,  r_1_triangle,
                  r_1_test,  r_1_ring,  r_1_sync, r_1_gate } <= data;
        'h0C:   { r_1_atk, r_1_dcy } <= data;
        'h0D:   { r_1_stn, r_1_rls } <= data;

        'h0E:   r_2_freq[7:0]  <= data;
        'h0F:   r_2_freq[15:8] <= data;
        'h10:   r_2_pw[7:0]    <= data;
        'h11:   r_2_pw[11:8]   <= data[3:0];
        'h12:   { r_2_noise, r_2_pulse, r_2_saw,  r_2_triangle,
                  r_2_test,  r_2_ring,  r_2_sync, r_2_gate } <= data;
        'h13:   { r_2_atk, r_2_dcy } <= data;
        'h14:   { r_2_stn, r_2_rls } <= data;

        'h15:   filter.fc[2:0]  <= data[2:0];
        'h16:   filter.fc[10:3] <= data;
        'h17:   { filter.res, filter.filt } <= data;
        'h18:   { filter.off3, filter.hp, filter.bp, filter.lp, filter.vol } <= data;
        default: ;
        endcase
    end
end

bit[11:0] v_0_out, v_1_out, v_2_out;
bit v_0_ring, v_1_ring, v_2_ring;
bit v_0_sync, v_1_sync, v_2_sync;

voice v_0(v_0_out, v_0_ring, v_2_ring, v_0_sync, v_2_sync,
r_0_freq,
r_0_pw,
r_0_noise, r_0_pulse, r_0_saw, r_0_triangle,
r_0_test, r_0_ring, r_0_sync, r_0_gate,
r_0_atk, r_0_dcy, r_0_stn, r_0_rls,
clk, clk_en, n_reset);

voice v_1(v_1_out, v_1_ring, v_0_ring, v_1_sync, v_0_sync,
r_1_freq,
r_1_pw,
r_1_noise, r_1_pulse, r_1_saw, r_1_triangle,
r_1_test, r_1_ring, r_1_sync, r_1_gate,
r_1_atk, r_1_dcy, r_1_stn, r_1_rls,
clk, clk_en, n_reset);

voice v_2(v_2_out, v_2_ring, v_1_ring, v_2_sync, v_1_sync,
r_2_freq,
r_2_pw,
r_2_noise, r_2_pulse, r_2_saw, r_2_triangle,
r_2_test, r_2_ring, r_2_sync, r_2_gate,
r_2_atk, r_2_dcy, r_2_stn, r_2_rls,
clk, clk_en, n_reset);

// assign audio_out = {4'b0000, v_0_out};
assign audio_out = {4'b0000, v_0_out + v_1_out + v_2_out};

/*
sid_filter filt(
    .audio_out (audio_out),
    .v_0       ( v_0_out ),
    .v_1       ( v_1_out ),
    .v_2       ( v_2_out ),
    .reg_fc    ( filter.fc        ),
    .reg_res   ( filter.res       ),
    .reg_en    ( filter.filt[2:0] ),
    .reg_off3  ( filter.off3      ),
    .reg_hp    ( filter.hp        ),
    .reg_bp    ( filter.bp        ),
    .reg_lp    ( filter.lp        ),
    .reg_vol   ( filter.vol       ),
    .clk       (clk),
    .clk_en    (clk_en),
    .n_reset   (n_reset)
);
*/

endmodule
