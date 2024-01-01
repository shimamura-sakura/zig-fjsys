#pragma endian little
#include <std/mem.pat>
#include <std/io.pat>

struct Parameter<auto end_opdata> {
    u64 parameter_begin = $;
    u8  kind;
    if (kind == 1)
        u32 _u32;
    else if (kind == 2)
        u32 _ref_u32;
    else if (kind == 3) {
        char string[while($ < end_opdata && $[$] != 0)];
        padding[1];
    }
    else if (kind == 4) {
        u32 data[while($ < end_opdata)];
    }
    else std::error(std::format("unknown kind {} at {:x}", kind, parameter_begin));
};

struct Instruction {
    u16 opcode;
    u16 opsize;
    u64 end_opdata = $ + opsize;
    Parameter<end_opdata> args[while($ < end_opdata)];
};

struct Head {
    char magic[16];
    u32  unknown;
    u32  count_1;
    u32  count_2;
};

struct Body<auto count_1, auto count_2> {
    u32  table_1[count_1];
    u32  table_2[count_2];
    u32  end = $;
};

Head                                         head @ 0x00;
Body<head.count_1, head.count_2>             body @ 0x458;
Instruction instructions[while(!std::mem::eof())] @ body.end;