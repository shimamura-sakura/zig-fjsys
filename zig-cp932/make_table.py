#!/bin/env python3

jby_high = [dict() for _ in range(256)]
j_hi_set = set()
j_lo_set = set()

uby_high = [dict() for _ in range(256)]
u_hi_set = set()
u_lo_set = set()


with open('CP932.TXT', 'r') as fp:
    for line in fp:
        if len(line := line.strip().partition('#')[0].split()) < 2:
            continue
        jis = int(line[0], 0)
        u16 = int(line[1], 0)
        # jis
        jhi = jis >> 0x8
        jlo = jis & 0xFF
        jby_high[jhi][jlo] = u16
        j_hi_set.add(jhi)
        j_lo_set.add(jlo)
        # u16
        uhi = u16 >> 0x8
        ulo = u16 & 0xFF
        uby_high[uhi][ulo] = jis


j_entries = []
j_literal = []
for hi, lo_map in enumerate(jby_high):
    if len(lo_map) == 0 or hi == 0:
        if jby_high[0].get(hi, 0) != 0:  # single byte
            j_entries.append('.{ 0, 0, 0x%02x }' % jby_high[0][hi])
        else:  # invalid first byte
            j_entries.append('.{ 0, 0, 0 }')
    else:
        lo_min = min(lo_map.keys())
        lo_max = max(lo_map.keys())
        lit_ix = len(j_literal)
        for lo in range(lo_min, lo_max + 1):
            j_literal.append('0x%04x' % lo_map.get(lo, 0))
        j_entries.append('.{ 0x%02x, 0x%02x, %d }' % (lo_min, lo_max, lit_ix))

u_entries = []
u_literal = []
for hi, lo_map in enumerate(uby_high):
    # if len(lo_map) == 0 or hi == 0:
    #     if uby_high[0].get(hi, 0) != 0:  # single byte
    #         u_entries.append('.{ 0, 0, 0x%02x }' % uby_high[0][hi])
    #     else:  # invalid first byte
    #         u_entries.append('.{ 0, 0, 0 }')
    # else:
    if len(lo_map) == 0:
        u_entries.append('.{ 0, 0, 0}')
    else:
        lo_min = min(lo_map.keys())
        lo_max = max(lo_map.keys())
        lit_ix = len(u_literal)
        for lo in range(lo_min, lo_max + 1):
            u_literal.append('0x%04x' % lo_map.get(lo, 0))
        u_entries.append('.{ 0x%02x, 0x%02x, %d }' % (lo_min, lo_max, lit_ix))


print('pub const DecError = lookup.DecError;')
print('pub const Decoder = lookup.Decoder(d_entries, d_litvals){};')
print('pub const encode = lookup.Encoder(e_entries, e_litvals).encode;')
print('const lookup = @import("cp932-lookup.zig");')
print('const d_entries = [_]lookup.Entry{')
for i in range(0, len(j_entries), 5):
    print('    ' + ', '.join(j_entries[i:i+5]) + ',')
print('};')
print('const d_litvals = [_]u16{')
for i in range(0, len(j_literal), 16):
    print('    ' + ', '.join(j_literal[i:i+16]) + ',')
print('};')
print('const e_entries = [_]lookup.Entry{')
for i in range(0, len(u_entries), 5):
    print('    ' + ', '.join(u_entries[i:i+5]) + ',')
print('};')
print('const e_litvals = [_]u16{')
for i in range(0, len(u_literal), 16):
    print('    ' + ', '.join(u_literal[i:i+16]) + ',')
print('};')
