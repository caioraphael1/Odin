#+no-instrumentation
import "base:intrinsics"


Raw_Quaternion64  :: struct { imag, jmag, kmag: f16, real: f16 }
Raw_Quaternion128 :: struct { imag, jmag, kmag: f32, real: f32 }
Raw_Quaternion256 :: struct { imag, jmag, kmag: f64, real: f64 }

Raw_Quaternion64_Vector_Scalar  :: struct { vector: [3]f16, scalar: f16 }
Raw_Quaternion128_Vector_Scalar :: struct { vector: [3]f32, scalar: f32 }
Raw_Quaternion256_Vector_Scalar :: struct { vector: [3]f64, scalar: f64 }


__quaternion64_eq  :: #force_inline proc(a, b: quaternion64)  -> bool { return real(a) == real(b) && imag(a) == imag(b) && jmag(a) == jmag(b) && kmag(a) == kmag(b) }
__quaternion128_eq :: #force_inline proc(a, b: quaternion128) -> bool { return real(a) == real(b) && imag(a) == imag(b) && jmag(a) == jmag(b) && kmag(a) == kmag(b) }
__quaternion256_eq :: #force_inline proc(a, b: quaternion256) -> bool { return real(a) == real(b) && imag(a) == imag(b) && jmag(a) == jmag(b) && kmag(a) == kmag(b) }

__quaternion64_ne  :: #force_inline proc(a, b: quaternion64)  -> bool { return real(a) != real(b) || imag(a) != imag(b) || jmag(a) != jmag(b) || kmag(a) != kmag(b) }
__quaternion128_ne :: #force_inline proc(a, b: quaternion128) -> bool { return real(a) != real(b) || imag(a) != imag(b) || jmag(a) != jmag(b) || kmag(a) != kmag(b) }
__quaternion256_ne :: #force_inline proc(a, b: quaternion256) -> bool { return real(a) != real(b) || imag(a) != imag(b) || jmag(a) != jmag(b) || kmag(a) != kmag(b) }



__quaternion64_abs :: #force_inline proc(x: quaternion64) -> f16 {
    r, i, j, k := real(x), imag(x), jmag(x), kmag(x)
    return f16(intrinsics.sqrt(f32(r*r + i*i + j*j + k*k)))
}
__quaternion128_abs :: #force_inline proc(x: quaternion128) -> f32 {
    r, i, j, k := real(x), imag(x), jmag(x), kmag(x)
    return intrinsics.sqrt(r*r + i*i + j*j + k*k)
}
__quaternion256_abs :: #force_inline proc(x: quaternion256) -> f64 {
    r, i, j, k := real(x), imag(x), jmag(x), kmag(x)
    return intrinsics.sqrt(r*r + i*i + j*j + k*k)
}


__quaternion64_mul :: proc(q, r: quaternion64) -> quaternion64 {
    q0, q1, q2, q3 := f32(real(q)), f32(imag(q)), f32(jmag(q)), f32(kmag(q))
    r0, r1, r2, r3 := f32(real(r)), f32(imag(r)), f32(jmag(r)), f32(kmag(r))

    t0 := r0*q0 - r1*q1 - r2*q2 - r3*q3
    t1 := r0*q1 + r1*q0 - r2*q3 + r3*q2
    t2 := r0*q2 + r1*q3 + r2*q0 - r3*q1
    t3 := r0*q3 - r1*q2 + r2*q1 + r3*q0

    return quaternion(w=f16(t0), x=f16(t1), y=f16(t2), z=f16(t3))
}
__quaternion128_mul :: proc(q, r: quaternion128) -> quaternion128 {
    q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q)
    r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r)

    t0 := r0*q0 - r1*q1 - r2*q2 - r3*q3
    t1 := r0*q1 + r1*q0 - r2*q3 + r3*q2
    t2 := r0*q2 + r1*q3 + r2*q0 - r3*q1
    t3 := r0*q3 - r1*q2 + r2*q1 + r3*q0

    return quaternion(w=t0, x=t1, y=t2, z=t3)
}
__quaternion256_mul :: proc(q, r: quaternion256) -> quaternion256 {
    q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q)
    r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r)

    t0 := r0*q0 - r1*q1 - r2*q2 - r3*q3
    t1 := r0*q1 + r1*q0 - r2*q3 + r3*q2
    t2 := r0*q2 + r1*q3 + r2*q0 - r3*q1
    t3 := r0*q3 - r1*q2 + r2*q1 + r3*q0

    return quaternion(w=t0, x=t1, y=t2, z=t3)
}


__quaternion64_quo :: proc(q, r: quaternion64) -> quaternion64 {
    q0, q1, q2, q3 := f32(real(q)), f32(imag(q)), f32(jmag(q)), f32(kmag(q))
    r0, r1, r2, r3 := f32(real(r)), f32(imag(r)), f32(jmag(r)), f32(kmag(r))

    invmag2 := 1.0 / (r0*r0 + r1*r1 + r2*r2 + r3*r3)

    t0 := (r0*q0 + r1*q1 + r2*q2 + r3*q3) * invmag2
    t1 := (r0*q1 - r1*q0 - r2*q3 - r3*q2) * invmag2
    t2 := (r0*q2 - r1*q3 - r2*q0 + r3*q1) * invmag2
    t3 := (r0*q3 + r1*q2 + r2*q1 - r3*q0) * invmag2

    return quaternion(w=f16(t0), x=f16(t1), y=f16(t2), z=f16(t3))
}
__quaternion128_quo :: proc(q, r: quaternion128) -> quaternion128 {
    q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q)
    r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r)

    invmag2 := 1.0 / (r0*r0 + r1*r1 + r2*r2 + r3*r3)

    t0 := (r0*q0 + r1*q1 + r2*q2 + r3*q3) * invmag2
    t1 := (r0*q1 - r1*q0 - r2*q3 - r3*q2) * invmag2
    t2 := (r0*q2 - r1*q3 - r2*q0 + r3*q1) * invmag2
    t3 := (r0*q3 + r1*q2 + r2*q1 - r3*q0) * invmag2

    return quaternion(w=t0, x=t1, y=t2, z=t3)
}
__quaternion256_quo :: proc(q, r: quaternion256) -> quaternion256 {
    q0, q1, q2, q3 := real(q), imag(q), jmag(q), kmag(q)
    r0, r1, r2, r3 := real(r), imag(r), jmag(r), kmag(r)

    invmag2 := 1.0 / (r0*r0 + r1*r1 + r2*r2 + r3*r3)

    t0 := (r0*q0 + r1*q1 + r2*q2 + r3*q3) * invmag2
    t1 := (r0*q1 - r1*q0 - r2*q3 - r3*q2) * invmag2
    t2 := (r0*q2 - r1*q3 - r2*q0 + r3*q1) * invmag2
    t3 := (r0*q3 + r1*q2 + r2*q1 - r3*q0) * invmag2

    return quaternion(w=t0, x=t1, y=t2, z=t3)
}
