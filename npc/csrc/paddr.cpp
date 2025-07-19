

#include "../include/debug.h"
#include "../include/common.h"
#include "../include/paddr.h"
#include "Vtop.h"
#include "verilated.h"

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#else
#endif
static uint8_t pmem[PMEM_SIZE] PG_ALIGN = {};

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }
static inline void host_write(void *addr, int len, word_t data);
extern Vtop *top;
static word_t pmem_read(uint32_t addr) {
  return *(uint32_t *)(guest_to_host(addr));
}

static inline void host_write(void *addr, int len, word_t data) {
  switch (len) {
    case 1: *(uint8_t  *)addr = data; return;
    case 2: *(uint16_t *)addr = data; return;
    case 4: *(uint32_t *)addr = data; return;
  }
}

static void pmem_write(paddr_t addr, word_t data,uint8_t mask ) {
    for(int i=0;i<4;i++)
        if(mask>>i & 1)host_write(guest_to_host(addr+i), 1, ((data>>(i*8)) & 0b11111111 ));
}

static void out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of pmem at pc = " FMT_WORD,
      addr, top->pc);

}

void init_mem() {
  memset(pmem,0,PMEM_SIZE);
}

extern "C" word_t paddr_read(paddr_t addr) {
  if (likely(in_pmem(addr))) return pmem_read(addr);
  return 0xffffffff;
}

extern "C" void paddr_write(paddr_t addr, word_t data,int8_t mask) {
  if (likely(in_pmem(addr))) { pmem_write(addr, data, mask); return; }
  out_of_bound(addr);
}

