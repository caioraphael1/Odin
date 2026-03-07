import "core:c"
import "base:math"

EPSILON :: math.F32_EPSILON

Vec2 :: [2]f32

// Cosine and sine pair
// This uses a custom implementation designed for cross-platform determinism
CosSin :: struct {
	// cosine and sine
	cosine: f32,
	sine:   f32,
}

Rot :: struct {
	c, s: f32, // cosine and sine
}

Transform :: struct {
	p: Vec2,
	q: Rot,
}

Mat22 :: matrix[2, 2]f32
AABB :: struct {
	lowerBound: Vec2,
	upperBound: Vec2,
}

// separation = dot(normal, point) - offset
Plane :: struct {
	normal: Vec2,
	offset: f32,
}

PI :: math.PI

Vec2_zero          :: Vec2{0, 0}
Rot_identity       :: Rot{1, 0}
Transform_identity :: Transform{{0, 0}, {1, 0}}
Mat22_zero         :: Mat22{0, 0, 0, 0}

// the minimum of two integers
@(deprecated="Prefer the built-in 'min(a, b)'")
MinInt :: proc "c" (a, b: c.int) -> c.int {
	return min(a, b)
}

// the maximum of two integers
@(deprecated="Prefer the built-in 'max(a, b)'")
MaxInt :: proc "c" (a, b: c.int) -> c.int {
	return max(a, b)
}

// the absolute value of an integer
@(deprecated="Prefer the built-in 'abs(a)'")
AbsInt :: proc "c" (a: c.int) -> c.int {
	return abs(a)
}

// an integer clamped between a lower and upper bound
@(deprecated="Prefer the built-in 'clamp(a, lower, upper)'")
ClampInt :: proc "c" (a, lower, upper: c.int) -> c.int {
	return clamp(a, lower, upper)
}


// the minimum of two floats
@(deprecated="Prefer the built-in 'min(a, b)'")
MinFloat :: proc "c" (a, b: f32) -> f32 {
	return min(a, b)
}

// the maximum of two floats
@(deprecated="Prefer the built-in 'max(a, b)'")
MaxFloat :: proc "c" (a, b: f32) -> f32 {
	return max(a, b)
}

// the absolute value of a float
@(deprecated="Prefer the built-in 'abs(a)'")
AbsFloat :: proc "c" (a: f32) -> f32 {
	return abs(a)
}

// a f32 clamped between a lower and upper bound
@(deprecated="Prefer the built-in 'clamp(a, lower, upper)'")
ClampFloat :: proc "c" (a, lower, upper: f32) -> f32 {
	return clamp(a, lower, upper)
}


Atan2 :: proc "c" (y, x: f32) -> f32 {
	return math.atan2(y, x)
}


ComputeCosSin :: proc "c" (radians: f32) -> (res: CosSin) {
	res.sine, res.cosine = math.sincos(radians)
	return
}

// Vector dot product

Dot :: proc "c" (a, b: Vec2) -> f32 {
	return a.x * b.x + a.y * b.y
}

// Vector cross product. In 2D this yields a scalar.

Cross :: proc "c" (a, b: Vec2) -> f32 {
	return a.x * b.y - a.y * b.x
}

// Perform the cross product on a vector and a scalar. In 2D this produces a vector.

CrossVS :: proc "c" (v: Vec2, s: f32) -> Vec2 {
	return {s * v.y, -s * v.x}
}

// Perform the cross product on a scalar and a vector. In 2D this produces a vector.

CrossSV :: proc "c" (s: f32, v: Vec2) -> Vec2 {
	return {-s * v.y, s * v.x}
}

// Get a left pointing perpendicular vector. Equivalent to b2CrossSV(1, v)

LeftPerp :: proc "c" (v: Vec2) -> Vec2 {
	return {-v.y, v.x}
}

// Get a right pointing perpendicular vector. Equivalent to b2CrossVS(v, 1)

RightPerp :: proc "c" (v: Vec2) -> Vec2 {
	return {v.y, -v.x}
}

// Vector addition
@(deprecated="Prefer 'a + b'")
Add :: proc "c" (a, b: Vec2) -> Vec2 {
	return a + b
}

// Vector subtraction
@(deprecated="Prefer 'a - b'")
Sub :: proc "c" (a, b: Vec2) -> Vec2 {
	return a - b
}

// Vector negation
@(deprecated="Prefer '-a'")
Neg :: proc "c" (a: Vec2) -> Vec2 {
	return -a
}

// Vector linear interpolation
// https://fgiesen.wordpress.com/2012/08/15/linear-interpolation-past-present-and-future/

Lerp :: proc "c" (a, b: Vec2, t: f32) -> Vec2 {
	return {(1 - t) * a.x + t * b.x, (1 - t) * a.y + t * b.y}
}

// Component-wise multiplication
@(deprecated="Prefer 'a * b'")
Mul :: proc "c" (a, b: Vec2) -> Vec2 {
	return a * b
}

// Multiply a scalar and vector
@(deprecated="Prefer 's * v'")
MulSV :: proc "c" (s: f32, v: Vec2) -> Vec2 {
	return s * v
}

// a + s * b
@(deprecated="Prefer 'a + s * b'")
MulAdd :: proc "c" (a: Vec2, s: f32, b: Vec2) -> Vec2 {
	return a + s * b
}

// a - s * b
@(deprecated="Prefer 'a - s * b'")
MulSub :: proc "c" (a: Vec2, s: f32, b: Vec2) -> Vec2 {
	return a - s * b
}

// Component-wise absolute vector

Abs :: proc "c" (a: Vec2) -> (b: Vec2) {
	b.x = abs(a.x)
	b.y = abs(a.y)
	return
}

// Component-wise minimum vector

Min :: proc "c" (a, b: Vec2) -> (c: Vec2) {
	c.x = min(a.x, b.x)
	c.y = min(a.y, b.y)
	return
}

// Component-wise maximum vector

Max :: proc "c" (a, b: Vec2) -> (c: Vec2) {
	c.x = max(a.x, b.x)
	c.y = max(a.y, b.y)
	return
}

// Component-wise clamp vector v into the range [a, b]

Clamp :: proc "c" (v: Vec2, a, b: Vec2) -> (c: Vec2) {
	c.x = clamp(v.x, a.x, b.x)
	c.y = clamp(v.y, a.y, b.y)
	return
}

// Get the length of this vector (the norm)

Length :: proc "c" (v: Vec2) -> f32 {
	return math.sqrt(v.x * v.x + v.y * v.y)
}

// Get the distance between two points

Distance :: proc "c" (a, b: Vec2) -> f32 {
	dx := b.x - a.x
	dy := b.y - a.y
	return math.sqrt(dx * dx + dy * dy)
}


Normalize :: proc "c" (v: Vec2) -> Vec2 {
	length := Length(v)
	if length < EPSILON {
		return Vec2_zero
	}
	invLength := 1 / length
	return invLength * v
}


IsNormalized :: proc "c" (v: Vec2) -> bool {
	aa := Dot(v, v)
	return abs(1. - aa) < 100. * EPSILON
}


NormalizeChecked :: proc(v: Vec2) -> Vec2 {
	length := Length(v)
	if length < 1e-23 {
		panic("zero-length Vec2")
	}
	invLength := 1 / length
	return invLength * v
}


GetLengthAndNormalize :: proc "c" (v: Vec2) -> (length: f32, vn: Vec2) {
	length = Length(v)
	if length < 1e-23 {
		return
	}
	invLength := 1 / length
	vn = invLength * v
	return
}

// Integration rotation from angular velocity
//	q1 initial rotation
//	deltaAngle the angular displacement in radians

IntegrateRotation :: proc "c" (q1: Rot, deltaAngle: f32) -> Rot {
	// dc/dt = -omega * sin(t)
	// ds/dt = omega * cos(t)
	// c2 = c1 - omega * h * s1
	// s2 = s1 + omega * h * c1
	q2 := Rot{q1.c - deltaAngle * q1.s, q1.s + deltaAngle * q1.c}
	mag := math.sqrt(q2.s * q2.s + q2.c * q2.c)
	invMag := f32(mag > 0.0 ? 1 / mag : 0.0)
	return {q2.c * invMag, q2.s * invMag}
}

// Get the length squared of this vector

LengthSquared :: proc "c" (v: Vec2) -> f32 {
	return v.x * v.x + v.y * v.y
}

// Get the distance squared between points

DistanceSquared :: proc "c" (a, b: Vec2) -> f32 {
	c := Vec2{b.x - a.x, b.y - a.y}
	return c.x * c.x + c.y * c.y
}

// Make a rotation using an angle in radians

MakeRot :: proc "c" (angle: f32) -> Rot {
	cs := ComputeCosSin(angle)
	return Rot{c=cs.cosine, s=cs.sine}
}

// Compute the rotation between two unit vectors

ComputeRotationBetweenUnitVectors :: proc(v1, v2: Vec2) -> Rot {
	return NormalizeRot({
		c = Dot(v1, v2),
		s = Cross(v1, v2),
	})
}

// Is this rotation normalized?

IsNormalizedRot :: proc "c" (q: Rot) -> bool {
	// larger tolerance due to failure on mingw 32-bit
	qq := q.s * q.s + q.c * q.c
	return 1.0 - 0.0006 < qq && qq < 1 + 0.0006
}

// Normalize rotation

NormalizeRot :: proc "c" (q: Rot) -> Rot {
	mag := math.sqrt(q.s * q.s + q.c * q.c)
	invMag := f32(mag > 0.0 ? 1.0 / mag : 0.0)
	return {q.c * invMag, q.s * invMag}
}

// Normalized linear interpolation
// https://fgiesen.wordpress.com/2012/08/15/linear-interpolation-past-present-and-future/
// https://web.archive.org/web/20170825184056/http://number-none.com/product/Understanding%20Slerp,%20Then%20Not%20Using%20It/

NLerp :: proc "c" (q1: Rot, q2: Rot, t: f32) -> Rot {
	omt := 1 - t
	return NormalizeRot({
		omt * q1.c + t * q2.c,
		omt * q1.s + t * q2.s,
	})
}

// Compute the angular velocity necessary to rotate between two rotations over a give time
//	q1 initial rotation
//	q2 final rotation
//	inv_h inverse time step

ComputeAngularVelocity :: proc "c" (q1: Rot, q2: Rot, inv_h: f32) -> f32 {
	// ds/dt = omega * cos(t)
	// dc/dt = -omega * sin(t)
	// s2 = s1 + omega * h * c1
	// c2 = c1 - omega * h * s1

	// omega * h * s1 = c1 - c2
	// omega * h * c1 = s2 - s1
	// omega * h = (c1 - c2) * s1 + (s2 - s1) * c1
	// omega * h = s1 * c1 - c2 * s1 + s2 * c1 - s1 * c1
	// omega * h = s2 * c1 - c2 * s1 = sin(a2 - a1) ~= a2 - a1 for small delta
	omega := inv_h * (q2.s * q1.c - q2.c * q1.s)
	return omega
}

// Get the angle in radians in the range [-pi, pi]

Rot_GetAngle :: proc "c" (q: Rot) -> f32 {
	return Atan2(q.s, q.c)
}

// Get the x-axis

Rot_GetXAxis :: proc "c" (q: Rot) -> Vec2 {
	return {q.c, q.s}
}

// Get the y-axis

Rot_GetYAxis :: proc "c" (q: Rot) -> Vec2 {
	return {-q.s, q.c}
}

// Multiply two rotations: q * r

MulRot :: proc "c" (q, r: Rot) -> (qr: Rot) {
	// [qc -qs] * [rc -rs] = [qc*rc-qs*rs -qc*rs-qs*rc]
	// [qs  qc]   [rs  rc]   [qs*rc+qc*rs -qs*rs+qc*rc]
	// s(q + r) = qs * rc + qc * rs
	// c(q + r) = qc * rc - qs * rs
	qr.s = q.s * r.c + q.c * r.s
	qr.c = q.c * r.c - q.s * r.s
	return
}

// Transpose multiply two rotations: qT * r

InvMulRot :: proc "c" (q, r: Rot) -> (qr: Rot) {
	// [ qc qs] * [rc -rs] = [qc*rc+qs*rs -qc*rs+qs*rc]
	// [-qs qc]   [rs  rc]   [-qs*rc+qc*rs qs*rs+qc*rc]
	// s(q - r) = qc * rs - qs * rc
	// c(q - r) = qc * rc + qs * rs
	qr.s = q.c * r.s - q.s * r.c
	qr.c = q.c * r.c + q.s * r.s
	return
}

// relative angle between b and a (rot_b * inv(rot_a))

RelativeAngle :: proc "c" (b, a: Rot) -> f32 {
	// sin(b - a) = bs * ac - bc * as
	// cos(b - a) = bc * ac + bs * as
	s := b.s * a.c - b.c * a.s
	c := b.c * a.c + b.s * a.s
	return Atan2(s, c)
}

// Convert any angle into the range [-pi, pi]

UnwindAngle :: proc "c" (radians: f32) -> f32 {
	return math.remainder(radians, 2. * PI)
}

// Rotate a vector

RotateVector :: proc "c" (q: Rot, v: Vec2) -> Vec2 {
	return {q.c * v.x - q.s * v.y, q.s * v.x + q.c * v.y}
}

// Inverse rotate a vector

InvRotateVector :: proc "c" (q: Rot, v: Vec2) -> Vec2 {
	return {q.c * v.x + q.s * v.y, -q.s * v.x + q.c * v.y}
}

// Transform a point (e.g. local space to world space)

TransformPoint :: proc "c" (t: Transform, p: Vec2) -> Vec2 {
	x := (t.q.c * p.x - t.q.s * p.y) + t.p.x
	y := (t.q.s * p.x + t.q.c * p.y) + t.p.y
	return {x, y}
}

// Inverse transform a point (e.g. world space to local space)

InvTransformPoint :: proc "c" (t: Transform, p: Vec2) -> Vec2 {
	vx := p.x - t.p.x
	vy := p.y - t.p.y
	return {t.q.c * vx + t.q.s * vy, -t.q.s * vx + t.q.c * vy}
}

// Multiply two transforms. If the result is applied to a point p local to frame B,
// the transform would first convert p to a point local to frame A, then into a point
// in the world frame.
// v2 = A.q.Rot(B.q.Rot(v1) + B.p) + A.p
//    = (A.q * B.q).Rot(v1) + A.q.Rot(B.p) + A.p

MulTransforms :: proc "c" (A, B: Transform) -> (C: Transform) {
	C.q = MulRot(A.q, B.q)
	C.p = RotateVector(A.q, B.p) + A.p
	return
}

// Creates a transform that converts a local point in frame B to a local point in frame A.
// v2 = A.q' * (B.q * v1 + B.p - A.p)
//    = A.q' * B.q * v1 + A.q' * (B.p - A.p)

InvMulTransforms :: proc "c" (A, B: Transform) -> (C: Transform) {
	C.q = InvMulRot(A.q, B.q)
	C.p = InvRotateVector(A.q, B.p-A.p)
	return
}

// Multiply a 2-by-2 matrix times a 2D vector
@(deprecated="Prefer 'A * v'")
MulMV :: proc "c" (A: Mat22, v: Vec2) -> Vec2 {
	return A * v
}

// Get the inverse of a 2-by-2 matrix

GetInverse22 :: proc "c" (A: Mat22) -> Mat22 {
	a := A[0, 0]
	b := A[0, 1]
	c := A[1, 0]
	d := A[1, 1]
	det := a * d - b * c
	if det != 0.0 {
		det = 1 / det
	}

	return Mat22{
		 det * d, -det * b,
		-det * c,  det * a,
	}
}

// Solve A * x = b, where b is a column vector. This is more efficient
// than computing the inverse in one-shot cases.

Solve22 :: proc "c" (A: Mat22, b: Vec2) -> Vec2 {
	a11 := A[0, 0]
	a12 := A[0, 1]
	a21 := A[1, 0]
	a22 := A[1, 1]
	det := a11 * a22 - a12 * a21
	if det != 0.0 {
		det = 1 / det
	}
	return {det * (a22 * b.x - a12 * b.y), det * (a11 * b.y - a21 * b.x)}
}

// Does a fully contain b

AABB_Contains :: proc "c" (a, b: AABB) -> bool {
	(a.lowerBound.x <= b.lowerBound.x) or_return
	(a.lowerBound.y <= b.lowerBound.y) or_return
	(b.upperBound.x <= a.upperBound.x) or_return
	(b.upperBound.y <= a.upperBound.y) or_return
	return true
}

// Get the center of the AABB.

AABB_Center :: proc "c" (a: AABB) -> Vec2 {
	return {0.5 * (a.lowerBound.x + a.upperBound.x), 0.5 * (a.lowerBound.y + a.upperBound.y)}
}

// Get the extents of the AABB (half-widths).

AABB_Extents :: proc "c" (a: AABB) -> Vec2 {
	return {0.5 * (a.upperBound.x - a.lowerBound.x), 0.5 * (a.upperBound.y - a.lowerBound.y)}
}

// Union of two AABBs

AABB_Union :: proc "c" (a, b: AABB) -> (c: AABB) {
	c.lowerBound.x = min(a.lowerBound.x, b.lowerBound.x)
	c.lowerBound.y = min(a.lowerBound.y, b.lowerBound.y)
	c.upperBound.x = max(a.upperBound.x, b.upperBound.x)
	c.upperBound.y = max(a.upperBound.y, b.upperBound.y)
	return
}

// Do a and b overlap

AABB_Overlaps :: proc "c" (a, b: AABB) -> bool {
	return !(
		b.lowerBound.x > a.upperBound.x ||
		b.lowerBound.y > a.upperBound.y ||
		a.lowerBound.x > b.upperBound.x ||
		a.lowerBound.y > b.upperBound.y \
	)
}

// Compute the bounding box of an array of circles

MakeAABB :: proc "c" (points: []Vec2, radius: f32) -> AABB {
	a := AABB{points[0], points[0]}
	for point in points {
		a.lowerBound = Min(a.lowerBound, point)
		a.upperBound = Max(a.upperBound, point)
	}

	r := Vec2{radius, radius}
	a.lowerBound = a.lowerBound - r
	a.upperBound = a.upperBound + r

	return a
}

// Signed separation of a point from a plane

PlaneSeparation :: proc "c" (plane: Plane, point: Vec2) -> f32 {
	return Dot(plane.normal, point) - plane.offset
}


IsValidFloat :: proc "c" (a: f32) -> bool {
	#partial switch math.classify(a) {
	case .NaN, .Inf, .Neg_Inf: return false
	case:                      return true
	}
}


IsValidVec2 :: proc "c" (v: Vec2) -> bool {
	IsValidFloat(v.x) or_return
	IsValidFloat(v.y) or_return
	return true
}


IsValidRotation :: proc "c" (q: Rot) -> bool {
	IsValidFloat(q.s) or_return
	IsValidFloat(q.c) or_return
	return IsNormalizedRot(q)
}

// Is this a valid bounding box? Not Nan or infinity. Upper bound greater than or equal to lower bound.

IsValidAABB :: proc "c" (aabb: AABB) -> bool {
	IsValidVec2(aabb.lowerBound) or_return
	IsValidVec2(aabb.upperBound) or_return
	(aabb.upperBound.x >= aabb.lowerBound.x) or_return
	(aabb.upperBound.y >= aabb.lowerBound.y) or_return
	return true
}

// Is this a valid plane? Normal is a unit vector. Not Nan or infinity.

IsValidPlane :: proc "c" (plane: Plane) -> bool {
	IsValidFloat(plane.offset) or_return
	IsValidVec2(plane.normal)  or_return
	IsNormalized(plane.normal) or_return
	return true
}

// One-dimensional mass-spring-damper simulation. Returns the new velocity given the position and time step.
// You can then compute the new position using:
// position += timeStep * newVelocity
// This drives towards a zero position. By using implicit integration we get a stable solution
// that doesn't require transcendental functions.

b2SpringDamper :: proc "c" (hertz, dampingRatio, position, velocity, timeStep: f32) -> f32 {
	omega  := 2. * PI * hertz
	omegaH := omega * timeStep
	return (velocity - omega * omegaH * position) / (1. + 2. * dampingRatio * omegaH + omegaH * omegaH)
}
