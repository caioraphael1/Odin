package linalg

import "core:math"
import "base:builtin"
import "base:intrinsics"
@(require) import "base:runtime"

// Generic

TAU          :: 6.28318530717958647692528676655900576
PI           :: 3.14159265358979323846264338327950288

E            :: 2.71828182845904523536

τ :: TAU
π :: PI
e :: E

SQRT_TWO     :: 1.41421356237309504880168872420969808
SQRT_THREE   :: 1.73205080756887729352744634150587236
SQRT_FIVE    :: 2.23606797749978969640917366873127623

LN2          :: 0.693147180559945309417232121458176568
LN10         :: 2.30258509299404568401799145468436421

MAX_F64_PRECISION :: 16 // Maximum number of meaningful digits after the decimal point for 'f64'
MAX_F32_PRECISION ::  8 // Maximum number of meaningful digits after the decimal point for 'f32'

RAD_PER_DEG :: TAU/360.0
DEG_PER_RAD :: 360.0/TAU



@(private) IS_NUMERIC :: intrinsics.type_is_numeric
@(private) IS_QUATERNION :: intrinsics.type_is_quaternion
@(private) IS_ARRAY :: intrinsics.type_is_array
@(private) IS_FLOAT :: intrinsics.type_is_float
@(private) BASE_TYPE :: intrinsics.type_base_type
@(private) ELEM_TYPE :: intrinsics.type_elem_type



scalar_dot :: proc(a, b: $T) -> T where IS_FLOAT(T), !IS_ARRAY(T) {
    return a * b
}


vector_dot :: proc(a, b: $T/[$N]$E) -> (c: E) where IS_NUMERIC(E) #no_bounds_check {
    for i in 0..<N {
        c += a[i] * b[i]
    }
    return
}

quaternion64_dot :: proc(a, b: $T/quaternion64) -> (c: f16) {
    return a.w*b.w + a.x*b.x + a.y*b.y + a.z*b.z
}

quaternion128_dot :: proc(a, b: $T/quaternion128) -> (c: f32) {
    return a.w*b.w + a.x*b.x + a.y*b.y + a.z*b.z
}

quaternion256_dot :: proc(a, b: $T/quaternion256) -> (c: f64) {
    return a.w*b.w + a.x*b.x + a.y*b.y + a.z*b.z
}


inner_product :: dot
outer_product :: intrinsics.outer_product


quaternion_inverse :: proc(q: $Q) -> Q where IS_QUATERNION(Q) {
    return conj(q) * quaternion(w=1.0/dot(q, q), x=0, y=0, z=0)
}



scalar_cross :: proc(a, b: $T) -> T where IS_FLOAT(T), !IS_ARRAY(T) {
    return a * b
}


vector_cross2 :: proc(a, b: $T/[2]$E) -> E where IS_NUMERIC(E) {
    return a[0]*b[1] - b[0]*a[1]
}


vector_cross3 :: proc(a, b: $T/[3]$E) -> (c: T) where IS_NUMERIC(E) {
    c[0] = a[1]*b[2] - b[1]*a[2]
    c[1] = a[2]*b[0] - b[2]*a[0]
    c[2] = a[0]*b[1] - b[0]*a[1]
    return
}


quaternion_cross :: proc(q1, q2: $Q) -> (q3: Q) where IS_QUATERNION(Q) {
    q3.x = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y
    q3.y = q1.w * q2.y + q1.y * q2.w + q1.z * q2.x - q1.x * q2.z
    q3.z = q1.w * q2.z + q1.z * q2.w + q1.x * q2.y - q1.y * q2.x
    q3.w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z
    return
}

vector_normalize :: proc(v: $T/[$N]$E) -> T where IS_FLOAT(E) {
    return v / length(v)
}

quaternion_normalize :: proc(q: $Q) -> Q where IS_QUATERNION(Q) {
    return q/abs(q)
}


vector_normalize0 :: proc(v: $T/[$N]$E) -> T where IS_FLOAT(E) {
    m := length(v)
    return 0 if m == 0 else v/m
}

quaternion_normalize0 :: proc(q: $Q) -> Q  where IS_QUATERNION(Q) {
    m := abs(q)
    return 0 if m == 0 else q/m
}



vector_length :: proc(v: $T/[$N]$E) -> E where IS_FLOAT(E) {
    return math.sqrt(dot(v, v))
}


vector_length2 :: proc(v: $T/[$N]$E) -> E where IS_NUMERIC(E) {
    return dot(v, v)
}


quaternion_length :: proc(q: $Q) -> Q where IS_QUATERNION(Q) {
    return abs(q)
}


quaternion_length2 :: proc(q: $Q) -> Q where IS_QUATERNION(Q) {
    return dot(q, q)
}


scalar_triple_product :: proc(a, b, c: $T/[$N]$E) -> E where IS_NUMERIC(E) {
    // a . (b x c)
    // b . (c x a)
    // c . (a x b)
    return dot(a, cross(b, c))
}


vector_triple_product :: proc(a, b, c: $T/[$N]$E) -> T where IS_NUMERIC(E) {
    // a x (b x c)
    // (a . c)b - (a . b)c
    return cross(a, cross(b, c))
}


clamp_length :: proc(v: $T/[$N]$E, a: E) -> T where IS_FLOAT(E) {
    if a <= 0 {
        return 0
    }
    
    m2 := length2(v)
    return v if (m2 <= a*a) else (v / sqrt(m2) * a) // returns original when m2 is 0
}



projection :: proc(x, normal: $T/[$N]$E) -> T where IS_NUMERIC(E) {
    return dot(x, normal) / dot(normal, normal) * normal
}


identity_array_based_matrix :: proc($T: typeid/[$N][N]$E) -> (m: T) #no_bounds_check {
    for i in 0..<N {
        m[i][i] = E(1)
    }
    return m
}


identity_matrix :: proc($T: typeid/matrix[$N, N]$E) -> T #no_bounds_check {
    return 1
}

transpose :: intrinsics.transpose


matrix_mul :: proc(a, b: $M/matrix[$N, N]$E) -> (c: M)
    where !IS_ARRAY(E), IS_NUMERIC(E) #no_bounds_check {
    return a * b
}


matrix_comp_mul :: proc(a, b: $M/matrix[$I, $J]$E) -> (c: M)
    where !IS_ARRAY(E), IS_NUMERIC(E) #no_bounds_check {
    return hadamard_product(a, b)
}


matrix_mul_differ :: proc(a: $A/matrix[$I, $J]$E, b: $B/matrix[J, $K]E) -> (c: matrix[I, K]E)
    where !IS_ARRAY(E), IS_NUMERIC(E), I != K #no_bounds_check {
    return a * b
}



matrix_mul_vector :: proc(a: $A/matrix[$I, $J]$E, b: $B/[J]E) -> (c: B)
    where !IS_ARRAY(E), IS_NUMERIC(E) #no_bounds_check {
    return a * b
}


quaternion_mul_quaternion :: proc(q1, q2: $Q) -> Q where IS_QUATERNION(Q) {
    return q1 * q2
}


quaternion64_mul_vector3 :: proc(q: $Q/quaternion64, v: $V/[3]$F/f16) -> V {
    q := transmute(runtime.Raw_Quaternion64_Vector_Scalar)q
    v := v

    t := cross(2*q.vector, v)
    return V(v + q.scalar*t + cross(q.vector, t))
}

quaternion128_mul_vector3 :: proc(q: $Q/quaternion128, v: $V/[3]$F/f32) -> V {
    q := transmute(runtime.Raw_Quaternion128_Vector_Scalar)q
    v := v

    t := cross(2*q.vector, v)
    return V(v + q.scalar*t + cross(q.vector, t))
}

quaternion256_mul_vector3 :: proc(q: $Q/quaternion256, v: $V/[3]$F/f64) -> V {
    q := transmute(runtime.Raw_Quaternion256_Vector_Scalar)q
    v := v

    t := cross(2*q.vector, v)
    return V(v + q.scalar*t + cross(q.vector, t))
}


vector_to_ptr :: proc(v: ^$V/[$N]$E) -> ^E where IS_NUMERIC(E), N > 0 #no_bounds_check {
    return &v[0]
}

matrix_to_ptr :: proc(m: ^$A/matrix[$I, $J]$E) -> ^E where IS_NUMERIC(E), I > 0, J > 0 #no_bounds_check {
    return &m[0, 0]
}


vector_angle_between :: proc(a, b: $V/[$N]$E) -> E {
    a0 := normalize0(a)
    b0 := normalize0(b)
    d  := clamp(dot(a0, b0), -1, +1)
    return math.acos(d)
}
quaternion64_angle_between :: proc(a, b: $Q/quaternion64) -> f16 {
    c := normalize0(conj(a) * b)
    return math.acos(c.w)
}
quaternion128_angle_between :: proc(a, b: $Q/quaternion128) -> f32 {
    c := normalize0(conj(a) * b)
    return math.acos(c.w)
}
quaternion256_angle_between :: proc(a, b: $Q/quaternion256) -> f64 {
    c := normalize0(conj(a) * b)
    return math.acos(c.w)
}


// Splines


vector_slerp :: proc(x, y: $T/[$N]$E, a: E) -> T #no_bounds_check {
    cos_alpha := dot(x, y)
    alpha := math.acos(cos_alpha)
    sin_alpha := math.sin(alpha)

    t1 := math.sin((1 - a) * alpha) / sin_alpha
    t2 := math.sin(a * alpha) / sin_alpha

    return x * t1 + y * t2
}


catmull_rom :: proc(v1, v2, v3, v4: $T/[$N]$E, s: E) -> T #no_bounds_check {
    s2 := s*s
    s3 := s2*s

    f1 := -s3 + 2 * s2 - s
    f2 := 3 * s3 - 5 * s2 + 2
    f3 := -3 * s3 + 4 * s2 + s
    f4 := s3 - s2

    return (f1 * v1 + f2 * v2 + f3 * v3 + f4 * v4) * 0.5
}


hermite :: proc(v1, t1, v2, t2: $T/[$N]$E, s: E) -> T #no_bounds_check {
    s2 := s*s
    s3 := s2*s

    f1 := 2 * s3 - 3 * s2 + 1
    f2 := -2 * s3 + 3 * s2
    f3 := s3 - 2 * s2 + s
    f4 := s3 - s2

    return f1 * v1 + f2 * v2 + f3 * t1 + f4 * t2
}


cubic :: proc(v1, v2, v3, v4: $T/[$N]$E, s: E) -> T #no_bounds_check {
    return ((v1 * s + v2) * s + v3) * s + v4
}




array_cast :: proc(v: $A/[$N]$T, $Elem_Type: typeid) -> (w: [N]Elem_Type) #no_bounds_check {
    for i in 0..<N {
        w[i] = Elem_Type(v[i])
    }
    return
}


matrix_cast :: proc(v: $A/matrix[$M, $N]$T, $Elem_Type: typeid) -> (w: matrix[M, N]Elem_Type) #no_bounds_check {
    for j in 0..<N {
        for i in 0..<M {
            w[i, j] = Elem_Type(v[i, j])
        }
    }
    return
}

 to_f32  :: #force_inline proc(v: $A/[$N]$T) -> [N]f32  { return array_cast(v, f32)  }
 to_f64  :: #force_inline proc(v: $A/[$N]$T) -> [N]f64  { return array_cast(v, f64)  }

 to_i8   :: #force_inline proc(v: $A/[$N]$T) -> [N]i8   { return array_cast(v, i8)   }
 to_i16  :: #force_inline proc(v: $A/[$N]$T) -> [N]i16  { return array_cast(v, i16)  }
 to_i32  :: #force_inline proc(v: $A/[$N]$T) -> [N]i32  { return array_cast(v, i32)  }
 to_i64  :: #force_inline proc(v: $A/[$N]$T) -> [N]i64  { return array_cast(v, i64)  }
 to_int  :: #force_inline proc(v: $A/[$N]$T) -> [N]int  { return array_cast(v, int)  }

 to_u8   :: #force_inline proc(v: $A/[$N]$T) -> [N]u8   { return array_cast(v, u8)   }
 to_u16  :: #force_inline proc(v: $A/[$N]$T) -> [N]u16  { return array_cast(v, u16)  }
 to_u32  :: #force_inline proc(v: $A/[$N]$T) -> [N]u32  { return array_cast(v, u32)  }
 to_u64  :: #force_inline proc(v: $A/[$N]$T) -> [N]u64  { return array_cast(v, u64)  }
 to_uint :: #force_inline proc(v: $A/[$N]$T) -> [N]uint { return array_cast(v, uint) }

 to_complex32     :: #force_inline proc(v: $A/[$N]$T) -> [N]complex32     { return array_cast(v, complex32)     }
 to_complex64     :: #force_inline proc(v: $A/[$N]$T) -> [N]complex64     { return array_cast(v, complex64)     }
 to_complex128    :: #force_inline proc(v: $A/[$N]$T) -> [N]complex128    { return array_cast(v, complex128)    }
 to_quaternion64  :: #force_inline proc(v: $A/[$N]$T) -> [N]quaternion64  { return array_cast(v, quaternion64)  }
 to_quaternion128 :: #force_inline proc(v: $A/[$N]$T) -> [N]quaternion128 { return array_cast(v, quaternion128) }
 to_quaternion256 :: #force_inline proc(v: $A/[$N]$T) -> [N]quaternion256 { return array_cast(v, quaternion256) }


hadamard_product :: intrinsics.hadamard_product
matrix_flatten   :: intrinsics.matrix_flatten


hermitian_adjoint :: proc(m: $M/matrix[$N, N]$T) -> M where intrinsics.type_is_complex(T), N >= 1 #no_bounds_check {
    return conj(transpose(m))
}


trace :: proc(m: $M/matrix[$N, N]$T) -> (trace: T) #no_bounds_check {
    for i in 0..<N {
        trace += m[i, i]
    }
    return
}


matrix_minor :: proc(m: $M/matrix[$N, N]$T, #any_int row, column: int) -> (minor: T) where N > 1 #no_bounds_check {
    K :: int(N-1)
    cut_down: matrix[K, K]T
    for col_idx in 0..<K {
        j := col_idx + int(col_idx >= column)
        for row_idx in 0..<K {
            i := row_idx + int(row_idx >= row)
            cut_down[row_idx, col_idx] = m[i, j]
        }
    }
    return determinant(cut_down)
}




matrix1x1_determinant :: proc(m: $M/matrix[1, 1]$T) -> (det: T) #no_bounds_check {
    return m[0, 0]
}


matrix2x2_determinant :: proc(m: $M/matrix[2, 2]$T) -> (det: T) #no_bounds_check {
    return m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
}

matrix3x3_determinant :: proc(m: $M/matrix[3, 3]$T) -> (det: T) #no_bounds_check {
    a := +m[0, 0] * (m[1, 1] * m[2, 2] - m[1, 2] * m[2, 1])
    b := -m[0, 1] * (m[1, 0] * m[2, 2] - m[1, 2] * m[2, 0])
    c := +m[0, 2] * (m[1, 0] * m[2, 1] - m[1, 1] * m[2, 0])
    return a + b + c
}

matrix4x4_determinant :: proc(m: $M/matrix[4, 4]$T) -> (det: T) #no_bounds_check {
    c := cofactor(m)
    for i in 0..<4 {
        det += m[0, i] * c[0, i]
    }
    return
}





matrix1x1_adjugate :: proc(x: $M/matrix[1, 1]$T) -> (y: M) #no_bounds_check {
    y = x
    return
}


matrix2x2_adjugate :: proc(x: $M/matrix[2, 2]$T) -> (y: M) #no_bounds_check {
    y[0, 0] = +x[1, 1]
    y[0, 1] = -x[0, 1]
    y[1, 0] = -x[1, 0]
    y[1, 1] = +x[0, 0]
    return
}


matrix3x3_adjugate :: proc(m: $M/matrix[3, 3]$T) -> (y: M) #no_bounds_check {
    y[0, 0] = +(m[1, 1] * m[2, 2] - m[2, 1] * m[1, 2])
    y[1, 0] = -(m[1, 0] * m[2, 2] - m[2, 0] * m[1, 2])
    y[2, 0] = +(m[1, 0] * m[2, 1] - m[2, 0] * m[1, 1])
    y[0, 1] = -(m[0, 1] * m[2, 2] - m[2, 1] * m[0, 2])
    y[1, 1] = +(m[0, 0] * m[2, 2] - m[2, 0] * m[0, 2])
    y[2, 1] = -(m[0, 0] * m[2, 1] - m[2, 0] * m[0, 1])
    y[0, 2] = +(m[0, 1] * m[1, 2] - m[1, 1] * m[0, 2])
    y[1, 2] = -(m[0, 0] * m[1, 2] - m[1, 0] * m[0, 2])
    y[2, 2] = +(m[0, 0] * m[1, 1] - m[1, 0] * m[0, 1])
    return
}


matrix4x4_adjugate :: proc(x: $M/matrix[4, 4]$T) -> (y: M) #no_bounds_check {
    for i in 0..<4 {
        for j in 0..<4 {
            sign: T = 1 if (i + j) % 2 == 0 else -1
            y[i, j] = sign * matrix_minor(x, j, i)
        }
    }
    return
}



matrix1x1_cofactor :: proc(x: $M/matrix[1, 1]$T) -> (y: M) #no_bounds_check {
    y = x
    return
}


matrix2x2_cofactor :: proc(x: $M/matrix[2, 2]$T) -> (y: M) #no_bounds_check {
    y[0, 0] = +x[1, 1]
    y[0, 1] = -x[1, 0]
    y[1, 0] = -x[0, 1]
    y[1, 1] = +x[0, 0]
    return
}


matrix3x3_cofactor :: proc(m: $M/matrix[3, 3]$T) -> (y: M) #no_bounds_check {
    y[0, 0] = +(m[1, 1] * m[2, 2] - m[2, 1] * m[1, 2])
    y[0, 1] = -(m[1, 0] * m[2, 2] - m[2, 0] * m[1, 2])
    y[0, 2] = +(m[1, 0] * m[2, 1] - m[2, 0] * m[1, 1])
    y[1, 0] = -(m[0, 1] * m[2, 2] - m[2, 1] * m[0, 2])
    y[1, 1] = +(m[0, 0] * m[2, 2] - m[2, 0] * m[0, 2])
    y[1, 2] = -(m[0, 0] * m[2, 1] - m[2, 0] * m[0, 1])
    y[2, 0] = +(m[0, 1] * m[1, 2] - m[1, 1] * m[0, 2])
    y[2, 1] = -(m[0, 0] * m[1, 2] - m[1, 0] * m[0, 2])
    y[2, 2] = +(m[0, 0] * m[1, 1] - m[1, 0] * m[0, 1])
    return
}



matrix4x4_cofactor :: proc(x: $M/matrix[4, 4]$T) -> (y: M) #no_bounds_check {
    for i in 0..<4 {
        for j in 0..<4 {
            sign: T = 1 if (i + j) % 2 == 0 else -1
            y[i, j] = sign * matrix_minor(x, i, j)
        }
    }
    return
}


matrix1x1_inverse_transpose :: proc(x: $M/matrix[1, 1]$T) -> (y: M) #no_bounds_check {
    y[0, 0] = 1/x[0, 0]
    return
}


matrix2x2_inverse_transpose :: proc(x: $M/matrix[2, 2]$T) -> (y: M) #no_bounds_check {
    d := x[0, 0]*x[1, 1] - x[0, 1]*x[1, 0]
    when intrinsics.type_is_integer(T) {
        y[0, 0] = +x[1, 1] / d
        y[1, 0] = -x[0, 1] / d
        y[0, 1] = -x[1, 0] / d
        y[1, 1] = +x[0, 0] / d
    } else {
        id := 1 / d
        y[0, 0] = +x[1, 1] * id
        y[1, 0] = -x[0, 1] * id
        y[0, 1] = -x[1, 0] * id
        y[1, 1] = +x[0, 0] * id
    }
    return
}


matrix3x3_inverse_transpose :: proc(x: $M/matrix[3, 3]$T) -> (y: M) #no_bounds_check {
    c := cofactor(x)
    d := determinant(x)
    when intrinsics.type_is_integer(T) {
        for i in 0..<3 {
            for j in 0..<3 {
                y[i, j] = c[i, j] / d
            }
        }
    } else {
        id := 1/d
        for i in 0..<3 {
            for j in 0..<3 {
                y[i, j] = c[i, j] * id
            }
        }
    }
    return
}


matrix4x4_inverse_transpose :: proc(x: $M/matrix[4, 4]$T) -> (y: M) #no_bounds_check {
    c := cofactor(x)
    d: T
    for i in 0..<4 {
        d += x[0, i] * c[0, i]
    }
    when intrinsics.type_is_integer(T) {
        for i in 0..<4 {
            for j in 0..<4 {
                y[i, j] = c[i, j] / d
            }
        }
    } else {
        id := 1/d
        for i in 0..<4 {
            for j in 0..<4 {
                y[i, j] = c[i, j] * id
            }
        }
    }
    return
}


matrix1x1_inverse :: proc(x: $M/matrix[1, 1]$T) -> (y: M) #no_bounds_check {
    y[0, 0] = 1/x[0, 0]
    return
}


matrix2x2_inverse :: proc(x: $M/matrix[2, 2]$T) -> (y: M) #no_bounds_check {
    d := x[0, 0]*x[1, 1] - x[0, 1]*x[1, 0]
    when intrinsics.type_is_integer(T) {
        y[0, 0] = +x[1, 1] / d
        y[0, 1] = -x[0, 1] / d
        y[1, 0] = -x[1, 0] / d
        y[1, 1] = +x[0, 0] / d
    } else {
        id := 1 / d
        y[0, 0] = +x[1, 1] * id
        y[0, 1] = -x[0, 1] * id
        y[1, 0] = -x[1, 0] * id
        y[1, 1] = +x[0, 0] * id
    }
    return
}


matrix3x3_inverse :: proc(x: $M/matrix[3, 3]$T) -> (y: M) #no_bounds_check {
    c := cofactor(x)
    d := determinant(x)
    when intrinsics.type_is_integer(T) {
        for i in 0..<3 {
            for j in 0..<3 {
                y[i, j] = c[j, i] / d
            }
        }
    } else {
        id := 1/d
        for i in 0..<3 {
            for j in 0..<3 {
                y[i, j] = c[j, i] * id
            }
        }
    }
    return
}


matrix4x4_inverse :: proc(x: $M/matrix[4, 4]$T) -> (y: M) #no_bounds_check {
    c := cofactor(x)
    d: T
    for i in 0..<4 {
        d += x[0, i] * c[0, i]
    }
    when intrinsics.type_is_integer(T) {
        for i in 0..<4 {
            for j in 0..<4 {
                y[i, j] = c[j, i] / d
            }
        }
    } else {
        id := 1/d
        for i in 0..<4 {
            for j in 0..<4 {
                y[i, j] = c[j, i] * id
            }
        }
    }
    return
}
