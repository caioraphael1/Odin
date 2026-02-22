package linalg

import "base:builtin"
import "core:math"

import "base:intrinsics"


to_radians :: proc(degrees: $T) -> (out: T) where intrinsics.type_is_numeric(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = degrees[i] * RAD_PER_DEG
        }
    } else {
        out = degrees * RAD_PER_DEG
    }
    return
}


to_degrees :: proc(radians: $T) -> (out: T) where intrinsics.type_is_numeric(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = radians[i] * DEG_PER_RAD
        }
    } else {
        out = radians * DEG_PER_RAD
    }
    return
}


min_double :: proc(a, b: $T) -> (out: T) where intrinsics.type_is_numeric(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = builtin.min(a[i], b[i])
        }
    } else {
        out = builtin.min(a, b)
    }
    return
}


min_single :: proc(a: $T) -> (out: T) where intrinsics.type_is_numeric(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        N :: len(T)

        when N == 1 {
            out = a[0]
        } else when N == 2 {
            out = builtin.min(a[0], a[1])
        } else {
            out = builtin.min(a[0], a[1])
            for i in 2..<N {
                out = builtin.min(out, a[i])
            }
        }
    } else {
        out = a
    }
    return
}


min_triple :: proc(a, b, c: $T) -> T where intrinsics.type_is_numeric(intrinsics.type_elem_type(T)) {
    return min_double(a, min_double(b, c))
}


max_double :: proc(a, b: $T) -> (out: T) where intrinsics.type_is_numeric(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = builtin.max(a[i], b[i])
        }
    } else {
        out = builtin.max(a, b)
    }
    return
}


max_single :: proc(a: $T) -> (out: T) where intrinsics.type_is_numeric(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        N :: len(T)

        when N == 1 {
            out = a[0]
        } else when N == 2 {
            out = builtin.max(a[0], a[1])
        } else when N == 3 {
            out = builtin.max(a[0], a[1], a[2])
        }else {
            out = builtin.max(a[0], a[1])
            for i in 2..<N {
                out = builtin.max(out, a[i])
            }
        }
    } else {
        out = a
    }
    return
}


max_triple :: proc(a, b, c: $T) -> T where intrinsics.type_is_numeric(intrinsics.type_elem_type(T)) {
    return max_double(a, max_double(b, c))
}


abs :: proc(a: $T) -> (out: T) where intrinsics.type_is_numeric(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = auto_cast builtin.abs(a[i])
        }
    } else {
        out = auto_cast builtin.abs(a)
    }
    return
}


sign :: proc(a: $T) -> (out: T) where intrinsics.type_is_numeric(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = #force_inline math.sign(a[i])
        }
    } else {
        out = #force_inline math.sign(a)
    }
    return
}


clamp :: proc(x, a, b: $T) -> (out: T) where intrinsics.type_is_numeric(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = builtin.clamp(x[i], a[i], b[i])
        }
    } else {
        out = builtin.clamp(x, a, b)
    }
    return
}



saturate :: proc(x: $T) -> T where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    return clamp(x, 0.0, 1.0)
}


lerp :: proc(a, b, t: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = a[i]*(1-t[i]) + b[i]*t[i]
        }
    } else {
        out = a * (1.0 - t) + b * t
    }
    return
}

mix :: proc(a, b, t: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = a[i]*(1-t[i]) + b[i]*t[i]
        }
    } else {
        out = a * (1.0 - t) + b * t
    }
    return
}


unlerp :: proc(a, b, x: $T) -> T where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    return (x - a) / (b - a)
}


step :: proc(e, x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = x[i] < e[i] ? 0.0 : 1.0
        }
    } else {
        out = x < e ? 0.0 : 1.0
    }
    return
}


smoothstep :: proc(e0, e1, x: $T) -> T where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    t := saturate(unlerp(e0, e1, x))
    return t * t * (3.0 - 2.0 * t)
}


smootherstep :: proc(e0, e1, x: $T) -> T where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    t := saturate(unlerp(e0, e1, x))
    return t * t * t * (t * (6*t - 15) + 10)
}



sqrt :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = math.sqrt(x[i])
        }
    } else {
        out = math.sqrt(x)
    }
    return
}


inverse_sqrt :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = 1.0/math.sqrt(x[i])
        }
    } else {
        out = 1.0/math.sqrt(x)
    }
    return
}


cos :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = math.cos(x[i])
        }
    } else {
        out = math.cos(x)
    }
    return
}


sin :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = math.sin(x[i])
        }
    } else {
        out = math.sin(x)
    }
    return
}


tan :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = math.tan(x[i])
        }
    } else {
        out = math.tan(x)
    }
    return
}


acos :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = math.acos(x[i])
        }
    } else {
        out = math.acos(x)
    }
    return
}


asin :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = math.asin(x[i])
        }
    } else {
        out = math.asin(x)
    }
    return
}


atan :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = math.atan(x[i])
        }
    } else {
        out = math.atan(x)
    }
    return
}

atan2 :: proc(y, x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = math.atan2(y[i], x[i])
        }
    } else {
        out = math.atan2(y, x)
    }
    return
}



ln :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = math.ln(x[i])
        }
    } else {
        out = math.ln(x)
    }
    return
}


log2 :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    INVLN2 :: 1.4426950408889634073599246810018921374266459541529859341354494069
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = INVLN2 * math.ln(x[i])
        }
    } else {
        out = INVLN2 * math.ln(x)
    }
    return
}


log10 :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    INVLN10 :: 0.4342944819032518276511289189166050822943970058036665661144537831
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = INVLN10 * math.ln(x[i])
        }
    } else {
        out = INVLN10 * math.ln(x)
    }
    return
}


log :: proc(x, b: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = math.ln(x[i]) / math.ln(cast(intrinsics.type_elem_type(T))b[i])
        }
    } else {
        out = math.ln(x) / math.ln(cast(intrinsics.type_elem_type(T))b)
    }
    return
}


exp :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = math.exp(x[i])
        }
    } else {
        out = math.exp(x)
    }
    return
}


exp2 :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = math.exp(LN2 * x[i])
        }
    } else {
        out = math.exp(LN2 * x)
    }
    return
}


exp10 :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = math.exp(LN10 * x[i])
        }
    } else {
        out = math.exp(LN10 * x)
    }
    return
}


pow :: proc(x, e: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = math.pow(x[i], e[i])
        }
    } else {
        out = math.pow(x, e)
    }
    return
}



ceil :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = #force_inline math.ceil(x[i])
        }
    } else {
        out = #force_inline math.ceil(x)
    }
    return
}


floor :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = #force_inline math.floor(x[i])
        }
    } else {
        out = #force_inline math.floor(x)
    }
    return
}


round :: proc(x: $T) -> (out: T) where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    when intrinsics.type_is_array(T) {
        for i in 0..<len(T) {
            out[i] = #force_inline math.round(x[i])
        }
    } else {
        out = #force_inline math.round(x)
    }
    return
}


fract :: proc(x: $T) -> T where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    f := #force_inline floor(x)
    return x - f
}


mod :: proc(x, m: $T) -> T where intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    f := #force_inline floor(x / m)
    return x - f * m
}



face_forward :: proc(N, I, N_ref: $T) -> (out: T) where intrinsics.type_is_array(T), intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    return dot(N_ref, I) < 0 ? N : -N
}


distance :: proc(p0, p1: $V/[$N]$E) -> E where intrinsics.type_is_numeric(E) {
    return length(p1 - p0)
}


reflect :: proc(I, N: $T) -> (out: T) where intrinsics.type_is_array(T), intrinsics.type_is_float(intrinsics.type_elem_type(T)) {
    b := N * (2 * dot(N, I))
    return I - b
}

refract :: proc(I, Normal: $V/[$N]$E, eta: E) -> (out: V) where intrinsics.type_is_array(V), intrinsics.type_is_float(intrinsics.type_elem_type(V)) {
    dv := dot(Normal, I)
    k := 1 - eta*eta * (1 - dv*dv)
    a := I * eta
    b := Normal * (eta*dv+math.sqrt(k))
    return (a - b) * E(int(k >= 0))
}





is_nan_single :: proc(x: $T) -> bool where intrinsics.type_is_float(T) {
    return #force_inline math.is_nan(x)
}


is_nan_array :: proc(x: $A/[$N]$T) -> (out: [N]bool) where intrinsics.type_is_float(T) {
    for i in 0..<N {
        out[i] = #force_inline is_nan(x[i])
    }
    return
}


is_inf_single :: proc(x: $T) -> bool where intrinsics.type_is_float(T) {
    return #force_inline math.is_inf(x)
}


is_inf_array :: proc(x: $A/[$N]$T) -> (out: [N]bool) where intrinsics.type_is_float(T) {
    for i in 0..<N {
        out[i] = #force_inline is_inf(x[i])
    }
    return
}


classify_single :: proc(x: $T) -> math.Float_Class where intrinsics.type_is_float(T) {
    return #force_inline math.classify(x)
}


classify_array :: proc(x: $A/[$N]$T) -> (out: [N]math.Float_Class) where intrinsics.type_is_float(T) {
    for i in 0..<N {
        out[i] = #force_inline classify_single(x[i])
    }
    return
}

less_than_single          :: proc(x, y: $T) -> (out: bool) where !intrinsics.type_is_array(T), intrinsics.type_is_float(T) { return x < y }
less_than_equal_single    :: proc(x, y: $T) -> (out: bool) where !intrinsics.type_is_array(T), intrinsics.type_is_float(T) { return x <= y }
greater_than_single       :: proc(x, y: $T) -> (out: bool) where !intrinsics.type_is_array(T), intrinsics.type_is_float(T) { return x > y }
greater_than_equal_single :: proc(x, y: $T) -> (out: bool) where !intrinsics.type_is_array(T), intrinsics.type_is_float(T) { return x >= y }
equal_single              :: proc(x, y: $T) -> (out: bool) where !intrinsics.type_is_array(T), intrinsics.type_is_float(T) { return x == y }
not_equal_single          :: proc(x, y: $T) -> (out: bool) where !intrinsics.type_is_array(T), intrinsics.type_is_float(T) { return x != y }


less_than_array :: proc(x, y: $A/[$N]$T) -> (out: [N]bool) where intrinsics.type_is_array(A), intrinsics.type_is_float(intrinsics.type_elem_type(A)) {
    for i in 0..<N {
        out[i] = x[i] < y[i]
    }
    return
}

less_than_equal_array :: proc(x, y: $A/[$N]$T) -> (out: [N]bool) where intrinsics.type_is_array(A), intrinsics.type_is_float(intrinsics.type_elem_type(A)) {
    for i in 0..<N {
        out[i] = x[i] <= y[i]
    }
    return
}

greater_than_array :: proc(x, y: $A/[$N]$T) -> (out: [N]bool) where intrinsics.type_is_array(A), intrinsics.type_is_float(intrinsics.type_elem_type(A)) {
    for i in 0..<N {
        out[i] = x[i] > y[i]
    }
    return
}

greater_than_equal_array :: proc(x, y: $A/[$N]$T) -> (out: [N]bool) where intrinsics.type_is_array(A), intrinsics.type_is_float(intrinsics.type_elem_type(A)) {
    for i in 0..<N {
        out[i] = x[i] >= y[i]
    }
    return
}

equal_array :: proc(x, y: $A/[$N]$T) -> (out: [N]bool) where intrinsics.type_is_array(A), intrinsics.type_is_float(intrinsics.type_elem_type(A)) {
    for i in 0..<N {
        out[i] = x[i] == y[i]
    }
    return
}

not_equal_array :: proc(x, y: $A/[$N]$T) -> (out: [N]bool) where intrinsics.type_is_array(A), intrinsics.type_is_float(intrinsics.type_elem_type(A)) {
    for i in 0..<N {
        out[i] = x[i] != y[i]
    }
    return
}


any :: proc(x: $A/[$N]bool) -> (out: bool) {
    for e in x {
        if e {
            return true
        }
    }
    return false
}

all :: proc(x: $A/[$N]bool) -> (out: bool) {
    for e in x {
        if !e {
            return false
        }
    }
    return true
}

not :: proc(x: $A/[$N]bool) -> (out: A) {
    for e, i in x {
        out[i] = !e
    }
    return
}
