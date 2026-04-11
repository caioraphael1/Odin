import "base:math"
import "core:math/linalg"

EPSILON :: 0.000001


//----------------------------------------------------------------------------------
// Module Functions Definition - Utils math
//----------------------------------------------------------------------------------


// Clamp float value

Clamp :: proc(value: f32, min, max: f32) -> f32 {
    return clamp(value, min, max)
}

// Calculate linear interpolation between two floats

Lerp :: proc(start, end: f32, amount: f32) -> f32 {
    return start*(1-amount) + end*amount
}

// Normalize input value within input range

Normalize :: proc(value: f32, start, end: f32) -> f32 {
    return (value - start) / (end - start)
}

// Remap input value within input range to output range

Remap :: proc(value: f32, inputStart, inputEnd: f32, outputStart, outputEnd: f32) -> f32 {
    return (value - inputStart)/(inputEnd - inputStart)*(outputEnd - outputStart) + outputStart
}

// Wrap input value from min to max

Wrap :: proc(value: f32, min, max: f32) -> f32 {
    return value - (max - min)*math.floor_f32((value - min)/(max - min))
}

// Check whether two given floats are almost equal

FloatEquals :: proc(x, y: f32) -> bool {
    return abs(x - y) <= EPSILON*fmaxf(1.0, fmaxf(abs(x), abs(y)))
}



//----------------------------------------------------------------------------------
// Module Functions Definition - [2]f32 math
//----------------------------------------------------------------------------------


// Calculate vector vec_length
Vector2Length :: proc(v: [2]f32) -> f32 {
    return linalg.vec_length(v)
}

// Calculate vector square vec_length
Vector2LengthSqr :: proc(v: [2]f32) -> f32 {
    return linalg.vec_length_squared(v)
}

// Calculate two vectors vec_dot product
Vector2DotProduct :: proc(v1, v2: [2]f32) -> f32 {
    return linalg.vec_dot(v1, v2)
}

// Calculate distance between two vectors
Vector2Distance :: proc(v1, v2: [2]f32) -> f32 {
    return linalg.distance(v1, v2)
}

// Calculate square distance between two vectors
Vector2DistanceSqrt :: proc(v1, v2: [2]f32) -> f32 {
    return linalg.vec_length_squared(v2-v1)
}
// Calculate angle between two vectors
// NOTE: Angle is calculated from origin point (0, 0)
Vector2Angle :: proc(v1, v2: [2]f32) -> f32 {
    return linalg.vec_angle_between(v1, v2)
}

// Calculate angle defined by a two vectors line
// NOTE: Parameters need to be normalized
// Current implementation should be aligned with glm::angle

Vector2LineAngle :: proc(start, end: [2]f32) -> f32 {
    // TODO(10/9/2023): Currently angles move clockwise, determine if this is wanted behavior
    return -math.atan2(end.y - start.y, end.x - start.x)
}

// Normalize provided vector
Vector2Normalize :: proc(v: [2]f32) -> [2]f32 {
    return linalg.vec_normalize_safe(v)
}

// Transforms a [2]f32 by a given Mat4_RowMajor
Vector2Transform :: proc(v: [2]f32, m: Mat4_RowMajor) -> [2]f32 {
    v4 := [4]f32{v.x, v.y, 0, 1}
    return (m * v4).xy
}

// Rotate vector by angle
Vector2Rotate :: proc(v: [2]f32, angle: f32) -> [2]f32 {
    c, s := math.cos_f32(angle), math.sin_f32(angle)

    return [2]f32{
        v.x*c - v.y*s,
        v.x*s + v.y*c,
    }
}

// Move Vector towards target

Vector2MoveTowards :: proc(v, target: [2]f32, maxDistance: f32) -> [2]f32 {
    dv := target - v
    value := linalg.vec_dot(dv, dv)

    if value == 0 || (maxDistance >= 0 && value <= maxDistance*maxDistance) {
        return target
    }

    dist := math.sqrt(value)
    return v + dv/dist*maxDistance
}


// Clamp the components of the vector between
// min and max values specified by the given vectors

Vector2Clamp :: proc(v: [2]f32, min, max: [2]f32) -> [2]f32 {
    return [2]f32{
        clamp(v.x, min.x, max.x),
        clamp(v.y, min.y, max.y),
    }
}

// Clamp the magnitude of the vector between two min and max values

Vector2ClampValue :: proc(v: [2]f32, min, max: f32) -> [2]f32 {
    result := v

    vec_length := linalg.vec_dot(v, v)
    if vec_length > 0 {
        vec_length = math.sqrt(vec_length)
        scale := f32(1)
        if vec_length < min {
            scale = min/vec_length
        } else if vec_length > max {
            scale = max/vec_length
        }
        result = v*scale
    }
    return result
}


Vector2Equals :: proc(p, q: [2]f32) -> bool {
    return FloatEquals(p.x, q.x) &&
           FloatEquals(p.y, q.y)
}



//----------------------------------------------------------------------------------
// Module Functions Definition - [3]f32 math
//----------------------------------------------------------------------------------

// Calculate vector vec_length
Vector3Length :: proc(v: [3]f32) -> f32 {
    return linalg.vec_length(v)
}

// Calculate vector square vec_length
Vector3LengthSqr :: proc(v: [3]f32) -> f32 {
    return linalg.vec_length_squared(v)
}

// Calculate two vectors vec_dot product
Vector3DotProduct :: proc(v1, v2: [3]f32) -> f32 {
    return linalg.vec_dot(v1, v2)
}

// Calculate two vectors vec_dot product
Vector3CrossProduct :: proc(v1, v2: [3]f32) -> [3]f32 {
    return linalg.vec3_cross(v1, v2)
}

// Calculate distance between two vectors
Vector3Distance :: proc(v1, v2: [3]f32) -> f32 {
    return linalg.distance(v1, v2)
}

// Calculate square distance between two vectors
Vector3DistanceSqrt :: proc(v1, v2: [3]f32) -> f32 {
    return linalg.vec_length_squared(v2-v1)
}

// Calculate angle between two vectors
// NOTE: Angle is calculated from origin point (0, 0)
Vector3Angle :: proc(v1, v2: [3]f32) -> f32 {
    return linalg.vec_angle_between(v1, v2)
}

// Calculate angle defined by a two vectors line
// NOTE: Parameters need to be normalized
// Current implementation should be aligned with glm::angle
Vector3LineAngle :: proc(start, end: [3]f32) -> f32 {
    // TODO(10/9/2023): Currently angles move clockwise, determine if this is wanted behavior
    return -math.atan2(end.y - start.y, end.x - start.x)
}

// Normalize provided vector
Vector3Normalize :: proc(v: [3]f32) -> [3]f32 {
    return linalg.vec_normalize_safe(v)
}

// Calculate the projection of the vector v1 on to v2
Vector3Project :: proc(v1, v2: [3]f32) -> [3]f32 {
    return linalg.projection(v1, v2)
}

// Calculate the rejection  of the vector v1 on to v2
Vector3Reject :: proc(v1, v2: [3]f32) -> [3]f32 {
    mag := linalg.vec_dot(v1, v2)/linalg.vec_dot(v2, v2)
    return v1 - v2*mag
}

// Orthonormalize provided vectors
// Makes vectors normalized and orthogonal to each other
// Gram-Schmidt function implementation
Vector3OrthoNormalize :: proc(v1, v2: ^[3]f32) {
    v1^ = linalg.vec_normalize_safe(v1^)
    v3 := linalg.vec_normalize_safe(linalg.vec3_cross(v1^, v2^))
    v2^ = linalg.vec3_cross(v3, v1^)
}

// Transform a vector by quaternion rotation

Vector3RotateByQuaternion :: proc(v: [3]f32, q: quaternion128) -> [3]f32 {
    return linalg.quaternionf32_mul_vec3(q, v)
}

// Rotates a vector around an axis

Vector3RotateByAxisAngle :: proc(v: [3]f32, axis: [3]f32, angle: f32) -> [3]f32 {
    axis, angle := axis, angle

    axis = linalg.vec_normalize_safe(axis)

    angle *= 0.5
    a := math.sin_f32(angle)
    b := axis.x*a
    c := axis.y*a
    d := axis.z*a
    a = math.cos_f32(angle)
    w := [3]f32{b, c, d}

    wv := linalg.vec3_cross(w, v)
    wwv := linalg.vec3_cross(w, wv)

    a *= 2
    wv *= a

    wwv *= 2

    return v + wv + wwv

}

// Transforms a [3]f32 by a given Mat4_RowMajor

Vector3Transform :: proc(v: [3]f32, m: Mat4_RowMajor) -> [3]f32 {
    v4 := [4]f32{v.x, v.y, v.z, 1}
    return (m * v4).xyz
}

// Move Vector towards target
Vector3MoveTowards :: proc(v, target: [3]f32, maxDistance: f32) -> [3]f32 {
    dv := target - v
    value := linalg.vec_dot(dv, dv)

    if value == 0 || (maxDistance >= 0 && value <= maxDistance*maxDistance) {
        return target
    }

    dist := math.sqrt(value)
    return v + dv/dist*maxDistance
}

// Clamp the components of the vector between
// min and max values specified by the given vectors
Vector3Clamp :: proc(v: [3]f32, min, max: [3]f32) -> [3]f32 {
    return [3]f32{
        clamp(v.x, min.x, max.x),
        clamp(v.y, min.y, max.y),
        clamp(v.z, min.z, max.z),
    }
}

// Clamp the magnitude of the vector between two min and max values
Vector3ClampValue :: proc(v: [3]f32, min, max: f32) -> [3]f32 {
    result := v

    vec_length := linalg.vec_dot(v, v)
    if vec_length > 0 {
        vec_length = math.sqrt(vec_length)
        scale := f32(1)
        if vec_length < min {
            scale = min/vec_length
        } else if vec_length > max {
            scale = max/vec_length
        }
        result = v*scale
    }
    return result
}


Vector3Equals :: proc(p, q: [3]f32) -> bool {
    return FloatEquals(p.x, q.x) &&
           FloatEquals(p.y, q.y) &&
           FloatEquals(p.z, q.z)
}

// Compute barycenter coordinates (u, v, w) for point p with respect to triangle (a, b, c)
// NOTE: Assumes P is on the plane of the triangle
Vector3Barycenter :: proc(p: [3]f32, a, b, c: [3]f32) -> (result: [3]f32) {
    v0 := b - a
    v1 := c - a
    v2 := p - a
    d00 := linalg.vec_dot(v0, v0)
    d01 := linalg.vec_dot(v0, v1)
    d11 := linalg.vec_dot(v1, v1)
    d20 := linalg.vec_dot(v2, v0)
    d21 := linalg.vec_dot(v2, v1)

    denom := d00*d11 - d01*d01

    result.y = (d11*d20 - d01*d21)/denom
    result.z = (d00*d21 - d01*d20)/denom
    result.x = 1 - (result.z + result.y)

    return result
}

// Projects a [3]f32 from screen space into object space
Vector3Unproject :: proc(source: [3]f32, projection: Mat4_RowMajor, view: Mat4_RowMajor) -> [3]f32 {
    matViewProj := view * projection

    matViewProjInv := linalg.matrix4x4_inverse(matViewProj)

    quat: quaternion128
    quat.x = source.x
    quat.y = source.y
    quat.z = source.z
    quat.w = 1

    qtransformed := QuaternionTransform(quat, matViewProjInv)

    return [3]f32{qtransformed.x/qtransformed.w, qtransformed.y/qtransformed.w, qtransformed.z/qtransformed.w}
}



//----------------------------------------------------------------------------------
// Module Functions Definition - Mat4_RowMajor math
//----------------------------------------------------------------------------------

// Compute matrix determinant
MatrixDeterminant :: proc(mat: Mat4_RowMajor) -> f32 {
    return linalg.matrix4x4_determinant(mat)
}

// Get the trace of the matrix (sum of the values along the diagonal)
MatrixTrace :: proc(mat: Mat4_RowMajor) -> f32 {
    return linalg.trace(mat)
}

// Transposes provided matrix
MatrixTranspose :: proc(mat: Mat4_RowMajor) -> Mat4_RowMajor {
    return linalg.transpose(mat)
}

// Invert provided matrix
MatrixInvert :: proc(mat: Mat4_RowMajor) -> Mat4_RowMajor {
    return linalg.matrix4x4_inverse(mat)
}

// Get translation matrix
MatrixTranslate :: proc(x, y, z: f32) -> Mat4_RowMajor {
    return {
        1, 0, 0, x,
        0, 1, 0, y,
        0, 0, 1, z,
        0, 0, 0, 1,
    }
}

// Get float array of matrix data
MatrixToFloatV :: proc(mat: Mat4_RowMajor) -> [16]f32 {
    return transmute([16]f32)linalg.transpose(mat)
}


//----------------------------------------------------------------------------------
// Module Functions Definition - quaternion128 math
//----------------------------------------------------------------------------------

// Add quaternion and float value
QuaternionAddValue :: proc(q: quaternion128, add: f32) -> quaternion128 {
    return q + quaternion128(add)
}

// Subtract quaternion and float value
QuaternionSubtractValue :: proc(q: quaternion128, sub: f32) -> quaternion128 {
    return q - quaternion128(sub)
}

// Normalize provided quaternion
QuaternionNormalize :: proc(q: quaternion128) -> quaternion128 {
    return linalg.quaternion_normalize_safe(q)
}

// Scale quaternion by float value
QuaternionScale :: proc(q: quaternion128, mul: f32) -> quaternion128 {
    return q * quaternion128(mul)
}

// Calculate linear interpolation between two quaternions
QuaternionLerp :: proc(q1, q2: quaternion128, amount: f32) -> (q3: quaternion128) {
    q3.x = q1.x + (q2.x-q1.x)*amount
    q3.y = q1.y + (q2.y-q1.y)*amount
    q3.z = q1.z + (q2.z-q1.z)*amount
    q3.w = q1.w + (q2.w-q1.w)*amount
    return
}

QuaternionToEuler :: proc(q: quaternion128) -> [3]f32 {
    result: [3]f32

    // Roll (x-axis rotation)
    x0 := 2.0*(q.w*q.x + q.y*q.z)
    x1 := 1.0 - 2.0*(q.x*q.x + q.y*q.y)
    result.x = math.atan2(x0, x1)

    // Pitch (y-axis rotation)
    y0 := 2.0*(q.w*q.y - q.z*q.x)
    y0 =  1.0 if y0 >  1.0 else y0
    y0 = -1.0 if y0 < -1.0 else y0
    result.y = math.asin(y0)

    // Yaw (z-axis rotation)
    z0 := 2.0*(q.w*q.z + q.x*q.y)
    z1 := 1.0 - 2.0*(q.y*q.y + q.z*q.z)
    result.z = math.atan2(z0, z1)

    return result
}

// Transform a quaternion given a transformation matrix
QuaternionTransform :: proc(q: quaternion128, mat: Mat4_RowMajor) -> quaternion128 {
    v := mat * transmute([4]f32)q
    return transmute(quaternion128)v
}

// Check whether two given quaternions are almost equal
QuaternionEquals :: proc(p, q: quaternion128) -> bool {
    return FloatEquals(p.x, q.x) &&
           FloatEquals(p.y, q.y) &&
           FloatEquals(p.z, q.z) &&
           FloatEquals(p.w, q.w)
}

@(private)
fmaxf :: proc(x, y: f32) -> f32 {
    if math.is_nan_f32(x) {
        return y
    }

    if math.is_nan_f32(y) {
        return x
    }

    if math.sign_bit_f32(x) != math.sign_bit_f32(y) {
        return y if math.sign_bit_f32(x) else x
    }

    return y if x < y else x
}
