module voice (
    output[11:0]     v_out,
    output           v_ring_out,
    input            v_ring_in,
    output           v_sync_out,   
    input            v_sync_in,

    input bit[15:0]   r_freq,
    input bit[11:0]   r_pw,
    input bit         r_noise, r_pulse, r_saw, r_triangle,
    input bit         r_test, r_ring, r_sync, r_gate,
    input bit[3:0]    r_atk, r_dcy, r_stn, r_rls,

    input            clk,
    input            clk_en,
    input            n_reset
);

// internal state
bit[23:0]   v_acc;
bit[22:0]   v_lfsr;
bit         v_sync_out;
bit[7:0]    v_env_vol;
bit[11:0]   v_out;

sid_acc acc(r_freq, v_acc, v_lfsr, r_test, r_sync, v_sync_in, v_sync_out, clk, clk_en, n_reset);
sid_env env(v_env_vol, r_atk, r_dcy, r_stn, r_rls, r_gate, clk, clk_en, n_reset);
sid_wave wave(v_out, v_acc, v_lfsr, v_env_vol, r_noise, r_pulse, r_saw, r_triangle, r_pw, r_ring, v_ring_in);

assign v_ring_out = v_acc[23];

endmodule
