module mos6581 (
    output[15:0]    audio_out,
    input[4:0]      addr,
    input[7:0]      data,       // TODO: inout
    input           n_cs,
    input           rw,
    input           clk, clk_en, n_reset,
    
//    input[11:0]     debug_in,
//    output[7:0]     debug_out
    output[3:0]     debug_out1,
    output[3:0]     debug_out2
);


//typedef struct packed {
    // register bits
    //
    bit[15:0]   v_0_freq;
    bit[11:0]   v_0_pw;
    bit         v_0_noise, v_0_pulse, v_0_saw, v_0_triangle;
    bit         v_0_test, v_0_ring, v_0_sync, v_0_gate;
    bit[3:0]    v_0_atk, v_0_dcy, v_0_stn, v_0_rls;

    // internal state
    //
    bit[23:0]   v_0_acc;
    bit[22:0]   v_0_lfsr;
    bit         v_0_sync_out;
    bit[7:0]    v_0_env_vol;
    bit[11:0]   v_0_out;
//} voice_t;


typedef struct packed {
    bit[10:0]   fc;
    bit[3:0]    res;
    bit[3:0]    filt;
    bit         off3, hp, bp, lp;
    bit[3:0]    vol;
} filter_t;


// voice_t     v[3];
filter_t    filter;


// ---------- Memory interface ----------
//
always_ff @(posedge clk, negedge n_reset)
begin
    if (!n_reset) begin
        // TODO: reset all registers     
    end 
    else if (!n_cs && !rw) begin
        unique case(addr)
        // Voice 0
        //
///*
        'h00:   v_0_freq[7:0]  <= data;
        'h01:   v_0_freq[15:8] <= data;
        'h02:   v_0_pw[7:0]    <= data;
        'h03:   v_0_pw[11:8]   <= data[3:0];
        'h04:   { v_0_noise, v_0_pulse, v_0_saw, v_0_triangle,
                  v_0_test,  v_0_ring,  v_0_sync, v_0_gate } <= data;
        'h05:   { v_0_atk, v_0_dcy } <= data;
        'h06:   { v_0_stn, v_0_rls } <= data;
//*/
/*
        // Voice 1
        //
        'h07:   v[1].freq[7:0]  <= data;
        'h08:   v[1].freq[15:8] <= data;
        'h09:   v[1].pw[7:0]    <= data;
        'h0A:   v[1].pw[11:8]   <= data[3:0];
        'h0B:   { v[1].noise, v[1].pulse, v[1].saw,  v[1].triangle, 
                  v[1].test,  v[1].ring,  v[1].sync, v[1].gate } <= data;
        'h0C:   { v[1].atk, v[1].dcy } <= data;
        'h0D:   { v[1].stn, v[1].rls } <= data;
        
        // Voice 2
        //
        'h0E:   v[2].freq[7:0]  <= data;
        'h0F:   v[2].freq[15:8] <= data;
        'h10:   v[2].pw[7:0]    <= data;
        'h11:   v[2].pw[11:8]   <= data[3:0];
        'h12:   { v[2].noise, v[2].pulse, v[2].saw,  v[2].triangle, 
                  v[2].test,  v[2].ring,  v[2].sync, v[2].gate } <= data;
        'h13:   { v[2].atk, v[2].dcy } <= data;
        'h14:   { v[2].stn, v[2].rls } <= data;
*/
        // Filter
        //
        'h15:   filter.fc[2:0]  <= data[2:0];
        'h16:   filter.fc[10:3] <= data;
        'h17:   { filter.res, filter.filt } <= data;
        'h18:   { filter.off3, filter.hp, filter.bp, filter.lp, filter.vol } <= data;

        default:    ;
        endcase
    end
end


/*
TODO: Read access
always_comb
begin
    data = 'z;
end
*/    

/*
genvar i;
generate
    for (i=0; i<3; i++) 
    begin: voice
        localparam prev_i = (i+5) % 3;

        sid_acc acc(
            .freq(v[i].freq), 
            .acc (v[i].acc),
            .lfsr(v[i].lfsr),
            .test(v[i].test),
            .sync(v[i].sync),

            .sync_in(v[prev_i].sync_out),
            .sync_out(v[i].sync_out),

            .clk(clk),
            .clk_en(clk_en),
            .n_reset(n_reset) 
        );

        sid_env env (
            .vol(v[i].env_vol),
            .gate(v[i].gate),
            .atk(v[i].atk),
            .dcy(v[i].dcy),
            .stn(v[i].stn),
            .rls(v[i].rls),

            .clk(clk),
            .clk_en(clk_en),
            .n_reset(n_reset) 
        );

        sid_wave wave(
            .out(       v[i].out ),
            .acc(       v[i].acc ),
            .lfsr(      v[i].lfsr ),
            .vol(       v[i].env_vol ),
            .noise(     v[i].noise ),
            .pulse(     v[i].pulse ),
            .saw(       v[i].saw ),
            .triangle(  v[i].triangle ),
            .pw(        v[i].pw ),
            .ring(      v[i].ring ),
            .ring_in(   v[prev_i].acc[23])
        );
    end
endgenerate
*/

        sid_acc acc(
            .freq(v_0_freq),
            .acc (v_0_acc),
            .lfsr(v_0_lfsr),
            .test(v_0_test),
            .sync(v_0_sync),

//            .sync_in(v[2].sync_out),
            .sync_in(1'b0),
            .sync_out(v_0_sync_out),

            .clk(clk),
            .clk_en(clk_en),
            .n_reset(n_reset)
        );

        sid_env env (
            .vol(v_0_env_vol),
            .gate(v_0_gate),
            .atk(v_0_atk),
            .dcy(v_0_dcy),
            .stn(v_0_stn),
            .rls(v_0_rls),

            .clk(clk),
            .clk_en(clk_en),
            .n_reset(n_reset)
        );

        sid_wave wave(
            .out(       v_0_out ),
            .acc(       v_0_acc ),
            .lfsr(      v_0_lfsr ),
            .vol(       v_0_env_vol ),
            .noise(     v_0_noise ),
            .pulse(     v_0_pulse ),
            .saw(       v_0_saw ),
            .triangle(  v_0_triangle ),
            .pw(        v_0_pw ),
            .ring(      v_0_ring ),
            .ring_in(   v_0_acc[23])
        );

// assign audio_out = {4'b0000, v_0_out};

///*
sid_filter  filt(
    .audio_out(audio_out),

//    .i_voice( { v[0].out, v[1].out, v[2].out } ),
    .voice_0( v_0_out ),

    .reg_fc     ( filter.fc     ),
    .reg_res    ( filter.res    ),
    .reg_en     ( filter.filt   ),
    .reg_off3   ( filter.off3   ),
    .reg_hp     ( filter.hp     ),
    .reg_bp     ( filter.bp     ),
    .reg_lp     ( filter.lp     ),
    .reg_vol    ( filter.vol    ),

    .clk(clk),
    .clk_en(clk_en),
    .n_reset(n_reset)
);
//*/

/*
    // TODO: Im Moment wird nur 3/4 des Wertebereichs ausgenutzt..
    //
    audio_out += 12'( (20'(v[i].out) * ) >> 6 );
*/


always_comb begin
/*
    debug_out2[0] = !v_0_gate;
    debug_out2[1] = !v_0_sync;
    debug_out2[2] = !v_0_ring;
*/

    debug_out2[0] = v_0_gate;
    debug_out2[1] = v_0_sync;
    debug_out2[2] = v_0_ring;
    debug_out2[3] = v_0_test;

    debug_out1[0] = v_0_triangle;
    debug_out1[1] = v_0_saw;
    debug_out1[2] = v_0_pulse;
    debug_out1[3] = v_0_noise;

/*
    debug_out1[0] = !filter.filt[0];
    debug_out1[1] = !filter.filt[1];
    debug_out1[2] = !filter.filt[2];

    debug_out2[0] = !v[0].gate;
    debug_out2[1] = !v[1].gate;
    debug_out2[2] = !v[2].gate;
*/
end


endmodule
