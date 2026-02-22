package linalg

/*
    These procedures are to allow for swizzling with non-compile (runtime) known components
*/


Scalar_Components :: enum u8 {
    x = 0,
    r = 0,
}

Vector2_Components :: enum u8 {
    x = 0,
    y = 1,
    r = 0,
    g = 1,
}

Vector3_Components :: enum u8 {
    x = 0,
    y = 1,
    z = 2,
    r = 0,
    g = 1,
    b = 2,
}

Vector4_Components :: enum u8 {
    x = 0,
    y = 1,
    z = 2,
    w = 3,
    r = 0,
    g = 1,
    b = 2,
    a = 3,
}


scalar_f32_swizzle1 :: proc(f: f32, c0: Scalar_Components) -> f32 {
    return f
}

scalar_f32_swizzle2 :: proc(f: f32, c0, c1: Scalar_Components) -> [2]f32 {
    return {f, f}
}

scalar_f32_swizzle3 :: proc(f: f32, c0, c1, c2: Scalar_Components) -> [3]f32 {
    return {f, f, f}
}

scalar_f32_swizzle4 :: proc(f: f32, c0, c1, c2, c3: Scalar_Components) -> [4]f32 {
    return {f, f, f, f}
}


vector2f32_swizzle1 :: proc(v: [2]f32, c0: Vector2_Components) -> f32 {
    return v[c0]
}

vector2f32_swizzle2 :: proc(v: [2]f32, c0, c1: Vector2_Components) -> [2]f32 {
    return {v[c0], v[c1]}
}

vector2f32_swizzle3 :: proc(v: [2]f32, c0, c1, c2: Vector2_Components) -> [3]f32 {
    return {v[c0], v[c1], v[c2]}
}

vector2f32_swizzle4 :: proc(v: [2]f32, c0, c1, c2, c3: Vector2_Components) -> [4]f32 {
    return {v[c0], v[c1], v[c2], v[c3]}
}



vector3f32_swizzle1 :: proc(v: [3]f32, c0: Vector3_Components) -> f32 {
    return v[c0]
}

vector3f32_swizzle2 :: proc(v: [3]f32, c0, c1: Vector3_Components) -> [2]f32 {
    return {v[c0], v[c1]}
}

vector3f32_swizzle3 :: proc(v: [3]f32, c0, c1, c2: Vector3_Components) -> [3]f32 {
    return {v[c0], v[c1], v[c2]}
}

vector3f32_swizzle4 :: proc(v: [3]f32, c0, c1, c2, c3: Vector3_Components) -> [4]f32 {
    return {v[c0], v[c1], v[c2], v[c3]}
}


vector4f32_swizzle1 :: proc(v: [4]f32, c0: Vector4_Components) -> f32 {
    return v[c0]
}

vector4f32_swizzle2 :: proc(v: [4]f32, c0, c1: Vector4_Components) -> [2]f32 {
    return {v[c0], v[c1]}
}

vector4f32_swizzle3 :: proc(v: [4]f32, c0, c1, c2: Vector4_Components) -> [3]f32 {
    return {v[c0], v[c1], v[c2]}
}

vector4f32_swizzle4 :: proc(v: [4]f32, c0, c1, c2, c3: Vector4_Components) -> [4]f32 {
    return {v[c0], v[c1], v[c2], v[c3]}
}



scalar_f64_swizzle1 :: proc(f: f64, c0: Scalar_Components) -> f64 {
    return f
}

scalar_f64_swizzle2 :: proc(f: f64, c0, c1: Scalar_Components) -> [2]f64 {
    return {f, f}
}

scalar_f64_swizzle3 :: proc(f: f64, c0, c1, c2: Scalar_Components) -> [3]f64 {
    return {f, f, f}
}

scalar_f64_swizzle4 :: proc(f: f64, c0, c1, c2, c3: Scalar_Components) -> [4]f64 {
    return {f, f, f, f}
}


vector2f64_swizzle1 :: proc(v: [2]f64, c0: Vector2_Components) -> f64 {
    return v[c0]
}

vector2f64_swizzle2 :: proc(v: [2]f64, c0, c1: Vector2_Components) -> [2]f64 {
    return {v[c0], v[c1]}
}

vector2f64_swizzle3 :: proc(v: [2]f64, c0, c1, c2: Vector2_Components) -> [3]f64 {
    return {v[c0], v[c1], v[c2]}
}

vector2f64_swizzle4 :: proc(v: [2]f64, c0, c1, c2, c3: Vector2_Components) -> [4]f64 {
    return {v[c0], v[c1], v[c2], v[c3]}
}



vector3f64_swizzle1 :: proc(v: [3]f64, c0: Vector3_Components) -> f64 {
    return v[c0]
}

vector3f64_swizzle2 :: proc(v: [3]f64, c0, c1: Vector3_Components) -> [2]f64 {
    return {v[c0], v[c1]}
}

vector3f64_swizzle3 :: proc(v: [3]f64, c0, c1, c2: Vector3_Components) -> [3]f64 {
    return {v[c0], v[c1], v[c2]}
}

vector3f64_swizzle4 :: proc(v: [3]f64, c0, c1, c2, c3: Vector3_Components) -> [4]f64 {
    return {v[c0], v[c1], v[c2], v[c3]}
}


vector4f64_swizzle1 :: proc(v: [4]f64, c0: Vector4_Components) -> f64 {
    return v[c0]
}

vector4f64_swizzle2 :: proc(v: [4]f64, c0, c1: Vector4_Components) -> [2]f64 {
    return {v[c0], v[c1]}
}

vector4f64_swizzle3 :: proc(v: [4]f64, c0, c1, c2: Vector4_Components) -> [3]f64 {
    return {v[c0], v[c1], v[c2]}
}

vector4f64_swizzle4 :: proc(v: [4]f64, c0, c1, c2, c3: Vector4_Components) -> [4]f64 {
    return {v[c0], v[c1], v[c2], v[c3]}
}
