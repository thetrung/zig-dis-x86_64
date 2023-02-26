const std = @import("std");
const assert = std.debug.assert;
const math = std.math;

const encoder = @import("encoder.zig");
const Instruction = encoder.Instruction;
const Rex = encoder.Rex;
const LegacyPrefixes = encoder.LegacyPrefixes;

const Entry = struct { Mnemonic, OpEn, Op, Op, Op, Op, u2, u8, u8, u8, u3 };

// TODO move this into a .zon file when Zig is capable of importing .zon files
const table = &[_]Entry{
    .{ .adc, .zi, .al, .imm8, .none, .none, 1, 0x14, 0x00, 0x00, 0 },
    .{ .adc, .zi, .ax, .imm16, .none, .none, 1, 0x15, 0x00, 0x00, 0 },
    .{ .adc, .zi, .eax, .imm32, .none, .none, 1, 0x15, 0x00, 0x00, 0 },
    .{ .adc, .zi, .rax, .imm32, .none, .none, 1, 0x15, 0x00, 0x00, 0 },
    .{ .adc, .mi, .rm8, .imm8, .none, .none, 1, 0x80, 0x00, 0x00, 2 },
    .{ .adc, .mi, .rm16, .imm16, .none, .none, 1, 0x81, 0x00, 0x00, 2 },
    .{ .adc, .mi, .rm32, .imm32, .none, .none, 1, 0x81, 0x00, 0x00, 2 },
    .{ .adc, .mi, .rm64, .imm32, .none, .none, 1, 0x81, 0x00, 0x00, 2 },
    .{ .adc, .mi, .rm16, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 2 },
    .{ .adc, .mi, .rm32, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 2 },
    .{ .adc, .mi, .rm64, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 2 },
    .{ .adc, .mr, .rm8, .r8, .none, .none, 1, 0x10, 0x00, 0x00, 0 },
    .{ .adc, .mr, .rm16, .r16, .none, .none, 1, 0x11, 0x00, 0x00, 0 },
    .{ .adc, .mr, .rm32, .r32, .none, .none, 1, 0x11, 0x00, 0x00, 0 },
    .{ .adc, .mr, .rm64, .r64, .none, .none, 1, 0x11, 0x00, 0x00, 0 },
    .{ .adc, .rm, .r8, .rm8, .none, .none, 1, 0x12, 0x00, 0x00, 0 },
    .{ .adc, .rm, .r16, .rm16, .none, .none, 1, 0x13, 0x00, 0x00, 0 },
    .{ .adc, .rm, .r32, .rm32, .none, .none, 1, 0x13, 0x00, 0x00, 0 },
    .{ .adc, .rm, .r64, .rm64, .none, .none, 1, 0x13, 0x00, 0x00, 0 },

    .{ .add, .zi, .al, .imm8, .none, .none, 1, 0x04, 0x00, 0x00, 0 },
    .{ .add, .zi, .ax, .imm16, .none, .none, 1, 0x05, 0x00, 0x00, 0 },
    .{ .add, .zi, .eax, .imm32, .none, .none, 1, 0x05, 0x00, 0x00, 0 },
    .{ .add, .zi, .rax, .imm32, .none, .none, 1, 0x05, 0x00, 0x00, 0 },
    .{ .add, .mi, .rm8, .imm8, .none, .none, 1, 0x80, 0x00, 0x00, 0 },
    .{ .add, .mi, .rm16, .imm16, .none, .none, 1, 0x81, 0x00, 0x00, 0 },
    .{ .add, .mi, .rm32, .imm32, .none, .none, 1, 0x81, 0x00, 0x00, 0 },
    .{ .add, .mi, .rm64, .imm32, .none, .none, 1, 0x81, 0x00, 0x00, 0 },
    .{ .add, .mi, .rm16, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 0 },
    .{ .add, .mi, .rm32, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 0 },
    .{ .add, .mi, .rm64, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 0 },
    .{ .add, .mr, .rm8, .r8, .none, .none, 1, 0x00, 0x00, 0x00, 0 },
    .{ .add, .mr, .rm16, .r16, .none, .none, 1, 0x01, 0x00, 0x00, 0 },
    .{ .add, .mr, .rm32, .r32, .none, .none, 1, 0x01, 0x00, 0x00, 0 },
    .{ .add, .mr, .rm64, .r64, .none, .none, 1, 0x01, 0x00, 0x00, 0 },
    .{ .add, .rm, .r8, .rm8, .none, .none, 1, 0x02, 0x00, 0x00, 0 },
    .{ .add, .rm, .r16, .rm16, .none, .none, 1, 0x03, 0x00, 0x00, 0 },
    .{ .add, .rm, .r32, .rm32, .none, .none, 1, 0x03, 0x00, 0x00, 0 },
    .{ .add, .rm, .r64, .rm64, .none, .none, 1, 0x03, 0x00, 0x00, 0 },

    .{ .@"and", .zi, .al, .imm8, .none, .none, 1, 0x24, 0x00, 0x00, 0 },
    .{ .@"and", .zi, .ax, .imm16, .none, .none, 1, 0x25, 0x00, 0x00, 0 },
    .{ .@"and", .zi, .eax, .imm32, .none, .none, 1, 0x25, 0x00, 0x00, 0 },
    .{ .@"and", .zi, .rax, .imm32, .none, .none, 1, 0x25, 0x00, 0x00, 0 },
    .{ .@"and", .mi, .rm8, .imm8, .none, .none, 1, 0x80, 0x00, 0x00, 4 },
    .{ .@"and", .mi, .rm16, .imm16, .none, .none, 1, 0x81, 0x00, 0x00, 4 },
    .{ .@"and", .mi, .rm32, .imm32, .none, .none, 1, 0x81, 0x00, 0x00, 4 },
    .{ .@"and", .mi, .rm64, .imm32, .none, .none, 1, 0x81, 0x00, 0x00, 4 },
    .{ .@"and", .mi, .rm16, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 4 },
    .{ .@"and", .mi, .rm32, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 4 },
    .{ .@"and", .mi, .rm64, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 4 },
    .{ .@"and", .mr, .rm8, .r8, .none, .none, 1, 0x20, 0x00, 0x00, 0 },
    .{ .@"and", .mr, .rm16, .r16, .none, .none, 1, 0x21, 0x00, 0x00, 0 },
    .{ .@"and", .mr, .rm32, .r32, .none, .none, 1, 0x21, 0x00, 0x00, 0 },
    .{ .@"and", .mr, .rm64, .r64, .none, .none, 1, 0x21, 0x00, 0x00, 0 },
    .{ .@"and", .rm, .r8, .rm8, .none, .none, 1, 0x22, 0x00, 0x00, 0 },
    .{ .@"and", .rm, .r16, .rm16, .none, .none, 1, 0x23, 0x00, 0x00, 0 },
    .{ .@"and", .rm, .r32, .rm32, .none, .none, 1, 0x23, 0x00, 0x00, 0 },
    .{ .@"and", .rm, .r64, .rm64, .none, .none, 1, 0x23, 0x00, 0x00, 0 },

    // This is M encoding according to Intel, but I makes more sense here.
    .{ .call, .i, .rel32, .none, .none, .none, 1, 0xe8, 0x00, 0x00, 0 },
    .{ .call, .m, .rm64, .none, .none, .none, 1, 0xff, 0x00, 0x00, 2 },

    .{ .cmp, .zi, .al, .imm8, .none, .none, 1, 0x3c, 0x00, 0x00, 0 },
    .{ .cmp, .zi, .ax, .imm16, .none, .none, 1, 0x3d, 0x00, 0x00, 0 },
    .{ .cmp, .zi, .eax, .imm32, .none, .none, 1, 0x3d, 0x00, 0x00, 0 },
    .{ .cmp, .zi, .rax, .imm32, .none, .none, 1, 0x3d, 0x00, 0x00, 0 },
    .{ .cmp, .mi, .rm8, .imm8, .none, .none, 1, 0x80, 0x00, 0x00, 7 },
    .{ .cmp, .mi, .rm16, .imm16, .none, .none, 1, 0x81, 0x00, 0x00, 7 },
    .{ .cmp, .mi, .rm32, .imm32, .none, .none, 1, 0x81, 0x00, 0x00, 7 },
    .{ .cmp, .mi, .rm64, .imm32, .none, .none, 1, 0x81, 0x00, 0x00, 7 },
    .{ .cmp, .mi, .rm16, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 7 },
    .{ .cmp, .mi, .rm32, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 7 },
    .{ .cmp, .mi, .rm64, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 7 },
    .{ .cmp, .mr, .rm8, .r8, .none, .none, 1, 0x38, 0x00, 0x00, 0 },
    .{ .cmp, .mr, .rm16, .r16, .none, .none, 1, 0x39, 0x00, 0x00, 0 },
    .{ .cmp, .mr, .rm32, .r32, .none, .none, 1, 0x39, 0x00, 0x00, 0 },
    .{ .cmp, .mr, .rm64, .r64, .none, .none, 1, 0x39, 0x00, 0x00, 0 },
    .{ .cmp, .rm, .r8, .rm8, .none, .none, 1, 0x3a, 0x00, 0x00, 0 },
    .{ .cmp, .rm, .r16, .rm16, .none, .none, 1, 0x3b, 0x00, 0x00, 0 },
    .{ .cmp, .rm, .r32, .rm32, .none, .none, 1, 0x3b, 0x00, 0x00, 0 },
    .{ .cmp, .rm, .r64, .rm64, .none, .none, 1, 0x3b, 0x00, 0x00, 0 },

    .{ .imul, .m, .rm8, .none, .none, .none, 1, 0xf6, 0x00, 0x00, 5 },
    .{ .imul, .m, .rm16, .none, .none, .none, 1, 0xf7, 0x00, 0x00, 5 },
    .{ .imul, .m, .rm32, .none, .none, .none, 1, 0xf7, 0x00, 0x00, 5 },
    .{ .imul, .m, .rm64, .none, .none, .none, 1, 0xf7, 0x00, 0x00, 5 },
    .{ .imul, .rm, .r16, .rm16, .none, .none, 2, 0x0f, 0xaf, 0x00, 0 },
    .{ .imul, .rm, .r32, .rm32, .none, .none, 2, 0x0f, 0xaf, 0x00, 0 },
    .{ .imul, .rm, .r64, .rm64, .none, .none, 2, 0x0f, 0xaf, 0x00, 0 },
    .{ .imul, .rmi, .r16, .rm16, .imm8, .none, 1, 0x6b, 0x00, 0x00, 0 },
    .{ .imul, .rmi, .r32, .rm32, .imm8, .none, 1, 0x6b, 0x00, 0x00, 0 },
    .{ .imul, .rmi, .r64, .rm64, .imm8, .none, 1, 0x6b, 0x00, 0x00, 0 },
    .{ .imul, .rmi, .r16, .rm16, .imm16, .none, 1, 0x69, 0x00, 0x00, 0 },
    .{ .imul, .rmi, .r32, .rm32, .imm32, .none, 1, 0x69, 0x00, 0x00, 0 },
    .{ .imul, .rmi, .r64, .rm64, .imm32, .none, 1, 0x69, 0x00, 0x00, 0 },

    .{ .int3, .np, .none, .none, .none, .none, 1, 0xcc, 0x00, 0x00, 0 },

    .{ .lea, .rm, .r16, .m, .none, .none, 1, 0x8d, 0x00, 0x00, 0 },
    .{ .lea, .rm, .r32, .m, .none, .none, 1, 0x8d, 0x00, 0x00, 0 },
    .{ .lea, .rm, .r64, .m, .none, .none, 1, 0x8d, 0x00, 0x00, 0 },

    .{ .mov, .mr, .rm8, .r8, .none, .none, 1, 0x88, 0x00, 0x00, 0 },
    .{ .mov, .mr, .rm16, .r16, .none, .none, 1, 0x89, 0x00, 0x00, 0 },
    .{ .mov, .mr, .rm32, .r32, .none, .none, 1, 0x89, 0x00, 0x00, 0 },
    .{ .mov, .mr, .rm64, .r64, .none, .none, 1, 0x89, 0x00, 0x00, 0 },
    .{ .mov, .rm, .r8, .rm8, .none, .none, 1, 0x8a, 0x00, 0x00, 0 },
    .{ .mov, .rm, .r16, .rm16, .none, .none, 1, 0x8b, 0x00, 0x00, 0 },
    .{ .mov, .rm, .r32, .rm32, .none, .none, 1, 0x8b, 0x00, 0x00, 0 },
    .{ .mov, .rm, .r64, .rm64, .none, .none, 1, 0x8b, 0x00, 0x00, 0 },
    .{ .mov, .mr, .rm16, .sreg, .none, .none, 1, 0x8c, 0x00, 0x00, 0 },
    .{ .mov, .mr, .rm64, .sreg, .none, .none, 1, 0x8c, 0x00, 0x00, 0 },
    .{ .mov, .rm, .sreg, .rm16, .none, .none, 1, 0x8e, 0x00, 0x00, 0 },
    .{ .mov, .rm, .sreg, .rm64, .none, .none, 1, 0x8e, 0x00, 0x00, 0 },
    .{ .mov, .fd, .al, .moffs, .none, .none, 1, 0xa0, 0x00, 0x00, 0 },
    .{ .mov, .fd, .ax, .moffs, .none, .none, 1, 0xa1, 0x00, 0x00, 0 },
    .{ .mov, .fd, .eax, .moffs, .none, .none, 1, 0xa1, 0x00, 0x00, 0 },
    .{ .mov, .fd, .rax, .moffs, .none, .none, 1, 0xa1, 0x00, 0x00, 0 },
    .{ .mov, .td, .moffs, .al, .none, .none, 1, 0xa2, 0x00, 0x00, 0 },
    .{ .mov, .td, .moffs, .ax, .none, .none, 1, 0xa3, 0x00, 0x00, 0 },
    .{ .mov, .td, .moffs, .eax, .none, .none, 1, 0xa3, 0x00, 0x00, 0 },
    .{ .mov, .td, .moffs, .rax, .none, .none, 1, 0xa3, 0x00, 0x00, 0 },
    .{ .mov, .oi, .r8, .imm8, .none, .none, 1, 0xb0, 0x00, 0x00, 0 },
    .{ .mov, .oi, .r16, .imm16, .none, .none, 1, 0xb8, 0x00, 0x00, 0 },
    .{ .mov, .oi, .r32, .imm32, .none, .none, 1, 0xb8, 0x00, 0x00, 0 },
    .{ .mov, .oi, .r64, .imm64, .none, .none, 1, 0xb8, 0x00, 0x00, 0 },
    .{ .mov, .mi, .rm8, .imm8, .none, .none, 1, 0xc6, 0x00, 0x00, 0 },
    .{ .mov, .mi, .rm16, .imm16, .none, .none, 1, 0xc7, 0x00, 0x00, 0 },
    .{ .mov, .mi, .rm32, .imm32, .none, .none, 1, 0xc7, 0x00, 0x00, 0 },
    .{ .mov, .mi, .rm64, .imm32, .none, .none, 1, 0xc7, 0x00, 0x00, 0 },

    .{ .movsx, .rm, .r16, .rm8, .none, .none, 2, 0x0f, 0xbe, 0x00, 0 },
    .{ .movsx, .rm, .r32, .rm8, .none, .none, 2, 0x0f, 0xbe, 0x00, 0 },
    .{ .movsx, .rm, .r64, .rm8, .none, .none, 2, 0x0f, 0xbe, 0x00, 0 },
    .{ .movsx, .rm, .r32, .rm16, .none, .none, 2, 0x0f, 0xbf, 0x00, 0 },
    .{ .movsx, .rm, .r64, .rm16, .none, .none, 2, 0x0f, 0xbf, 0x00, 0 },

    .{ .movsxd, .rm, .r64, .rm32, .none, .none, 1, 0x63, 0x00, 0x00, 0 },

    .{ .movzx, .rm, .r16, .rm8, .none, .none, 2, 0x0f, 0xb6, 0x00, 0 },
    .{ .movzx, .rm, .r32, .rm8, .none, .none, 2, 0x0f, 0xb6, 0x00, 0 },
    .{ .movzx, .rm, .r64, .rm8, .none, .none, 2, 0x0f, 0xb6, 0x00, 0 },
    .{ .movzx, .rm, .r32, .rm16, .none, .none, 2, 0x0f, 0xb7, 0x00, 0 },
    .{ .movzx, .rm, .r64, .rm16, .none, .none, 2, 0x0f, 0xb7, 0x00, 0 },

    .{ .nop, .np, .none, .none, .none, .none, 1, 0x90, 0x00, 0x00, 0 },

    .{ .@"or", .zi, .al, .imm8, .none, .none, 1, 0x0c, 0x00, 0x00, 0 },
    .{ .@"or", .zi, .ax, .imm16, .none, .none, 1, 0x0d, 0x00, 0x00, 0 },
    .{ .@"or", .zi, .eax, .imm32, .none, .none, 1, 0x0d, 0x00, 0x00, 0 },
    .{ .@"or", .zi, .rax, .imm32, .none, .none, 1, 0x0d, 0x00, 0x00, 0 },
    .{ .@"or", .mi, .rm8, .imm8, .none, .none, 1, 0x80, 0x00, 0x00, 1 },
    .{ .@"or", .mi, .rm16, .imm16, .none, .none, 1, 0x81, 0x00, 0x00, 1 },
    .{ .@"or", .mi, .rm32, .imm32, .none, .none, 1, 0x81, 0x00, 0x00, 1 },
    .{ .@"or", .mi, .rm64, .imm32, .none, .none, 1, 0x81, 0x00, 0x00, 1 },
    .{ .@"or", .mi, .rm16, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 1 },
    .{ .@"or", .mi, .rm32, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 1 },
    .{ .@"or", .mi, .rm64, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 1 },
    .{ .@"or", .mr, .rm8, .r8, .none, .none, 1, 0x08, 0x00, 0x00, 0 },
    .{ .@"or", .mr, .rm16, .r16, .none, .none, 1, 0x09, 0x00, 0x00, 0 },
    .{ .@"or", .mr, .rm32, .r32, .none, .none, 1, 0x09, 0x00, 0x00, 0 },
    .{ .@"or", .mr, .rm64, .r64, .none, .none, 1, 0x09, 0x00, 0x00, 0 },
    .{ .@"or", .rm, .r8, .rm8, .none, .none, 1, 0x0a, 0x00, 0x00, 0 },
    .{ .@"or", .rm, .r16, .rm16, .none, .none, 1, 0x0b, 0x00, 0x00, 0 },
    .{ .@"or", .rm, .r32, .rm32, .none, .none, 1, 0x0b, 0x00, 0x00, 0 },
    .{ .@"or", .rm, .r64, .rm64, .none, .none, 1, 0x0b, 0x00, 0x00, 0 },

    .{ .pop, .o, .r16, .none, .none, .none, 1, 0x58, 0x00, 0x00, 0 },
    .{ .pop, .o, .r64, .none, .none, .none, 1, 0x58, 0x00, 0x00, 0 },
    .{ .pop, .m, .rm16, .none, .none, .none, 1, 0x8f, 0x00, 0x00, 0 },
    .{ .pop, .m, .rm64, .none, .none, .none, 1, 0x8f, 0x00, 0x00, 0 },

    .{ .push, .o, .r16, .none, .none, .none, 1, 0x50, 0x00, 0x00, 0 },
    .{ .push, .o, .r64, .none, .none, .none, 1, 0x50, 0x00, 0x00, 0 },
    .{ .push, .m, .rm16, .none, .none, .none, 1, 0xff, 0x0, 0x00, 6 },
    .{ .push, .m, .rm64, .none, .none, .none, 1, 0xff, 0x0, 0x00, 6 },
    .{ .push, .i, .imm8, .none, .none, .none, 1, 0x6a, 0x00, 0x00, 0 },
    .{ .push, .i, .imm16, .none, .none, .none, 1, 0x68, 0x00, 0x00, 0 },
    .{ .push, .i, .imm32, .none, .none, .none, 1, 0x68, 0x00, 0x00, 0 },

    .{ .ret, .np, .none, .none, .none, .none, 1, 0xc3, 0x00, 0x00, 0 },

    .{ .sbb, .zi, .al, .imm8, .none, .none, 1, 0x1c, 0x00, 0x00, 0 },
    .{ .sbb, .zi, .ax, .imm16, .none, .none, 1, 0x1d, 0x00, 0x00, 0 },
    .{ .sbb, .zi, .eax, .imm32, .none, .none, 1, 0x1d, 0x00, 0x00, 0 },
    .{ .sbb, .zi, .rax, .imm32, .none, .none, 1, 0x1d, 0x00, 0x00, 0 },
    .{ .sbb, .mi, .rm8, .imm8, .none, .none, 1, 0x80, 0x00, 0x00, 3 },
    .{ .sbb, .mi, .rm16, .imm16, .none, .none, 1, 0x81, 0x00, 0x00, 3 },
    .{ .sbb, .mi, .rm32, .imm32, .none, .none, 1, 0x81, 0x00, 0x00, 3 },
    .{ .sbb, .mi, .rm64, .imm32, .none, .none, 1, 0x81, 0x00, 0x00, 3 },
    .{ .sbb, .mi, .rm16, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 3 },
    .{ .sbb, .mi, .rm32, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 3 },
    .{ .sbb, .mi, .rm64, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 3 },
    .{ .sbb, .mr, .rm8, .r8, .none, .none, 1, 0x18, 0x00, 0x00, 0 },
    .{ .sbb, .mr, .rm16, .r16, .none, .none, 1, 0x19, 0x00, 0x00, 0 },
    .{ .sbb, .mr, .rm32, .r32, .none, .none, 1, 0x19, 0x00, 0x00, 0 },
    .{ .sbb, .mr, .rm64, .r64, .none, .none, 1, 0x19, 0x00, 0x00, 0 },
    .{ .sbb, .rm, .r8, .rm8, .none, .none, 1, 0x1a, 0x00, 0x00, 0 },
    .{ .sbb, .rm, .r16, .rm16, .none, .none, 1, 0x1b, 0x00, 0x00, 0 },
    .{ .sbb, .rm, .r32, .rm32, .none, .none, 1, 0x1b, 0x00, 0x00, 0 },
    .{ .sbb, .rm, .r64, .rm64, .none, .none, 1, 0x1b, 0x00, 0x00, 0 },

    .{ .sub, .zi, .al, .imm8, .none, .none, 1, 0x2c, 0x00, 0x00, 0 },
    .{ .sub, .zi, .ax, .imm16, .none, .none, 1, 0x2d, 0x00, 0x00, 0 },
    .{ .sub, .zi, .eax, .imm32, .none, .none, 1, 0x2d, 0x00, 0x00, 0 },
    .{ .sub, .zi, .rax, .imm32, .none, .none, 1, 0x2d, 0x00, 0x00, 0 },
    .{ .sub, .mi, .rm8, .imm8, .none, .none, 1, 0x80, 0x00, 0x00, 5 },
    .{ .sub, .mi, .rm16, .imm16, .none, .none, 1, 0x81, 0x00, 0x00, 5 },
    .{ .sub, .mi, .rm32, .imm32, .none, .none, 1, 0x81, 0x00, 0x00, 5 },
    .{ .sub, .mi, .rm64, .imm32, .none, .none, 1, 0x81, 0x00, 0x00, 5 },
    .{ .sub, .mi, .rm16, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 5 },
    .{ .sub, .mi, .rm32, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 5 },
    .{ .sub, .mi, .rm64, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 5 },
    .{ .sub, .mr, .rm8, .r8, .none, .none, 1, 0x28, 0x00, 0x00, 0 },
    .{ .sub, .mr, .rm16, .r16, .none, .none, 1, 0x29, 0x00, 0x00, 0 },
    .{ .sub, .mr, .rm32, .r32, .none, .none, 1, 0x29, 0x00, 0x00, 0 },
    .{ .sub, .mr, .rm64, .r64, .none, .none, 1, 0x29, 0x00, 0x00, 0 },
    .{ .sub, .rm, .r8, .rm8, .none, .none, 1, 0x2a, 0x00, 0x00, 0 },
    .{ .sub, .rm, .r16, .rm16, .none, .none, 1, 0x2b, 0x00, 0x00, 0 },
    .{ .sub, .rm, .r32, .rm32, .none, .none, 1, 0x2b, 0x00, 0x00, 0 },
    .{ .sub, .rm, .r64, .rm64, .none, .none, 1, 0x2b, 0x00, 0x00, 0 },

    .{ .syscall, .np, .none, .none, .none, .none, 2, 0x0f, 0x05, 0x00, 0 },

    .{ .xor, .zi, .al, .imm8, .none, .none, 1, 0x34, 0x00, 0x00, 0 },
    .{ .xor, .zi, .ax, .imm16, .none, .none, 1, 0x35, 0x00, 0x00, 0 },
    .{ .xor, .zi, .eax, .imm32, .none, .none, 1, 0x35, 0x00, 0x00, 0 },
    .{ .xor, .zi, .rax, .imm32, .none, .none, 1, 0x35, 0x00, 0x00, 0 },
    .{ .xor, .mi, .rm8, .imm8, .none, .none, 1, 0x80, 0x00, 0x00, 6 },
    .{ .xor, .mi, .rm16, .imm16, .none, .none, 1, 0x81, 0x00, 0x00, 6 },
    .{ .xor, .mi, .rm32, .imm32, .none, .none, 1, 0x81, 0x00, 0x00, 6 },
    .{ .xor, .mi, .rm64, .imm32, .none, .none, 1, 0x81, 0x00, 0x00, 6 },
    .{ .xor, .mi, .rm16, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 6 },
    .{ .xor, .mi, .rm32, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 6 },
    .{ .xor, .mi, .rm64, .imm8, .none, .none, 1, 0x83, 0x00, 0x00, 6 },
    .{ .xor, .mr, .rm8, .r8, .none, .none, 1, 0x30, 0x00, 0x00, 0 },
    .{ .xor, .mr, .rm16, .r16, .none, .none, 1, 0x31, 0x00, 0x00, 0 },
    .{ .xor, .mr, .rm32, .r32, .none, .none, 1, 0x31, 0x00, 0x00, 0 },
    .{ .xor, .mr, .rm64, .r64, .none, .none, 1, 0x31, 0x00, 0x00, 0 },
    .{ .xor, .rm, .r8, .rm8, .none, .none, 1, 0x32, 0x00, 0x00, 0 },
    .{ .xor, .rm, .r16, .rm16, .none, .none, 1, 0x33, 0x00, 0x00, 0 },
    .{ .xor, .rm, .r32, .rm32, .none, .none, 1, 0x33, 0x00, 0x00, 0 },
    .{ .xor, .rm, .r64, .rm64, .none, .none, 1, 0x33, 0x00, 0x00, 0 },
};

pub const Mnemonic = enum {
    // zig fmt: off
    adc, add, @"and",
    call, cmp,
    imul, int3,
    lea,
    mov, movsx, movsxd, movzx,
    nop,
    @"or",
    pop, push,
    ret,
    sbb, sub, syscall,
    xor,
    // zig fmt: on

    pub fn defaultsTo64Bits(mnemonic: Mnemonic) bool {
        return switch (mnemonic) {
            .call, .push, .pop, .ret => true,
            else => false,
        };
    }
};

pub const OpEn = enum {
    // zig fmt: off
    np,
    o, oi,
    i, zi,
    m,
    fd, td,
    mi, mr, rm, rmi,
    // zig fmt: on
};

pub const Op = enum {
    // zig fmt: off
    none,
    imm8, imm16, imm32, imm64,
    al, ax, eax, rax,
    r8, r16, r32, r64,
    rm8, rm16, rm32, rm64,
    m8, m16, m32, m64,
    rel16, rel32,
    m,
    moffs,
    sreg,
    // zig fmt: on

    pub fn fromOperand(operand: Instruction.Operand) Op {
        switch (operand) {
            .none => return .none,

            .reg => |reg| {
                if (reg.isSegment()) return .sreg;

                const bit_size = reg.bitSize();
                if (reg.to64() == .rax) {
                    return switch (bit_size) {
                        8 => .al,
                        16 => .ax,
                        32 => .eax,
                        64 => .rax,
                        else => unreachable,
                    };
                } else {
                    return switch (bit_size) {
                        8 => .r8,
                        16 => .r16,
                        32 => .r32,
                        64 => .r64,
                        else => unreachable,
                    };
                }
            },

            .mem => |mem| switch (mem) {
                .moffs => return .moffs,
                .sib, .rip => {
                    const bit_size = mem.bitSize();
                    return switch (bit_size) {
                        8 => .m8,
                        16 => .m16,
                        32 => .m32,
                        64 => .m64,
                        else => unreachable,
                    };
                },
            },

            .imm => |imm| {
                if (math.cast(i8, imm)) |_| return .imm8;
                if (math.cast(i16, imm)) |_| return .imm16;
                if (math.cast(i32, imm)) |_| return .imm32;
                return .imm64;
            },
        }
    }

    pub fn bitSize(op: Op) u64 {
        return switch (op) {
            .none, .moffs, .m, .sreg => unreachable,
            .imm8, .al, .r8, .m8, .rm8 => 8,
            .imm16, .ax, .r16, .m16, .rm16, .rel16 => 16,
            .imm32, .eax, .r32, .m32, .rm32, .rel32 => 32,
            .imm64, .rax, .r64, .m64, .rm64 => 64,
        };
    }

    pub fn isRegister(op: Op) bool {
        // zig fmt: off
        return switch (op) {
            .al, .ax, .eax, .rax,
            .r8, .r16, .r32, .r64,
            .rm8, .rm16, .rm32, .rm64,
            => return true,
            else => false,
        };
        // zig fmt: on
    }

    pub fn isImmediate(op: Op) bool {
        return switch (op) {
            .imm8, .imm16, .imm32, .imm64, .rel16, .rel32 => return true,
            else => false,
        };
    }

    pub fn isMemory(op: Op) bool {
        // zig fmt: off
        return switch (op) {
            .rm8, .rm16, .rm32, .rm64,
            .m8, .m16, .m32, .m64,
            .m,
            => return true,
            else => false,
        };
        // zig fmt: on
    }

    pub fn isSegment(op: Op) bool {
        return switch (op) {
            .moffs, .sreg => return true,
            else => false,
        };
    }

    /// Given an operand `op` checks if `target` is a subset for the purposes
    /// of the encoding.
    pub fn isSubset(op: Op, target: Op) bool {
        switch (op) {
            .m => unreachable,
            .none, .moffs, .sreg => return op == target,
            else => {
                if (op.isRegister() and target.isRegister()) switch (target) {
                    .al, .ax, .eax, .rax => return op == target,
                    else => return op.bitSize() == target.bitSize(),
                };
                if (op.isMemory() and target.isMemory()) switch (target) {
                    .m => return true,
                    else => return op.bitSize() == target.bitSize(),
                };
                if (op.isImmediate() and target.isImmediate()) switch (target) {
                    .imm32 => switch (op) {
                        .imm8, .imm16, .imm32 => return true,
                        else => return op == target,
                    },
                    .imm16 => switch (op) {
                        .imm8, .imm16 => return true,
                        else => return op == target,
                    },
                    .rel32 => switch (op) {
                        .imm8, .imm16, .imm32 => return true,
                        else => return op == target,
                    },
                    else => return op == target,
                };
                return false;
            },
        }
    }
};

pub const Encoding = struct {
    mnemonic: Mnemonic,
    op_en: OpEn,
    op1: Op,
    op2: Op,
    op3: Op,
    op4: Op,
    opc_len: u2,
    opc: [3]u8,
    modrm_ext: u3,

    pub fn findByMnemonic(mnemonic: Mnemonic, args: struct {
        op1: Instruction.Operand,
        op2: Instruction.Operand,
        op3: Instruction.Operand,
        op4: Instruction.Operand,
    }) ?Encoding {
        const input_op1 = Op.fromOperand(args.op1);
        const input_op2 = Op.fromOperand(args.op2);
        const input_op3 = Op.fromOperand(args.op3);
        const input_op4 = Op.fromOperand(args.op4);

        // TODO work out what is the maximum number of variants we can actually find in one swoop.
        var candidates: [10]Encoding = undefined;
        var count: usize = 0;
        inline for (table) |entry| {
            if (entry[0] == mnemonic and
                input_op1.isSubset(entry[2]) and
                input_op2.isSubset(entry[3]) and
                input_op3.isSubset(entry[4]) and
                input_op4.isSubset(entry[5]))
            {
                candidates[count] = Encoding{
                    .mnemonic = mnemonic,
                    .op_en = entry[1],
                    .op1 = entry[2],
                    .op2 = entry[3],
                    .op3 = entry[4],
                    .op4 = entry[5],
                    .opc_len = entry[6],
                    .opc = .{ entry[7], entry[8], entry[9] },
                    .modrm_ext = entry[10],
                };
                count += 1;
            }
        }

        if (count == 0) return null;
        if (count == 1) return candidates[0];

        const EncodingLength = struct {
            fn estimate(encoding: Encoding, params: struct {
                op1: Instruction.Operand,
                op2: Instruction.Operand,
                op3: Instruction.Operand,
                op4: Instruction.Operand,
            }) usize {
                var inst = Instruction{
                    .op1 = params.op1,
                    .op2 = params.op2,
                    .op3 = params.op3,
                    .op4 = params.op4,
                    .encoding = encoding,
                };
                var cwriter = std.io.countingWriter(std.io.null_writer);
                inst.encode(cwriter.writer()) catch unreachable;
                return cwriter.bytes_written;
            }
        };

        var shortest_encoding: ?struct {
            index: usize,
            len: usize,
        } = null;
        var i: usize = 0;
        while (i < count) : (i += 1) {
            const len = EncodingLength.estimate(candidates[i], .{
                .op1 = args.op1,
                .op2 = args.op2,
                .op3 = args.op3,
                .op4 = args.op4,
            });
            const current = shortest_encoding orelse {
                shortest_encoding = .{ .index = i, .len = len };
                continue;
            };
            if (len < current.len) {
                shortest_encoding = .{ .index = i, .len = len };
            }
        }

        return candidates[shortest_encoding.?.index];
    }

    pub fn findByOpcode(opc: [3]u8) ?Encoding {
        inline for (table) |entry| {
            if (entry[6] == opc[0] and entry[7] == opc[1] and entry[8] == opc[2]) {
                return .{
                    .mnemonic = entry[0],
                    .op_en = entry[1],
                    .op1 = .none,
                    .op2 = .none,
                    .op3 = .none,
                    .op4 = .none,
                    .opc_len = entry[6],
                    .opc = .{ entry[7], entry[8], entry[9] },
                    .modrm_ext = entry[10],
                };
            }
        }
        return null;
    }

    pub fn opcode(encoding: *const Encoding) []const u8 {
        return encoding.opc[0..encoding.opc_len];
    }

    pub fn modRmExt(encoding: Encoding) u3 {
        return switch (encoding.op_en) {
            .m, .mi => encoding.modrm_ext,
            else => unreachable,
        };
    }

    pub fn format(
        encoding: Encoding,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;
        _ = fmt;
        for (encoding.opcode()) |byte| {
            try writer.print("{x:0>2} ", .{byte});
        }

        switch (encoding.op_en) {
            .np, .fd, .td, .i, .zi => {},
            .o, .oi => {
                const tag = switch (encoding.op1) {
                    .r8 => "rb",
                    .r16 => "rw",
                    .r32 => "rd",
                    .r64 => "rd",
                    else => unreachable,
                };
                try writer.print("+{s} ", .{tag});
            },
            .m, .mi => try writer.print("/{d} ", .{encoding.modRmExt()}),
            .mr, .rm, .rmi => try writer.writeAll("/r "),
        }

        switch (encoding.op_en) {
            .i, .zi, .oi, .mi, .rmi => {
                const op = switch (encoding.op_en) {
                    .i => encoding.op1,
                    .zi, .oi, .mi => encoding.op2,
                    .rmi => encoding.op3,
                    else => unreachable,
                };
                const tag = switch (op) {
                    .imm8 => "ib",
                    .imm16 => "iw",
                    .imm32 => "id",
                    .imm64 => "io",
                    .rel16 => "cw ",
                    .rel32 => "cd ",
                    else => unreachable,
                };
                try writer.print("{s} ", .{tag});
            },
            .np, .fd, .td, .o, .m, .mr, .rm => {},
        }

        try writer.print("{s} ", .{@tagName(encoding.mnemonic)});

        const ops = &[_]Op{ encoding.op1, encoding.op2, encoding.op3, encoding.op4 };
        for (ops) |op| {
            if (op == .none) break;
            try writer.print("{s} ", .{@tagName(op)});
        }

        const op_en = switch (encoding.op_en) {
            .zi => .i,
            else => |op_en| op_en,
        };
        try writer.print("{s}", .{@tagName(op_en)});
    }
};
