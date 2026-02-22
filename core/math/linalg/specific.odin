package linalg

import "base:builtin"
import "base:intrinsics"
import "core:math"


F16_EPSILON :: 1e-3
F32_EPSILON :: 1e-7
F64_EPSILON :: 1e-15

Quaternionf16 :: quaternion64
Quaternionf32 :: quaternion128
Quaternionf64 :: quaternion256

MATRIX1F16_IDENTITY :: (matrix[1, 1]f16)(1)
MATRIX2F16_IDENTITY :: (matrix[2, 2]f16)(1)
MATRIX3F16_IDENTITY :: (matrix[3, 3]f16)(1)
MATRIX4F16_IDENTITY :: (matrix[4, 4]f16)(1)

MATRIX1F32_IDENTITY :: (matrix[1, 1]f32)(1)
MATRIX2F32_IDENTITY :: (matrix[2, 2]f32)(1)
MATRIX3F32_IDENTITY :: (matrix[3, 3]f32)(1)
MATRIX4F32_IDENTITY :: (matrix[4, 4]f32)(1)

MATRIX1F64_IDENTITY :: (matrix[1, 1]f64)(1)
MATRIX2F64_IDENTITY :: (matrix[2, 2]f64)(1)
MATRIX3F64_IDENTITY :: (matrix[3, 3]f64)(1)
MATRIX4F64_IDENTITY :: (matrix[4, 4]f64)(1)

QUATERNIONF16_IDENTITY :: Quaternionf16(1)
QUATERNIONF32_IDENTITY :: Quaternionf32(1)
QUATERNIONF64_IDENTITY :: Quaternionf64(1)


Euler_Angle_Order :: enum {
    // Tait-Bryan
    XYZ,
    XZY,
    YXZ,
    YZX,
    ZXY,
    ZYX,

    // Proper Euler
    XYX,
    XZX,
    YXY,
    YZY,
    ZXZ,
    ZYZ,
}


vector2_orthogonal :: proc(v: $V/[2]$E) -> V where !intrinsics.type_is_array(E), intrinsics.type_is_float(E) {
    return {-v.y, v.x}
}


vector3_orthogonal :: proc(v: $V/[3]$E) -> V where !intrinsics.type_is_array(E), intrinsics.type_is_float(E) {
    x := abs(v.x)
    y := abs(v.y)
    z := abs(v.z)

    other: V
    if x < y {
        if x < z {
            other = {1, 0, 0}
        } else {
            other = {0, 0, 1}
        }
    } else {
        if y < z {
            other = {0, 1, 0}
        } else {
            other = {0, 0, 1}
        }
    }
    return vec_normalize(vec3_cross(v, other))
}


vector4_srgb_to_linear_f16 :: proc(col: [4]f16) -> [4]f16 {
    r := math.pow_f16((col.x + 0.055) / 1.055, 2.4) if col.x > 0.04045 else col.x / 12.92
    g := math.pow_f16((col.y + 0.055) / 1.055, 2.4) if col.y > 0.04045 else col.y / 12.92
    b := math.pow_f16((col.z + 0.055) / 1.055, 2.4) if col.z > 0.04045 else col.z / 12.92
    a := col.w
    return {r, g, b, a}
}
vector4_srgb_to_linear_f32 :: proc(col: [4]f32) -> [4]f32 {
    r := math.pow_f32((col.x + 0.055) / 1.055, 2.4) if col.x > 0.04045 else col.x / 12.92
    g := math.pow_f32((col.y + 0.055) / 1.055, 2.4) if col.y > 0.04045 else col.y / 12.92
    b := math.pow_f32((col.z + 0.055) / 1.055, 2.4) if col.z > 0.04045 else col.z / 12.92
    a := col.w
    return {r, g, b, a}
}
vector4_srgb_to_linear_f64 :: proc(col: [4]f64) -> [4]f64 {
    r := math.pow_f64((col.x + 0.055) / 1.055, 2.4) if col.x > 0.04045 else col.x / 12.92
    g := math.pow_f64((col.y + 0.055) / 1.055, 2.4) if col.y > 0.04045 else col.y / 12.92
    b := math.pow_f64((col.z + 0.055) / 1.055, 2.4) if col.z > 0.04045 else col.z / 12.92
    a := col.w
    return {r, g, b, a}
}


vector3_srgb_to_linear_f16 :: proc(col: [3]f16) -> [3]f16 {
    r := math.pow_f16((col.x + 0.055) / 1.055, 2.4) if col.x > 0.04045 else col.x / 12.92
    g := math.pow_f16((col.y + 0.055) / 1.055, 2.4) if col.y > 0.04045 else col.y / 12.92
    b := math.pow_f16((col.z + 0.055) / 1.055, 2.4) if col.z > 0.04045 else col.z / 12.92
    return {r, g, b}
}
vector3_srgb_to_linear_f32 :: proc(col: [3]f32) -> [3]f32 {
    r := math.pow_f32((col.x + 0.055) / 1.055, 2.4) if col.x > 0.04045 else col.x / 12.92
    g := math.pow_f32((col.y + 0.055) / 1.055, 2.4) if col.y > 0.04045 else col.y / 12.92
    b := math.pow_f32((col.z + 0.055) / 1.055, 2.4) if col.z > 0.04045 else col.z / 12.92
    return {r, g, b}
}
vector3_srgb_to_linear_f64 :: proc(col: [3]f64) -> [3]f64 {
    r := math.pow_f64((col.x + 0.055) / 1.055, 2.4) if col.x > 0.04045 else col.x / 12.92
    g := math.pow_f64((col.y + 0.055) / 1.055, 2.4) if col.y > 0.04045 else col.y / 12.92
    b := math.pow_f64((col.z + 0.055) / 1.055, 2.4) if col.z > 0.04045 else col.z / 12.92
    return {r, g, b}
}


vector4_linear_to_srgb_f16 :: proc(col: [4]f16) -> [4]f16 {
    x := 1.055 * math.pow_f16(col.x, 1.0 / 2.4) - 0.055 if col.x > 0.0031308 else 12.92 * col.x
    y := 1.055 * math.pow_f16(col.y, 1.0 / 2.4) - 0.055 if col.y > 0.0031308 else 12.92 * col.y
    z := 1.055 * math.pow_f16(col.z, 1.0 / 2.4) - 0.055 if col.z > 0.0031308 else 12.92 * col.z

    return {x, y, z, col.w}
}
vector4_linear_to_srgb_f32 :: proc(col: [4]f32) -> [4]f32 {
    x := 1.055 * math.pow_f32(col.x, 1.0 / 2.4) - 0.055 if col.x > 0.0031308 else 12.92 * col.x
    y := 1.055 * math.pow_f32(col.y, 1.0 / 2.4) - 0.055 if col.y > 0.0031308 else 12.92 * col.y
    z := 1.055 * math.pow_f32(col.z, 1.0 / 2.4) - 0.055 if col.z > 0.0031308 else 12.92 * col.z

    return {x, y, z, col.w}
}
vector4_linear_to_srgb_f64 :: proc(col: [4]f64) -> [4]f64 {
    x := 1.055 * math.pow_f64(col.x, 1.0 / 2.4) - 0.055 if col.x > 0.0031308 else 12.92 * col.x
    y := 1.055 * math.pow_f64(col.y, 1.0 / 2.4) - 0.055 if col.y > 0.0031308 else 12.92 * col.y
    z := 1.055 * math.pow_f64(col.z, 1.0 / 2.4) - 0.055 if col.z > 0.0031308 else 12.92 * col.z

    return {x, y, z, col.w}
}


vector3_linear_to_srgb_f16 :: proc(col: [3]f16) -> [3]f16 {
    x := 1.055 * math.pow_f16(col.x, 1.0 / 2.4) - 0.055 if col.x > 0.0031308 else 12.92 * col.x
    y := 1.055 * math.pow_f16(col.y, 1.0 / 2.4) - 0.055 if col.y > 0.0031308 else 12.92 * col.y
    z := 1.055 * math.pow_f16(col.z, 1.0 / 2.4) - 0.055 if col.z > 0.0031308 else 12.92 * col.z

    return {x, y, z}
}
vector3_linear_to_srgb_f32 :: proc(col: [3]f32) -> [3]f32 {
    x := 1.055 * math.pow_f32(col.x, 1.0 / 2.4) - 0.055 if col.x > 0.0031308 else 12.92 * col.x
    y := 1.055 * math.pow_f32(col.y, 1.0 / 2.4) - 0.055 if col.y > 0.0031308 else 12.92 * col.y
    z := 1.055 * math.pow_f32(col.z, 1.0 / 2.4) - 0.055 if col.z > 0.0031308 else 12.92 * col.z

    return {x, y, z}
}
vector3_linear_to_srgb_f64 :: proc(col: [3]f64) -> [3]f64 {
    x := 1.055 * math.pow_f64(col.x, 1.0 / 2.4) - 0.055 if col.x > 0.0031308 else 12.92 * col.x
    y := 1.055 * math.pow_f64(col.y, 1.0 / 2.4) - 0.055 if col.y > 0.0031308 else 12.92 * col.y
    z := 1.055 * math.pow_f64(col.z, 1.0 / 2.4) - 0.055 if col.z > 0.0031308 else 12.92 * col.z

    return {x, y, z}
}


vector4_hsl_to_rgb_f16 :: proc(h, s, l: f16, a: f16 = 1) -> [4]f16 {
    
    hue_to_rgb :: proc(p, q, t: f16) -> f16 {
        t := t
        if t < 0 { t += 1 }
        if t > 1 { t -= 1 }
        switch {
        case t < 1.0/6.0: return p + (q - p) * 6.0 * t
        case t < 1.0/2.0: return q
        case t < 2.0/3.0: return p + (q - p) * 6.0 * (2.0/3.0 - t)
        }
        return p
    }

    r, g, b: f16
    if s == 0 {
        r = l
        g = l
        b = l
    } else {
        q := l * (1+s) if l < 0.5 else l+s - l*s
        p := 2*l - q
        r = hue_to_rgb(p, q, h + 1.0/3.0)
        g = hue_to_rgb(p, q, h)
        b = hue_to_rgb(p, q, h - 1.0/3.0)
    }
    return {r, g, b, a}
}
vector4_hsl_to_rgb_f32 :: proc(h, s, l: f32, a: f32 = 1) -> [4]f32 {
    
    hue_to_rgb :: proc(p, q, t: f32) -> f32 {
        t := t
        if t < 0 { t += 1 }
        if t > 1 { t -= 1 }
        switch {
        case t < 1.0/6.0: return p + (q - p) * 6.0 * t
        case t < 1.0/2.0: return q
        case t < 2.0/3.0: return p + (q - p) * 6.0 * (2.0/3.0 - t)
        }
        return p
    }

    r, g, b: f32
    if s == 0 {
        r = l
        g = l
        b = l
    } else {
        q := l * (1+s) if l < 0.5 else l+s - l*s
        p := 2*l - q
        r = hue_to_rgb(p, q, h + 1.0/3.0)
        g = hue_to_rgb(p, q, h)
        b = hue_to_rgb(p, q, h - 1.0/3.0)
    }
    return {r, g, b, a}
}
vector4_hsl_to_rgb_f64 :: proc(h, s, l: f64, a: f64 = 1) -> [4]f64 {
    
    hue_to_rgb :: proc(p, q, t: f64) -> f64 {
        t := t
        if t < 0 { t += 1 }
        if t > 1 { t -= 1 }
        switch {
        case t < 1.0/6.0: return p + (q - p) * 6.0 * t
        case t < 1.0/2.0: return q
        case t < 2.0/3.0: return p + (q - p) * 6.0 * (2.0/3.0 - t)
        }
        return p
    }

    r, g, b: f64
    if s == 0 {
        r = l
        g = l
        b = l
    } else {
        q := l * (1+s) if l < 0.5 else l+s - l*s
        p := 2*l - q
        r = hue_to_rgb(p, q, h + 1.0/3.0)
        g = hue_to_rgb(p, q, h)
        b = hue_to_rgb(p, q, h - 1.0/3.0)
    }
    return {r, g, b, a}
}


vector4_rgb_to_hsl_f16 :: proc(col: [4]f16) -> [4]f16 {
    r := col.x
    g := col.y
    b := col.z
    a := col.w
    v_min := min(r, g, b)
    v_max := max(r, g, b)
    h, s, l: f16
    h  = 0.0
    s  = 0.0
    l  = (v_min + v_max) * 0.5

    if v_max != v_min {
        d: = v_max - v_min
        s = d / (2.0 - v_max - v_min) if l > 0.5 else d / (v_max + v_min)
        switch {
        case v_max == r:
            h = (g - b) / d + (6.0 if g < b else 0.0)
        case v_max == g:
            h = (b - r) / d + 2.0
        case v_max == b:
            h = (r - g) / d + 4.0
        }

        h *= 1.0/6.0
    }

    return {h, s, l, a}
}
vector4_rgb_to_hsl_f32 :: proc(col: [4]f32) -> [4]f32 {
    r := col.x
    g := col.y
    b := col.z
    a := col.w
    v_min := min(r, g, b)
    v_max := max(r, g, b)
    h, s, l: f32
    h  = 0.0
    s  = 0.0
    l  = (v_min + v_max) * 0.5

    if v_max != v_min {
        d: = v_max - v_min
        s = d / (2.0 - v_max - v_min) if l > 0.5 else d / (v_max + v_min)
        switch {
        case v_max == r:
            h = (g - b) / d + (6.0 if g < b else 0.0)
        case v_max == g:
            h = (b - r) / d + 2.0
        case v_max == b:
            h = (r - g) / d + 4.0
        }

        h *= 1.0/6.0
    }

    return {h, s, l, a}
}
vector4_rgb_to_hsl_f64 :: proc(col: [4]f64) -> [4]f64 {
    r := col.x
    g := col.y
    b := col.z
    a := col.w
    v_min := min(r, g, b)
    v_max := max(r, g, b)
    h, s, l: f64
    h  = 0.0
    s  = 0.0
    l  = (v_min + v_max) * 0.5

    if v_max != v_min {
        d: = v_max - v_min
        s = d / (2.0 - v_max - v_min) if l > 0.5 else d / (v_max + v_min)
        switch {
        case v_max == r:
            h = (g - b) / d + (6.0 if g < b else 0.0)
        case v_max == g:
            h = (b - r) / d + 2.0
        case v_max == b:
            h = (r - g) / d + 4.0
        }

        h *= 1.0/6.0
    }

    return {h, s, l, a}
}


quaternion_angle_axis_f16 :: proc(angle_radians: f16, axis: [3]f16) -> (q: Quaternionf16) {
    t := angle_radians*0.5
    v := vec_normalize(axis) * math.sin_f16(t)
    q.x = v.x
    q.y = v.y
    q.z = v.z
    q.w = math.cos_f16(t)
    return
}
quaternion_angle_axis_f32 :: proc(angle_radians: f32, axis: [3]f32) -> (q: Quaternionf32) {
    t := angle_radians*0.5
    v := vec_normalize(axis) * math.sin_f32(t)
    q.x = v.x
    q.y = v.y
    q.z = v.z
    q.w = math.cos_f32(t)
    return
}
quaternion_angle_axis_f64 :: proc(angle_radians: f64, axis: [3]f64) -> (q: Quaternionf64) {
    t := angle_radians*0.5
    v := vec_normalize(axis) * math.sin_f64(t)
    q.x = v.x
    q.y = v.y
    q.z = v.z
    q.w = math.cos_f64(t)
    return
}


angle_from_quaternion_f16 :: proc(q: Quaternionf16) -> f16 {
    if abs(q.w) > math.SQRT_THREE*0.5 {
        return math.asin(math.sqrt(q.x*q.x + q.y*q.y + q.z*q.z)) * 2
    }

    return math.acos(q.w) * 2
}
angle_from_quaternion_f32 :: proc(q: Quaternionf32) -> f32 {
    if abs(q.w) > math.SQRT_THREE*0.5 {
        return math.asin(math.sqrt(q.x*q.x + q.y*q.y + q.z*q.z)) * 2
    }

    return math.acos(q.w) * 2
}
angle_from_quaternion_f64 :: proc(q: Quaternionf64) -> f64 {
    if abs(q.w) > math.SQRT_THREE*0.5 {
        return math.asin(math.sqrt(q.x*q.x + q.y*q.y + q.z*q.z)) * 2
    }

    return math.acos(q.w) * 2
}


axis_from_quaternion_f16 :: proc(q: Quaternionf16) -> [3]f16 {
    t1 := 1 - q.w*q.w
    if t1 <= 0 {
        return {0, 0, 1}
    }
    t2 := 1.0 / math.sqrt(t1)
    return {q.x*t2, q.y*t2, q.z*t2}
}
axis_from_quaternion_f32 :: proc(q: Quaternionf32) -> [3]f32 {
    t1 := 1 - q.w*q.w
    if t1 <= 0 {
        return {0, 0, 1}
    }
    t2 := 1.0 / math.sqrt(t1)
    return {q.x*t2, q.y*t2, q.z*t2}
}
axis_from_quaternion_f64 :: proc(q: Quaternionf64) -> [3]f64 {
    t1 := 1 - q.w*q.w
    if t1 <= 0 {
        return {0, 0, 1}
    }
    t2 := 1.0 / math.sqrt(t1)
    return {q.x*t2, q.y*t2, q.z*t2}
}


angle_axis_from_quaternion_f16 :: proc(q: Quaternionf16) -> (angle: f16, axis: [3]f16) {
    angle = angle_from_quaternion_f16(q)
    axis  = axis_from_quaternion_f16(q)
    return
}
angle_axis_from_quaternion_f32 :: proc(q: Quaternionf32) -> (angle: f32, axis: [3]f32) {
    angle = angle_from_quaternion_f32(q)
    axis  = axis_from_quaternion_f32(q)
    return
}
angle_axis_from_quaternion_f64 :: proc(q: Quaternionf64) -> (angle: f64, axis: [3]f64) {
    angle = angle_from_quaternion_f64(q)
    axis  = axis_from_quaternion_f64(q)
    return
}


quaternion_from_forward_and_up_f16 :: proc(forward, up: [3]f16) -> Quaternionf16 #no_bounds_check {
    f := vec_normalize(forward)
    s := vec_normalize(vec3_cross(f, up))
    u := vec3_cross(s, f)
    m := matrix[3, 3]f16{
        +s.x, +s.y, +s.z,
        +u.x, +u.y, +u.z,
        -f.x, -f.y, -f.z,
    }

    tr := trace(m)

    q: Quaternionf16

    switch {
    case tr > 0:
        S := 2 * math.sqrt(1 + tr)
        q.w = 0.25 * S
        q.x = (m[1, 2] - m[2, 1]) / S
        q.y = (m[2, 0] - m[0, 2]) / S
        q.z = (m[0, 1] - m[1, 0]) / S
    case (m[0, 0] > m[1, 1]) && (m[0, 0] > m[2, 2]):
        S := 2 * math.sqrt(1 + m[0, 0] - m[1, 1] - m[2, 2])
        q.w = (m[1, 2] - m[2, 1]) / S
        q.x = 0.25 * S
        q.y = (m[1, 0] + m[0, 1]) / S
        q.z = (m[2, 0] + m[0, 2]) / S
    case m[1, 1] > m[2, 2]:
        S := 2 * math.sqrt(1 + m[1, 1] - m[0, 0] - m[2, 2])
        q.w = (m[2, 0] - m[0, 2]) / S
        q.x = (m[1, 0] + m[0, 1]) / S
        q.y = 0.25 * S
        q.z = (m[2, 1] + m[1, 2]) / S
    case:
        S := 2 * math.sqrt(1 + m[2, 2] - m[0, 0] - m[1, 1])
        q.w = (m[0, 1] - m[1, 0]) / S
        q.x = (m[2, 0] + m[0, 2]) / S
        q.y = (m[2, 1] + m[1, 2]) / S
        q.z = 0.25 * S
    }

    return quaternion_normalize(q)
}
quaternion_from_forward_and_up_f32 :: proc(forward, up: [3]f32) -> Quaternionf32 #no_bounds_check {
    f := vec_normalize(forward)
    s := vec_normalize(vec3_cross(f, up))
    u := vec3_cross(s, f)
    m := matrix[3, 3]f32{
        +s.x, +s.y, +s.z,
        +u.x, +u.y, +u.z,
        -f.x, -f.y, -f.z,
    }

    tr := trace(m)

    q: Quaternionf32

    switch {
    case tr > 0:
        S := 2 * math.sqrt(1 + tr)
        q.w = 0.25 * S
        q.x = (m[1, 2] - m[2, 1]) / S
        q.y = (m[2, 0] - m[0, 2]) / S
        q.z = (m[0, 1] - m[1, 0]) / S
    case (m[0, 0] > m[1, 1]) && (m[0, 0] > m[2, 2]):
        S := 2 * math.sqrt(1 + m[0, 0] - m[1, 1] - m[2, 2])
        q.w = (m[1, 2] - m[2, 1]) / S
        q.x = 0.25 * S
        q.y = (m[1, 0] + m[0, 1]) / S
        q.z = (m[2, 0] + m[0, 2]) / S
    case m[1, 1] > m[2, 2]:
        S := 2 * math.sqrt(1 + m[1, 1] - m[0, 0] - m[2, 2])
        q.w = (m[2, 0] - m[0, 2]) / S
        q.x = (m[1, 0] + m[0, 1]) / S
        q.y = 0.25 * S
        q.z = (m[2, 1] + m[1, 2]) / S
    case:
        S := 2 * math.sqrt(1 + m[2, 2] - m[0, 0] - m[1, 1])
        q.w = (m[0, 1] - m[1, 0]) / S
        q.x = (m[2, 0] + m[0, 2]) / S
        q.y = (m[2, 1] + m[1, 2]) / S
        q.z = 0.25 * S
    }

    return quaternion_normalize(q)
}
quaternion_from_forward_and_up_f64 :: proc(forward, up: [3]f64) -> Quaternionf64 #no_bounds_check {
    f := vec_normalize(forward)
    s := vec_normalize(vec3_cross(f, up))
    u := vec3_cross(s, f)
    m := matrix[3, 3]f64{
        +s.x, +s.y, +s.z,
        +u.x, +u.y, +u.z,
        -f.x, -f.y, -f.z,
    }

    tr := trace(m)

    q: Quaternionf64

    switch {
    case tr > 0:
        S := 2 * math.sqrt(1 + tr)
        q.w = 0.25 * S
        q.x = (m[1, 2] - m[2, 1]) / S
        q.y = (m[2, 0] - m[0, 2]) / S
        q.z = (m[0, 1] - m[1, 0]) / S
    case (m[0, 0] > m[1, 1]) && (m[0, 0] > m[2, 2]):
        S := 2 * math.sqrt(1 + m[0, 0] - m[1, 1] - m[2, 2])
        q.w = (m[1, 2] - m[2, 1]) / S
        q.x = 0.25 * S
        q.y = (m[1, 0] + m[0, 1]) / S
        q.z = (m[2, 0] + m[0, 2]) / S
    case m[1, 1] > m[2, 2]:
        S := 2 * math.sqrt(1 + m[1, 1] - m[0, 0] - m[2, 2])
        q.w = (m[2, 0] - m[0, 2]) / S
        q.x = (m[1, 0] + m[0, 1]) / S
        q.y = 0.25 * S
        q.z = (m[2, 1] + m[1, 2]) / S
    case:
        S := 2 * math.sqrt(1 + m[2, 2] - m[0, 0] - m[1, 1])
        q.w = (m[0, 1] - m[1, 0]) / S
        q.x = (m[2, 0] + m[0, 2]) / S
        q.y = (m[2, 1] + m[1, 2]) / S
        q.z = 0.25 * S
    }

    return quaternion_normalize(q)
}


quaternion_look_at_f16 :: proc(eye, centre: [3]f16, up: [3]f16) -> Quaternionf16 {
    return quaternion_from_matrix3_f16(matrix3_look_at_f16(eye, centre, up))
}
quaternion_look_at_f32 :: proc(eye, centre: [3]f32, up: [3]f32) -> Quaternionf32 {
    return quaternion_from_matrix3_f32(matrix3_look_at_f32(eye, centre, up))
}
quaternion_look_at_f64 :: proc(eye, centre: [3]f64, up: [3]f64) -> Quaternionf64 {
    return quaternion_from_matrix3_f64(matrix3_look_at_f64(eye, centre, up))
}


quaternion_nlerp_f16 :: proc(a, b: Quaternionf16, t: f16) -> (c: Quaternionf16) {
    c.x = a.x + (b.x-a.x)*t
    c.y = a.y + (b.y-a.y)*t
    c.z = a.z + (b.z-a.z)*t
    c.w = a.w + (b.w-a.w)*t
    return quaternion_normalize(c)
}
quaternion_nlerp_f32 :: proc(a, b: Quaternionf32, t: f32) -> (c: Quaternionf32) {
    c.x = a.x + (b.x-a.x)*t
    c.y = a.y + (b.y-a.y)*t
    c.z = a.z + (b.z-a.z)*t
    c.w = a.w + (b.w-a.w)*t
    return quaternion_normalize(c)
}
quaternion_nlerp_f64 :: proc(a, b: Quaternionf64, t: f64) -> (c: Quaternionf64) {
    c.x = a.x + (b.x-a.x)*t
    c.y = a.y + (b.y-a.y)*t
    c.z = a.z + (b.z-a.z)*t
    c.w = a.w + (b.w-a.w)*t
    return quaternion_normalize(c)
}


quaternion_slerp_f16 :: proc(x, y: Quaternionf16, t: f16) -> (q: Quaternionf16) {
    a, b := x, y
    cos_angle := quaternionf16_dot(a, b)
    if cos_angle < 0 {
        b = -b
        cos_angle = -cos_angle
    }
    if cos_angle > 1 - F32_EPSILON {
        q.x = a.x + (b.x-a.x)*t
        q.y = a.y + (b.y-a.y)*t
        q.z = a.z + (b.z-a.z)*t
        q.w = a.w + (b.w-a.w)*t
        return
    }

    angle := math.acos(cos_angle)
    sin_angle := math.sin_f16(angle)
    factor_a := math.sin_f16((1-t) * angle) / sin_angle
    factor_b := math.sin_f16(t * angle)     / sin_angle


    q.x = factor_a * a.x + factor_b * b.x
    q.y = factor_a * a.y + factor_b * b.y
    q.z = factor_a * a.z + factor_b * b.z
    q.w = factor_a * a.w + factor_b * b.w
    return
}
quaternion_slerp_f32 :: proc(x, y: Quaternionf32, t: f32) -> (q: Quaternionf32) {
    a, b := x, y
    cos_angle := quaternionf32_dot(a, b)
    if cos_angle < 0 {
        b = -b
        cos_angle = -cos_angle
    }
    if cos_angle > 1 - F32_EPSILON {
        q.x = a.x + (b.x-a.x)*t
        q.y = a.y + (b.y-a.y)*t
        q.z = a.z + (b.z-a.z)*t
        q.w = a.w + (b.w-a.w)*t
        return
    }

    angle := math.acos(cos_angle)
    sin_angle := math.sin_f32(angle)
    factor_a := math.sin_f32((1-t) * angle) / sin_angle
    factor_b := math.sin_f32(t * angle)     / sin_angle


    q.x = factor_a * a.x + factor_b * b.x
    q.y = factor_a * a.y + factor_b * b.y
    q.z = factor_a * a.z + factor_b * b.z
    q.w = factor_a * a.w + factor_b * b.w
    return
}
quaternion_slerp_f64 :: proc(x, y: Quaternionf64, t: f64) -> (q: Quaternionf64) {
    a, b := x, y
    cos_angle := quaternionf64_dot(a, b)
    if cos_angle < 0 {
        b = -b
        cos_angle = -cos_angle
    }
    if cos_angle > 1 - F64_EPSILON {
        q.x = a.x + (b.x-a.x)*t
        q.y = a.y + (b.y-a.y)*t
        q.z = a.z + (b.z-a.z)*t
        q.w = a.w + (b.w-a.w)*t
        return
    }

    angle := math.acos(cos_angle)
    sin_angle := math.sin_f64(angle)
    factor_a := math.sin_f64((1-t) * angle) / sin_angle
    factor_b := math.sin_f64(t * angle)     / sin_angle


    q.x = factor_a * a.x + factor_b * b.x
    q.y = factor_a * a.y + factor_b * b.y
    q.z = factor_a * a.z + factor_b * b.z
    q.w = factor_a * a.w + factor_b * b.w
    return
}


quaternion_squad_f16 :: proc(q1, q2, s1, s2: Quaternionf16, h: f16) -> Quaternionf16 {
    slerp :: quaternion_slerp_f16
    return slerp(slerp(q1, q2, h), slerp(s1, s2, h), 2 * (1 - h) * h)
}
quaternion_squad_f32 :: proc(q1, q2, s1, s2: Quaternionf32, h: f32) -> Quaternionf32 {
    slerp :: quaternion_slerp_f32
    return slerp(slerp(q1, q2, h), slerp(s1, s2, h), 2 * (1 - h) * h)
}
quaternion_squad_f64 :: proc(q1, q2, s1, s2: Quaternionf64, h: f64) -> Quaternionf64 {
    slerp :: quaternion_slerp_f64
    return slerp(slerp(q1, q2, h), slerp(s1, s2, h), 2 * (1 - h) * h)
}


quaternion_from_matrix4_f16 :: proc(m: matrix[4, 4]f16) -> (q: Quaternionf16) #no_bounds_check {
    m3: matrix[3, 3]f16 = ---
    m3[0, 0], m3[1, 0], m3[2, 0] = m[0, 0], m[1, 0], m[2, 0]
    m3[0, 1], m3[1, 1], m3[2, 1] = m[0, 1], m[1, 1], m[2, 1]
    m3[0, 2], m3[1, 2], m3[2, 2] = m[0, 2], m[1, 2], m[2, 2]
    return quaternion_from_matrix3_f16(m3)
}
quaternion_from_matrix4_f32 :: proc(m: matrix[4, 4]f32) -> (q: Quaternionf32) #no_bounds_check {
    m3: matrix[3, 3]f32 = ---
    m3[0, 0], m3[1, 0], m3[2, 0] = m[0, 0], m[1, 0], m[2, 0]
    m3[0, 1], m3[1, 1], m3[2, 1] = m[0, 1], m[1, 1], m[2, 1]
    m3[0, 2], m3[1, 2], m3[2, 2] = m[0, 2], m[1, 2], m[2, 2]
    return quaternion_from_matrix3_f32(m3)
}
quaternion_from_matrix4_f64 :: proc(m: matrix[4, 4]f64) -> (q: Quaternionf64) #no_bounds_check {
    m3: matrix[3, 3]f64 = ---
    m3[0, 0], m3[1, 0], m3[2, 0] = m[0, 0], m[1, 0], m[2, 0]
    m3[0, 1], m3[1, 1], m3[2, 1] = m[0, 1], m[1, 1], m[2, 1]
    m3[0, 2], m3[1, 2], m3[2, 2] = m[0, 2], m[1, 2], m[2, 2]
    return quaternion_from_matrix3_f64(m3)
}


quaternion_from_matrix3_f16 :: proc(m: matrix[3, 3]f16) -> (q: Quaternionf16) #no_bounds_check {
    four_x_squared_minus_1 := m[0, 0] - m[1, 1] - m[2, 2]
    four_y_squared_minus_1 := m[1, 1] - m[0, 0] - m[2, 2]
    four_z_squared_minus_1 := m[2, 2] - m[0, 0] - m[1, 1]
    four_w_squared_minus_1 := m[0, 0] + m[1, 1] + m[2, 2]

    biggest_index := 0
    four_biggest_squared_minus_1 := four_w_squared_minus_1
    if four_x_squared_minus_1 > four_biggest_squared_minus_1 {
        four_biggest_squared_minus_1 = four_x_squared_minus_1
        biggest_index = 1
    }
    if four_y_squared_minus_1 > four_biggest_squared_minus_1 {
        four_biggest_squared_minus_1 = four_y_squared_minus_1
        biggest_index = 2
    }
    if four_z_squared_minus_1 > four_biggest_squared_minus_1 {
        four_biggest_squared_minus_1 = four_z_squared_minus_1
        biggest_index = 3
    }

    biggest_val := math.sqrt(four_biggest_squared_minus_1 + 1) * 0.5
    mult := 0.25 / biggest_val

    q = 1
    switch biggest_index {
    case 0:
        q.w = biggest_val
        q.x = (m[2, 1] - m[1, 2]) * mult
        q.y = (m[0, 2] - m[2, 0]) * mult
        q.z = (m[1, 0] - m[0, 1]) * mult
    case 1:
        q.w = (m[2, 1] - m[1, 2]) * mult
        q.x = biggest_val
        q.y = (m[1, 0] + m[0, 1]) * mult
        q.z = (m[0, 2] + m[2, 0]) * mult
    case 2:
        q.w = (m[0, 2] - m[2, 0]) * mult
        q.x = (m[1, 0] + m[0, 1]) * mult
        q.y = biggest_val
        q.z = (m[2, 1] + m[1, 2]) * mult
    case 3:
        q.w = (m[1, 0] - m[0, 1]) * mult
        q.x = (m[0, 2] + m[2, 0]) * mult
        q.y = (m[2, 1] + m[1, 2]) * mult
        q.z = biggest_val
    }
    return
}
quaternion_from_matrix3_f32 :: proc(m: matrix[3, 3]f32) -> (q: Quaternionf32) #no_bounds_check {
    four_x_squared_minus_1 := m[0, 0] - m[1, 1] - m[2, 2]
    four_y_squared_minus_1 := m[1, 1] - m[0, 0] - m[2, 2]
    four_z_squared_minus_1 := m[2, 2] - m[0, 0] - m[1, 1]
    four_w_squared_minus_1 := m[0, 0] + m[1, 1] + m[2, 2]

    biggest_index := 0
    four_biggest_squared_minus_1 := four_w_squared_minus_1
    if four_x_squared_minus_1 > four_biggest_squared_minus_1 {
        four_biggest_squared_minus_1 = four_x_squared_minus_1
        biggest_index = 1
    }
    if four_y_squared_minus_1 > four_biggest_squared_minus_1 {
        four_biggest_squared_minus_1 = four_y_squared_minus_1
        biggest_index = 2
    }
    if four_z_squared_minus_1 > four_biggest_squared_minus_1 {
        four_biggest_squared_minus_1 = four_z_squared_minus_1
        biggest_index = 3
    }

    biggest_val := math.sqrt(four_biggest_squared_minus_1 + 1) * 0.5
    mult := 0.25 / biggest_val

    q = 1
    switch biggest_index {
    case 0:
        q.w = biggest_val
        q.x = (m[2, 1] - m[1, 2]) * mult
        q.y = (m[0, 2] - m[2, 0]) * mult
        q.z = (m[1, 0] - m[0, 1]) * mult
    case 1:
        q.w = (m[2, 1] - m[1, 2]) * mult
        q.x = biggest_val
        q.y = (m[1, 0] + m[0, 1]) * mult
        q.z = (m[0, 2] + m[2, 0]) * mult
    case 2:
        q.w = (m[0, 2] - m[2, 0]) * mult
        q.x = (m[1, 0] + m[0, 1]) * mult
        q.y = biggest_val
        q.z = (m[2, 1] + m[1, 2]) * mult
    case 3:
        q.w = (m[1, 0] - m[0, 1]) * mult
        q.x = (m[0, 2] + m[2, 0]) * mult
        q.y = (m[2, 1] + m[1, 2]) * mult
        q.z = biggest_val
    }
    return
}
quaternion_from_matrix3_f64 :: proc(m: matrix[3, 3]f64) -> (q: Quaternionf64) #no_bounds_check {
    four_x_squared_minus_1 := m[0, 0] - m[1, 1] - m[2, 2]
    four_y_squared_minus_1 := m[1, 1] - m[0, 0] - m[2, 2]
    four_z_squared_minus_1 := m[2, 2] - m[0, 0] - m[1, 1]
    four_w_squared_minus_1 := m[0, 0] + m[1, 1] + m[2, 2]

    biggest_index := 0
    four_biggest_squared_minus_1 := four_w_squared_minus_1
    if four_x_squared_minus_1 > four_biggest_squared_minus_1 {
        four_biggest_squared_minus_1 = four_x_squared_minus_1
        biggest_index = 1
    }
    if four_y_squared_minus_1 > four_biggest_squared_minus_1 {
        four_biggest_squared_minus_1 = four_y_squared_minus_1
        biggest_index = 2
    }
    if four_z_squared_minus_1 > four_biggest_squared_minus_1 {
        four_biggest_squared_minus_1 = four_z_squared_minus_1
        biggest_index = 3
    }

    biggest_val := math.sqrt(four_biggest_squared_minus_1 + 1) * 0.5
    mult := 0.25 / biggest_val

    q = 1
    switch biggest_index {
    case 0:
        q.w = biggest_val
        q.x = (m[2, 1] - m[1, 2]) * mult
        q.y = (m[0, 2] - m[2, 0]) * mult
        q.z = (m[1, 0] - m[0, 1]) * mult
    case 1:
        q.w = (m[2, 1] - m[1, 2]) * mult
        q.x = biggest_val
        q.y = (m[1, 0] + m[0, 1]) * mult
        q.z = (m[0, 2] + m[2, 0]) * mult
    case 2:
        q.w = (m[0, 2] - m[2, 0]) * mult
        q.x = (m[1, 0] + m[0, 1]) * mult
        q.y = biggest_val
        q.z = (m[2, 1] + m[1, 2]) * mult
    case 3:
        q.w = (m[1, 0] - m[0, 1]) * mult
        q.x = (m[0, 2] + m[2, 0]) * mult
        q.y = (m[2, 1] + m[1, 2]) * mult
        q.z = biggest_val
    }
    return
}


quaternion_between_two_vector3_f16 :: proc(from, to: [3]f16) -> (q: Quaternionf16) {
    x := vec_normalize(from)
    y := vec_normalize(to)

    cos_theta := vec_dot(x, y)
    if abs(cos_theta + 1) < 2*F32_EPSILON {
        v := vector3_orthogonal(x)
        q.x = v.x
        q.y = v.y
        q.z = v.z
        q.w = 0
        return
    }
    v := vec3_cross(x, y)
    w := cos_theta + 1
    q.w = w
    q.x = v.x
    q.y = v.y
    q.z = v.z
    return quaternion_normalize(q)
}
quaternion_between_two_vector3_f32 :: proc(from, to: [3]f32) -> (q: Quaternionf32) {
    x := vec_normalize(from)
    y := vec_normalize(to)

    cos_theta := vec_dot(x, y)
    if abs(cos_theta + 1) < 2*F32_EPSILON {
        v := vector3_orthogonal(x)
        q.x = v.x
        q.y = v.y
        q.z = v.z
        q.w = 0
        return
    }
    v := vec3_cross(x, y)
    w := cos_theta + 1
    q.w = w
    q.x = v.x
    q.y = v.y
    q.z = v.z
    return quaternion_normalize(q)
}
quaternion_between_two_vector3_f64 :: proc(from, to: [3]f64) -> (q: Quaternionf64) {
    x := vec_normalize(from)
    y := vec_normalize(to)

    cos_theta := vec_dot(x, y)
    if abs(cos_theta + 1) < 2*F64_EPSILON {
        v := vector3_orthogonal(x)
        q.x = v.x
        q.y = v.y
        q.z = v.z
        q.w = 0
        return
    }
    v := vec3_cross(x, y)
    w := cos_theta + 1
    q.w = w
    q.x = v.x
    q.y = v.y
    q.z = v.z
    return quaternion_normalize(q)
}


matrix2_inverse_transpose_f16 :: proc(m: matrix[2, 2]f16) -> (c: matrix[2, 2]f16) #no_bounds_check {
    d := m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
    id := 1.0/d
    c[0, 0] = +m[1, 1] * id
    c[1, 0] = -m[1, 0] * id
    c[0, 1] = -m[0, 1] * id
    c[1, 1] = +m[0, 0] * id
    return c
}
matrix2_inverse_transpose_f32 :: proc(m: matrix[2, 2]f32) -> (c: matrix[2, 2]f32) #no_bounds_check {
    d := m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
    id := 1.0/d
    c[0, 0] = +m[1, 1] * id
    c[1, 0] = -m[1, 0] * id
    c[0, 1] = -m[0, 1] * id
    c[1, 1] = +m[0, 0] * id
    return c
}
matrix2_inverse_transpose_f64 :: proc(m: matrix[2, 2]f64) -> (c: matrix[2, 2]f64) #no_bounds_check {
    d := m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
    id := 1.0/d
    c[0, 0] = +m[1, 1] * id
    c[1, 0] = -m[1, 0] * id
    c[0, 1] = -m[0, 1] * id
    c[1, 1] = +m[0, 0] * id
    return c
}


matrix2_determinant_f16 :: proc(m: matrix[2, 2]f16) -> f16 #no_bounds_check {
    return m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
}
matrix2_determinant_f32 :: proc(m: matrix[2, 2]f32) -> f32 #no_bounds_check {
    return m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
}
matrix2_determinant_f64 :: proc(m: matrix[2, 2]f64) -> f64 #no_bounds_check {
    return m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
}


matrix2_inverse_f16 :: proc(m: matrix[2, 2]f16) -> (c: matrix[2, 2]f16) #no_bounds_check {
    d := m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
    id := 1.0/d
    c[0, 0] = +m[1, 1] * id
    c[0, 1] = -m[0, 1] * id
    c[1, 0] = -m[1, 0] * id
    c[1, 1] = +m[0, 0] * id
    return c
}
matrix2_inverse_f32 :: proc(m: matrix[2, 2]f32) -> (c: matrix[2, 2]f32) #no_bounds_check {
    d := m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
    id := 1.0/d
    c[0, 0] = +m[1, 1] * id
    c[0, 1] = -m[0, 1] * id
    c[1, 0] = -m[1, 0] * id
    c[1, 1] = +m[0, 0] * id
    return c
}
matrix2_inverse_f64 :: proc(m: matrix[2, 2]f64) -> (c: matrix[2, 2]f64) #no_bounds_check {
    d := m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
    id := 1.0/d
    c[0, 0] = +m[1, 1] * id
    c[0, 1] = -m[0, 1] * id
    c[1, 0] = -m[1, 0] * id
    c[1, 1] = +m[0, 0] * id
    return c
}


matrix2_adjoint_f16 :: proc(m: matrix[2, 2]f16) -> (c: matrix[2, 2]f16) #no_bounds_check {
    c[0, 0] = +m[1, 1]
    c[1, 0] = -m[0, 1]
    c[0, 1] = -m[1, 0]
    c[1, 1] = +m[0, 0]
    return c
}
matrix2_adjoint_f32 :: proc(m: matrix[2, 2]f32) -> (c: matrix[2, 2]f32) #no_bounds_check {
    c[0, 0] = +m[1, 1]
    c[1, 0] = -m[0, 1]
    c[0, 1] = -m[1, 0]
    c[1, 1] = +m[0, 0]
    return c
}
matrix2_adjoint_f64 :: proc(m: matrix[2, 2]f64) -> (c: matrix[2, 2]f64) #no_bounds_check {
    c[0, 0] = +m[1, 1]
    c[1, 0] = -m[0, 1]
    c[0, 1] = -m[1, 0]
    c[1, 1] = +m[0, 0]
    return c
}


matrix2_rotate_f16 :: proc(angle_radians: f16) -> matrix[2, 2]f16 {
    c := math.cos_f16(angle_radians)
    s := math.sin_f16(angle_radians)

    return matrix[2, 2]f16{
        c, -s,
        s,  c,
    }
}
matrix2_rotate_f32 :: proc(angle_radians: f32) -> matrix[2, 2]f32 {
    c := math.cos_f32(angle_radians)
    s := math.sin_f32(angle_radians)

    return matrix[2, 2]f32{
        c, -s,
        s,  c,
    }
}
matrix2_rotate_f64 :: proc(angle_radians: f64) -> matrix[2, 2]f64 {
    c := math.cos_f64(angle_radians)
    s := math.sin_f64(angle_radians)

    return matrix[2, 2]f64{
        c, -s,
        s,  c,
    }
}


matrix3_from_quaternion_f16 :: proc(q: Quaternionf16) -> (m: matrix[3, 3]f16) #no_bounds_check {
    qxx := q.x * q.x
    qyy := q.y * q.y
    qzz := q.z * q.z
    qxz := q.x * q.z
    qxy := q.x * q.y
    qyz := q.y * q.z
    qwx := q.w * q.x
    qwy := q.w * q.y
    qwz := q.w * q.z

    m[0, 0] = 1 - 2 * (qyy + qzz)
    m[1, 0] = 2 * (qxy + qwz)
    m[2, 0] = 2 * (qxz - qwy)

    m[0, 1] = 2 * (qxy - qwz)
    m[1, 1] = 1 - 2 * (qxx + qzz)
    m[2, 1] = 2 * (qyz + qwx)

    m[0, 2] = 2 * (qxz + qwy)
    m[1, 2] = 2 * (qyz - qwx)
    m[2, 2] = 1 - 2 * (qxx + qyy)
    return m
}
matrix3_from_quaternion_f32 :: proc(q: Quaternionf32) -> (m: matrix[3, 3]f32) #no_bounds_check {
    qxx := q.x * q.x
    qyy := q.y * q.y
    qzz := q.z * q.z
    qxz := q.x * q.z
    qxy := q.x * q.y
    qyz := q.y * q.z
    qwx := q.w * q.x
    qwy := q.w * q.y
    qwz := q.w * q.z

    m[0, 0] = 1 - 2 * (qyy + qzz)
    m[1, 0] = 2 * (qxy + qwz)
    m[2, 0] = 2 * (qxz - qwy)

    m[0, 1] = 2 * (qxy - qwz)
    m[1, 1] = 1 - 2 * (qxx + qzz)
    m[2, 1] = 2 * (qyz + qwx)

    m[0, 2] = 2 * (qxz + qwy)
    m[1, 2] = 2 * (qyz - qwx)
    m[2, 2] = 1 - 2 * (qxx + qyy)
    return m
}
matrix3_from_quaternion_f64 :: proc(q: Quaternionf64) -> (m: matrix[3, 3]f64) #no_bounds_check {
    qxx := q.x * q.x
    qyy := q.y * q.y
    qzz := q.z * q.z
    qxz := q.x * q.z
    qxy := q.x * q.y
    qyz := q.y * q.z
    qwx := q.w * q.x
    qwy := q.w * q.y
    qwz := q.w * q.z

    m[0, 0] = 1 - 2 * (qyy + qzz)
    m[1, 0] = 2 * (qxy + qwz)
    m[2, 0] = 2 * (qxz - qwy)

    m[0, 1] = 2 * (qxy - qwz)
    m[1, 1] = 1 - 2 * (qxx + qzz)
    m[2, 1] = 2 * (qyz + qwx)

    m[0, 2] = 2 * (qxz + qwy)
    m[1, 2] = 2 * (qyz - qwx)
    m[2, 2] = 1 - 2 * (qxx + qyy)
    return m
}


matrix3_inverse_f16 :: proc(m: matrix[3, 3]f16) -> matrix[3, 3]f16 {
    return transpose(matrix3_inverse_transpose_f16(m))
}
matrix3_inverse_f32 :: proc(m: matrix[3, 3]f32) -> matrix[3, 3]f32 {
    return transpose(matrix3_inverse_transpose_f32(m))
}
matrix3_inverse_f64 :: proc(m: matrix[3, 3]f64) -> matrix[3, 3]f64 {
    return transpose(matrix3_inverse_transpose_f64(m))
}


matrix3_determinant_f16 :: proc(m: matrix[3, 3]f16) -> f16 #no_bounds_check {
    a := +m[0, 0] * (m[1, 1] * m[2, 2] - m[1, 2] * m[2, 1])
    b := -m[0, 1] * (m[1, 0] * m[2, 2] - m[1, 2] * m[2, 0])
    c := +m[0, 2] * (m[1, 0] * m[2, 1] - m[1, 1] * m[2, 0])
    return a + b + c
}
matrix3_determinant_f32 :: proc(m: matrix[3, 3]f32) -> f32 #no_bounds_check {
    a := +m[0, 0] * (m[1, 1] * m[2, 2] - m[1, 2] * m[2, 1])
    b := -m[0, 1] * (m[1, 0] * m[2, 2] - m[1, 2] * m[2, 0])
    c := +m[0, 2] * (m[1, 0] * m[2, 1] - m[1, 1] * m[2, 0])
    return a + b + c
}
matrix3_determinant_f64 :: proc(m: matrix[3, 3]f64) -> f64 #no_bounds_check {
    a := +m[0, 0] * (m[1, 1] * m[2, 2] - m[1, 2] * m[2, 1])
    b := -m[0, 1] * (m[1, 0] * m[2, 2] - m[1, 2] * m[2, 0])
    c := +m[0, 2] * (m[1, 0] * m[2, 1] - m[1, 1] * m[2, 0])
    return a + b + c
}


matrix3_adjoint_f16 :: proc(m: matrix[3, 3]f16) -> (adjoint: matrix[3, 3]f16) #no_bounds_check {
    adjoint[0, 0] = +(m[1, 1] * m[2, 2] - m[2, 1] * m[1, 2])
    adjoint[0, 1] = -(m[1, 0] * m[2, 2] - m[2, 0] * m[1, 2])
    adjoint[0, 2] = +(m[1, 0] * m[2, 1] - m[2, 0] * m[1, 1])
    adjoint[1, 0] = -(m[0, 1] * m[2, 2] - m[2, 1] * m[0, 2])
    adjoint[1, 1] = +(m[0, 0] * m[2, 2] - m[2, 0] * m[0, 2])
    adjoint[1, 2] = -(m[0, 0] * m[2, 1] - m[2, 0] * m[0, 1])
    adjoint[2, 0] = +(m[0, 1] * m[1, 2] - m[1, 1] * m[0, 2])
    adjoint[2, 1] = -(m[0, 0] * m[1, 2] - m[1, 0] * m[0, 2])
    adjoint[2, 2] = +(m[0, 0] * m[1, 1] - m[1, 0] * m[0, 1])
    return adjoint
}
matrix3_adjoint_f32 :: proc(m: matrix[3, 3]f32) -> (adjoint: matrix[3, 3]f32) #no_bounds_check {
    adjoint[0, 0] = +(m[1, 1] * m[2, 2] - m[2, 1] * m[1, 2])
    adjoint[0, 1] = -(m[1, 0] * m[2, 2] - m[2, 0] * m[1, 2])
    adjoint[0, 2] = +(m[1, 0] * m[2, 1] - m[2, 0] * m[1, 1])
    adjoint[1, 0] = -(m[0, 1] * m[2, 2] - m[2, 1] * m[0, 2])
    adjoint[1, 1] = +(m[0, 0] * m[2, 2] - m[2, 0] * m[0, 2])
    adjoint[1, 2] = -(m[0, 0] * m[2, 1] - m[2, 0] * m[0, 1])
    adjoint[2, 0] = +(m[0, 1] * m[1, 2] - m[1, 1] * m[0, 2])
    adjoint[2, 1] = -(m[0, 0] * m[1, 2] - m[1, 0] * m[0, 2])
    adjoint[2, 2] = +(m[0, 0] * m[1, 1] - m[1, 0] * m[0, 1])
    return adjoint
}
matrix3_adjoint_f64 :: proc(m: matrix[3, 3]f64) -> (adjoint: matrix[3, 3]f64) #no_bounds_check {
    adjoint[0, 0] = +(m[1, 1] * m[2, 2] - m[2, 1] * m[1, 2])
    adjoint[0, 1] = -(m[1, 0] * m[2, 2] - m[2, 0] * m[1, 2])
    adjoint[0, 2] = +(m[1, 0] * m[2, 1] - m[2, 0] * m[1, 1])
    adjoint[1, 0] = -(m[0, 1] * m[2, 2] - m[2, 1] * m[0, 2])
    adjoint[1, 1] = +(m[0, 0] * m[2, 2] - m[2, 0] * m[0, 2])
    adjoint[1, 2] = -(m[0, 0] * m[2, 1] - m[2, 0] * m[0, 1])
    adjoint[2, 0] = +(m[0, 1] * m[1, 2] - m[1, 1] * m[0, 2])
    adjoint[2, 1] = -(m[0, 0] * m[1, 2] - m[1, 0] * m[0, 2])
    adjoint[2, 2] = +(m[0, 0] * m[1, 1] - m[1, 0] * m[0, 1])
    return adjoint
}


matrix3_inverse_transpose_f16 :: proc(m: matrix[3, 3]f16) -> (p: matrix[3, 3]f16) {
    return matrix3_inverse_transpose_f16(m)
}
matrix3_inverse_transpose_f32 :: proc(m: matrix[3, 3]f32) -> (p: matrix[3, 3]f32) {
    return matrix3_inverse_transpose_f32(m)
}
matrix3_inverse_transpose_f64 :: proc(m: matrix[3, 3]f64) -> (p: matrix[3, 3]f64) {
    return matrix3_inverse_transpose_f64(m)
}


matrix3_scale_f16 :: proc(s: [3]f16) -> (m: matrix[3, 3]f16) #no_bounds_check {
    m[0, 0] = s[0]
    m[1, 1] = s[1]
    m[2, 2] = s[2]
    return m
}
matrix3_scale_f32 :: proc(s: [3]f32) -> (m: matrix[3, 3]f32) #no_bounds_check {
    m[0, 0] = s[0]
    m[1, 1] = s[1]
    m[2, 2] = s[2]
    return m
}
matrix3_scale_f64 :: proc(s: [3]f64) -> (m: matrix[3, 3]f64) #no_bounds_check {
    m[0, 0] = s[0]
    m[1, 1] = s[1]
    m[2, 2] = s[2]
    return m
}


// Implementation of Rodrigues’ rotation formula.
matrix3_rotate_f16 :: proc(angle_radians: f16, v: [3]f16) -> (rot: matrix[3, 3]f16) #no_bounds_check {
    c := math.cos_f16(angle_radians)
    s := math.sin_f16(angle_radians)

    a := vec_normalize(v)
    t := a * (1-c)

    rot[0, 0] = c + t[0]*a[0]
    rot[1, 0] = 0 + t[0]*a[1] + s*a[2]
    rot[2, 0] = 0 + t[0]*a[2] - s*a[1]

    rot[0, 1] = 0 + t[1]*a[0] - s*a[2]
    rot[1, 1] = c + t[1]*a[1]
    rot[2, 1] = 0 + t[1]*a[2] + s*a[0]

    rot[0, 2] = 0 + t[2]*a[0] + s*a[1]
    rot[1, 2] = 0 + t[2]*a[1] - s*a[0]
    rot[2, 2] = c + t[2]*a[2]

    return rot
}
matrix3_rotate_f32 :: proc(angle_radians: f32, v: [3]f32) -> (rot: matrix[3, 3]f32) #no_bounds_check {
    c := math.cos_f32(angle_radians)
    s := math.sin_f32(angle_radians)

    a := vec_normalize(v)
    t := a * (1-c)

    rot[0, 0] = c + t[0]*a[0]
    rot[1, 0] = 0 + t[0]*a[1] + s*a[2]
    rot[2, 0] = 0 + t[0]*a[2] - s*a[1]

    rot[0, 1] = 0 + t[1]*a[0] - s*a[2]
    rot[1, 1] = c + t[1]*a[1]
    rot[2, 1] = 0 + t[1]*a[2] + s*a[0]

    rot[0, 2] = 0 + t[2]*a[0] + s*a[1]
    rot[1, 2] = 0 + t[2]*a[1] - s*a[0]
    rot[2, 2] = c + t[2]*a[2]

    return rot
}
matrix3_rotate_f64 :: proc(angle_radians: f64, v: [3]f64) -> (rot: matrix[3, 3]f64) {
    c := math.cos_f64(angle_radians)
    s := math.sin_f64(angle_radians)

    a := vec_normalize(v)
    t := a * (1-c)

    rot[0, 0] = c + t[0]*a[0]
    rot[1, 0] = 0 + t[0]*a[1] + s*a[2]
    rot[2, 0] = 0 + t[0]*a[2] - s*a[1]

    rot[0, 1] = 0 + t[1]*a[0] - s*a[2]
    rot[1, 1] = c + t[1]*a[1]
    rot[2, 1] = 0 + t[1]*a[2] + s*a[0]

    rot[0, 2] = 0 + t[2]*a[0] + s*a[1]
    rot[1, 2] = 0 + t[2]*a[1] - s*a[0]
    rot[2, 2] = c + t[2]*a[2]

    return rot
}


matrix3_look_at_f16 :: proc(eye, centre, up: [3]f16) -> matrix[3, 3]f16 {
    f := vec_normalize(centre - eye)
    s := vec_normalize(vec3_cross(f, up))
    u := vec3_cross(s, f)
    return matrix[3, 3]f16{
        +s.x, +s.y, +s.z,
        +u.x, +u.y, +u.z,
        -f.x, -f.y, -f.z,
    }
}
matrix3_look_at_f32 :: proc(eye, centre, up: [3]f32) -> matrix[3, 3]f32 {
    f := vec_normalize(centre - eye)
    s := vec_normalize(vec3_cross(f, up))
    u := vec3_cross(s, f)
    return matrix[3, 3]f32{
        +s.x, +s.y, +s.z,
        +u.x, +u.y, +u.z,
        -f.x, -f.y, -f.z,
    }
}
matrix3_look_at_f64 :: proc(eye, centre, up: [3]f64) -> matrix[3, 3]f64 {
    f := vec_normalize(centre - eye)
    s := vec_normalize(vec3_cross(f, up))
    u := vec3_cross(s, f)
    return matrix[3, 3]f64{
        +s.x, +s.y, +s.z,
        +u.x, +u.y, +u.z,
        -f.x, -f.y, -f.z,
    }
}


matrix4_from_quaternion_f16 :: proc(q: Quaternionf16) -> (m: matrix[4, 4]f16) #no_bounds_check {
    qxx := q.x * q.x
    qyy := q.y * q.y
    qzz := q.z * q.z
    qxz := q.x * q.z
    qxy := q.x * q.y
    qyz := q.y * q.z
    qwx := q.w * q.x
    qwy := q.w * q.y
    qwz := q.w * q.z

    m[0, 0] = 1 - 2 * (qyy + qzz)
    m[1, 0] = 2 * (qxy + qwz)
    m[2, 0] = 2 * (qxz - qwy)

    m[0, 1] = 2 * (qxy - qwz)
    m[1, 1] = 1 - 2 * (qxx + qzz)
    m[2, 1] = 2 * (qyz + qwx)

    m[0, 2] = 2 * (qxz + qwy)
    m[1, 2] = 2 * (qyz - qwx)
    m[2, 2] = 1 - 2 * (qxx + qyy)

    m[3, 3] = 1

    return m
}
matrix4_from_quaternion_f32 :: proc(q: Quaternionf32) -> (m: matrix[4, 4]f32) #no_bounds_check {
    qxx := q.x * q.x
    qyy := q.y * q.y
    qzz := q.z * q.z
    qxz := q.x * q.z
    qxy := q.x * q.y
    qyz := q.y * q.z
    qwx := q.w * q.x
    qwy := q.w * q.y
    qwz := q.w * q.z

    m[0, 0] = 1 - 2 * (qyy + qzz)
    m[1, 0] = 2 * (qxy + qwz)
    m[2, 0] = 2 * (qxz - qwy)

    m[0, 1] = 2 * (qxy - qwz)
    m[1, 1] = 1 - 2 * (qxx + qzz)
    m[2, 1] = 2 * (qyz + qwx)

    m[0, 2] = 2 * (qxz + qwy)
    m[1, 2] = 2 * (qyz - qwx)
    m[2, 2] = 1 - 2 * (qxx + qyy)

    m[3, 3] = 1

    return m
}
matrix4_from_quaternion_f64 :: proc(q: Quaternionf64) -> (m: matrix[4, 4]f64) #no_bounds_check {
    qxx := q.x * q.x
    qyy := q.y * q.y
    qzz := q.z * q.z
    qxz := q.x * q.z
    qxy := q.x * q.y
    qyz := q.y * q.z
    qwx := q.w * q.x
    qwy := q.w * q.y
    qwz := q.w * q.z

    m[0, 0] = 1 - 2 * (qyy + qzz)
    m[1, 0] = 2 * (qxy + qwz)
    m[2, 0] = 2 * (qxz - qwy)

    m[0, 1] = 2 * (qxy - qwz)
    m[1, 1] = 1 - 2 * (qxx + qzz)
    m[2, 1] = 2 * (qyz + qwx)

    m[0, 2] = 2 * (qxz + qwy)
    m[1, 2] = 2 * (qyz - qwx)
    m[2, 2] = 1 - 2 * (qxx + qyy)

    m[3, 3] = 1

    return m
}


matrix4_from_trs_f16 :: proc(t: [3]f16, r: Quaternionf16, s: [3]f16) -> matrix[4, 4]f16 {
    translation := matrix4_translate_f16(t)
    rotation := matrix4_from_quaternion_f16(r)
    scale := matrix4_scale_f16(s)
    return matrix_mul(translation, matrix_mul(rotation, scale))
}
matrix4_from_trs_f32 :: proc(t: [3]f32, r: Quaternionf32, s: [3]f32) -> matrix[4, 4]f32 {
    translation := matrix4_translate_f32(t)
    rotation := matrix4_from_quaternion_f32(r)
    scale := matrix4_scale_f32(s)
    return matrix_mul(translation, matrix_mul(rotation, scale))
}
matrix4_from_trs_f64 :: proc(t: [3]f64, r: Quaternionf64, s: [3]f64) -> matrix[4, 4]f64 {
    translation := matrix4_translate_f64(t)
    rotation := matrix4_from_quaternion_f64(r)
    scale := matrix4_scale_f64(s)
    return matrix_mul(translation, matrix_mul(rotation, scale))
}


matrix4_inverse_f16 :: proc(m: matrix[4, 4]f16) -> matrix[4, 4]f16 {
    return transpose(matrix4_inverse_transpose_f16(m))
}
matrix4_inverse_f32 :: proc(m: matrix[4, 4]f32) -> matrix[4, 4]f32 {
    return transpose(matrix4_inverse_transpose_f32(m))
}
matrix4_inverse_f64 :: proc(m: matrix[4, 4]f64) -> matrix[4, 4]f64 {
    return transpose(matrix4_inverse_transpose_f64(m))
}


matrix4_minor_f16 :: proc(m: matrix[4, 4]f16, c, r: int) -> f16 #no_bounds_check {
    cut_down: matrix[3, 3]f16
    for i in 0..<3 {
        col := i if i < c else i+1
        for j in 0..<3 {
            row := j if j < r else j+1
            cut_down[i][j] = m[col][row]
        }
    }
    return matrix3_determinant_f16(cut_down)
}
matrix4_minor_f32 :: proc(m: matrix[4, 4]f32, c, r: int) -> f32 #no_bounds_check {
    cut_down: matrix[3, 3]f32
    for i in 0..<3 {
        col := i if i < c else i+1
        for j in 0..<3 {
            row := j if j < r else j+1
            cut_down[i][j] = m[col][row]
        }
    }
    return matrix3_determinant_f32(cut_down)
}
matrix4_minor_f64 :: proc(m: matrix[4, 4]f64, c, r: int) -> f64 #no_bounds_check {
    cut_down: matrix[3, 3]f64
    for i in 0..<3 {
        col := i if i < c else i+1
        for j in 0..<3 {
            row := j if j < r else j+1
            cut_down[i][j] = m[col][row]
        }
    }
    return matrix3_determinant_f64(cut_down)
}


matrix4_cofactor_f16 :: proc(m: matrix[4, 4]f16, c, r: int) -> f16 {
    sign, minor: f16
    sign = 1 if (c + r) % 2 == 0 else -1
    minor = matrix4_minor_f16(m, c, r)
    return sign * minor
}
matrix4_cofactor_f32 :: proc(m: matrix[4, 4]f32, c, r: int) -> f32 {
    sign, minor: f32
    sign = 1 if (c + r) % 2 == 0 else -1
    minor = matrix4_minor_f32(m, c, r)
    return sign * minor
}
matrix4_cofactor_f64 :: proc(m: matrix[4, 4]f64, c, r: int) -> f64 {
    sign, minor: f64
    sign = 1 if (c + r) % 2 == 0 else -1
    minor = matrix4_minor_f64(m, c, r)
    return sign * minor
}


matrix4_adjoint_f16 :: proc(m: matrix[4, 4]f16) -> (adjoint: matrix[4, 4]f16) #no_bounds_check {
    for i in 0..<4 {
        for j in 0..<4 {
            adjoint[i][j] = matrix4_cofactor_f16(m, i, j)
        }
    }
    return
}
matrix4_adjoint_f32 :: proc(m: matrix[4, 4]f32) -> (adjoint: matrix[4, 4]f32) #no_bounds_check {
    for i in 0..<4 {
        for j in 0..<4 {
            adjoint[i][j] = matrix4_cofactor_f32(m, i, j)
        }
    }
    return
}
matrix4_adjoint_f64 :: proc(m: matrix[4, 4]f64) -> (adjoint: matrix[4, 4]f64) #no_bounds_check {
    for i in 0..<4 {
        for j in 0..<4 {
            adjoint[i][j] = matrix4_cofactor_f64(m, i, j)
        }
    }
    return
}


matrix4_determinant_f16 :: proc(m: matrix[4, 4]f16) -> (determinant: f16) #no_bounds_check {
    adjoint := matrix4_adjoint_f16(m)
    for i in 0..<4 {
        determinant += m[i][0] * adjoint[i][0]
    }
    return
}
matrix4_determinant_f32 :: proc(m: matrix[4, 4]f32) -> (determinant: f32) #no_bounds_check {
    adjoint := matrix4_adjoint_f32(m)
    for i in 0..<4 {
        determinant += m[i][0] * adjoint[i][0]
    }
    return
}
matrix4_determinant_f64 :: proc(m: matrix[4, 4]f64) -> (determinant: f64) #no_bounds_check {
    adjoint := matrix4_adjoint_f64(m)
    for i in 0..<4 {
        determinant += m[i][0] * adjoint[i][0]
    }
    return
}


matrix4_inverse_transpose_f16 :: proc(m: matrix[4, 4]f16) -> (inverse_transpose: matrix[4, 4]f16) #no_bounds_check {
    adjoint := matrix4_adjoint_f16(m)
    determinant: f16 = 0
    for i in 0..<4 {
        determinant += m[i][0] * adjoint[i][0]
    }
    inv_determinant := 1.0 / determinant
    for i in 0..<4 {
        for j in 0..<4 {
            inverse_transpose[i][j] = adjoint[i][j] * inv_determinant
        }
    }
    return
}
matrix4_inverse_transpose_f32 :: proc(m: matrix[4, 4]f32) -> (inverse_transpose: matrix[4, 4]f32) #no_bounds_check {
    adjoint := matrix4_adjoint_f32(m)
    determinant: f32 = 0
    for i in 0..<4 {
        determinant += m[i][0] * adjoint[i][0]
    }
    inv_determinant := 1.0 / determinant
    for i in 0..<4 {
        for j in 0..<4 {
            inverse_transpose[i][j] = adjoint[i][j] * inv_determinant
        }
    }
    return
}
matrix4_inverse_transpose_f64 :: proc(m: matrix[4, 4]f64) -> (inverse_transpose: matrix[4, 4]f64) #no_bounds_check {
    adjoint := matrix4_adjoint_f64(m)
    determinant: f64 = 0
    for i in 0..<4 {
        determinant += m[i][0] * adjoint[i][0]
    }
    inv_determinant := 1.0 / determinant
    for i in 0..<4 {
        for j in 0..<4 {
            inverse_transpose[i][j] = adjoint[i][j] * inv_determinant
        }
    }
    return
}


matrix4_translate_f16 :: proc(v: [3]f16) -> matrix[4, 4]f16 #no_bounds_check {
    m := MATRIX4F16_IDENTITY
    m[3][0] = v[0]
    m[3][1] = v[1]
    m[3][2] = v[2]
    return m
}
matrix4_translate_f32 :: proc(v: [3]f32) -> matrix[4, 4]f32 #no_bounds_check {
    m := MATRIX4F32_IDENTITY
    m[3][0] = v[0]
    m[3][1] = v[1]
    m[3][2] = v[2]
    return m
}
matrix4_translate_f64 :: proc(v: [3]f64) -> matrix[4, 4]f64 #no_bounds_check {
    m := MATRIX4F64_IDENTITY
    m[3][0] = v[0]
    m[3][1] = v[1]
    m[3][2] = v[2]
    return m
}


matrix4_rotate_f16 :: proc(angle_radians: f16, v: [3]f16) -> matrix[4, 4]f16 #no_bounds_check {
    c := math.cos_f16(angle_radians)
    s := math.sin_f16(angle_radians)

    a := vec_normalize(v)
    t := a * (1-c)

    rot := MATRIX4F16_IDENTITY

    rot[0][0] = c + t[0]*a[0]
    rot[0][1] = 0 + t[0]*a[1] + s*a[2]
    rot[0][2] = 0 + t[0]*a[2] - s*a[1]
    rot[0][3] = 0

    rot[1][0] = 0 + t[1]*a[0] - s*a[2]
    rot[1][1] = c + t[1]*a[1]
    rot[1][2] = 0 + t[1]*a[2] + s*a[0]
    rot[1][3] = 0

    rot[2][0] = 0 + t[2]*a[0] + s*a[1]
    rot[2][1] = 0 + t[2]*a[1] - s*a[0]
    rot[2][2] = c + t[2]*a[2]
    rot[2][3] = 0

    return rot
}
matrix4_rotate_f32 :: proc(angle_radians: f32, v: [3]f32) -> matrix[4, 4]f32 #no_bounds_check {
    c := math.cos_f32(angle_radians)
    s := math.sin_f32(angle_radians)

    a := vec_normalize(v)
    t := a * (1-c)

    rot := MATRIX4F32_IDENTITY

    rot[0][0] = c + t[0]*a[0]
    rot[0][1] = 0 + t[0]*a[1] + s*a[2]
    rot[0][2] = 0 + t[0]*a[2] - s*a[1]
    rot[0][3] = 0

    rot[1][0] = 0 + t[1]*a[0] - s*a[2]
    rot[1][1] = c + t[1]*a[1]
    rot[1][2] = 0 + t[1]*a[2] + s*a[0]
    rot[1][3] = 0

    rot[2][0] = 0 + t[2]*a[0] + s*a[1]
    rot[2][1] = 0 + t[2]*a[1] - s*a[0]
    rot[2][2] = c + t[2]*a[2]
    rot[2][3] = 0

    return rot
}
matrix4_rotate_f64 :: proc(angle_radians: f64, v: [3]f64) -> matrix[4, 4]f64 #no_bounds_check {
    c := math.cos_f64(angle_radians)
    s := math.sin_f64(angle_radians)

    a := vec_normalize(v)
    t := a * (1-c)

    rot := MATRIX4F64_IDENTITY

    rot[0][0] = c + t[0]*a[0]
    rot[0][1] = 0 + t[0]*a[1] + s*a[2]
    rot[0][2] = 0 + t[0]*a[2] - s*a[1]
    rot[0][3] = 0

    rot[1][0] = 0 + t[1]*a[0] - s*a[2]
    rot[1][1] = c + t[1]*a[1]
    rot[1][2] = 0 + t[1]*a[2] + s*a[0]
    rot[1][3] = 0

    rot[2][0] = 0 + t[2]*a[0] + s*a[1]
    rot[2][1] = 0 + t[2]*a[1] - s*a[0]
    rot[2][2] = c + t[2]*a[2]
    rot[2][3] = 0

    return rot
}


matrix4_scale_f16 :: proc(v: [3]f16) -> (m: matrix[4, 4]f16) #no_bounds_check {
    m[0][0] = v[0]
    m[1][1] = v[1]
    m[2][2] = v[2]
    m[3][3] = 1
    return
}
matrix4_scale_f32 :: proc(v: [3]f32) -> (m: matrix[4, 4]f32) #no_bounds_check {
    m[0][0] = v[0]
    m[1][1] = v[1]
    m[2][2] = v[2]
    m[3][3] = 1
    return
}
matrix4_scale_f64 :: proc(v: [3]f64) -> (m: matrix[4, 4]f64) #no_bounds_check {
    m[0][0] = v[0]
    m[1][1] = v[1]
    m[2][2] = v[2]
    m[3][3] = 1
    return
}


matrix4_look_at_f16 :: proc(eye, centre, up: [3]f16, flip_z_axis := true) -> (m: matrix[4, 4]f16) {
    f := vec_normalize(centre - eye)
    s := vec_normalize(vec3_cross(f, up))
    u := vec3_cross(s, f)

    fe := vec_dot(f, eye)

    return {
        +s.x, +s.y, +s.z, -vec_dot(s, eye),
        +u.x, +u.y, +u.z, -vec_dot(u, eye),
        -f.x, -f.y, -f.z, +fe if flip_z_axis else -fe,
           0,    0,    0, 1,
    }
}
matrix4_look_at_f32 :: proc(eye, centre, up: [3]f32, flip_z_axis := true) -> (m: matrix[4, 4]f32) {
    f := vec_normalize(centre - eye)
    s := vec_normalize(vec3_cross(f, up))
    u := vec3_cross(s, f)

    fe := vec_dot(f, eye)

    return {
        +s.x, +s.y, +s.z, -vec_dot(s, eye),
        +u.x, +u.y, +u.z, -vec_dot(u, eye),
        -f.x, -f.y, -f.z, +fe if flip_z_axis else -fe,
           0,    0,    0, 1,
    }
}
matrix4_look_at_f64 :: proc(eye, centre, up: [3]f64, flip_z_axis := true) -> (m: matrix[4, 4]f64) {
    f := vec_normalize(centre - eye)
    s := vec_normalize(vec3_cross(f, up))
    u := vec3_cross(s, f)

    fe := vec_dot(f, eye)

    return {
        +s.x, +s.y, +s.z, -vec_dot(s, eye),
        +u.x, +u.y, +u.z, -vec_dot(u, eye),
        -f.x, -f.y, -f.z, +fe if flip_z_axis else -fe,
           0,    0,    0, 1,
    }
}


matrix4_look_at_from_fru_f16 :: proc(eye, f, r, u: [3]f16, flip_z_axis := true) -> (m: matrix[4, 4]f16) {
    f, s, u := f, r, u
    f = vec_normalize(f)
    s = vec_normalize(s)
    u = vec_normalize(u)
    fe := vec_dot(f, eye)

    return {
        +s.x, +s.y, +s.z, -vec_dot(s, eye),
        +u.x, +u.y, +u.z, -vec_dot(u, eye),
        -f.x, -f.y, -f.z, +fe if flip_z_axis else -fe,
           0,    0,    0, 1,
    }
}
matrix4_look_at_from_fru_f32 :: proc(eye, f, r, u: [3]f32, flip_z_axis := true) -> (m: matrix[4, 4]f32) {
    f, s, u := f, r, u
    f = vec_normalize(f)
    s = vec_normalize(s)
    u = vec_normalize(u)
    fe := vec_dot(f, eye)

    return {
        +s.x, +s.y, +s.z, -vec_dot(s, eye),
        +u.x, +u.y, +u.z, -vec_dot(u, eye),
        -f.x, -f.y, -f.z, +fe if flip_z_axis else -fe,
           0,    0,    0, 1,
    }
}
matrix4_look_at_from_fru_f64 :: proc(eye, f, r, u: [3]f64, flip_z_axis := true) -> (m: matrix[4, 4]f64) {
    f, s, u := f, r, u
    f = vec_normalize(f)
    s = vec_normalize(s)
    u = vec_normalize(u)
    fe := vec_dot(f, eye)

    return {
        +s.x, +s.y, +s.z, -vec_dot(s, eye),
        +u.x, +u.y, +u.z, -vec_dot(u, eye),
        -f.x, -f.y, -f.z, +fe if flip_z_axis else -fe,
           0,    0,    0, 1,
    }
}


matrix4_perspective_f16 :: proc(fovy, aspect, near, far: f16, flip_z_axis := true) -> (m: matrix[4, 4]f16) #no_bounds_check {
    tan_half_fovy := math.tan_f16(0.5 * fovy)
    m[0, 0] = 1 / (aspect*tan_half_fovy)
    m[1, 1] = 1 / (tan_half_fovy)
    m[2, 2] = +(far + near) / (far - near)
    m[3, 2] = +1
    m[2, 3] = -2*far*near / (far - near)

    if flip_z_axis {
        m[2] = -m[2]
    }

    return
}
matrix4_perspective_f32 :: proc(fovy, aspect, near, far: f32, flip_z_axis := true) -> (m: matrix[4, 4]f32) #no_bounds_check {
    tan_half_fovy := math.tan_f32(0.5 * fovy)
    m[0, 0] = 1 / (aspect*tan_half_fovy)
    m[1, 1] = 1 / (tan_half_fovy)
    m[2, 2] = +(far + near) / (far - near)
    m[3, 2] = +1
    m[2, 3] = -2*far*near / (far - near)

    if flip_z_axis {
        m[2] = -m[2]
    }

    return
}
matrix4_perspective_f64 :: proc(fovy, aspect, near, far: f64, flip_z_axis := true) -> (m: matrix[4, 4]f64) #no_bounds_check {
    tan_half_fovy := math.tan_f64(0.5 * fovy)
    m[0, 0] = 1 / (aspect*tan_half_fovy)
    m[1, 1] = 1 / (tan_half_fovy)
    m[2, 2] = +(far + near) / (far - near)
    m[3, 2] = +1
    m[2, 3] = -2*far*near / (far - near)

    if flip_z_axis {
        m[2] = -m[2]
    }

    return
}


matrix_ortho3d_f16 :: proc(left, right, bottom, top, near, far: f16, flip_z_axis := true) -> (m: matrix[4, 4]f16) #no_bounds_check {
    m[0, 0] = +2 / (right - left)
    m[1, 1] = +2 / (top - bottom)
    m[2, 2] = +2 / (far - near)
    m[0, 3] = -(right + left)   / (right - left)
    m[1, 3] = -(top   + bottom) / (top - bottom)
    m[2, 3] = -(far + near) / (far- near)
    m[3, 3] = 1

    if flip_z_axis {
        m[2] = -m[2]
    }

    return
}
matrix_ortho3d_f32 :: proc(left, right, bottom, top, near, far: f32, flip_z_axis := true) -> (m: matrix[4, 4]f32) #no_bounds_check {
    m[0, 0] = +2 / (right - left)
    m[1, 1] = +2 / (top - bottom)
    m[2, 2] = +2 / (far - near)
    m[0, 3] = -(right + left)   / (right - left)
    m[1, 3] = -(top   + bottom) / (top - bottom)
    m[2, 3] = -(far + near) / (far- near)
    m[3, 3] = 1

    if flip_z_axis {
        m[2] = -m[2]
    }

    return
}
matrix_ortho3d_f64 :: proc(left, right, bottom, top, near, far: f64, flip_z_axis := true) -> (m: matrix[4, 4]f64) #no_bounds_check {
    m[0, 0] = +2 / (right - left)
    m[1, 1] = +2 / (top - bottom)
    m[2, 2] = +2 / (far - near)
    m[0, 3] = -(right + left)   / (right - left)
    m[1, 3] = -(top   + bottom) / (top - bottom)
    m[2, 3] = -(far + near) / (far- near)
    m[3, 3] = 1

    if flip_z_axis {
        m[2] = -m[2]
    }

    return
}


matrix4_infinite_perspective_f16 :: proc(fovy, aspect, near: f16, flip_z_axis := true) -> (m: matrix[4, 4]f16) #no_bounds_check {
    tan_half_fovy := math.tan_f16(0.5 * fovy)
    m[0, 0] = 1 / (aspect*tan_half_fovy)
    m[1, 1] = 1 / (tan_half_fovy)
    m[2, 2] = +1
    m[3, 2] = +1
    m[2, 3] = -2*near

    if flip_z_axis {
        m[2] = -m[2]
    }

    return
}
matrix4_infinite_perspective_f32 :: proc(fovy, aspect, near: f32, flip_z_axis := true) -> (m: matrix[4, 4]f32) #no_bounds_check {
    tan_half_fovy := math.tan_f32(0.5 * fovy)
    m[0, 0] = 1 / (aspect*tan_half_fovy)
    m[1, 1] = 1 / (tan_half_fovy)
    m[2, 2] = +1
    m[3, 2] = +1
    m[2, 3] = -2*near

    if flip_z_axis {
        m[2] = -m[2]
    }

    return
}
matrix4_infinite_perspective_f64 :: proc(fovy, aspect, near: f64, flip_z_axis := true) -> (m: matrix[4, 4]f64) #no_bounds_check {
    tan_half_fovy := math.tan_f64(0.5 * fovy)
    m[0, 0] = 1 / (aspect*tan_half_fovy)
    m[1, 1] = 1 / (tan_half_fovy)
    m[2, 2] = +1
    m[3, 2] = +1
    m[2, 3] = -2*near

    if flip_z_axis {
        m[2] = -m[2]
    }

    return
}


matrix2_from_scalar_f16 :: proc(f: f16) -> (m: matrix[2, 2]f16) #no_bounds_check {
    m[0, 0], m[1, 0] = f, 0
    m[0, 1], m[1, 1] = 0, f
    return
}
matrix2_from_scalar_f32 :: proc(f: f32) -> (m: matrix[2, 2]f32) #no_bounds_check {
    m[0, 0], m[1, 0] = f, 0
    m[0, 1], m[1, 1] = 0, f
    return
}
matrix2_from_scalar_f64 :: proc(f: f64) -> (m: matrix[2, 2]f64) #no_bounds_check {
    m[0, 0], m[1, 0] = f, 0
    m[0, 1], m[1, 1] = 0, f
    return
}


matrix3_from_scalar_f16 :: proc(f: f16) -> (m: matrix[3, 3]f16) #no_bounds_check {
    m[0, 0], m[1, 0], m[2, 0] = f, 0, 0
    m[0, 1], m[1, 1], m[2, 1] = 0, f, 0
    m[0, 2], m[1, 2], m[2, 2] = 0, 0, f
    return
}
matrix3_from_scalar_f32 :: proc(f: f32) -> (m: matrix[3, 3]f32) #no_bounds_check {
    m[0, 0], m[1, 0], m[2, 0] = f, 0, 0
    m[0, 1], m[1, 1], m[2, 1] = 0, f, 0
    m[0, 2], m[1, 2], m[2, 2] = 0, 0, f
    return
}
matrix3_from_scalar_f64 :: proc(f: f64) -> (m: matrix[3, 3]f64) #no_bounds_check {
    m[0, 0], m[1, 0], m[2, 0] = f, 0, 0
    m[0, 1], m[1, 1], m[2, 1] = 0, f, 0
    m[0, 2], m[1, 2], m[2, 2] = 0, 0, f
    return
}


matrix4_from_scalar_f16 :: proc(f: f16) -> (m: matrix[4, 4]f16) #no_bounds_check {
    m[0, 0], m[1, 0], m[2, 0], m[3, 0] = f, 0, 0, 0
    m[0, 1], m[1, 1], m[2, 1], m[3, 1] = 0, f, 0, 0
    m[0, 2], m[1, 2], m[2, 2], m[3, 2] = 0, 0, f, 0
    m[0, 3], m[1, 3], m[2, 3], m[3, 3] = 0, 0, 0, f
    return
}
matrix4_from_scalar_f32 :: proc(f: f32) -> (m: matrix[4, 4]f32) #no_bounds_check {
    m[0, 0], m[1, 0], m[2, 0], m[3, 0] = f, 0, 0, 0
    m[0, 1], m[1, 1], m[2, 1], m[3, 1] = 0, f, 0, 0
    m[0, 2], m[1, 2], m[2, 2], m[3, 2] = 0, 0, f, 0
    m[0, 3], m[1, 3], m[2, 3], m[3, 3] = 0, 0, 0, f
    return
}
matrix4_from_scalar_f64 :: proc(f: f64) -> (m: matrix[4, 4]f64) #no_bounds_check {
    m[0, 0], m[1, 0], m[2, 0], m[3, 0] = f, 0, 0, 0
    m[0, 1], m[1, 1], m[2, 1], m[3, 1] = 0, f, 0, 0
    m[0, 2], m[1, 2], m[2, 2], m[3, 2] = 0, 0, f, 0
    m[0, 3], m[1, 3], m[2, 3], m[3, 3] = 0, 0, 0, f
    return
}


matrix2_from_matrix3_f16 :: proc(m: matrix[3, 3]f16) -> (r: matrix[2, 2]f16) #no_bounds_check {
    r[0, 0], r[1, 0] = m[0, 0], m[1, 0]
    r[0, 1], r[1, 1] = m[0, 1], m[1, 1]
    return
}
matrix2_from_matrix3_f32 :: proc(m: matrix[3, 3]f32) -> (r: matrix[2, 2]f32) #no_bounds_check {
    r[0, 0], r[1, 0] = m[0, 0], m[1, 0]
    r[0, 1], r[1, 1] = m[0, 1], m[1, 1]
    return
}
matrix2_from_matrix3_f64 :: proc(m: matrix[3, 3]f64) -> (r: matrix[2, 2]f64) #no_bounds_check {
    r[0, 0], r[1, 0] = m[0, 0], m[1, 0]
    r[0, 1], r[1, 1] = m[0, 1], m[1, 1]
    return
}


matrix2_from_matrix4_f16 :: proc(m: matrix[4, 4]f16) -> (r: matrix[2, 2]f16) #no_bounds_check {
    r[0, 0], r[1, 0] = m[0, 0], m[1, 0]
    r[0, 1], r[1, 1] = m[0, 1], m[1, 1]
    return
}
matrix2_from_matrix4_f32 :: proc(m: matrix[4, 4]f32) -> (r: matrix[2, 2]f32) #no_bounds_check {
    r[0, 0], r[1, 0] = m[0, 0], m[1, 0]
    r[0, 1], r[1, 1] = m[0, 1], m[1, 1]
    return
}
matrix2_from_matrix4_f64 :: proc(m: matrix[4, 4]f64) -> (r: matrix[2, 2]f64) #no_bounds_check {
    r[0, 0], r[1, 0] = m[0, 0], m[1, 0]
    r[0, 1], r[1, 1] = m[0, 1], m[1, 1]
    return
}


matrix3_from_matrix2_f16 :: proc(m: matrix[2, 2]f16) -> (r: matrix[3, 3]f16) #no_bounds_check {
    r[0, 0], r[1, 0], r[2, 0] = m[0, 0], m[1, 0], 0
    r[0, 1], r[1, 1], r[2, 1] = m[0, 1], m[1, 1], 0
    r[0, 2], r[1, 2], r[2, 2] =       0,       0, 1
    return
}
matrix3_from_matrix2_f32 :: proc(m: matrix[2, 2]f32) -> (r: matrix[3, 3]f32) #no_bounds_check {
    r[0, 0], r[1, 0], r[2, 0] = m[0, 0], m[1, 0], 0
    r[0, 1], r[1, 1], r[2, 1] = m[0, 1], m[1, 1], 0
    r[0, 2], r[1, 2], r[2, 2] =       0,       0, 1
    return
}
matrix3_from_matrix2_f64 :: proc(m: matrix[2, 2]f64) -> (r: matrix[3, 3]f64) #no_bounds_check {
    r[0, 0], r[1, 0], r[2, 0] = m[0, 0], m[1, 0], 0
    r[0, 1], r[1, 1], r[2, 1] = m[0, 1], m[1, 1], 0
    r[0, 2], r[1, 2], r[2, 2] =       0,       0, 1
    return
}


matrix3_from_matrix4_f16 :: proc(m: matrix[4, 4]f16) -> (r: matrix[3, 3]f16) #no_bounds_check {
    r[0, 0], r[1, 0], r[2, 0] = m[0, 0], m[1, 0], m[2, 0]
    r[0, 1], r[1, 1], r[2, 1] = m[0, 1], m[1, 1], m[2, 1]
    r[0, 2], r[1, 2], r[2, 2] = m[0, 2], m[1, 2], m[2, 2]
    return
}
matrix3_from_matrix4_f32 :: proc(m: matrix[4, 4]f32) -> (r: matrix[3, 3]f32) #no_bounds_check {
    r[0, 0], r[1, 0], r[2, 0] = m[0, 0], m[1, 0], m[2, 0]
    r[0, 1], r[1, 1], r[2, 1] = m[0, 1], m[1, 1], m[2, 1]
    r[0, 2], r[1, 2], r[2, 2] = m[0, 2], m[1, 2], m[2, 2]
    return
}
matrix3_from_matrix4_f64 :: proc(m: matrix[4, 4]f64) -> (r: matrix[3, 3]f64) #no_bounds_check {
    r[0, 0], r[1, 0], r[2, 0] = m[0, 0], m[1, 0], m[2, 0]
    r[0, 1], r[1, 1], r[2, 1] = m[0, 1], m[1, 1], m[2, 1]
    r[0, 2], r[1, 2], r[2, 2] = m[0, 2], m[1, 2], m[2, 2]
    return
}


matrix4_from_matrix2_f16 :: proc(m: matrix[2, 2]f16) -> (r: matrix[4, 4]f16) #no_bounds_check {
    r[0, 0], r[1, 0], r[2, 0], r[3, 0] = m[0, 0], m[1, 0], 0, 0
    r[0, 1], r[1, 1], r[2, 1], r[3, 1] = m[0, 1], m[1, 1], 0, 0
    r[0, 2], r[1, 2], r[2, 2], r[3, 2] =       0,       0, 1, 0
    r[0, 3], r[1, 3], r[2, 3], r[3, 3] =       0,       0, 0, 1
    return
}
matrix4_from_matrix2_f32 :: proc(m: matrix[2, 2]f32) -> (r: matrix[4, 4]f32) #no_bounds_check {
    r[0, 0], r[1, 0], r[2, 0], r[3, 0] = m[0, 0], m[1, 0], 0, 0
    r[0, 1], r[1, 1], r[2, 1], r[3, 1] = m[0, 1], m[1, 1], 0, 0
    r[0, 2], r[1, 2], r[2, 2], r[3, 2] =       0,       0, 1, 0
    r[0, 3], r[1, 3], r[2, 3], r[3, 3] =       0,       0, 0, 1
    return
}
matrix4_from_matrix2_f64 :: proc(m: matrix[2, 2]f64) -> (r: matrix[4, 4]f64) #no_bounds_check {
    r[0, 0], r[1, 0], r[2, 0], r[3, 0] = m[0, 0], m[1, 0], 0, 0
    r[0, 1], r[1, 1], r[2, 1], r[3, 1] = m[0, 1], m[1, 1], 0, 0
    r[0, 2], r[1, 2], r[2, 2], r[3, 2] =       0,       0, 1, 0
    r[0, 3], r[1, 3], r[2, 3], r[3, 3] =       0,       0, 0, 1
    return
}


matrix4_from_matrix3_f16 :: proc(m: matrix[3, 3]f16) -> (r: matrix[4, 4]f16) #no_bounds_check {
    r[0, 0], r[1, 0], r[2, 0], r[3, 0] = m[0, 0], m[1, 0], m[2, 0], 0
    r[0, 1], r[1, 1], r[2, 1], r[3, 1] = m[0, 1], m[1, 1], m[2, 1], 0
    r[0, 2], r[1, 2], r[2, 2], r[3, 2] = m[0, 2], m[1, 2], m[2, 2], 0
    r[0, 3], r[1, 3], r[2, 3], r[3, 3] =       0,       0,       0, 1
    return
}
matrix4_from_matrix3_f32 :: proc(m: matrix[3, 3]f32) -> (r: matrix[4, 4]f32) #no_bounds_check {
    r[0, 0], r[1, 0], r[2, 0], r[3, 0] = m[0, 0], m[1, 0], m[2, 0], 0
    r[0, 1], r[1, 1], r[2, 1], r[3, 1] = m[0, 1], m[1, 1], m[2, 1], 0
    r[0, 2], r[1, 2], r[2, 2], r[3, 2] = m[0, 2], m[1, 2], m[2, 2], 0
    r[0, 3], r[1, 3], r[2, 3], r[3, 3] =       0,       0,       0, 1
    return
}
matrix4_from_matrix3_f64 :: proc(m: matrix[3, 3]f64) -> (r: matrix[4, 4]f64) #no_bounds_check {
    r[0, 0], r[1, 0], r[2, 0], r[3, 0] = m[0, 0], m[1, 0], m[2, 0], 0
    r[0, 1], r[1, 1], r[2, 1], r[3, 1] = m[0, 1], m[1, 1], m[2, 1], 0
    r[0, 2], r[1, 2], r[2, 2], r[3, 2] = m[0, 2], m[1, 2], m[2, 2], 0
    r[0, 3], r[1, 3], r[2, 3], r[3, 3] =       0,       0,       0, 1
    return
}


quaternion_from_scalar_f16 :: proc(f: f16) -> (q: Quaternionf16) {
    q.w = f
    return
}
quaternion_from_scalar_f32 :: proc(f: f32) -> (q: Quaternionf32) {
    q.w = f
    return
}
quaternion_from_scalar_f64 :: proc(f: f64) -> (q: Quaternionf64) {
    q.w = f
    return
}


matrix2_orthonormalize_f16 :: proc(m: matrix[2, 2]f16) -> (r: matrix[2, 2]f16) #no_bounds_check {
    r = m
    r[0] = vec_normalize(m[0])

    d0 := vec_dot(r[0], r[1])
    r[1] -= r[0] * d0
    r[1] = vec_normalize(r[1])

    return
}
matrix2_orthonormalize_f32 :: proc(m: matrix[2, 2]f32) -> (r: matrix[2, 2]f32) #no_bounds_check {
    r = m
    r[0] = vec_normalize(m[0])

    d0 := vec_dot(r[0], r[1])
    r[1] -= r[0] * d0
    r[1] = vec_normalize(r[1])

    return
}
matrix2_orthonormalize_f64 :: proc(m: matrix[2, 2]f64) -> (r: matrix[2, 2]f64) #no_bounds_check {
    r = m
    r[0] = vec_normalize(m[0])

    d0 := vec_dot(r[0], r[1])
    r[1] -= r[0] * d0
    r[1] = vec_normalize(r[1])

    return
}


matrix3_orthonormalize_f16 :: proc(m: matrix[3, 3]f16) -> (r: matrix[3, 3]f16) #no_bounds_check {
    r = m
    r[0] = vec_normalize(m[0])

    d0 := vec_dot(r[0], r[1])
    r[1] -= r[0] * d0
    r[1] = vec_normalize(r[1])

    d1 := vec_dot(r[1], r[2])
    d0 = vec_dot(r[0], r[2])
    r[2] -= r[0]*d0 + r[1]*d1
    r[2] = vec_normalize(r[2])

    return
}
matrix3_orthonormalize_f32 :: proc(m: matrix[3, 3]f32) -> (r: matrix[3, 3]f32) #no_bounds_check {
    r = m
    r[0] = vec_normalize(m[0])

    d0 := vec_dot(r[0], r[1])
    r[1] -= r[0] * d0
    r[1] = vec_normalize(r[1])

    d1 := vec_dot(r[1], r[2])
    d0 = vec_dot(r[0], r[2])
    r[2] -= r[0]*d0 + r[1]*d1
    r[2] = vec_normalize(r[2])

    return
}
matrix3_orthonormalize_f64 :: proc(m: matrix[3, 3]f64) -> (r: matrix[3, 3]f64) #no_bounds_check {
    r = m
    r[0] = vec_normalize(m[0])

    d0 := vec_dot(r[0], r[1])
    r[1] -= r[0] * d0
    r[1] = vec_normalize(r[1])

    d1 := vec_dot(r[1], r[2])
    d0 = vec_dot(r[0], r[2])
    r[2] -= r[0]*d0 + r[1]*d1
    r[2] = vec_normalize(r[2])

    return
}


vector3_orthonormalize_f16 :: proc(x, y: [3]f16) -> (z: [3]f16) {
    return vec_normalize(x - y * vec_dot(y, x))
}
vector3_orthonormalize_f32 :: proc(x, y: [3]f32) -> (z: [3]f32) {
    return vec_normalize(x - y * vec_dot(y, x))
}
vector3_orthonormalize_f64 :: proc(x, y: [3]f64) -> (z: [3]f64) {
    return vec_normalize(x - y * vec_dot(y, x))
}


matrix4_orientation_f16 :: proc(normal, up: [3]f16) -> matrix[4, 4]f16 {
    if all(equal_array(normal, up)) {
        return MATRIX4F16_IDENTITY
    }

    rotation_axis := vec3_cross(up, normal)
    angle := math.acos(vec_dot(normal, up))

    return matrix4_rotate_f16(angle, rotation_axis)
}
matrix4_orientation_f32 :: proc(normal, up: [3]f32) -> matrix[4, 4]f32 {
    if all(equal_array(normal, up)) {
        return MATRIX4F32_IDENTITY
    }

    rotation_axis := vec3_cross(up, normal)
    angle := math.acos(vec_dot(normal, up))

    return matrix4_rotate_f32(angle, rotation_axis)
}
matrix4_orientation_f64 :: proc(normal, up: [3]f64) -> matrix[4, 4]f64 {
    if all(equal_array(normal, up)) {
        return MATRIX4F64_IDENTITY
    }

    rotation_axis := vec3_cross(up, normal)
    angle := math.acos(vec_dot(normal, up))

    return matrix4_rotate_f64(angle, rotation_axis)
}


euclidean_from_polar_f16 :: proc(polar: [2]f16) -> [3]f16 {
    latitude, longitude := polar.x, polar.y
    cx, sx := math.cos_f16(latitude),  math.sin_f16(latitude)
    cy, sy := math.cos_f16(longitude), math.sin_f16(longitude)

    return {
        cx*sy,
        sx,
        cx*cy,
    }
}
euclidean_from_polar_f32 :: proc(polar: [2]f32) -> [3]f32 {
    latitude, longitude := polar.x, polar.y
    cx, sx := math.cos_f32(latitude),  math.sin_f32(latitude)
    cy, sy := math.cos_f32(longitude), math.sin_f32(longitude)

    return {
        cx*sy,
        sx,
        cx*cy,
    }
}
euclidean_from_polar_f64 :: proc(polar: [2]f64) -> [3]f64 {
    latitude, longitude := polar.x, polar.y
    cx, sx := math.cos_f64(latitude),  math.sin_f64(latitude)
    cy, sy := math.cos_f64(longitude), math.sin_f64(longitude)

    return {
        cx*sy,
        sx,
        cx*cy,
    }
}


polar_from_euclidean_f16 :: proc(euclidean: [3]f16) -> [3]f16 {
    n := vec_length(euclidean)
    tmp := euclidean / n

    xz_dist := math.sqrt(tmp.x*tmp.x + tmp.z*tmp.z)

    return [3]f16{
        math.asin(tmp.y),
        math.atan2(tmp.x, tmp.z),
        xz_dist,
    }
}
polar_from_euclidean_f32 :: proc(euclidean: [3]f32) -> [3]f32 {
    n := vec_length(euclidean)
    tmp := euclidean / n

    xz_dist := math.sqrt(tmp.x*tmp.x + tmp.z*tmp.z)

    return [3]f32{
        math.asin(tmp.y),
        math.atan2(tmp.x, tmp.z),
        xz_dist,
    }
}
polar_from_euclidean_f64 :: proc(euclidean: [3]f64) -> [3]f64 {
    n := vec_length(euclidean)
    tmp := euclidean / n

    xz_dist := math.sqrt(tmp.x*tmp.x + tmp.z*tmp.z)

    return [3]f64{
        math.asin(tmp.y),
        math.atan2(tmp.x, tmp.z),
        xz_dist,
    }
}
