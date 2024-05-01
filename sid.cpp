#include <verilated.h>
#include "obj_dir/Vsid_top.h"
#if VM_TRACE
#include <verilated_vcd_c.h>
#endif

Vsid_top *sid;

unsigned main_time = 0;

double sc_time_stamp () {	// Called by $time in Verilog
    return main_time;		// Note does conversion to real, to match SystemC
}

int main(int argc, char **argv, char **env) {
    if (0 && argc && argv && env) {}	// Prevent unused variable warnings
    sid = new Vsid_top;

    Verilated::commandArgs(argc, argv);
    Verilated::debug(0);

#if VM_TRACE
    Verilated::traceEverOn(true);
    VL_PRINTF("Enabling waves...\n");
    VerilatedVcdC* tfp = new VerilatedVcdC;
    cpu->trace(tfp, 99);
    tfp->open("vlt_dump.vcd");
#endif

    sid->RSTn_i = 0x01;

    while (main_time < 32860 && !Verilated::gotFinish()) {
        sid->eval();

        if ((main_time % 2) == 0) {
            sid->SYS_CLK = 0x00;
        }

        if ((main_time % 2) == 1) {
            sid->SYS_CLK = 0x01;
        }

    #if VM_TRACE
        if (tfp) tfp->dump (main_time);
    #endif
/*
        if (sid->SYS_CLK) {
            VL_PRINTF ("%03d clk:%03d dac:%d\n",
                main_time/2,
                sid->SYS_CLK,
                sid->dac
            );
        }
*/
        main_time++;
    }

    sid->final();

#if VM_TRACE
    if (tfp) tfp->close();
#endif

    exit(0L);
}
