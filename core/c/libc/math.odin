package libc

// 7.12 Mathematics

import "base:intrinsics"

when ODIN_OS == .Windows {
    foreign import libc "system:libucrt.lib"
} else when ODIN_OS == .Darwin {
    foreign import libc "system:System"
} else {
    foreign import libc "system:c"
}

// To support C's tgmath behavior we use Odin's explicit procedure overloading,
// but we cannot use the same names as exported by libc so use @(link_name)
// and keep them as private symbols of name "libc_"
@(private="file")
@(default_calling_convention="c")
foreign libc {
    // 7.12.4 Trigonometric functions
    @(link_name="acos")       libc_acos       :: proc(x: double) -> double ---
    @(link_name="acosf")      libc_acosf      :: proc(x: float) -> float ---
    @(link_name="asin")       libc_asin       :: proc(x: double) -> double ---
    @(link_name="asinf")      libc_asinf      :: proc(x: float) -> float ---
    @(link_name="atan")       libc_atan       :: proc(x: double) -> double ---
    @(link_name="atanf")      libc_atanf      :: proc(x: float) -> float ---
    @(link_name="atan2")      libc_atan2      :: proc(y: double, x: double) -> double ---
    @(link_name="atan2f")     libc_atan2f     :: proc(y: float, x: float) -> float ---
    @(link_name="cos")        libc_cos        :: proc(x: double) -> double ---
    @(link_name="cosf")       libc_cosf       :: proc(x: float) -> float ---
    @(link_name="sin")        libc_sin        :: proc(x: double) -> double ---
    @(link_name="sinf")       libc_sinf       :: proc(x: float) -> float ---
    @(link_name="tan")        libc_tan        :: proc(x: double) -> double ---
    @(link_name="tanf")       libc_tanf       :: proc(x: float) -> float ---

    // 7.12.5 Hyperbolic functions
    @(link_name="acosh")      libc_acosh      :: proc(x: double) -> double ---
    @(link_name="acoshf")     libc_acoshf     :: proc(x: float) -> float ---
    @(link_name="asinh")      libc_asinh      :: proc(x: double) -> double ---
    @(link_name="asinhf")     libc_asinhf     :: proc(x: float) -> float ---
    @(link_name="atanh")      libc_atanh      :: proc(x: double) -> double ---
    @(link_name="atanhf")     libc_atanhf     :: proc(x: float) -> float ---
    @(link_name="cosh")       libc_cosh       :: proc(x: double) -> double ---
    @(link_name="coshf")      libc_coshf      :: proc(x: float) -> float ---
    @(link_name="sinh")       libc_sinh       :: proc(x: double) -> double ---
    @(link_name="sinhf")      libc_sinhf      :: proc(x: float) -> float ---
    @(link_name="tanh")       libc_tanh       :: proc(x: double) -> double ---
    @(link_name="tanhf")      libc_tanhf      :: proc(x: float) -> float ---

    // 7.12.6 Exponential and logarithmic functions
    @(link_name="exp")        libc_exp        :: proc(x: double) -> double ---
    @(link_name="expf")       libc_expf       :: proc(x: float) -> float ---
    @(link_name="exp2")       libc_exp2       :: proc(x: double) -> double ---
    @(link_name="exp2f")      libc_exp2f      :: proc(x: float) -> float ---
    @(link_name="expm1")      libc_expm1      :: proc(x: double) -> double ---
    @(link_name="expm1f")     libc_expm1f     :: proc(x: float) -> float ---
    @(link_name="frexp")      libc_frexp      :: proc(value: double, exp: ^int) -> double ---
    @(link_name="frexpf")     libc_frexpf     :: proc(value: float, exp: ^int) -> float ---
    @(link_name="ilogb")      libc_ilogb      :: proc(x: double) -> int ---
    @(link_name="ilogbf")     libc_ilogbf     :: proc(x: float) -> int ---
    @(link_name="ldexp")      libc_ldexp      :: proc(x: double, exp: int) -> double ---
    @(link_name="ldexpf")     libc_ldexpf     :: proc(x: float, exp: int) -> float ---
    @(link_name="log")        libc_log        :: proc(x: double) -> double ---
    @(link_name="logf")       libc_logf       :: proc(x: float) -> float ---
    @(link_name="log10")      libc_log10      :: proc(x: double) -> double ---
    @(link_name="log10f")     libc_log10f     :: proc(x: float) -> float ---
    @(link_name="log1p")      libc_log1p      :: proc(x: double) -> double ---
    @(link_name="log1pf")     libc_log1pf     :: proc(x: float) -> float ---
    @(link_name="log2")       libc_log2       :: proc(x: double) -> double ---
    @(link_name="log2f")      libc_log2f      :: proc(x: float) -> float ---
    @(link_name="logb")       libc_logb       :: proc(x: double) -> double ---
    @(link_name="logbf")      libc_logbf      :: proc(x: float) -> float ---
    @(link_name="modf")       libc_modf       :: proc(value: double, iptr: ^double) -> double ---
    @(link_name="modff")      libc_modff      :: proc(value: float, iptr: ^float) -> float ---
    @(link_name="scalbn")     libc_scalbn     :: proc(x: double, n: int) -> double ---
    @(link_name="scalbnf")    libc_scalbnf    :: proc(x: float, n: int) -> float ---
    @(link_name="scalbln")    libc_scalbln    :: proc(x: double, n: long) -> double ---
    @(link_name="scalblnf")   libc_scalblnf   :: proc(x: float, n: long) -> float ---

    // 7.12.7 Power and absolute-value functions
    @(link_name="cbrt")       libc_cbrt       :: proc(x: double) -> double ---
    @(link_name="cbrtf")      libc_cbrtf      :: proc(x: float) -> float ---
    @(link_name="fabs")       libc_fabs       :: proc(x: double) -> double ---
    @(link_name="fabsf")      libc_fabsf      :: proc(x: float) -> float ---
    @(link_name="hypot")      libc_hypot      :: proc(x: double, y: double) -> double ---
    @(link_name="hypotf")     libc_hypotf     :: proc(x: float, y: float) -> float ---
    @(link_name="pow")        libc_pow        :: proc(x: double, y: double) -> double ---
    @(link_name="powf")       libc_powf       :: proc(x: float, y: float) -> float ---
    @(link_name="sqrt")       libc_sqrt       :: proc(x: double) -> double ---
    @(link_name="sqrtf")      libc_sqrtf      :: proc(x: float) -> float ---

    // 7.12.8 Error and gamma functions
    @(link_name="erf")        libc_erf        :: proc(x: double) -> double ---
    @(link_name="erff")       libc_erff       :: proc(x: float) -> float ---
    @(link_name="erfc")       libc_erfc       :: proc(x: double) -> double ---
    @(link_name="erfcf")      libc_erfcf      :: proc(x: float) -> float ---
    @(link_name="lgamma")     libc_lgamma     :: proc(x: double) -> double ---
    @(link_name="lgammaf")    libc_lgammaf    :: proc(x: float) -> float ---
    @(link_name="tgamma")     libc_tgamma     :: proc(x: double) -> double ---
    @(link_name="tgammaf")    libc_tgammaf    :: proc(x: float) -> float ---

    // 7.12.9 Nearest integer functions
    @(link_name="ceil")       libc_ceil       :: proc(x: double) -> double ---
    @(link_name="ceilf")      libc_ceilf      :: proc(x: float) -> float ---
    @(link_name="floor")      libc_floor      :: proc(x: double) -> double ---
    @(link_name="floorf")     libc_floorf     :: proc(x: float) -> float ---
    @(link_name="nearbyint")  libc_nearbyint  :: proc(x: double) -> double ---
    @(link_name="nearbyintf") libc_nearbyintf :: proc(x: float) -> float ---
    @(link_name="rint")       libc_rint       :: proc(x: double) -> double ---
    @(link_name="rintf")      libc_rintf      :: proc(x: float) -> float ---
    @(link_name="lrint")      libc_lrint      :: proc(x: double) -> long ---
    @(link_name="lrintf")     libc_lrintf     :: proc(x: float) -> long ---
    @(link_name="llrint")     libc_llrint     :: proc(x: double) -> longlong ---
    @(link_name="llrintf")    libc_llrintf    :: proc(x: float) -> longlong ---
    @(link_name="round")      libc_round      :: proc(x: double) -> double ---
    @(link_name="roundf")     libc_roundf     :: proc(x: float) -> float ---
    @(link_name="lround")     libc_lround     :: proc(x: double) -> long ---
    @(link_name="lroundf")    libc_lroundf    :: proc(x: float) -> long ---
    @(link_name="llround")    libc_llround    :: proc(x: double) -> longlong ---
    @(link_name="llroundf")   libc_llroundf   :: proc(x: float) -> longlong ---
    @(link_name="trunc")      libc_trunc      :: proc(x: double) -> double ---
    @(link_name="truncf")     libc_truncf     :: proc(x: float) -> float ---

    // 7.12.10 Remainder functions
    @(link_name="fmod")       libc_fmod       :: proc(x: double, y: double) -> double ---
    @(link_name="fmodf")      libc_fmodf      :: proc(x: float, y: float) -> float ---
    @(link_name="remainder")  libc_remainder  :: proc(x: double, y: double) -> double ---
    @(link_name="remainderf") libc_remainderf :: proc(x: float, y: float) -> float ---
    @(link_name="remquo")     libc_remquo     :: proc(x: double, y: double, quo: ^int) -> double ---
    @(link_name="remquof")    libc_remquof    :: proc(x: float, y: float, quo: ^int) -> float ---

    // 7.12.11 Manipulation functions
    @(link_name="copysign")   libc_copysign   :: proc(x: double, y: double) -> double ---
    @(link_name="copysignf")  libc_copysignf  :: proc(x: float, y: float) -> float ---
    @(link_name="nan")        libc_nan        :: proc(tagp: cstring) -> double ---
    @(link_name="nanf")       libc_nanf       :: proc(tagp: cstring) -> float ---
    @(link_name="nextafter")  libc_nextafter  :: proc(x: double, y: double) -> double ---
    @(link_name="nextafterf") libc_nextafterf :: proc(x: float, y: float) -> float ---

    // 7.12.12 Maximum, minimum, and positive difference functions
    @(link_name="fdim")       libc_fdim       :: proc(x: double, y: double) -> double ---
    @(link_name="fdimf")      libc_fdimf      :: proc(x: float, y: float) -> float ---
    @(link_name="fmax")       libc_fmax       :: proc(x: double, y: double) -> double ---
    @(link_name="fmaxf")      libc_fmaxf      :: proc(x: float, y: float) -> float ---
    @(link_name="fmin")       libc_fmin       :: proc(x: double, y: double) -> double ---
    @(link_name="fminf")      libc_fminf      :: proc(x: float, y: float) -> float ---
    @(link_name="fma")        libc_fma        :: proc(x, y, z: double) -> double ---
    @(link_name="fmaf")       libc_fmaf       :: proc(x, y, z: float) -> float ---
}

@(private="file")
_nan_bit_pattern := ~u64(0)

// On amd64 Windows and Linux, float_t and double_t are respectively both
// their usual types. On x86 it's not possible to define these types correctly
// since they would be long double which Odin does have support for.
float_t          :: float
double_t         :: double

NAN              := transmute(double)(_nan_bit_pattern)
INFINITY         :: 1e5000

HUGE_VALF        :: INFINITY
HUGE_VAL         :: double(INFINITY)

MATH_ERRNO       :: 1
MATH_ERREXCEPT   :: 2

math_errhandling :: 2 // Windows, Linux, macOS all use this mode.

FP_ILOGBNAN      :: -1 - int((~uint(0)) >> 1)
FP_ILOGB0        :: FP_ILOGBNAN

// Number classification constants. These do not have to match libc since we
// implement our own classification functions as libc requires they be macros,
// which means libc does not export standard functions for them.
FP_NAN           :: 0
FP_INFINITE      :: 1
FP_ZERO          :: 2
FP_NORMAL        :: 3
FP_SUBNORMAL     :: 4

@(private)
_fpclassify :: #force_inline proc(x: double) -> int {
    u := transmute(uint64_t)x
    switch e := u >> 52 & 0x7ff; e {
    case 0:     return FP_SUBNORMAL if (u << 1)  != 0 else FP_ZERO
    case 0x7ff: return FP_NAN       if (u << 12) != 0 else FP_INFINITE
    }
    return FP_NORMAL
}

@(private)
_fpclassifyf :: #force_inline proc(x: float) -> int {
    u := transmute(uint32_t)x
    switch e := u >> 23 & 0xff; e {
    case 0:    return FP_SUBNORMAL if (u << 1)  != 0 else FP_ZERO
    case 0xff: return FP_NAN       if (u << 9)  != 0 else FP_INFINITE
    }
    return FP_NORMAL
}

@(private)
_signbit :: #force_inline proc(x: double) -> int {
    return int(transmute(uint64_t)x >> 63)
}

@(private)
_signbitf :: #force_inline proc(x: float) -> int {
    return int(transmute(uint32_t)x >> 31)
}

isfinite :: #force_inline proc(x: $T) -> bool where intrinsics.type_is_float(T) {
    return fpclassify(x) == FP_INFINITE
}

isinf :: #force_inline proc(x: $T) -> bool where intrinsics.type_is_float(T) {
    return fpclassify(x) > FP_INFINITE
}

isnan :: #force_inline proc(x: $T) -> bool where intrinsics.type_is_float(T) {
    return fpclassify(x) == FP_NAN
}

isnormal :: #force_inline proc(x: $T) -> bool where intrinsics.type_is_float(T) {
    return fpclassify(x) == FP_NORMAL
}

// These are special in that they avoid float exceptions. They cannot just be
// implemented as the relational comparisons, as that would produce an invalid
// "sticky" state that propagates and affects maths results. These need
// to be implemented natively in Odin assuming isunordered to prevent that.
isgreater :: #force_inline proc(x, y: $T) -> bool where intrinsics.type_is_float(T) {
    return !isunordered(x, y) && x > y
}

isgreaterequal :: #force_inline proc(x, y: $T) -> bool where intrinsics.type_is_float(T) {
    return !isunordered(x, y) && x >= y
}

isless :: #force_inline proc(x, y: $T) -> bool where intrinsics.type_is_float(T) {
    return !isunordered(x, y) && x < y
}

islessequal :: #force_inline proc(x, y: $T) -> bool where intrinsics.type_is_float(T) {
    return !isunordered(x, y) && x <= y
}

islessgreater :: #force_inline proc(x, y: $T) -> bool where intrinsics.type_is_float(T) {
    return !isunordered(x, y) && x <= y
}

isunordered :: #force_inline proc(x, y: $T) -> bool where intrinsics.type_is_float(T) {
    if isnan(x) {
        // Force evaluation of y to propagate exceptions for ordering semantics.
        // To ensure correct semantics of IEEE 754 this cannot be compiled away.
        sink: T
        intrinsics.volatile_store(&sink, intrinsics.volatile_load(&y))
        return true
    }
    return isnan(y)
}
