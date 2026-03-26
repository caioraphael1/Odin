

@(require) import "core:crypto"
import p256r1 "core:crypto/_fiat/field_scalarp256r1"
import p384r1 "core:crypto/_fiat/field_scalarp384r1"
import subtle "core:crypto/_subtle"

Scalar_p256r1 :: p256r1.Montgomery_Domain_Field_Element
Scalar_p384r1 :: p384r1.Montgomery_Domain_Field_Element

SC_SIZE_P256R1 :: 32
SC_SIZE_P384R1 :: 48
SC_SIZE_MAX    :: SC_SIZE_P384R1

sc_size :: proc(sc: ^$T) -> int where T == Scalar_p256r1 || T == Scalar_p384r1 {
    when T == Scalar_p256r1 {
        return SC_SIZE_P256R1
    } else when T == Scalar_p384r1 {
        return SC_SIZE_P384R1
    }
}

sc_set_random :: proc(sc: ^$T) where T == Scalar_p256r1 || T == Scalar_p384r1 {
    internal.ensure(crypto.HAS_RAND_BYTES, "weierstrass: entropy source required")

    b: [48]u8 = ---
    defer crypto.zero_explicit(&b, size_of(b))

    when T == Scalar_p256r1 {
        // 384-bits reduced makes the modulo bias insignificant
        for {
            crypto.rand_bytes(b[:])
            _ = sc_set_bytes(sc, b[:])
            if sc_is_zero(sc) == 0 { // Likely
                break
            }
        }
    } else when T == Scalar_p384r1 {
        for {
            crypto.rand_bytes(b[:])
            did_reduce := sc_set_bytes(sc, b[:])
            if !did_reduce && sc_is_zero(sc) == 0 { // Likely
                break
            }
        }
    }
}


sc_is_zero_p256r1 :: proc(fe: ^Scalar_p256r1) -> int {
    return int(subtle.u64_is_zero(p256r1.fe_non_zero(fe)))
}


sc_is_zero_p384r1 :: proc(fe: ^Scalar_p384r1) -> int {
    return int(subtle.u64_is_zero(p384r1.fe_non_zero(fe)))
}
