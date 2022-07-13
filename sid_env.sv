module sid_env (
    output[7:0]  vol,
    input [3:0]  atk, dcy, stn, rls,
    input   gate,
    
    input   clk, clk_en, n_reset
);


bit[7:0] vol = 0;

// TODO: Good practice?
typedef enum bit[1:0] {
    ATTACK,
    DECAY_SUSTAIN,
    RELEASE
} state_t;


/*
const bit[14:0] adsrtable[16] = '{
    'h007F, 'h3000, 'h1E00, 'h0660,
    'h0182, 'h5573, 'h000E, 'h3805,
    'h2424, 'h2220, 'h090C, 'h0ECD,
    'h010E, 'h23F7, 'h5237, 'h64A8
};
*/


bit[14:0] adsrtable[16];
initial begin
    adsrtable[0]=15'h007F;
    adsrtable[1]=15'h3000;
    adsrtable[2]=15'h1E00;
    adsrtable[3]=15'h0660;
    adsrtable[4]=15'h0182;
    adsrtable[5]=15'h5573;
    adsrtable[6]=15'h000E;
    adsrtable[7]=15'h3805;
    adsrtable[8]=15'h2424;
    adsrtable[9]=15'h2220;
    adsrtable[10]=15'h090C;
    adsrtable[11]=15'h0ECD;
    adsrtable[12]=15'h010E;
    adsrtable[13]=15'h23F7;
    adsrtable[14]=15'h5237;
    adsrtable[15]=15'h64A8;
end


state_t     state = RELEASE, state_next;

bit[7:0]    vol_next;
bit[14:0]   lfsr = '1, lfsr_next;

bit[4:0]    exp_counter = 0, exp_counter_next;
bit[4:0]    exp_period = 1, exp_period_next;


always_ff @(posedge clk, negedge n_reset)
begin
    if (!n_reset) begin
        state <= RELEASE;
        vol <= 0;
        lfsr <= '1;      
        exp_counter <= 0;
        exp_period <= 1;
    end
    else if (clk_en) begin
        state <= state_next;
        vol <= vol_next;
        lfsr <= lfsr_next;
        exp_counter <= exp_counter_next;
        exp_period  <= exp_period_next;
    end
end



always_comb
begin
    state_next = state;   
    vol_next = vol;
    exp_period_next = exp_period;

    case (vol)
        'hFF:   exp_period_next = 1;
        'h5D:   exp_period_next = 2;
        'h36:   exp_period_next = 4;
        'h1A:   exp_period_next = 8;
        'h0E:   exp_period_next = 16;
        'h06:   exp_period_next = 30;
        'h00:   exp_period_next = 1;
    endcase
    
    if (exp_counter == exp_period) begin
        exp_counter_next = 0;
    end
    else begin
        exp_counter_next = exp_counter + 1;
    end

    if (exp_counter == 0 || state == ATTACK)
        lfsr_next = { lfsr[1] ^ lfsr[0], lfsr[14:1] };
    else
        lfsr_next = lfsr;
    
    unique case (state)
        ATTACK: begin
            if (lfsr == adsrtable[atk]) begin
                lfsr_next = '1;
                if (vol != 255)
                    vol_next = vol + 1;
                else
                    state_next = DECAY_SUSTAIN;
            end
            
            if (!gate)
                state_next = RELEASE;        
        end
                
        DECAY_SUSTAIN: begin
            if (lfsr == adsrtable[dcy]) begin
                lfsr_next = '1;
                if (vol != { stn, stn })
                    vol_next = vol - 1;
            end

            if (!gate)
                state_next = RELEASE;
        end

        RELEASE: begin
            if (lfsr == adsrtable[rls]) begin
                lfsr_next = '1;
                if (vol != 0)
                    vol_next = vol - 1;
            end
            
            if (gate)
                state_next = ATTACK;
        end
        
        default:            
            state_next = RELEASE;
    endcase

end


endmodule
