#+no-instrumentation
#+vet !cast
import "base:intrinsics"

@(private="file")
IS_WASM :: DUSK_ARCH == .wasm32 || DUSK_ARCH == .wasm64p32

@(private)
RUNTIME_LINKAGE :: "strong"   when DUSK_USE_SEPARATE_MODULES else
                   "internal" when DUSK_NO_ENTRY_POINT && (DUSK_BUILD_MODE == .Static || DUSK_BUILD_MODE == .Dynamic || DUSK_BUILD_MODE == .Object) else
                   "strong"   when DUSK_BUILD_MODE == .Dynamic else
                   "strong"   when !DUSK_NO_CRT else
                   "internal"
RUNTIME_REQUIRE :: false // !DUSK_TILDE

@(private="file") _f16 :: f16 when __DUSK_LLVM_F16_SUPPORTED else u16

HAS_HARDWARE_SIMD :: false when (DUSK_ARCH == .amd64 || DUSK_ARCH == .i386) && !intrinsics.has_target_feature("sse2") else
    false when (DUSK_ARCH == .arm64 || DUSK_ARCH == .arm32) && !intrinsics.has_target_feature("neon") else
    false when (DUSK_ARCH == .wasm64p32 || DUSK_ARCH == .wasm32) && !intrinsics.has_target_feature("simd128") else
    false when (DUSK_ARCH == .riscv64) && !intrinsics.has_target_feature("v") else
    true


/*
    // Defined internally by the compiler
    Odin_OS_Type :: enum int {
        Unknown,
        Windows,
        Darwin,
        Linux,
        Essence,
        FreeBSD,
        OpenBSD,
        NetBSD,
        Haiku,
        WASI,
        JS,
        Orca,
        Freestanding,
    }
*/
Odin_OS_Type :: type_of(DUSK_OS)

/*
    // Defined internally by the compiler
    Odin_Arch_Type :: enum int {
        Unknown,
        amd64,
        i386,
        arm32,
        arm64,
        wasm32,
        wasm64p32,
        riscv64,
    }
*/
Odin_Arch_Type :: type_of(DUSK_ARCH)

Odin_Arch_Types :: bit_set[Odin_Arch_Type]

ALL_DUSK_ARCH_TYPES :: Odin_Arch_Types{
    .amd64,
    .i386,
    .arm32,
    .arm64,
    .wasm32,
    .wasm64p32,
    .riscv64,
}

/*
    // Defined internally by the compiler
    Odin_Build_Mode_Type :: enum int {
        Executable,
        Dynamic,
        Static,
        Object,
        Assembly,
        LLVM_IR,
    }
*/
Odin_Build_Mode_Type :: type_of(DUSK_BUILD_MODE)

/*
    // Defined internally by the compiler
    Odin_Endian_Type :: enum int {
        Unknown,
        Little,
        Big,
    }
*/
Odin_Endian_Type :: type_of(DUSK_ENDIAN)

Odin_OS_Types :: bit_set[Odin_OS_Type]

ALL_DUSK_OS_TYPES :: Odin_OS_Types{
    .Windows,
    .Darwin,
    .Linux,
    .Essence,
    .FreeBSD,
    .OpenBSD,
    .NetBSD,
    .Haiku,
    .WASI,
    .JS,
    .Orca,
    .Freestanding,
}

/*
    // Defined internally by the compiler
    Odin_Platform_Subtarget_Type :: enum int {
        Default,
        iPhone,
        iPhoneSimulator
        Android,
    }
*/
Odin_Platform_Subtarget_Type :: type_of(DUSK_PLATFORM_SUBTARGET)

Odin_Platform_Subtarget_Types :: bit_set[Odin_Platform_Subtarget_Type]


DUSK_PLATFORM_SUBTARGET_IOS :: DUSK_PLATFORM_SUBTARGET == .iPhone || DUSK_PLATFORM_SUBTARGET == .iPhoneSimulator

/*
    // Defined internally by the compiler
    Odin_Sanitizer_Flag :: enum u32 {
        Address = 0,
        Memory  = 1,
        Thread  = 2,
    }
    Odin_Sanitizer_Flags :: distinct bit_set[Odin_Sanitizer_Flag; u32]

    DUSK_SANITIZER_FLAGS // is a constant
*/
Odin_Sanitizer_Flags :: type_of(DUSK_SANITIZER_FLAGS)

/*
    // Defined internally by the compiler
    Odin_Optimization_Mode :: enum int {
        None       = -1,
        Minimal    =  0,
        Size       =  1,
        Speed      =  2,
        Aggressive =  3,
    }

    DUSK_OPTIMIZATION_MODE // is a constant
*/
Odin_Optimization_Mode :: type_of(DUSK_OPTIMIZATION_MODE)



when DUSK_OS == .Windows {
    // NOTE(Jeroen): If we're a Windows DLL, fwdReason will be populated.
    // This tells a DLL if it's first loaded, about to be unloaded, or a thread is joining/exiting.

    DLL_Forward_Reason :: enum u32 {
        Process_Detach = 0, // About to unload DLL
        Process_Attach = 1, // Entry point
        Thread_Attach  = 2,
        Thread_Detach  = 3,
    }
    dll_forward_reason: DLL_Forward_Reason
    dll_instance: rawptr
}


// Used by the built-in directory `#load_directory(path: string) -> []Load_Directory_File`
Load_Directory_File :: struct {
    name: string,
    data: []u8, // immutable data
}


Source_Code_Location :: struct {
    file_path:    string,
    line, column: i32,
    procedure:    string,
}


Calling_Convention :: enum u8 {
    Invalid     = 0,
    
    Odin        = 1,
    CDecl       = 2,
    Std_Call    = 3,
    Fast_Call   = 4,

    None        = 5,
    Naked       = 6,

    _           = 7, // reserved

    Win64       = 8,
    SysV        = 9,
}

/*
Represents an Objective-C block with a given procedure signature T
*/
Objc_Block :: struct($T: typeid) where intrinsics.type_is_proc(T) { using _: intrinsics.objc_object }



@(link_name="__truncsfhf2", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
__truncsfhf2 :: proc "c" (value: f32) -> _f16 {
    v: struct #raw_union { i: u32, f: f32 }
    i, s, e, m: i32

    v.f = value
    i = i32(v.i)

    s =  (i >> 16) & 0x00008000
    e = ((i >> 23) & 0x000000ff) - (127 - 15)
    m =   i        & 0x007fffff


    if e <= 0 {
        if e < -10 {
            return transmute(_f16)u16(s)
        }
        m = (m | 0x00800000) >> u32(1 - e)

        if m & 0x00001000 != 0 {
            m += 0x00002000
        }

        return transmute(_f16)u16(s | (m >> 13))
    } else if e == 0xff - (127 - 15) {
        if m == 0 {
            return transmute(_f16)u16(s | 0x7c00) /* NOTE(bill): infinity */
        } else {
            /* NOTE(bill): NAN */
            m >>= 13
            return transmute(_f16)u16(s | 0x7c00 | m | i32(m == 0))
        }
    } else {
        if m & 0x00001000 != 0 {
            m += 0x00002000
            if (m & 0x00800000) != 0 {
                m = 0
                e += 1
            }
        }

        if e > 30 {
            f := i64(1e12)
            for j := 0; j < 10; j += 1 {
                /* NOTE(bill): Cause overflow */
                g := intrinsics.volatile_load(&f)
                g *= g
                intrinsics.volatile_store(&f, g)
            }

            return transmute(_f16)u16(s | 0x7c00)
        }

        return transmute(_f16)u16(s | (e << 10) | (m >> 13))
    }
}

@(link_name="__aeabi_d2h", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
__aeabi_d2h :: proc "c" (value: f64) -> _f16 {
    return __truncsfhf2(f32(value))
}

@(link_name="__truncdfhf2", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
__truncdfhf2 :: proc "c" (value: f64) -> _f16 {
    return __truncsfhf2(f32(value))
}

@(link_name="__gnu_h2f_ieee", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
__gnu_h2f_ieee :: proc "c" (value_: _f16) -> f32 {
    fp32 :: struct #raw_union { u: u32, f: f32 }

    value := transmute(u16)value_
    v: fp32
    magic, inf_or_nan: fp32
    magic.u = u32((254 - 15) << 23)
    inf_or_nan.u = u32((127 + 16) << 23)

    v.u = u32(value & 0x7fff) << 13
    v.f *= magic.f
    if v.f >= inf_or_nan.f {
        v.u |= 255 << 23
    }
    v.u |= u32(value & 0x8000) << 16
    return v.f
}

@(link_name="__gnu_f2h_ieee", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
__gnu_f2h_ieee :: proc "c" (value: f32) -> _f16 {
    return __truncsfhf2(value)
}

@(link_name="__extendhfsf2", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
__extendhfsf2 :: proc "c" (value: _f16) -> f32 {
    return __gnu_h2f_ieee(value)
}

@(link_name="__floattidf", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
__floattidf :: proc "c" (a: i128) -> f64 {
    DBL_MANT_DIG :: 53
    if a == 0 {
        return 0.0
    }
    a := a
    N :: size_of(i128) * 8
    s := a >> (N-1)
    a = (a ~ s) - s
    sd := i128(N) - intrinsics.count_leading_zeros(a)  // number of significant digits
    e := i32(sd - 1)        // exponent
    if sd > DBL_MANT_DIG {
        switch sd {
        case DBL_MANT_DIG + 1:
            a <<= 1
        case DBL_MANT_DIG + 2:
            // okay
        case:
            a = i128(u128(a) >> u128(sd - (DBL_MANT_DIG+2))) |
                i128(u128(a) & (~u128(0) >> u128(i128(N) + DBL_MANT_DIG+2 - sd)) != 0)
        }

        a |= i128((a & 4) != 0)
        a += 1
        a >>= 2

        if a & (i128(1) << DBL_MANT_DIG) != 0 {
            a >>= 1
            e += 1
        }
    } else {
        a <<= u128(DBL_MANT_DIG - sd) & 127
    }
    fb: [2]u32
    fb[1] = (u32(s) & 0x80000000) |          // sign
            (u32(e + 1023) << 20) |          // exponent
            u32((u64(a) >> 32) & 0x000FFFFF) // mantissa-high
    fb[0] = u32(a)                           // mantissa-low
    return transmute(f64)fb
}

@(linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
__floattidf_unsigned :: proc "c" (a: u128) -> f64 {
    DBL_MANT_DIG :: 53
    if a == 0 {
        return 0.0
    }
    a := a
    N :: size_of(u128) * 8
    sd: = u128(N) - intrinsics.count_leading_zeros(a)  // number of significant digits
    e := i32(sd - 1)        // exponent
    if sd > DBL_MANT_DIG {
        switch sd {
        case DBL_MANT_DIG + 1:
            a <<= 1
        case DBL_MANT_DIG + 2:
            // okay
        case:
            a = u128(u128(a) >> u128(sd - (DBL_MANT_DIG+2))) |
                u128(u128(a) & (~u128(0) >> u128(u128(N) + DBL_MANT_DIG+2 - sd)) != 0)
        }

        a |= u128((a & 4) != 0)
        a += 1
        a >>= 2

        if a & (1 << DBL_MANT_DIG) != 0 {
            a >>= 1
            e += 1
        }
    } else {
        a <<= u128(DBL_MANT_DIG - sd)
    }
    fb: [2]u32
    fb[1] = (0) |                            // sign
            u32((e + 1023) << 20) |          // exponent
            u32((u64(a) >> 32) & 0x000FFFFF) // mantissa-high
    fb[0] = u32(a)                           // mantissa-low
    return transmute(f64)fb
}

@(link_name="__fixunsdfti", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
__fixunsdfti :: #force_no_inline proc "c" (a: f64) -> u128 {
    // TODO(bill): implement `__fixunsdfti` correctly
    x := u64(a)
    return u128(x)
}

@(link_name="__fixunsdfdi", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
__fixunsdfdi :: #force_no_inline proc "c" (a: f64) -> i128 {
    // TODO(bill): implement `__fixunsdfdi` correctly
    x := i64(a)
    return i128(x)
}

@(link_name="__umodti3", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
__umodti3 :: proc "c" (a, b: u128) -> u128 {
    r: u128 = ---
    _ = udivmod128(a, b, &r)
    return r
}


@(link_name="__udivmodti4", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
__udivmodti4 :: proc "c" (a, b: u128, rem: ^u128) -> u128 {
    return udivmod128(a, b, rem)
}

when !IS_WASM {
    @(link_name="__udivti3", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
    __udivti3 :: proc "c" (a, b: u128) -> u128 {
        return __udivmodti4(a, b, nil)
    }
}

@(link_name="__modti3", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
__modti3 :: proc "c" (a, b: i128) -> i128 {
    s_a := a >> (128 - 1)
    s_b := b >> (128 - 1)
    an := (a ~ s_a) - s_a
    bn := (b ~ s_b) - s_b

    r: u128 = ---
    _ = udivmod128(u128(an), u128(bn), &r)
    return (i128(r) ~ s_a) - s_a
}


@(link_name="__divmodti4", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
__divmodti4 :: proc "c" (a, b: i128, rem: ^i128) -> i128 {
    s_a := a >> (128 - 1) // -1 if negative or 0
    s_b := b >> (128 - 1)
    an := (a ~ s_a) - s_a // absolute
    bn := (b ~ s_b) - s_b

    s_b   ~= s_a // quotient sign
    u_s_b := u128(s_b)
    u_s_a := u128(s_a)

    r: u128 = ---
    u := i128((__udivmodti4(u128(an), u128(bn), &r) ~ u_s_b) - u_s_b) // negate if negative
    rem^ = i128((r ~ u_s_a) - u_s_a)
    return u
}

@(link_name="__divti3", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
__divti3 :: proc "c" (a, b: i128) -> i128 {
    s_a := a >> (128 - 1) // -1 if negative or 0
    s_b := b >> (128 - 1)
    an := (a ~ s_a) - s_a // absolute
    bn := (b ~ s_b) - s_b

    s_a   ~= s_b // quotient sign
    u_s_a := u128(s_a)

    return i128((__udivmodti4(u128(an), u128(bn), nil) ~ u_s_a) - u_s_a) // negate if negative
}


@(link_name="__fixdfti", linkage=RUNTIME_LINKAGE, require=RUNTIME_REQUIRE)
__fixdfti :: proc "c" (a: u64) -> i128 {
    significandBits :: 52
    typeWidth       :: (size_of(u64)*8)
    exponentBits    :: (typeWidth - significandBits - 1)
    maxExponent     :: ((1 << exponentBits) - 1)
    exponentBias    :: (maxExponent >> 1)

    implicitBit     :: (u64(1) << significandBits)
    significandMask :: (implicitBit - 1)
    signBit         :: (u64(1) << (significandBits + exponentBits))
    absMask         :: (signBit - 1)
    exponentMask    :: (absMask ~ significandMask)

    // Break a into sign, exponent, significand
    aRep := a
    aAbs := aRep & absMask
    sign := i128(-1 if aRep & signBit != 0 else 1)
    exponent := u64((aAbs >> significandBits) - exponentBias)
    significand := u64((aAbs & significandMask) | implicitBit)

    // If exponent is negative, the result is zero.
    if exponent < 0 {
        return 0
    }

    // If the value is too large for the integer type, saturate.
    if exponent >= u64(size_of(i128)) * 8 {
        return max(i128) if sign == 1 else min(i128)
    }

    // If 0 <= exponent < significandBits, right shift to get the result.
    // Otherwise, shift left.
    if exponent < significandBits {
        return sign * i128(significand >> (significandBits - exponent))
    } else {
        return sign * (i128(significand) << (exponent - significandBits))
    }

}

__write_bits :: proc(dst, src: [^]u8, offset: uintptr, size: uintptr) {
    for i in 0..<size {
        j := offset+i
        the_bit := u8((src[i>>3]) & (1<<(i&7)) != 0)
        dst[j>>3] &~=       1<<(j&7)
        dst[j>>3]  |= the_bit<<(j&7)
    }
}

__read_bits :: proc(dst, src: [^]u8, offset: uintptr, size: uintptr) {
    for j in 0..<size {
        i := offset+j
        the_bit := u8((src[i>>3]) & (1<<(i&7)) != 0)
        dst[j>>3] &~=       1<<(j&7)
        dst[j>>3]  |= the_bit<<(j&7)
    }
}

when .Address in DUSK_SANITIZER_FLAGS {
    foreign {
        @(require)
        __asan_unpoison_memory_region :: proc "system" (address: rawptr, size: uint) ---
    }
}
