import argparse
import sys
import os

# ===================
# PIM mode
# ===================
PIM_MODES = {
    'ERASE':    0b001,
    'PROGRAM':  0b010,
    'READ':     0b011,
    'DEBUG':    0b100,
    'PARALLEL': 0b101,
    'RBR':      0b110,
    'LOAD':     0b111,
}


# ===================
# Hardware Model 
# ===================
def rbr_encoder(data: int) -> int:
    inv = (~data) & 0xFF
    zeros = bin(inv).count('1')
    lut = {0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 6, 6: 6, 7: 9, 8: 9}
    return lut.get(zeros, 0)

def parallel_encoder(data: int) -> int:
    inv = (~data) & 0xFF
    return bin(inv).count('1')

def encoder(pim_mode: int, mout: int, fout: int) -> int:
    if pim_mode == PIM_MODES['PARALLEL']:
        return (8 * parallel_encoder(mout) + parallel_encoder(fout)) & 0x7F
    elif pim_mode == PIM_MODES['RBR']:
        return rbr_encoder(mout) & 0x7F
    else:
        return 0

def bl_group_shifter(enc_out: list) -> int:
    result = ((enc_out[0] << 6)
             + (enc_out[1] << 4)
             + (enc_out[2] << 2)
             + enc_out[3])
    return result & 0x3FFF

def cycle_shifter(cycle_count: int, data: int) -> int:
    shift = cycle_count * 2
    return (data << shift) & 0xFFFFF

def post_processing_group(pim_mode: int, cycle_count: int,
                           mout_4: list, fout_4: list) -> int:
    enc_out  = [encoder(pim_mode, mout_4[i], fout_4[i]) for i in range(4)]
    bl_shift = bl_group_shifter(enc_out)
    return cycle_shifter(cycle_count, bl_shift)

def post_processing_top(pim_mode: int, cycle_count: int,
                         mout_32: list, fout_32: list) -> list:
    results = []
    for g in range(8):
        base = g * 4
        val = post_processing_group(pim_mode, cycle_count,
                                    mout_32[base:base + 4],
                                    fout_32[base:base + 4])
        results.append(val)
    return results


# ===================
# Input file parser
# ===================
def parse_hex256(token: str) -> list:
    token = token.strip().lower().replace('0x', '').replace('_', '')
    if len(token) != 64:
        raise ValueError(f"Expected 64 hex chars (256 bits), got {len(token)}: '{token}'")
    value = int(token, 16)
    return [(value >> (8 * i)) & 0xFF for i in range(32)]

ZEROS_32 = [0] * 32

def parse_input_file(filepath: str):
    """
    MOUT/FOUT 쌍을 entry로 파싱.
    FOUT 생략 시 0으로 채움 (RBR 모드용).
    빈 줄 또는 다음 MOUT 등장 시 현재 entry flush.
    """
    entries = []
    current_mout = None
    current_fout = None

    def flush():
        nonlocal current_mout, current_fout
        if current_mout is not None:
            fout = current_fout if current_fout is not None else ZEROS_32[:]
            entries.append((current_mout, fout))
            current_mout = None
            current_fout = None

    with open(filepath, 'r') as f:
        for lineno, raw in enumerate(f, 1):
            line = raw.strip()
            if not line or line.startswith('#'):
                flush()
                continue

            if ':' not in line:
                raise ValueError(f"Line {lineno}: expected 'KEY: value', got: '{line}'")

            key, _, value = line.partition(':')
            key   = key.strip().upper()
            value = value.strip()

            if key == 'MOUT':
                flush()  # 이전 entry 저장 후 새 entry 시작
                current_mout = parse_hex256(value)
            elif key == 'FOUT':
                current_fout = parse_hex256(value)
            else:
                raise ValueError(f"Line {lineno}: unknown key '{key}' (expected MOUT or FOUT)")

    flush()  # 마지막 entry

    if not entries:
        raise ValueError("No valid MOUT entries found in the input file.")

    return entries


# ===================
# Debug / Load mode
# ===================
def run_debug_mode(mout_32: list, fout_32: list, verbose: bool = True):
    print("\n" + "=" * 70)
    print("  MODE: DEBUG  (pim_mode = 3'b100)")
    print("=" * 70)

    if verbose:
        print("\n  [Input]")
        print(f"    MOUT (256-bit): 0x{''.join(f'{mout_32[31-i]:02X}' for i in range(32))}")
        print(f"    FOUT (256-bit): 0x{''.join(f'{fout_32[31-i]:02X}' for i in range(32))}")

    print()
    print("  [Output - output_buf_mux, 16 words total]")
    print()
    print(f"  {'buf8_cnt':>8}  {'Source':>14}  {'Byte[3] Byte[2] Byte[1] Byte[0]':>31}  {'32-bit Word':>12}")
    print("  " + "-" * 74)

    words = []
    for cnt in range(8):
        base = cnt * 4
        b = mout_32[base:base + 4]
        word = ((b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3]) & 0xFFFFFFFF
        words.append(word)
        src = f"MOUT[{base}:{base+3}]"
        print(f"  {cnt:>8}  {src:>14}  "
              f"{b[0]:02X}      {b[1]:02X}      {b[2]:02X}      {b[3]:02X}      "
              f"  0x{word:08X}")

    print()
    for cnt in range(8):
        base = cnt * 4
        b = fout_32[base:base + 4]
        word = ((b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3]) & 0xFFFFFFFF
        words.append(word)
        src = f"FOUT[{base}:{base+3}]"
        print(f"  {cnt + 8:>8}  {src:>14}  "
              f"{b[0]:02X}      {b[1]:02X}      {b[2]:02X}      {b[3]:02X}      "
              f"  0x{word:08X}")

    print()
    print("  [Summary]")
    print("  " + "  ".join(f"0x{w:08X}" for w in words[:8]))
    print("  " + "  ".join(f"0x{w:08X}" for w in words[8:]))

    return words


def run_load_mode(sub_mode: str, cycles_data: list, verbose: bool = True):
    if sub_mode not in ('PARALLEL', 'RBR'):
        raise ValueError(f"LOAD sub-mode must be PARALLEL or RBR, got '{sub_mode}'")

    pim_mode = PIM_MODES[sub_mode]
    n_total  = len(cycles_data)

    # cycle_count: 0 → 1 → 2 → 3 → 0 → 1 → ... (2-bit wrapping)
    cycle_seq = [i % 4 for i in range(n_total)]

    print("\n" + "=" * 70)
    print(f"  MODE: LOAD  (pim_mode = 3'b111)  |  Sub-mode: PIM_{sub_mode}")
    print(f"  Total passes  : {n_total}")
    print(f"  cycle_count   : {' -> '.join(map(str, cycle_seq[:8]))}{'-> ...' if n_total > 8 else ''}")
    print("=" * 70)

    accumulator = [0] * 8

    for entry_idx, (mout_32, fout_32) in enumerate(cycles_data):
        cycle_cnt = entry_idx % 4

        ppg_out = post_processing_top(pim_mode, cycle_cnt, mout_32, fout_32)

        if verbose:
            print(f"\n  -- Pass {entry_idx}  (cycle_count = {cycle_cnt}, left-shift = {cycle_cnt * 2} bits) --")
            print(f"    MOUT: 0x{''.join(f'{mout_32[31-i]:02X}' for i in range(32))}")
            if sub_mode == 'PARALLEL':
                print(f"    FOUT: 0x{''.join(f'{fout_32[31-i]:02X}' for i in range(32))}")
            print()

            for g in range(8):
                base = g * 4
                enc_out = [encoder(pim_mode, mout_32[base + j], fout_32[base + j])
                           for j in range(4)]
                bl = bl_group_shifter(enc_out)
                cs = cycle_shifter(cycle_cnt, bl)
                accumulator[g] = (accumulator[g] + ppg_out[g]) & 0xFFFFFFFF
                print(f"    PPG[{g}]  enc={[f'{e:3d}' for e in enc_out]}  "
                      f"bl_shift=0x{bl:04X} ({bl:4d})  "
                      f"cycle_shift=0x{cs:05X} ({cs:6d})  "
                      f"acc=0x{accumulator[g]:08X}")
        else:
            for g in range(8):
                accumulator[g] = (accumulator[g] + ppg_out[g]) & 0xFFFFFFFF

    print()
    print("  [Accumulated result]")
    print()
    print(f"  {'buf32_cnt':>9}  {'Group':>5}  {'Value (hex)':>12}  {'Value (dec)':>12}")
    print("  " + "-" * 46)
    for cnt in range(8):
        val = accumulator[cnt]
        print(f"  {cnt:>9}  PPG[{cnt}]  0x{val:08X}  {val:>12d}")

    print()
    print("  [Summary - data_o[0:7]]")
    print("  " + "  ".join(f"0x{accumulator[i]:08X}" for i in range(8)))

    return accumulator


# ===================
# Save output
# ===================
def save_output(words: list, filepath: str):
    with open(filepath, 'w') as f:
        for w in words:
            f.write(f"0x{w:08X}\n")
    print(f"\n  [Saved {len(words)} words -> '{filepath}']")


# ===================
# Main
# ===================
def main():
    parser = argparse.ArgumentParser(description="Post Processing Unit tester")
    parser.add_argument('--input',    '-i', required=True,  metavar='FILE', help='Input text file')
    parser.add_argument('--output',   '-o', default=None,   metavar='FILE', help='Output text file (optional)')
    parser.add_argument('--mode',     '-m', required=True,  choices=['debug', 'load'], help='debug | load')
    parser.add_argument('--sub-mode', '-s', default='parallel', choices=['parallel', 'rbr'],
                        help='(LOAD only) parallel | rbr  [default: parallel]')
    parser.add_argument('--quiet',    '-q', action='store_true', help='Hide per-pass detail')
    args = parser.parse_args()

    if not os.path.isfile(args.input):
        print(f"ERROR: File not found: {args.input}", file=sys.stderr)
        sys.exit(1)

    try:
        entries = parse_input_file(args.input)
    except ValueError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    verbose = not args.quiet

    if args.mode == 'debug':
        if len(entries) > 1 and verbose:
            print(f"  INFO: DEBUG mode uses only the first entry ({len(entries)} found).")
        words = run_debug_mode(*entries[0], verbose=verbose)
        if args.output:
            save_output(words, args.output)

    elif args.mode == 'load':
        words = run_load_mode(args.sub_mode.upper(), entries, verbose=verbose)
        if args.output:
            save_output(words, args.output)


if __name__ == '__main__':
    main()