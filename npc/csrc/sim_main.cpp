//与verilator无关的一些头文件
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
// #include <debug.h>
#include "../include/paddr.h"

//使用verilater必须include
#include "Vtop.h" //仿真模型的头文件，由top.v生成，如果顶层文件名更改则也需要更改
#include "verilated.h"

// contextp用来保存仿真的时间
VerilatedContext *contextp = new VerilatedContext;

// 构建一个名为top的仿真模型
Vtop *top = new Vtop{contextp};

// 配置修改（建议使用 FST）
#define CONFIG_FST_WAVE_TRACE 1  // 启用 FST 跟踪
#define CONFIG_VCD_WAVE_TRACE 0  // 禁用 VCD

// 包含对应头文件
#if CONFIG_FST_WAVE_TRACE
#include "verilated_fst_c.h"  // FST 格式支持
#elif CONFIG_VCD_WAVE_TRACE
#include "verilated_vcd_c.h"  // VCD 格式支持
#endif
vluint64_t main_time = 0;


extern "C" void ebreak(int inst)
{
    if(Verilated::gotFinish())
        return;
    
    Verilated::gotFinish(true);
}
extern uint32_t* inst_rom_;
//仿真的过程
int main(int argc, char **argv)
{
    
    // 传递参数给verilator
    contextp->commandArgs(argc, argv);
    load_mem_file("./mem.hex");
    uint8_t * inst_rom = (uint8_t *)inst_rom_;
    init_mem();

//如果生成FST格式的wave
#if CONFIG_FST_WAVE_TRACE || CONFIG_VCD_WAVE_TRACE
    Verilated::traceEverOn(true);
#if CONFIG_FST_WAVE_TRACE
    VerilatedFstC* tfp = new VerilatedFstC();  // FST 对象
#elif CONFIG_VCD_WAVE_TRACE
    VerilatedVcdC* tfp = new VerilatedVcdC();  // VCD 对象
#endif
    top->trace(tfp, 0);  // 注册所有信号
#if CONFIG_FST_WAVE_TRACE
    tfp->open("wave.fst");  // 打开 FST 文件
#elif CONFIG_VCD_WAVE_TRACE
    tfp->open("wave.vcd");  // 打开 VCD 文件
#endif
#endif

    /***************对top端口的初始化*******************/
    top->clk = 0;
    top->rst = 1;  // 复位信号初始有效
    vluint64_t last_clk_flip = 0;  // 记录上次时钟翻转时间

    uint32_t cycle = 0;
    /**************verilator的仿真循环*****************/
    while (contextp->time()/500 <= 268 && !contextp->gotFinish())
    {
        vluint64_t current_time = contextp->time();
        
        // 每1ns翻转一次时钟（1000ps）
        if (current_time - last_clk_flip >= 500) {
            cycle ++ ;
            top->clk = !top->clk;
            last_clk_flip = current_time;
            
            // 在时钟上升沿后释放复位（可选）
            if (current_time >= 2000 && top->clk == 1) {
                top->rst = 0;
            }
        }
        // int a,b;
        // 随机生成输入信号（可调整频率）
        // if (current_time % 1000 == 0) {  // 每500ps变化一次
        //     a = rand() ;
        //     b = rand() ;
        //     top->inst = a;
        //     top->rdata = b;
        // }
        u_int32_t pc = top->pc;
        u_int32_t inst = (u_int32_t)((inst_rom[pc+3]<<24) | (inst_rom[pc+2]<<16) | (inst_rom[pc+1]<<8) | inst_rom[pc]);
        top->inst = inst;
        if (current_time == last_clk_flip ) {
            printf("cycle:%d pc:%x inst:%08x\n",cycle,pc,inst);
        }

        top->eval();  // 更新电路状态

        
        // assert(top->f == (a ^ b)); 
#if CONFIG_VCD_WAVE_TRACE || CONFIG_FST_WAVE_TRACE
        tfp->dump(current_time);  // 记录当前时刻波形
#endif

        contextp->timeInc(1);  // 每次推进1ps
    }

/*****************仿真结束，一些善后工作***************/
#if CONFIG_FST_WAVE_TRACE || CONFIG_VCD_WAVE_TRACE
    tfp->close();
    delete tfp;
#endif

    // 清理top仿真模型，并销毁相关指针，并将指针变为空指针
    top->final();
    delete top;
    top = nullptr;
    delete contextp;
    contextp = nullptr;

    return 0;
}
