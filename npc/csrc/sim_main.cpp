#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
// #include <debug.h>
#include "../include/paddr.h"

#include "Vtop.h"
#include "verilated.h"

VerilatedContext *contextp = new VerilatedContext;

Vtop *top = new Vtop{contextp};

#define CONFIG_FST_WAVE_TRACE 1
#define CONFIG_VCD_WAVE_TRACE 0
#if CONFIG_FST_WAVE_TRACE
#include "verilated_fst_c.h"
#elif CONFIG_VCD_WAVE_TRACE
#include "verilated_vcd_c.h"
#endif
vluint64_t main_time = 0;


extern "C" void ebreak(int inst)
{
    if(Verilated::gotFinish())
        return;
    
    Verilated::gotFinish(true);
}

extern uint32_t* inst_rom_;

int main(int argc, char **argv)
{
    contextp->commandArgs(argc, argv);
    load_mem_file("./mem.hex");
    uint8_t * inst_rom = (uint8_t *)inst_rom_;
    init_mem();

#if CONFIG_FST_WAVE_TRACE || CONFIG_VCD_WAVE_TRACE
    Verilated::traceEverOn(true);
#if CONFIG_FST_WAVE_TRACE
    VerilatedFstC* tfp = new VerilatedFstC();
#elif CONFIG_VCD_WAVE_TRACE
    VerilatedVcdC* tfp = new VerilatedVcdC();
#endif
    top->trace(tfp, 0);
#if CONFIG_FST_WAVE_TRACE
    tfp->open("wave.fst");
#elif CONFIG_VCD_WAVE_TRACE
    tfp->open("wave.vcd");
#endif
#endif

    top->clk = 0;
    top->rst = 1;
    vluint64_t last_clk_flip = 0;

    uint32_t cycle = 0;
    while (contextp->time()/500 <= 268 && !contextp->gotFinish())
    {
        vluint64_t current_time = contextp->time();
        if (current_time - last_clk_flip >= 500) {
            cycle ++ ;
            top->clk = !top->clk;
            last_clk_flip = current_time;
            if (current_time >= 2000 && top->clk == 1) {
                top->rst = 0;
            }
        }

        u_int32_t pc = top->pc;
        u_int32_t inst = (u_int32_t)((inst_rom[pc+3]<<24) | (inst_rom[pc+2]<<16) | (inst_rom[pc+1]<<8) | inst_rom[pc]);
        top->inst = inst;
        if (current_time == last_clk_flip ) {
            printf("cycle:%d pc:%x inst:%08x\n",cycle,pc,inst);
        }

        top->eval();

#if CONFIG_VCD_WAVE_TRACE || CONFIG_FST_WAVE_TRACE
        tfp->dump(current_time);
#endif

        contextp->timeInc(1);
    }

#if CONFIG_FST_WAVE_TRACE || CONFIG_VCD_WAVE_TRACE
    tfp->close();
    delete tfp;
#endif

    top->final();
    delete top;
    top = nullptr;
    delete contextp;
    contextp = nullptr;

    return 0;
}
