#include <fstream>
#include <iostream>
#include <vector>
#include <cstdint>
#include <sstream>
#include <string>
#include <iomanip>
#include <cstdint>
#include "../include/paddr.h"

size_t inst_rom_size = 0;      // 指令存储器大小

uint32_t* inst_rom_ = nullptr;  // 全局指令存储器指针

bool load_mem_file(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "无法打开文件: " << filename << std::endl;
        return false;
    }

    std::vector<uint32_t> instructions;
    std::string line;
    bool data_section = false;
    std::getline(file,line);

    while (std::getline(file, line)) {
        // 跳过文件头标记
        size_t colon_pos = line.find(':');
        if (colon_pos == std::string::npos) {
            std::cerr << "Error: Colon not found in input string" << std::endl;
            return 1;
        }

        // 提取冒号后的子串
        std::string hex_str = line.substr(colon_pos + 1);
        std::istringstream iss(hex_str);
        // std::cout<<line << std::endl;
        
        // 解析8个十六进制数
        for (int i = 0; i < 8; ++i) {
            // 从流中读取十六进制字符串并转换为整数
            uint32_t num;
            if (!(iss >> std::hex >> num)) {
                std::cerr << "Error parsing hex number at position " << i << std::endl;
                return 1;
            }
            instructions.push_back(num);
        }
        // std::cout<<line << std::endl;
    }

    // 复制到全局指令存储器
    inst_rom_size = instructions.size();
    if (inst_rom_size > 0) {
        inst_rom_ = new uint32_t[inst_rom_size];
        std::copy(instructions.begin(), instructions.end(), inst_rom_);
    }
    return inst_rom_size > 0;
}