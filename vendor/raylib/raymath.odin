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
    return value - (max - min)*math.floor((value - min)/(max - min))
}

// Check whether two given floats are almost equal

FloatEquals :: proc(x, y: f32) -> bool {
    return abs(x - y) <= EPSILON*fmaxf(1.0, fmaxf(abs(x), abs(y)))
}



//----------------------------------------------------------------------------------
// Module Functions Definition - Vector2 math
//----------------------------------------------------------------------------------


// Vector with components value 0.0
@(deprecated="Prefer Vector2(0)")
Vector2Zero :: proc() -> Vector2 {
    return Vector2(0)
}
// Vector with components value 1.0
@(deprecated="Prefer Vector2(1)")
Vector2One :: proc() -> Vector2 {
    return Vector2(1)
}
// Add two vectors (v1 + v2)
@(deprecated="Prefer v1 + v2")
Vector2Add :: proc(v1, v2: Vector2) -> Vector2 {
    return v1 + v2
}
// Add vector and float value
@(deprecated="Prefer v + value")
Vector2AddValue :: proc(v: Vector2, value: f32) -> Vector2 {
    return v + value
}
// Subtract two vectors (v1 - v2)
@(deprecated="Prefer a - b")
Vector2Subtract :: proc(a, b: Vector2) -> Vector2 {
    return a - b
}
// Subtract vector by float value
@(deprecated="Prefer v + value")
Vector2SubtractValue :: proc(v: Vector2, value: f32) -> Vector2 {
    return v - value
}
// Calculate vector length

Vector2Length :: proc(v: Vector2) -> f32 {
    return linalg.length(v)
}
// Calculate vector square length

Vector2LengthSqr :: proc(v: Vector2) -> f32 {
    return linalg.length2(v)
}
// Calculate two vectors dot product

Vector2DotProduct :: proc(v1, v2: Vector2) -> f32 {
    return linalg.dot(v1, v2)
}
// Calculate distance between two vectors

Vector2Distance :: proc(v1, v2: Vector2) -> f32 {
    return linalg.distance(v1, v2)
}
// Calculate square distance between two vectors

Vector2DistanceSqrt :: proc(v1, v2: Vector2) -> f32 {
    return linalg.length2(v2-v1)
}
// Calculate angle between two vectors
// NOTE: Angle is calculated from origin point (0, 0)

Vector2Angle :: proc(v1, v2: Vector2) -> f32 {
    return linalg.angle_between(v1, v2)
}

// Calculate angle defined by a two vectors line
// NOTE: Parameters need to be normalized
// Current implementation should be aligned with glm::angle

Vector2LineAngle :: proc(start, end: Vector2) -> f32 {
    // TODO(10/9/2023): Currently angles move clockwise, determine if this is wanted behavior
    return -math.atan2(end.y - start.y, end.x - start.x)
}

// Scale vector (multiply by value)
@(deprecated="Prefer v * scale")
Vector2Scale :: proc(v: Vector2, scale: f32) -> Vector2 {
    return v * scale
}
// Multiply vector by vector
@(deprecated="Prefer v1 * v2")
Vector2Multiply :: proc(v1, v2: Vector2) -> Vector2 {
    return v1 * v2
}
// Negate vector
@(deprecated="Prefer -v")
Vector2Negate :: proc(v: Vector2) -> Vector2 {
    return -v
}
// Divide vector by vector
@(deprecated="Prefer v1 / v2")
Vector2Divide :: proc(v1, v2: Vector2) -> Vector2 {
    return v1 / v2
}
// Normalize provided vector

Vector2Normalize :: proc(v: Vector2) -> Vector2 {
    return linalg.normalize0(v)
}
// Transforms a Vector2 by a given Matrix

Vector2Transform :: proc(v: Vector2, m: Matrix) -> Vector2 {
    v4 := Vector4{v.x, v.y, 0, 1}
    return (m * v4).xy
}
// Calculate linear interpolation between two vectors
@(deprecated="Prefer = linalg.lerp(v1, v2, amount)")
Vector2Lerp :: proc(v1, v2: Vector2, amount: f32) -> Vector2 {
    return linalg.lerp(v1, v2, Vector2(amount))
}
// Calculate reflected vector to normal
@(deprecated="Prefer = linalg.reflect(v, normal)")
Vector2Reflect :: proc(v, normal: Vector2) -> Vector2 {
    return linalg.reflect(v, normal)
}
// Rotate vector by angle

Vector2Rotate :: proc(v: Vector2, angle: f32) -> Vector2 {
    c, s := math.cos(angle), math.sin(angle)

    return Vector2{
        v.x*c - v.y*s,
        v.x*s + v.y*c,
    }
}

// Move Vector towards target

Vector2MoveTowards :: proc(v, target: Vector2, maxDistance: f32) -> Vector2 {
    dv := target - v
    value := linalg.dot(dv, dv)

    if value == 0 || (maxDistance >= 0 && value <= maxDistance*maxDistance) {
        return target
    }

    dist := math.sqrt(value)
    return v + dv/dist*maxDistance
}

// Invert the given vector
@(deprecated="Prefer 1.0/v")
Vector2Invert :: proc(v: Vector2) -> Vector2 {
    return 1.0/v
}

// Clamp the components of the vector between
// min and max values specified by the given vectors

Vector2Clamp :: proc(v: Vector2, min, max: Vector2) -> Vector2 {
    return Vector2{
        clamp(v.x, min.x, max.x),
        clamp(v.y, min.y, max.y),
    }
}

// Clamp the magnitude of the vector between two min and max values

Vector2ClampValue :: proc(v: Vector2, min, max: f32) -> Vector2 {
    result := v

    length := linalg.dot(v, v)
    if length > 0 {
        length = math.sqrt(length)
        scale := f32(1)
        if length < min {
            scale = min/length
        } else if length > max {
            scale = max/length
        }
        result = v*scale
    }
    return result
}


Vector2Equals :: proc(p, q: Vector2) -> bool {
    return FloatEquals(p.x, q.x) &&
           FloatEquals(p.y, q.y)
}



//----------------------------------------------------------------------------------
// Module Functions Definition - Vector3 math
//----------------------------------------------------------------------------------


// Vector with components value 0.0
@(deprecated="Prefer Vector3(0)")
Vector3Zero :: proc() -> Vector3 {
    return Vector3(0)
}
// Vector with components value 1.0
@(deprecated="Prefer Vector3(1)")
Vector3One :: proc() -> Vector3 {
    return Vector3(1)
}
// Add two vectors (v1 + v2)
@(deprecated="Prefer v1 + v2")
Vector3Add :: proc(v1, v2: Vector3) -> Vector3 {
    return v1 + v2
}
// Add vector and float value
@(deprecated="Prefer v + value")
Vector3AddValue :: proc(v: Vector3, value: f32) -> Vector3 {
    return v + value
}
// Subtract two vectors (v1 - v2)
@(deprecated="Prefer a - b")
Vector3Subtract :: proc(a, b: Vector3) -> Vector3 {
    return a - b
}
// Subtract vector by float value
@(deprecated="Prefer v + value")
Vector3SubtractValue :: proc(v: Vector3, value: f32) -> Vector3 {
    return v - value
}
// Calculate vector length

Vector3Length :: proc(v: Vector3) -> f32 {
    return linalg.length(v)
}
// Calculate vector square length

Vector3LengthSqr :: proc(v: Vector3) -> f32 {
    return linalg.length2(v)
}
// Calculate two vectors dot product

Vector3DotProduct :: proc(v1, v2: Vector3) -> f32 {
    return linalg.dot(v1, v2)
}
// Calculate two vectors dot product

Vector3CrossProduct :: proc(v1, v2: Vector3) -> Vector3 {
    return linalg.cross(v1, v2)
}
// Calculate distance between two vectors

Vector3Distance :: proc(v1, v2: Vector3) -> f32 {
    return linalg.distance(v1, v2)
}
// Calculate square distance between two vectors

Vector3DistanceSqrt :: proc(v1, v2: Vector3) -> f32 {
    return linalg.length2(v2-v1)
}
// Calculate angle between two vectors
// NOTE: Angle is calculated from origin point (0, 0)

Vector3Angle :: proc(v1, v2: Vector3) -> f32 {
    return linalg.angle_between(v1, v2)
}

// Calculate angle defined by a two vectors line
// NOTE: Parameters need to be normalized
// Current implementation should be aligned with glm::angle

Vector3LineAngle :: proc(start, end: Vector3) -> f32 {
    // TODO(10/9/2023): Currently angles move clockwise, determine if this is wanted behavior
    return -math.atan2(end.y - start.y, end.x - start.x)
}

// Scale vector (multiply by value)
@(deprecated="Prefer v * scale")
Vector3Scale :: proc(v: Vector3, scale: f32) -> Vector3 {
    return v * scale
}
// Multiply vector by vector
@(deprecated="Prefer v1 * v2")
Vector3Multiply :: proc(v1, v2: Vector3) -> Vector3 {
    return v1 * v2
}
// Negate vector
@(deprecated="Prefer -v")
Vector3Negate :: proc(v: Vector3) -> Vector3 {
    return -v
}
// Divide vector by vector
@(deprecated="Prefer v1 / v2")
Vector3Divide :: proc(v1, v2: Vector3) -> Vector3 {
    return v1 / v2
}
// Normalize provided vector

Vector3Normalize :: proc(v: Vector3) -> Vector3 {
    return linalg.normalize0(v)
}

// Calculate the projection of the vector v1 on to v2

Vector3Project :: proc(v1, v2: Vector3) -> Vector3 {
    return linalg.projection(v1, v2)
}

// Calculate the rejection  of the vector v1 on to v2

Vector3Reject :: proc(v1, v2: Vector3) -> Vector3 {
    mag := linalg.dot(v1, v2)/linalg.dot(v2, v2)
    return v1 - v2*mag
}

// Orthonormalize provided vectors
// Makes vectors normalized and orthogonal to each other
// Gram-Schmidt function implementation
Vector3OrthoNormalize :: proc(v1, v2: ^Vector3) {
    v1^ = linalg.normalize0(v1^)
    v3 := linalg.normalize0(linalg.cross(v1^, v2^))
    v2^ = linalg.cross(v3, v1^)
}

// Transform a vector by quaternion rotation

Vector3RotateByQuaternion :: proc(v: Vector3, q: Quaternion) -> Vector3 {
    return linalg.mul(q, v)
}

// Rotates a vector around an axis

Vector3RotateByAxisAngle :: proc(v: Vector3, axis: Vector3, angle: f32) -> Vector3 {
    axis, angle := axis, angle

    axis = linalg.normalize0(axis)

    angle *= 0.5
    a := math.sin(angle)
    b := axis.x*a
    c := axis.y*a
    d := axis.z*a
    a = math.cos(angle)
    w := Vector3{b, c, d}

    wv := linalg.cross(w, v)
    wwv := linalg.cross(w, wv)

    a *= 2
    wv *= a

    wwv *= 2

    return v + wv + wwv

}

// Transforms a Vector3 by a given Matrix

Vector3Transform :: proc(v: Vector3, m: Matrix) -> Vector3 {
    v4 := Vector4{v.x, v.y, v.z, 1}
    return (m * v4).xyz
}
// Calculate linear interpolation between two vectors
@(deprecated="Prefer = linalg.lerp(v1, v2, amount)")
Vector3Lerp :: proc(v1, v2: Vector3, amount: f32) -> Vector3 {
    return linalg.lerp(v1, v2, Vector3(amount))
}
// Calculate reflected vector to normal
@(deprecated="Prefer = linalg.reflect(v, normal)")
Vector3Reflect :: proc(v, normal: Vector3) -> Vector3 {
    return linalg.reflect(v, normal)
}
// Compute the direction of a refracted ray
// v: normalized direction of the incoming ray
// n: normalized normal vector of the interface of two optical media
// r: ratio of the refractive index of the medium from where the ray comes
//    to the refractive index of the medium on the other side of the surface
@(deprecated="Prefer = linalg.refract(v, n, r)")
Vector3Refract :: proc(v, n: Vector3, r: f32) -> Vector3 {
    return linalg.refract(v, n, r)
}

// Move Vector towards target

Vector3MoveTowards :: proc(v, target: Vector3, maxDistance: f32) -> Vector3 {
    dv := target - v
    value := linalg.dot(dv, dv)

    if value == 0 || (maxDistance >= 0 && value <= maxDistance*maxDistance) {
        return target
    }

    dist := math.sqrt(value)
    return v + dv/dist*maxDistance
}

// Invert the given vector
@(deprecated="Prefer 1.0/v")
Vector3Invert :: proc(v: Vector3) -> Vector3 {
    return 1.0/v
}

// Clamp the components of the vector between
// min and max values specified by the given vectors

Vector3Clamp :: proc(v: Vector3, min, max: Vector3) -> Vector3 {
    return Vector3{
        clamp(v.x, min.x, max.x),
        clamp(v.y, min.y, max.y),
        clamp(v.z, min.z, max.z),
    }
}

// Clamp the magnitude of the vector between two min and max values

Vector3ClampValue :: proc(v: Vector3, min, max: f32) -> Vector3 {
    result := v

    length := linalg.dot(v, v)
    if length > 0 {
        length = math.sqrt(length)
        scale := f32(1)
        if length < min {
            scale = min/length
        } else if length > max {
            scale = max/length
        }
        result = v*scale
    }
    return result
}


Vector3Equals :: proc(p, q: Vector3) -> bool {
    return FloatEquals(p.x, q.x) &&
           FloatEquals(p.y, q.y) &&
           FloatEquals(p.z, q.z)
}



Vector3Min :: proc(v1, v2: Vector3) -> Vector3 {
    return linalg.min(v1, v2)
}


Vector3Max :: proc(v1, v2: Vector3) -> Vector3 {
    return linalg.max(v1, v2)
}


// Compute barycenter coordinates (u, v, w) for point p with respect to triangle (a, b, c)
// NOTE: Assumes P is on the plane of the triangle

Vector3Barycenter :: proc(p: Vector3, a, b, c: Vector3) -> (result: Vector3) {
    v0 := b - a
    v1 := c - a
    v2 := p - a
    d00 := linalg.dot(v0, v0)
    d01 := linalg.dot(v0, v1)
    d11 := linalg.dot(v1, v1)
    d20 := linalg.dot(v2, v0)
    d21 := linalg.dot(v2, v1)

    denom := d00*d11 - d01*d01

    result.y = (d11*d20 - d01*d21)/denom
    result.z = (d00*d21 - d01*d20)/denom
    result.x = 1 - (result.z + result.y)

    return result
}


// Projects a Vector3 from screen space into object space

Vector3Unproject :: proc(source: Vector3, projection: Matrix, view: Matrix) -> Vector3 {
    matViewProj := view * projection

    matViewProjInv := linalg.inverse(matViewProj)

    quat: Quaternion
    quat.x = source.x
    quat.y = source.y
    quat.z = source.z
    quat.w = 1

    qtransformed := QuaternionTransform(quat, matViewProjInv)

    return Vector3{qtransformed.x/qtransformed.w, qtransformed.y/qtransformed.w, qtransformed.z/qtransformed.w}
}



//----------------------------------------------------------------------------------
// Module Functions Definition - Matrix math
//----------------------------------------------------------------------------------

// Compute matrix determinant

MatrixDeterminant :: proc(mat: Matrix) -> f32 {
    return linalg.determinant(mat)
}

// Get the trace of the matrix (sum of the values along the diagonal)

MatrixTrace :: proc(mat: Matrix) -> f32 {
    return linalg.trace(mat)
}

// Transposes provided matrix

MatrixTranspose :: proc(mat: Matrix) -> Matrix {
    return linalg.transpose(mat)
}

// Invert provided matrix

MatrixInvert :: proc(mat: Matrix) -> Matrix {
    return linalg.inverse(mat)
}

// Get identity matrix
@(deprecated="Prefer Matrix(1)")
MatrixIdentity :: proc() -> Matrix {
    return Matrix(1)
}

// Add two matrices
@(deprecated="Prefer left + right")
MatrixAdd :: proc(left, right: Matrix) -> Matrix {
    return left + right
}

// Subtract two matrices (left - right)
@(deprecated="Prefer left - right")
MatrixSubtract :: proc(left, right: Matrix) -> Matrix {
    return left - right
}

// Get two matrix multiplication
// NOTE: When multiplying matrices... the order matters!
@(deprecated="Prefer left * right")
MatrixMultiply :: proc(left, right: Matrix) -> Matrix {
    return left * right
}

// Get translation matrix

MatrixTranslate :: proc(x, y, z: f32) -> Matrix {
    return {
        1, 0, 0, x,
        0, 1, 0, y,
        0, 0, 1, z,
        0, 0, 0, 1,
    }
}

// Create rotation matrix from axis and angle
// NOTE: Angle should be provided in radians

MatrixRotate :: proc(axis: Vector3, angle: f32) -> Matrix {
    return auto_cast linalg.matrix4_rotate(angle, axis)
}

// Get x-rotation matrix
// NOTE: Angle must be provided in radians

MatrixRotateX :: proc(angle: f32) -> Matrix {
    return auto_cast linalg.matrix4_rotate(angle, Vector3{1, 0, 0})
}

// Get y-rotation matrix
// NOTE: Angle must be provided in radians

MatrixRotateY :: proc(angle: f32) -> Matrix {
    return auto_cast linalg.matrix4_rotate(angle, Vector3{0, 1, 0})
}

// Get z-rotation matrix
// NOTE: Angle must be provided in radians

MatrixRotateZ :: proc(angle: f32) -> Matrix {
    return auto_cast linalg.matrix4_rotate(angle, Vector3{0, 0, 1})
}

// Get xyz-rotation matrix
// NOTE: Angle must be provided in radians

MatrixRotateXYZ :: proc(angle: Vector3) -> Matrix {
    return auto_cast linalg.matrix4_from_euler_angles_xyz(angle.x, angle.y, angle.z)
}

// Get zyx-rotation matrix
// NOTE: Angle must be provided in radians

MatrixRotateZYX :: proc(angle: Vector3) -> Matrix {
    return auto_cast linalg.matrix4_from_euler_angles_zyx(angle.x, angle.y, angle.z)
}


// Get scaling matrix

MatrixScale :: proc(x, y, z: f32) -> Matrix {
    return auto_cast linalg.matrix4_scale(Vector3{x, y, z})
}

// Get orthographic projection matrix

MatrixOrtho :: proc(left, right, bottom, top, near, far: f32) -> Matrix {
    return auto_cast linalg.matrix_ortho3d(left, right, bottom, top, near, far)
}

// Get perspective projection matrix
// NOTE: Fovy angle must be provided in radians

MatrixPerspective :: proc(fovY, aspect, nearPlane, farPlane: f32) -> Matrix {
    return auto_cast linalg.matrix4_perspective(fovY, aspect, nearPlane, farPlane)
}
// Get camera look-at matrix (view matrix)

MatrixLookAt :: proc(eye, target, up: Vector3) -> Matrix {
    return auto_cast linalg.matrix4_look_at(eye, target, up)
}

// Get float array of matrix data

MatrixToFloatV :: proc(mat: Matrix) -> [16]f32 {
    return transmute([16]f32)linalg.transpose(mat)
}


//----------------------------------------------------------------------------------
// Module Functions Definition - Quaternion math
//----------------------------------------------------------------------------------



// Add two quaternions
@(deprecated="Prefer q1 + q2")
QuaternionAdd :: proc(q1, q2: Quaternion) -> Quaternion {
    return q1 + q2
}
// Add quaternion and float value

QuaternionAddValue :: proc(q: Quaternion, add: f32) -> Quaternion {
    return q + Quaternion(add)
}
// Subtract two quaternions
@(deprecated="Prefer q1 - q2")
QuaternionSubtract :: proc(q1, q2: Quaternion) -> Quaternion {
    return q1 - q2
}
// Subtract quaternion and float value

QuaternionSubtractValue :: proc(q: Quaternion, sub: f32) -> Quaternion {
    return q - Quaternion(sub)
}
// Get identity quaternion
@(deprecated="Prefer Quaternion(1)")
QuaternionIdentity :: proc() -> Quaternion {
    return 1
}
// Computes the length of a quaternion
@(deprecated="Prefer abs(q)")
QuaternionLength :: proc(q: Quaternion) -> f32 {
    return abs(q)
}
// Normalize provided quaternion

QuaternionNormalize :: proc(q: Quaternion) -> Quaternion {
    return linalg.normalize0(q)
}
// Invert provided quaternion
@(deprecated="Prefer 1/q")
QuaternionInvert :: proc(q: Quaternion) -> Quaternion {
    return 1/q
}
// Calculate two quaternion multiplication
@(deprecated="Prefer q1 * q2")
QuaternionMultiply :: proc(q1, q2: Quaternion) -> Quaternion {
    return q1 * q2
}
// Scale quaternion by float value

QuaternionScale :: proc(q: Quaternion, mul: f32) -> Quaternion {
    return q * Quaternion(mul)
}
// Divide two quaternions
@(deprecated="Prefer q1 / q2")
QuaternionDivide :: proc(q1, q2: Quaternion) -> Quaternion {
    return q1 / q2
}
// Calculate linear interpolation between two quaternions

QuaternionLerp :: proc(q1, q2: Quaternion, amount: f32) -> (q3: Quaternion) {
    q3.x = q1.x + (q2.x-q1.x)*amount
    q3.y = q1.y + (q2.y-q1.y)*amount
    q3.z = q1.z + (q2.z-q1.z)*amount
    q3.w = q1.w + (q2.w-q1.w)*amount
    return
}
// Calculate slerp-optimized interpolation between two quaternions

QuaternionNlerp :: proc(q1, q2: Quaternion, amount: f32) -> Quaternion {
    return linalg.quaternion_nlerp(q1, q2, amount)
}
// Calculates spherical linear interpolation between two quaternions

QuaternionSlerp :: proc(q1, q2: Quaternion, amount: f32) -> Quaternion {
    return linalg.quaternion_slerp(q1, q2, amount)
}
// Calculate quaternion based on the rotation from one vector to another

QuaternionFromVector3ToVector3 :: proc(from, to: Vector3) -> Quaternion {
    return linalg.quaternion_between_two_vector3(from, to)
}
// Get a quaternion for a given rotation matrix

QuaternionFromMatrix :: proc(mat: Matrix) -> Quaternion {
    return linalg.quaternion_from_matrix4((matrix[4, 4]f32)(mat))
}
// Get a matrix for a given quaternion

QuaternionToMatrix :: proc(q: Quaternion) -> Matrix {
    return auto_cast linalg.matrix4_from_quaternion(q)
}
// Get rotation quaternion for an angle and axis NOTE: Angle must be provided in radians

QuaternionFromAxisAngle :: proc(axis: Vector3, angle: f32) -> Quaternion {
    return linalg.quaternion_angle_axis(angle, axis)
}
// Get the rotation angle and axis for a given quaternion

QuaternionToAxisAngle :: proc(q: Quaternion) -> (outAxis: Vector3, outAngle: f32) {
    outAngle, outAxis = linalg.angle_axis_from_quaternion(q)
    return
}
// Get the quaternion equivalent to Euler angles NOTE: Rotation order is ZYX

QuaternionFromEuler :: proc(pitch, yaw, roll: f32) -> Quaternion {
    return linalg.quaternion_from_pitch_yaw_roll(pitch, yaw, roll)
}
// Get the Euler angles equivalent to quaternion (roll, pitch, yaw) NOTE: Angles are returned in a Vector3 struct in radians

QuaternionToEuler :: proc(q: Quaternion) -> Vector3 {
    result: Vector3

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

QuaternionTransform :: proc(q: Quaternion, mat: Matrix) -> Quaternion {
    v := mat * transmute(Vector4)q
    return transmute(Quaternion)v
}
// Check whether two given quaternions are almost equal

QuaternionEquals :: proc(p, q: Quaternion) -> bool {
    return FloatEquals(p.x, q.x) &&
           FloatEquals(p.y, q.y) &&
           FloatEquals(p.z, q.z) &&
           FloatEquals(p.w, q.w)
}

@(private)
fmaxf :: proc(x, y: f32) -> f32 {
    if math.is_nan(x) {
        return y
    }

    if math.is_nan(y) {
        return x
    }

    if math.sign_bit(x) != math.sign_bit(y) {
        return y if math.sign_bit(x) else x
    }

    return y if x < y else x
}
