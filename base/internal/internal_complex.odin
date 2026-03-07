import "base:intrinsics"

Raw_Complex32   :: struct { real, imag: f16 }
Raw_Complex64   :: struct { real, imag: f32 }
Raw_Complex128  :: struct { real, imag: f64 }

__complex32_eq  :: #force_inline proc(a, b: complex32)  -> bool { return real(a) == real(b) && imag(a) == imag(b) }
__complex64_eq  :: #force_inline proc(a, b: complex64)  -> bool { return real(a) == real(b) && imag(a) == imag(b) }
__complex128_eq :: #force_inline proc(a, b: complex128) -> bool { return real(a) == real(b) && imag(a) == imag(b) }

__complex32_ne  :: #force_inline proc(a, b: complex32)  -> bool { return real(a) != real(b) || imag(a) != imag(b) }
__complex64_ne  :: #force_inline proc(a, b: complex64)  -> bool { return real(a) != real(b) || imag(a) != imag(b) }
__complex128_ne :: #force_inline proc(a, b: complex128) -> bool { return real(a) != real(b) || imag(a) != imag(b) }


__complex32_abs :: #force_inline proc(x: complex32) -> f16 {
    p, q := abs(real(x)), abs(imag(x))
    if p < q {
        p, q = q, p
    }
    if p == 0 {
        return 0
    }
    q = q / p
    return p * f16(intrinsics.sqrt(f32(1 + q*q)))
}
__complex64_abs :: #force_inline proc(x: complex64) -> f32 {
    p, q := abs(real(x)), abs(imag(x))
    if p < q {
        p, q = q, p
    }
    if p == 0 {
        return 0
    }
    q = q / p
    return p * intrinsics.sqrt(1 + q*q)
}
__complex128_abs :: #force_inline proc(x: complex128) -> f64 {
    p, q := abs(real(x)), abs(imag(x))
    if p < q {
        p, q = q, p
    }
    if p == 0 {
        return 0
    }
    q = q / p
    return p * intrinsics.sqrt(1 + q*q)
}


__complex32_quo :: proc(n, m: complex32) -> complex32 {
    nr, ni := f32(real(n)), f32(imag(n))
    mr, mi := f32(real(m)), f32(imag(m))

    e, f: f32

    if abs(mr) >= abs(mi) {
        ratio := mi / mr
        denom := mr + ratio*mi
        e = (nr + ni*ratio) / denom
        f = (ni - nr*ratio) / denom
    } else {
        ratio := mr / mi
        denom := mi + ratio*mr
        e = (nr*ratio + ni) / denom
        f = (ni*ratio - nr) / denom
    }

    return complex(f16(e), f16(f))
}
__complex64_quo :: proc(n, m: complex64) -> complex64 {
    e, f: f32

    if abs(real(m)) >= abs(imag(m)) {
        ratio := imag(m) / real(m)
        denom := real(m) + ratio*imag(m)
        e = (real(n) + imag(n)*ratio) / denom
        f = (imag(n) - real(n)*ratio) / denom
    } else {
        ratio := real(m) / imag(m)
        denom := imag(m) + ratio*real(m)
        e = (real(n)*ratio + imag(n)) / denom
        f = (imag(n)*ratio - real(n)) / denom
    }

    return complex(e, f)
}
__complex128_quo :: proc(n, m: complex128) -> complex128 {
    e, f: f64

    if abs(real(m)) >= abs(imag(m)) {
        ratio := imag(m) / real(m)
        denom := real(m) + ratio*imag(m)
        e = (real(n) + imag(n)*ratio) / denom
        f = (imag(n) - real(n)*ratio) / denom
    } else {
        ratio := real(m) / imag(m)
        denom := imag(m) + ratio*real(m)
        e = (real(n)*ratio + imag(n)) / denom
        f = (imag(n)*ratio - real(n)) / denom
    }

    return complex(e, f)
}
