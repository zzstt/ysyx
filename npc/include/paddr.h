#ifndef __PADDR_H__
#define __PADDR_H__

#define PMEM_SIZE   0x8000000
#define PMEM_BASE   0x00000000
#define CONFIG_MBASE 0x00000000
#include "common.h"
#include <string>
void init_mem();

bool load_mem_file(const std::string& filename) ;
static inline bool in_pmem(paddr_t addr) {
  return addr - PMEM_BASE < PMEM_SIZE;
}
#endif