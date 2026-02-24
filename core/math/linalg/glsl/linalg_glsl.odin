// `GLSL`-like mathematics library plus numerous other utility procedures.
import "base:builtin"
import "base:intrinsics"

TAU :: 6.28318530717958647692528676655900576
PI  :: 3.14159265358979323846264338327950288
E   :: 2.71828182845904523536
τ   :: TAU
π   :: PI
e   :: E

SQRT_TWO   :: 1.41421356237309504880168872420969808
SQRT_THREE :: 1.73205080756887729352744634150587236
SQRT_FIVE  :: 2.23606797749978969640917366873127623

LN2  :: 0.693147180559945309417232121458176568
LN10 :: 2.30258509299404568401799145468436421

F32_EPSILON :: 1e-7
F64_EPSILON :: 1e-15

// Odin matrices are stored internally as Column-Major, which matches OpenGL/GLSL by default
mat2 :: matrix[2, 2]f32
mat3 :: matrix[3, 3]f32
mat4 :: matrix[4, 4]f32
mat2x2 :: mat2
mat3x3 :: mat3
mat4x4 :: mat4

// IMPORTANT NOTE: These data types are "backwards" in normal mathematical terms
// but they match how GLSL and OpenGL defines them in name
// Odin: matrix[R, C]f32 
// GLSL: matCxR
mat3x2 :: matrix[2, 3]f32
mat4x2 :: matrix[2, 4]f32
mat2x3 :: matrix[3, 2]f32
mat4x3 :: matrix[3, 4]f32
mat2x4 :: matrix[4, 2]f32
mat3x4 :: matrix[4, 3]f32

vec2 :: [2]f32
vec3 :: [3]f32
vec4 :: [4]f32

ivec2 :: [2]i32
ivec3 :: [3]i32
ivec4 :: [4]i32

uvec2 :: [2]u32
uvec3 :: [3]u32
uvec4 :: [4]u32

bvec2 :: [2]bool
bvec3 :: [3]bool
bvec4 :: [4]bool

quat :: quaternion128

// Double Precision (f64) Floating Point Types 

dmat2 :: matrix[2, 2]f64
dmat3 :: matrix[3, 3]f64
dmat4 :: matrix[4, 4]f64
dmat2x2 :: dmat2
dmat3x3 :: dmat3
dmat4x4 :: dmat4

dmat3x2 :: matrix[2, 3]f64
dmat4x2 :: matrix[2, 4]f64
dmat2x3 :: matrix[3, 2]f64
dmat4x3 :: matrix[3, 4]f64
dmat2x4 :: matrix[4, 2]f64
dmat3x4 :: matrix[4, 3]f64

dvec2 :: [2]f64
dvec3 :: [3]f64
dvec4 :: [4]f64

dquat :: quaternion256


cos_vec2  :: proc "c" (x: vec2) -> vec2 { return {cos(x.x), cos(x.y)} }
cos_vec3  :: proc "c" (x: vec3) -> vec3 { return {cos(x.x), cos(x.y), cos(x.z)} }
cos_vec4  :: proc "c" (x: vec4) -> vec4 { return {cos(x.x), cos(x.y), cos(x.z), cos(x.w)} }
cos_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {cos(x.x), cos(x.y)} }
cos_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {cos(x.x), cos(x.y), cos(x.z)} }
cos_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {cos(x.x), cos(x.y), cos(x.z), cos(x.w)} }


sin_vec2  :: proc "c" (x: vec2) -> vec2 { return {sin(x.x), sin(x.y)} }
sin_vec3  :: proc "c" (x: vec3) -> vec3 { return {sin(x.x), sin(x.y), sin(x.z)} }
sin_vec4  :: proc "c" (x: vec4) -> vec4 { return {sin(x.x), sin(x.y), sin(x.z), sin(x.w)} }
sin_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {sin(x.x), sin(x.y)} }
sin_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {sin(x.x), sin(x.y), sin(x.z)} }
sin_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {sin(x.x), sin(x.y), sin(x.z), sin(x.w)} }


tan_vec2  :: proc "c" (x: vec2) -> vec2 { return {tan(x.x), tan(x.y)} }
tan_vec3  :: proc "c" (x: vec3) -> vec3 { return {tan(x.x), tan(x.y), tan(x.z)} }
tan_vec4  :: proc "c" (x: vec4) -> vec4 { return {tan(x.x), tan(x.y), tan(x.z), tan(x.w)} }
tan_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {tan(x.x), tan(x.y)} }
tan_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {tan(x.x), tan(x.y), tan(x.z)} }
tan_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {tan(x.x), tan(x.y), tan(x.z), tan(x.w)} }


acos_vec2  :: proc "c" (x: vec2) -> vec2 { return {acos(x.x), acos(x.y)} }
acos_vec3  :: proc "c" (x: vec3) -> vec3 { return {acos(x.x), acos(x.y), acos(x.z)} }
acos_vec4  :: proc "c" (x: vec4) -> vec4 { return {acos(x.x), acos(x.y), acos(x.z), acos(x.w)} }
acos_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {acos(x.x), acos(x.y)} }
acos_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {acos(x.x), acos(x.y), acos(x.z)} }
acos_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {acos(x.x), acos(x.y), acos(x.z), acos(x.w)} }


asin_vec2  :: proc "c" (x: vec2) -> vec2 { return {asin(x.x), asin(x.y)} }
asin_vec3  :: proc "c" (x: vec3) -> vec3 { return {asin(x.x), asin(x.y), asin(x.z)} }
asin_vec4  :: proc "c" (x: vec4) -> vec4 { return {asin(x.x), asin(x.y), asin(x.z), asin(x.w)} }
asin_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {asin(x.x), asin(x.y)} }
asin_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {asin(x.x), asin(x.y), asin(x.z)} }
asin_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {asin(x.x), asin(x.y), asin(x.z), asin(x.w)} }


atan_vec2  :: proc "c" (x: vec2) -> vec2 { return {atan(x.x), atan(x.y)} }
atan_vec3  :: proc "c" (x: vec3) -> vec3 { return {atan(x.x), atan(x.y), atan(x.z)} }
atan_vec4  :: proc "c" (x: vec4) -> vec4 { return {atan(x.x), atan(x.y), atan(x.z), atan(x.w)} }
atan_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {atan(x.x), atan(x.y)} }
atan_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {atan(x.x), atan(x.y), atan(x.z)} }
atan_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {atan(x.x), atan(x.y), atan(x.z), atan(x.w)} }


atan2_vec2 :: proc "c" (y, x: vec2) -> vec2 { return {atan2(y.x, x.x), atan2(y.y, x.y)} }
atan2_vec3 :: proc "c" (y, x: vec3) -> vec3 { return {atan2(y.x, x.x), atan2(y.y, x.y), atan2(y.z, x.z)} }
atan2_vec4 :: proc "c" (y, x: vec4) -> vec4 { return {atan2(y.x, x.x), atan2(y.y, x.y), atan2(y.z, x.z), atan2(y.w, x.w)} }
atan2_dvec2 :: proc "c" (y, x: dvec2) -> dvec2 { return {atan2(y.x, x.x), atan2(y.y, x.y)} }
atan2_dvec3 :: proc "c" (y, x: dvec3) -> dvec3 { return {atan2(y.x, x.x), atan2(y.y, x.y), atan2(y.z, x.z)} }
atan2_dvec4 :: proc "c" (y, x: dvec4) -> dvec4 { return {atan2(y.x, x.x), atan2(y.y, x.y), atan2(y.z, x.z), atan2(y.w, x.w)} }


cosh_vec2 :: proc "c" (x: vec2) -> vec2 { return {cosh(x.x), cosh(x.y)} }
cosh_vec3 :: proc "c" (x: vec3) -> vec3 { return {cosh(x.x), cosh(x.y), cosh(x.z)} }
cosh_vec4 :: proc "c" (x: vec4) -> vec4 { return {cosh(x.x), cosh(x.y), cosh(x.z), cosh(x.w)} }
cosh_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {cosh(x.x), cosh(x.y)} }
cosh_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {cosh(x.x), cosh(x.y), cosh(x.z)} }
cosh_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {cosh(x.x), cosh(x.y), cosh(x.z), cosh(x.w)} }


sinh_vec2 :: proc "c" (x: vec2) -> vec2 { return {sinh(x.x), sinh(x.y)} }
sinh_vec3 :: proc "c" (x: vec3) -> vec3 { return {sinh(x.x), sinh(x.y), sinh(x.z)} }
sinh_vec4 :: proc "c" (x: vec4) -> vec4 { return {sinh(x.x), sinh(x.y), sinh(x.z), sinh(x.w)} }
sinh_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {sinh(x.x), sinh(x.y)} }
sinh_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {sinh(x.x), sinh(x.y), sinh(x.z)} }
sinh_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {sinh(x.x), sinh(x.y), sinh(x.z), sinh(x.w)} }


tanh_vec2 :: proc "c" (x: vec2) -> vec2 { return {tanh(x.x), tanh(x.y)} }
tanh_vec3 :: proc "c" (x: vec3) -> vec3 { return {tanh(x.x), tanh(x.y), tanh(x.z)} }
tanh_vec4 :: proc "c" (x: vec4) -> vec4 { return {tanh(x.x), tanh(x.y), tanh(x.z), tanh(x.w)} }
tanh_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {tanh(x.x), tanh(x.y)} }
tanh_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {tanh(x.x), tanh(x.y), tanh(x.z)} }
tanh_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {tanh(x.x), tanh(x.y), tanh(x.z), tanh(x.w)} }


acosh_vec2 :: proc "c" (x: vec2) -> vec2 { return {acosh(x.x), acosh(x.y)} }
acosh_vec3 :: proc "c" (x: vec3) -> vec3 { return {acosh(x.x), acosh(x.y), acosh(x.z)} }
acosh_vec4 :: proc "c" (x: vec4) -> vec4 { return {acosh(x.x), acosh(x.y), acosh(x.z), acosh(x.w)} }


acosh_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {acosh(x.x), acosh(x.y)} }
acosh_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {acosh(x.x), acosh(x.y), acosh(x.z)} }
acosh_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {acosh(x.x), acosh(x.y), acosh(x.z), acosh(x.w)} }


asinh_vec2 :: proc "c" (x: vec2) -> vec2 { return {asinh(x.x), asinh(x.y)} }
asinh_vec3 :: proc "c" (x: vec3) -> vec3 { return {asinh(x.x), asinh(x.y), asinh(x.z)} }
asinh_vec4 :: proc "c" (x: vec4) -> vec4 { return {asinh(x.x), asinh(x.y), asinh(x.z), asinh(x.w)} }


asinh_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {asinh(x.x), asinh(x.y)} }
asinh_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {asinh(x.x), asinh(x.y), asinh(x.z)} }
asinh_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {asinh(x.x), asinh(x.y), asinh(x.z), asinh(x.w)} }


atanh_vec2 :: proc "c" (x: vec2) -> vec2 { return {atanh(x.x), atanh(x.y)} }
atanh_vec3 :: proc "c" (x: vec3) -> vec3 { return {atanh(x.x), atanh(x.y), atanh(x.z)} }
atanh_vec4 :: proc "c" (x: vec4) -> vec4 { return {atanh(x.x), atanh(x.y), atanh(x.z), atanh(x.w)} }
atanh_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {atanh(x.x), atanh(x.y)} }
atanh_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {atanh(x.x), atanh(x.y), atanh(x.z)} }
atanh_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {atanh(x.x), atanh(x.y), atanh(x.z), atanh(x.w)} }


sqrt_vec2 :: proc "c" (x: vec2) -> vec2 { return {sqrt(x.x), sqrt(x.y)} }
sqrt_vec3 :: proc "c" (x: vec3) -> vec3 { return {sqrt(x.x), sqrt(x.y), sqrt(x.z)} }
sqrt_vec4 :: proc "c" (x: vec4) -> vec4 { return {sqrt(x.x), sqrt(x.y), sqrt(x.z), sqrt(x.w)} }
sqrt_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {sqrt(x.x), sqrt(x.y)} }
sqrt_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {sqrt(x.x), sqrt(x.y), sqrt(x.z)} }
sqrt_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {sqrt(x.x), sqrt(x.y), sqrt(x.z), sqrt(x.w)} }


inversesqrt_vec2 :: proc "c" (x: vec2) -> vec2 { return {inversesqrt(x.x), inversesqrt(x.y)} }
inversesqrt_vec3 :: proc "c" (x: vec3) -> vec3 { return {inversesqrt(x.x), inversesqrt(x.y), inversesqrt(x.z)} }
inversesqrt_vec4 :: proc "c" (x: vec4) -> vec4 { return {inversesqrt(x.x), inversesqrt(x.y), inversesqrt(x.z), inversesqrt(x.w)} }
inversesqrt_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {inversesqrt(x.x), inversesqrt(x.y)} }
inversesqrt_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {inversesqrt(x.x), inversesqrt(x.y), inversesqrt(x.z)} }
inversesqrt_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {inversesqrt(x.x), inversesqrt(x.y), inversesqrt(x.z), inversesqrt(x.w)} }


pow_vec2 :: proc "c" (x, y: vec2) -> vec2 { return {pow(x.x, y.x), pow(x.y, y.y)} }
pow_vec3 :: proc "c" (x, y: vec3) -> vec3 { return {pow(x.x, y.x), pow(x.y, y.y), pow(x.z, y.z)} }
pow_vec4 :: proc "c" (x, y: vec4) -> vec4 { return {pow(x.x, y.x), pow(x.y, y.y), pow(x.z, y.z), pow(x.w, y.w)} }
pow_dvec2 :: proc "c" (x, y: dvec2) -> dvec2 { return {pow(x.x, y.x), pow(x.y, y.y)} }
pow_dvec3 :: proc "c" (x, y: dvec3) -> dvec3 { return {pow(x.x, y.x), pow(x.y, y.y), pow(x.z, y.z)} }
pow_dvec4 :: proc "c" (x, y: dvec4) -> dvec4 { return {pow(x.x, y.x), pow(x.y, y.y), pow(x.z, y.z), pow(x.w, y.w)} }


exp_vec2 :: proc "c" (x: vec2) -> vec2 { return {exp(x.x), exp(x.y)} }
exp_vec3 :: proc "c" (x: vec3) -> vec3 { return {exp(x.x), exp(x.y), exp(x.z)} }
exp_vec4 :: proc "c" (x: vec4) -> vec4 { return {exp(x.x), exp(x.y), exp(x.z), exp(x.w)} }
exp_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {exp(x.x), exp(x.y)} }
exp_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {exp(x.x), exp(x.y), exp(x.z)} }
exp_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {exp(x.x), exp(x.y), exp(x.z), exp(x.w)} }


log_vec2 :: proc "c" (x: vec2) -> vec2 { return {log(x.x), log(x.y)} }
log_vec3 :: proc "c" (x: vec3) -> vec3 { return {log(x.x), log(x.y), log(x.z)} }
log_vec4 :: proc "c" (x: vec4) -> vec4 { return {log(x.x), log(x.y), log(x.z), log(x.w)} }
log_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {log(x.x), log(x.y)} }
log_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {log(x.x), log(x.y), log(x.z)} }
log_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {log(x.x), log(x.y), log(x.z), log(x.w)} }


exp2_vec2 :: proc "c" (x: vec2) -> vec2 { return {exp2(x.x), exp2(x.y)} }
exp2_vec3 :: proc "c" (x: vec3) -> vec3 { return {exp2(x.x), exp2(x.y), exp2(x.z)} }
exp2_vec4 :: proc "c" (x: vec4) -> vec4 { return {exp2(x.x), exp2(x.y), exp2(x.z), exp2(x.w)} }
exp2_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {exp2(x.x), exp2(x.y)} }
exp2_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {exp2(x.x), exp2(x.y), exp2(x.z)} }
exp2_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {exp2(x.x), exp2(x.y), exp2(x.z), exp2(x.w)} }


sign_i32 :: proc "c" (x: i32) -> i32 { return -1 if x < 0 else +1 if x > 0 else 0 }
sign_u32 :: proc "c" (x: u32) -> u32 { return +1 if x > 0 else 0 }
sign_vec2 :: proc "c" (x: vec2) -> vec2 { return {sign(x.x), sign(x.y)} }
sign_vec3 :: proc "c" (x: vec3) -> vec3 { return {sign(x.x), sign(x.y), sign(x.z)} }
sign_vec4 :: proc "c" (x: vec4) -> vec4 { return {sign(x.x), sign(x.y), sign(x.z), sign(x.w)} }
sign_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {sign(x.x), sign(x.y)} }
sign_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {sign(x.x), sign(x.y), sign(x.z)} }
sign_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {sign(x.x), sign(x.y), sign(x.z), sign(x.w)} }
sign_ivec2 :: proc "c" (x: ivec2) -> ivec2 { return {sign(x.x), sign(x.y)} }
sign_ivec3 :: proc "c" (x: ivec3) -> ivec3 { return {sign(x.x), sign(x.y), sign(x.z)} }
sign_ivec4 :: proc "c" (x: ivec4) -> ivec4 { return {sign(x.x), sign(x.y), sign(x.z), sign(x.w)} }
sign_uvec2 :: proc "c" (x: uvec2) -> uvec2 { return {sign(x.x), sign(x.y)} }
sign_uvec3 :: proc "c" (x: uvec3) -> uvec3 { return {sign(x.x), sign(x.y), sign(x.z)} }
sign_uvec4 :: proc "c" (x: uvec4) -> uvec4 { return {sign(x.x), sign(x.y), sign(x.z), sign(x.w)} }


floor_vec2 :: proc "c" (x: vec2) -> vec2 { return {floor(x.x), floor(x.y)} }
floor_vec3 :: proc "c" (x: vec3) -> vec3 { return {floor(x.x), floor(x.y), floor(x.z)} }
floor_vec4 :: proc "c" (x: vec4) -> vec4 { return {floor(x.x), floor(x.y), floor(x.z), floor(x.w)} }
floor_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {floor(x.x), floor(x.y)} }
floor_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {floor(x.x), floor(x.y), floor(x.z)} }
floor_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {floor(x.x), floor(x.y), floor(x.z), floor(x.w)} }


trunc_vec2 :: proc "c" (x: vec2) -> vec2 { return {trunc(x.x), trunc(x.y)} }
trunc_vec3 :: proc "c" (x: vec3) -> vec3 { return {trunc(x.x), trunc(x.y), trunc(x.z)} }
trunc_vec4 :: proc "c" (x: vec4) -> vec4 { return {trunc(x.x), trunc(x.y), trunc(x.z), trunc(x.w)} }
trunc_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {trunc(x.x), trunc(x.y)} }
trunc_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {trunc(x.x), trunc(x.y), trunc(x.z)} }
trunc_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {trunc(x.x), trunc(x.y), trunc(x.z), trunc(x.w)} }


round_vec2 :: proc "c" (x: vec2) -> vec2 { return {round(x.x), round(x.y)} }
round_vec3 :: proc "c" (x: vec3) -> vec3 { return {round(x.x), round(x.y), round(x.z)} }
round_vec4 :: proc "c" (x: vec4) -> vec4 { return {round(x.x), round(x.y), round(x.z), round(x.w)} }
round_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {round(x.x), round(x.y)} }
round_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {round(x.x), round(x.y), round(x.z)} }
round_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {round(x.x), round(x.y), round(x.z), round(x.w)} }


ceil_vec2 :: proc "c" (x: vec2) -> vec2 { return {ceil(x.x), ceil(x.y)} }
ceil_vec3 :: proc "c" (x: vec3) -> vec3 { return {ceil(x.x), ceil(x.y), ceil(x.z)} }
ceil_vec4 :: proc "c" (x: vec4) -> vec4 { return {ceil(x.x), ceil(x.y), ceil(x.z), ceil(x.w)} }
ceil_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {ceil(x.x), ceil(x.y)} }
ceil_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {ceil(x.x), ceil(x.y), ceil(x.z)} }
ceil_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {ceil(x.x), ceil(x.y), ceil(x.z), ceil(x.w)} }


mod_vec2 :: proc "c" (x, y: vec2) -> vec2 { return {mod(x.x, y.x), mod(x.y, y.y)} }
mod_vec3 :: proc "c" (x, y: vec3) -> vec3 { return {mod(x.x, y.x), mod(x.y, y.y), mod(x.z, y.z)} }
mod_vec4 :: proc "c" (x, y: vec4) -> vec4 { return {mod(x.x, y.x), mod(x.y, y.y), mod(x.z, y.z), mod(x.w, y.w)} }
mod_dvec2 :: proc "c" (x, y: dvec2) -> dvec2 { return {mod(x.x, y.x), mod(x.y, y.y)} }
mod_dvec3 :: proc "c" (x, y: dvec3) -> dvec3 { return {mod(x.x, y.x), mod(x.y, y.y), mod(x.z, y.z)} }
mod_dvec4 :: proc "c" (x, y: dvec4) -> dvec4 { return {mod(x.x, y.x), mod(x.y, y.y), mod(x.z, y.z), mod(x.w, y.w)} }


fract_vec2 :: proc "c" (x: vec2) -> vec2 { return {fract(x.x), fract(x.y)} }
fract_vec3 :: proc "c" (x: vec3) -> vec3 { return {fract(x.x), fract(x.y), fract(x.z)} }
fract_vec4 :: proc "c" (x: vec4) -> vec4 { return {fract(x.x), fract(x.y), fract(x.z), fract(x.w)} }
fract_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {fract(x.x), fract(x.y)} }
fract_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {fract(x.x), fract(x.y), fract(x.z)} }
fract_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {fract(x.x), fract(x.y), fract(x.z), fract(x.w)} }


radians_f32  :: proc "c" (degrees: f32)  -> f32  { return degrees * TAU / 360.0 }
radians_f64  :: proc "c" (degrees: f64)  -> f64  { return degrees * TAU / 360.0 }
radians_vec2 :: proc "c" (degrees: vec2) -> vec2 { return degrees * TAU / 360.0 }
radians_vec3 :: proc "c" (degrees: vec3) -> vec3 { return degrees * TAU / 360.0 }
radians_vec4 :: proc "c" (degrees: vec4) -> vec4 { return degrees * TAU / 360.0 }
radians_dvec2 :: proc "c" (degrees: dvec2) -> dvec2 { return degrees * TAU / 360.0 }
radians_dvec3 :: proc "c" (degrees: dvec3) -> dvec3 { return degrees * TAU / 360.0 }
radians_dvec4 :: proc "c" (degrees: dvec4) -> dvec4 { return degrees * TAU / 360.0 }


degrees_f32  :: proc "c" (radians: f32)  -> f32  { return radians * 360.0 / TAU }
degrees_f64  :: proc "c" (radians: f64)  -> f64  { return radians * 360.0 / TAU }
degrees_vec2 :: proc "c" (radians: vec2) -> vec2 { return radians * 360.0 / TAU }
degrees_vec3 :: proc "c" (radians: vec3) -> vec3 { return radians * 360.0 / TAU }
degrees_vec4 :: proc "c" (radians: vec4) -> vec4 { return radians * 360.0 / TAU }
degrees_dvec2 :: proc "c" (radians: dvec2) -> dvec2 { return radians * 360.0 / TAU }
degrees_dvec3 :: proc "c" (radians: dvec3) -> dvec3 { return radians * 360.0 / TAU }
degrees_dvec4 :: proc "c" (radians: dvec4) -> dvec4 { return radians * 360.0 / TAU }


min_i32  :: proc "c" (x, y: i32) -> i32   { return builtin.min(x, y) }
min_u32  :: proc "c" (x, y: u32) -> u32   { return builtin.min(x, y) }
min_f32  :: proc "c" (x, y: f32) -> f32   { return builtin.min(x, y) }
min_f64  :: proc "c" (x, y: f64) -> f64   { return builtin.min(x, y) }
min_vec2 :: proc "c" (x, y: vec2) -> vec2 { return {min(x.x, y.x), min(x.y, y.y)} }
min_vec3 :: proc "c" (x, y: vec3) -> vec3 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z)} }
min_vec4 :: proc "c" (x, y: vec4) -> vec4 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z), min(x.w, y.w)} }
min_dvec2 :: proc "c" (x, y: dvec2) -> dvec2 { return {min(x.x, y.x), min(x.y, y.y)} }
min_dvec3 :: proc "c" (x, y: dvec3) -> dvec3 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z)} }
min_dvec4 :: proc "c" (x, y: dvec4) -> dvec4 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z), min(x.w, y.w)} }
min_ivec2 :: proc "c" (x, y: ivec2) -> ivec2 { return {min(x.x, y.x), min(x.y, y.y)} }
min_ivec3 :: proc "c" (x, y: ivec3) -> ivec3 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z)} }
min_ivec4 :: proc "c" (x, y: ivec4) -> ivec4 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z), min(x.w, y.w)} }
min_uvec2 :: proc "c" (x, y: uvec2) -> uvec2 { return {min(x.x, y.x), min(x.y, y.y)} }
min_uvec3 :: proc "c" (x, y: uvec3) -> uvec3 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z)} }
min_uvec4 :: proc "c" (x, y: uvec4) -> uvec4 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z), min(x.w, y.w)} }


max_i32  :: proc "c" (x, y: i32) -> i32   { return builtin.max(x, y) }
max_u32  :: proc "c" (x, y: u32) -> u32   { return builtin.max(x, y) }
max_f32  :: proc "c" (x, y: f32) -> f32   { return builtin.max(x, y) }
max_f64  :: proc "c" (x, y: f64) -> f64   { return builtin.max(x, y) }
max_vec2 :: proc "c" (x, y: vec2) -> vec2 { return {max(x.x, y.x), max(x.y, y.y)} }
max_vec3 :: proc "c" (x, y: vec3) -> vec3 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z)} }
max_vec4 :: proc "c" (x, y: vec4) -> vec4 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z), max(x.w, y.w)} }
max_dvec2 :: proc "c" (x, y: dvec2) -> dvec2 { return {max(x.x, y.x), max(x.y, y.y)} }
max_dvec3 :: proc "c" (x, y: dvec3) -> dvec3 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z)} }
max_dvec4 :: proc "c" (x, y: dvec4) -> dvec4 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z), max(x.w, y.w)} }
max_ivec2 :: proc "c" (x, y: ivec2) -> ivec2 { return {max(x.x, y.x), max(x.y, y.y)} }
max_ivec3 :: proc "c" (x, y: ivec3) -> ivec3 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z)} }
max_ivec4 :: proc "c" (x, y: ivec4) -> ivec4 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z), max(x.w, y.w)} }
max_uvec2 :: proc "c" (x, y: uvec2) -> uvec2 { return {max(x.x, y.x), max(x.y, y.y)} }
max_uvec3 :: proc "c" (x, y: uvec3) -> uvec3 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z)} }
max_uvec4 :: proc "c" (x, y: uvec4) -> uvec4 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z), max(x.w, y.w)} }


clamp_i32  :: proc "c" (x, y, z: i32) -> i32   { return builtin.clamp(x, y, z) }
clamp_u32  :: proc "c" (x, y, z: u32) -> u32   { return builtin.clamp(x, y, z) }
clamp_f32  :: proc "c" (x, y, z: f32) -> f32   { return builtin.clamp(x, y, z) }
clamp_f64  :: proc "c" (x, y, z: f64) -> f64   { return builtin.clamp(x, y, z) }
clamp_vec2 :: proc "c" (x, y, z: vec2) -> vec2 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y)} }
clamp_vec3 :: proc "c" (x, y, z: vec3) -> vec3 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z)} }
clamp_vec4 :: proc "c" (x, y, z: vec4) -> vec4 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z), clamp(x.w, y.w, z.w)} }
clamp_dvec2 :: proc "c" (x, y, z: dvec2) -> dvec2 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y)} }
clamp_dvec3 :: proc "c" (x, y, z: dvec3) -> dvec3 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z)} }
clamp_dvec4 :: proc "c" (x, y, z: dvec4) -> dvec4 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z), clamp(x.w, y.w, z.w)} }
clamp_ivec2 :: proc "c" (x, y, z: ivec2) -> ivec2 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y)} }
clamp_ivec3 :: proc "c" (x, y, z: ivec3) -> ivec3 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z)} }
clamp_ivec4 :: proc "c" (x, y, z: ivec4) -> ivec4 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z), clamp(x.w, y.w, z.w)} }
clamp_uvec2 :: proc "c" (x, y, z: uvec2) -> uvec2 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y)} }
clamp_uvec3 :: proc "c" (x, y, z: uvec3) -> uvec3 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z)} }
clamp_uvec4 :: proc "c" (x, y, z: uvec4) -> uvec4 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z), clamp(x.w, y.w, z.w)} }


saturate_i32  :: proc "c" (v: i32) -> i32   { return builtin.clamp(v, 0, 1) }
saturate_u32  :: proc "c" (v: u32) -> u32   { return builtin.clamp(v, 0, 1) }
saturate_f32  :: proc "c" (v: f32) -> f32   { return builtin.clamp(v, 0, 1) }
saturate_f64  :: proc "c" (v: f64) -> f64   { return builtin.clamp(v, 0, 1) }
saturate_vec2 :: proc "c" (v: vec2) -> vec2 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1)} }
saturate_vec3 :: proc "c" (v: vec3) -> vec3 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1)} }
saturate_vec4 :: proc "c" (v: vec4) -> vec4 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1), builtin.clamp(v.w, 0, 1)} }
saturate_dvec2 :: proc "c" (v: dvec2) -> dvec2 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1)} }
saturate_dvec3 :: proc "c" (v: dvec3) -> dvec3 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1)} }
saturate_dvec4 :: proc "c" (v: dvec4) -> dvec4 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1), builtin.clamp(v.w, 0, 1)} }
saturate_ivec2 :: proc "c" (v: ivec2) -> ivec2 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1)} }
saturate_ivec3 :: proc "c" (v: ivec3) -> ivec3 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1)} }
saturate_ivec4 :: proc "c" (v: ivec4) -> ivec4 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1), builtin.clamp(v.w, 0, 1)} }
saturate_uvec2 :: proc "c" (v: uvec2) -> uvec2 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1)} }
saturate_uvec3 :: proc "c" (v: uvec3) -> uvec3 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1)} }
saturate_uvec4 :: proc "c" (v: uvec4) -> uvec4 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1), builtin.clamp(v.w, 0, 1)} }


mix_f32  :: proc "c" (x, y, t: f32) -> f32   { return x*(1-t) + y*t }
mix_f64  :: proc "c" (x, y, t: f64) -> f64   { return x*(1-t) + y*t }
mix_vec2 :: proc "c" (x, y, t: vec2) -> vec2 { return {mix(x.x, y.x, t.x), mix(x.y, y.y, t.y)} }
mix_vec3 :: proc "c" (x, y, t: vec3) -> vec3 { return {mix(x.x, y.x, t.x), mix(x.y, y.y, t.y), mix(x.z, y.z, t.z)} }
mix_vec4 :: proc "c" (x, y, t: vec4) -> vec4 { return {mix(x.x, y.x, t.x), mix(x.y, y.y, y.y), mix(x.z, y.z, t.z), mix(x.w, y.w, t.w)} }
mix_dvec2 :: proc "c" (x, y, t: dvec2) -> dvec2 { return {mix(x.x, y.x, t.x), mix(x.y, y.y, t.y)} }
mix_dvec3 :: proc "c" (x, y, t: dvec3) -> dvec3 { return {mix(x.x, y.x, t.x), mix(x.y, y.y, t.y), mix(x.z, y.z, t.z)} }
mix_dvec4 :: proc "c" (x, y, t: dvec4) -> dvec4 { return {mix(x.x, y.x, t.x), mix(x.y, y.y, y.y), mix(x.z, y.z, t.z), mix(x.w, y.w, t.w)} }


lerp_f32  :: proc "c" (x, y, t: f32) -> f32   { return x*(1-t) + y*t }
lerp_f64  :: proc "c" (x, y, t: f64) -> f64   { return x*(1-t) + y*t }
lerp_vec2 :: proc "c" (x, y, t: vec2) -> vec2 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, t.y)} }
lerp_vec3 :: proc "c" (x, y, t: vec3) -> vec3 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, t.y), lerp(x.z, y.z, t.z)} }
lerp_vec4 :: proc "c" (x, y, t: vec4) -> vec4 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, t.y), lerp(x.z, y.z, t.z), lerp(x.w, y.w, t.w)} }
lerp_dvec2 :: proc "c" (x, y, t: dvec2) -> dvec2 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, t.y)} }
lerp_dvec3 :: proc "c" (x, y, t: dvec3) -> dvec3 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, t.y), lerp(x.z, y.z, t.z)} }
lerp_dvec4 :: proc "c" (x, y, t: dvec4) -> dvec4 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, t.y), lerp(x.z, y.z, t.z), lerp(x.w, y.w, t.w)} }


step_f32  :: proc "c" (edge, x: f32) -> f32   { return 0 if x < edge else 1 }
step_f64  :: proc "c" (edge, x: f64) -> f64   { return 0 if x < edge else 1 }
step_vec2 :: proc "c" (edge, x: vec2) -> vec2 { return {step(edge.x, x.x), step(edge.y, x.y)} }
step_vec3 :: proc "c" (edge, x: vec3) -> vec3 { return {step(edge.x, x.x), step(edge.y, x.y), step(edge.z, x.z)} }
step_vec4 :: proc "c" (edge, x: vec4) -> vec4 { return {step(edge.x, x.x), step(edge.y, x.y), step(edge.z, x.z), step(edge.w, x.w)} }
step_dvec2 :: proc "c" (edge, x: dvec2) -> dvec2 { return {step(edge.x, x.x), step(edge.y, x.y)} }
step_dvec3 :: proc "c" (edge, x: dvec3) -> dvec3 { return {step(edge.x, x.x), step(edge.y, x.y), step(edge.z, x.z)} }
step_dvec4 :: proc "c" (edge, x: dvec4) -> dvec4 { return {step(edge.x, x.x), step(edge.y, x.y), step(edge.z, x.z), step(edge.w, x.w)} }


smoothstep_f32 :: proc "c" (edge0, edge1, x: f32) -> f32 {
    y := clamp(((x-edge0) / (edge1 - edge0)), 0, 1)
    return y * y * (3 - 2*y)
}
smoothstep_f64 :: proc "c" (edge0, edge1, x: f64) -> f64 {
    y := clamp(((x-edge0) / (edge1 - edge0)), 0, 1)
    return y * y * (3 - 2*y)
}
smoothstep_vec2  :: proc "c" (edge0, edge1, x: vec2) -> vec2   { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y)} }
smoothstep_vec3  :: proc "c" (edge0, edge1, x: vec3) -> vec3   { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y), smoothstep(edge0.z, edge1.z, x.z)} }
smoothstep_vec4  :: proc "c" (edge0, edge1, x: vec4) -> vec4   { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y), smoothstep(edge0.z, edge1.z, x.z), smoothstep(edge0.w, edge1.w, x.w)} }
smoothstep_dvec2 :: proc "c" (edge0, edge1, x: dvec2) -> dvec2 { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y)} }
smoothstep_dvec3 :: proc "c" (edge0, edge1, x: dvec3) -> dvec3 { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y), smoothstep(edge0.z, edge1.z, x.z)} }
smoothstep_dvec4 :: proc "c" (edge0, edge1, x: dvec4) -> dvec4 { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y), smoothstep(edge0.z, edge1.z, x.z), smoothstep(edge0.w, edge1.w, x.w)} }


abs_i32  :: proc "c" (x: i32)  -> i32  { return builtin.abs(x) }
abs_u32  :: proc "c" (x: u32)  -> u32  { return x }
abs_f32  :: proc "c" (x: f32)  -> f32  { return builtin.abs(x) }
abs_f64  :: proc "c" (x: f64)  -> f64  { return builtin.abs(x) }
abs_vec2 :: proc "c" (x: vec2) -> vec2 { return {abs(x.x), abs(x.y)} }
abs_vec3 :: proc "c" (x: vec3) -> vec3 { return {abs(x.x), abs(x.y), abs(x.z)} }
abs_vec4 :: proc "c" (x: vec4) -> vec4 { return {abs(x.x), abs(x.y), abs(x.z), abs(x.w)} }
abs_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return {abs(x.x), abs(x.y)} }
abs_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return {abs(x.x), abs(x.y), abs(x.z)} }
abs_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return {abs(x.x), abs(x.y), abs(x.z), abs(x.w)} }
abs_ivec2 :: proc "c" (x: ivec2) -> ivec2 { return {abs(x.x), abs(x.y)} }
abs_ivec3 :: proc "c" (x: ivec3) -> ivec3 { return {abs(x.x), abs(x.y), abs(x.z)} }
abs_ivec4 :: proc "c" (x: ivec4) -> ivec4 { return {abs(x.x), abs(x.y), abs(x.z), abs(x.w)} }
abs_uvec2 :: proc "c" (x: uvec2) -> uvec2 { return x }
abs_uvec3 :: proc "c" (x: uvec3) -> uvec3 { return x }
abs_uvec4 :: proc "c" (x: uvec4) -> uvec4 { return x }


dot_i32  :: proc "c" (a, b: i32)  -> i32 { return a*b }
dot_u32  :: proc "c" (a, b: u32)  -> u32 { return a*b }
dot_f32  :: proc "c" (a, b: f32)  -> f32 { return a*b }
dot_f64  :: proc "c" (a, b: f64)  -> f64 { return a*b }
dot_vec2 :: proc "c" (a, b: vec2) -> f32 { return a.x*b.x + a.y*b.y }
dot_vec3 :: proc "c" (a, b: vec3) -> f32 { return a.x*b.x + a.y*b.y + a.z*b.z }
dot_vec4 :: proc "c" (a, b: vec4) -> f32 { return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w }
dot_dvec2 :: proc "c" (a, b: dvec2) -> f64 { return a.x*b.x + a.y*b.y }
dot_dvec3 :: proc "c" (a, b: dvec3) -> f64 { return a.x*b.x + a.y*b.y + a.z*b.z }
dot_dvec4 :: proc "c" (a, b: dvec4) -> f64 { return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w }
dot_ivec2 :: proc "c" (a, b: ivec2) -> i32 { return a.x*b.x + a.y*b.y }
dot_ivec3 :: proc "c" (a, b: ivec3) -> i32 { return a.x*b.x + a.y*b.y + a.z*b.z }
dot_ivec4 :: proc "c" (a, b: ivec4) -> i32 { return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w }
dot_uvec2 :: proc "c" (a, b: uvec2) -> u32 { return a.x*b.x + a.y*b.y }
dot_uvec3 :: proc "c" (a, b: uvec3) -> u32 { return a.x*b.x + a.y*b.y + a.z*b.z }
dot_uvec4 :: proc "c" (a, b: uvec4) -> u32 { return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w }
dot_quat :: proc "c" (a, b: quat) -> f32 { return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w }
dot_dquat :: proc "c" (a, b: dquat) -> f64 { return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w }


length_f32  :: proc "c" (x: f32)  -> f32 { return builtin.abs(x) }
length_f64  :: proc "c" (x: f64)  -> f64 { return builtin.abs(x) }
length_vec2 :: proc "c" (x: vec2) -> f32 { return sqrt(x.x*x.x + x.y*x.y) }
length_vec3 :: proc "c" (x: vec3) -> f32 { return sqrt(x.x*x.x + x.y*x.y + x.z*x.z) }
length_vec4 :: proc "c" (x: vec4) -> f32 { return sqrt(x.x*x.x + x.y*x.y + x.z*x.z + x.w*x.w) }
length_dvec2 :: proc "c" (x: dvec2) -> f64 { return sqrt(x.x*x.x + x.y*x.y) }
length_dvec3 :: proc "c" (x: dvec3) -> f64 { return sqrt(x.x*x.x + x.y*x.y + x.z*x.z) }
length_dvec4 :: proc "c" (x: dvec4) -> f64 { return sqrt(x.x*x.x + x.y*x.y + x.z*x.z + x.w*x.w) }
length_quat :: proc "c" (x: quat) -> f32 { return sqrt(x.x*x.x + x.y*x.y + x.z*x.z + x.w*x.w) }
length_dquat :: proc "c" (x: dquat) -> f64 { return sqrt(x.x*x.x + x.y*x.y + x.z*x.z + x.w*x.w) }


distance_f32  :: proc "c" (x, y: f32)  -> f32 { return length(y-x) }
distance_f64  :: proc "c" (x, y: f64)  -> f64 { return length(y-x) }
distance_vec2 :: proc "c" (x, y: vec2) -> f32 { return length(y-x) }
distance_vec3 :: proc "c" (x, y: vec3) -> f32 { return length(y-x) }
distance_vec4 :: proc "c" (x, y: vec4) -> f32 { return length(y-x) }
distance_dvec2 :: proc "c" (x, y: dvec2) -> f64 { return length(y-x) }
distance_dvec3 :: proc "c" (x, y: dvec3) -> f64 { return length(y-x) }
distance_dvec4 :: proc "c" (x, y: dvec4) -> f64 { return length(y-x) }


cross_vec3 :: proc "c" (a, b: vec3) -> (c: vec3) {
    c.x = a.y*b.z - b.y*a.z
    c.y = a.z*b.x - b.z*a.x
    c.z = a.x*b.y - b.x*a.y
return
}
cross_dvec3 :: proc "c" (a, b: dvec3) -> (c: dvec3) {
    c.x = a.y*b.z - b.y*a.z
    c.y = a.z*b.x - b.z*a.x
    c.z = a.x*b.y - b.x*a.y
return
}
cross_ivec3 :: proc "c" (a, b: ivec3) -> (c: ivec3) {
    c.x = a.y*b.z - b.y*a.z
    c.y = a.z*b.x - b.z*a.x
    c.z = a.x*b.y - b.x*a.y
return
}


normalize_f32  :: proc "c" (x: f32)  -> f32  { return 1.0 }
normalize_f64  :: proc "c" (x: f64)  -> f64  { return 1.0 }
normalize_vec2 :: proc "c" (x: vec2) -> vec2 { return x / length(x) }
normalize_vec3 :: proc "c" (x: vec3) -> vec3 { return x / length(x) }
normalize_vec4 :: proc "c" (x: vec4) -> vec4 { return x / length(x) }
normalize_dvec2 :: proc "c" (x: dvec2) -> dvec2 { return x / length(x) }
normalize_dvec3 :: proc "c" (x: dvec3) -> dvec3 { return x / length(x) }
normalize_dvec4 :: proc "c" (x: dvec4) -> dvec4 { return x / length(x) }
normalize_quat :: proc "c" (x: quat) -> quat { return x / quat(length(x)) }
normalize_dquat :: proc "c" (x: dquat) -> dquat { return x / dquat(length(x)) }


faceForward_f32  :: proc "c" (N, I, Nref: f32)  -> f32  { return N if dot(I, Nref) < 0 else -N }
faceForward_f64  :: proc "c" (N, I, Nref: f64)  -> f64  { return N if dot(I, Nref) < 0 else -N }
faceForward_vec2 :: proc "c" (N, I, Nref: vec2) -> vec2 { return N if dot(I, Nref) < 0 else -N }
faceForward_vec3 :: proc "c" (N, I, Nref: vec3) -> vec3 { return N if dot(I, Nref) < 0 else -N }
faceForward_vec4 :: proc "c" (N, I, Nref: vec4) -> vec4 { return N if dot(I, Nref) < 0 else -N }
faceForward_dvec2 :: proc "c" (N, I, Nref: dvec2) -> dvec2 { return N if dot(I, Nref) < 0 else -N }
faceForward_dvec3 :: proc "c" (N, I, Nref: dvec3) -> dvec3 { return N if dot(I, Nref) < 0 else -N }
faceForward_dvec4 :: proc "c" (N, I, Nref: dvec4) -> dvec4 { return N if dot(I, Nref) < 0 else -N }


reflect_f32  :: proc "c" (I, N: f32)  -> f32  { return I - 2*N*dot(N, I) }
reflect_f64  :: proc "c" (I, N: f64)  -> f64  { return I - 2*N*dot(N, I) }
reflect_vec2 :: proc "c" (I, N: vec2) -> vec2 { return I - 2*N*dot(N, I) }
reflect_vec3 :: proc "c" (I, N: vec3) -> vec3 { return I - 2*N*dot(N, I) }
reflect_vec4 :: proc "c" (I, N: vec4) -> vec4 { return I - 2*N*dot(N, I) }
reflect_dvec2 :: proc "c" (I, N: dvec2) -> dvec2 { return I - 2*N*dot(N, I) }
reflect_dvec3 :: proc "c" (I, N: dvec3) -> dvec3 { return I - 2*N*dot(N, I) }
reflect_dvec4 :: proc "c" (I, N: dvec4) -> dvec4 { return I - 2*N*dot(N, I) }


refract_f32  :: proc "c" (i, n, eta: f32) -> f32 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * f32(i32(cost2 > 0))
}
refract_f64  :: proc "c" (i, n, eta: f64) -> f64 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * f64(i32(cost2 > 0))
}
refract_vec2  :: proc "c" (i, n, eta: vec2) -> vec2 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * vec2{f32(i32(cost2.x > 0)), f32(i32(cost2.y > 0))}
}
refract_vec3  :: proc "c" (i, n, eta: vec3) -> vec3 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * vec3{f32(i32(cost2.x > 0)), f32(i32(cost2.y > 0)), f32(i32(cost2.z > 0))}
}
refract_vec4  :: proc "c" (i, n, eta: vec4) -> vec4 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * vec4{f32(i32(cost2.x > 0)), f32(i32(cost2.y > 0)), f32(i32(cost2.z > 0)), f32(i32(cost2.w > 0))}
}
refract_dvec2  :: proc "c" (i, n, eta: dvec2) -> dvec2 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * dvec2{f64(i32(cost2.x > 0)), f64(i32(cost2.y > 0))}
}
refract_dvec3  :: proc "c" (i, n, eta: dvec3) -> dvec3 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * dvec3{f64(i32(cost2.x > 0)), f64(i32(cost2.y > 0)), f64(i32(cost2.z > 0))}
}
refract_dvec4  :: proc "c" (i, n, eta: dvec4) -> dvec4 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * dvec4{f64(i32(cost2.x > 0)), f64(i32(cost2.y > 0)), f64(i32(cost2.z > 0)), f64(i32(cost2.w > 0))}
}


scalarTripleProduct_vec3 :: proc "c" (a, b, c: vec3) -> f32  { return dot(a, cross(b, c)) }
scalarTripleProduct_dvec3 :: proc "c" (a, b, c: dvec3) -> f64  { return dot(a, cross(b, c)) }
scalarTripleProduct_ivec3 :: proc "c" (a, b, c: ivec3) -> i32  { return dot(a, cross(b, c)) }


vectorTripleProduct_vec3 :: proc "c" (a, b, c: vec3) -> vec3 { return cross(a, cross(b, c)) }
vectorTripleProduct_dvec3 :: proc "c" (a, b, c: dvec3) -> dvec3 { return cross(a, cross(b, c)) }
vectorTripleProduct_ivec3 :: proc "c" (a, b, c: ivec3) -> ivec3 { return cross(a, cross(b, c)) }


// Vector Relational Procedures


lessThan_f32   :: proc "c" (a, b: f32) -> bool { return a < b }
lessThan_f64   :: proc "c" (a, b: f64) -> bool { return a < b }
lessThan_i32   :: proc "c" (a, b: i32) -> bool { return a < b }
lessThan_u32   :: proc "c" (a, b: u32) -> bool { return a < b }
lessThan_vec2  :: proc "c" (a, b: vec2) -> bvec2 { return {a.x < b.x, a.y < b.y} }
lessThan_dvec2 :: proc "c" (a, b: dvec2) -> bvec2 { return {a.x < b.x, a.y < b.y} }
lessThan_ivec2 :: proc "c" (a, b: ivec2) -> bvec2 { return {a.x < b.x, a.y < b.y} }
lessThan_uvec2 :: proc "c" (a, b: uvec2) -> bvec2 { return {a.x < b.x, a.y < b.y} }
lessThan_vec3  :: proc "c" (a, b: vec3) -> bvec3 { return {a.x < b.x, a.y < b.y, a.z < b.z} }
lessThan_dvec3  :: proc "c" (a, b: dvec3) -> bvec3 { return {a.x < b.x, a.y < b.y, a.z < b.z} }
lessThan_ivec3 :: proc "c" (a, b: ivec3) -> bvec3 { return {a.x < b.x, a.y < b.y, a.z < b.z} }
lessThan_uvec3 :: proc "c" (a, b: uvec3) -> bvec3 { return {a.x < b.x, a.y < b.y, a.z < b.z} }
lessThan_vec4  :: proc "c" (a, b: vec4) -> bvec4 { return {a.x < b.x, a.y < b.y, a.z < b.z, a.w < b.w} }
lessThan_dvec4  :: proc "c" (a, b: dvec4) -> bvec4 { return {a.x < b.x, a.y < b.y, a.z < b.z, a.w < b.w} }
lessThan_ivec4 :: proc "c" (a, b: ivec4) -> bvec4 { return {a.x < b.x, a.y < b.y, a.z < b.z, a.w < b.w} }
lessThan_uvec4 :: proc "c" (a, b: uvec4) -> bvec4 { return {a.x < b.x, a.y < b.y, a.z < b.z, a.w < b.w} }


lessThanEqual_f32   :: proc "c" (a, b: f32) -> bool { return a <= b }
lessThanEqual_f64   :: proc "c" (a, b: f64) -> bool { return a <= b }
lessThanEqual_i32   :: proc "c" (a, b: i32) -> bool { return a <= b }
lessThanEqual_u32   :: proc "c" (a, b: u32) -> bool { return a <= b }
lessThanEqual_vec2  :: proc "c" (a, b: vec2) -> bvec2 { return {a.x <= b.x, a.y <= b.y} }
lessThanEqual_dvec2  :: proc "c" (a, b: dvec2) -> bvec2 { return {a.x <= b.x, a.y <= b.y} }
lessThanEqual_ivec2 :: proc "c" (a, b: ivec2) -> bvec2 { return {a.x <= b.x, a.y <= b.y} }
lessThanEqual_uvec2 :: proc "c" (a, b: uvec2) -> bvec2 { return {a.x <= b.x, a.y <= b.y} }
lessThanEqual_vec3  :: proc "c" (a, b: vec3) -> bvec3 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z} }
lessThanEqual_dvec3  :: proc "c" (a, b: dvec3) -> bvec3 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z} }
lessThanEqual_ivec3 :: proc "c" (a, b: ivec3) -> bvec3 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z} }
lessThanEqual_uvec3 :: proc "c" (a, b: uvec3) -> bvec3 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z} }
lessThanEqual_vec4  :: proc "c" (a, b: vec4) -> bvec4 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z, a.w <= b.w} }
lessThanEqual_dvec4  :: proc "c" (a, b: dvec4) -> bvec4 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z, a.w <= b.w} }
lessThanEqual_ivec4 :: proc "c" (a, b: ivec4) -> bvec4 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z, a.w <= b.w} }
lessThanEqual_uvec4 :: proc "c" (a, b: uvec4) -> bvec4 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z, a.w <= b.w} }


greaterThan_f32   :: proc "c" (a, b: f32) -> bool { return a > b }
greaterThan_f64   :: proc "c" (a, b: f64) -> bool { return a > b }
greaterThan_i32   :: proc "c" (a, b: i32) -> bool { return a > b }
greaterThan_u32   :: proc "c" (a, b: u32) -> bool { return a > b }
greaterThan_vec2  :: proc "c" (a, b: vec2) -> bvec2 { return {a.x > b.x, a.y > b.y} }
greaterThan_dvec2  :: proc "c" (a, b: dvec2) -> bvec2 { return {a.x > b.x, a.y > b.y} }
greaterThan_ivec2 :: proc "c" (a, b: ivec2) -> bvec2 { return {a.x > b.x, a.y > b.y} }
greaterThan_uvec2 :: proc "c" (a, b: uvec2) -> bvec2 { return {a.x > b.x, a.y > b.y} }
greaterThan_vec3  :: proc "c" (a, b: vec3) -> bvec3 { return {a.x > b.x, a.y > b.y, a.z > b.z} }
greaterThan_dvec3  :: proc "c" (a, b: dvec3) -> bvec3 { return {a.x > b.x, a.y > b.y, a.z > b.z} }
greaterThan_ivec3 :: proc "c" (a, b: ivec3) -> bvec3 { return {a.x > b.x, a.y > b.y, a.z > b.z} }
greaterThan_uvec3 :: proc "c" (a, b: uvec3) -> bvec3 { return {a.x > b.x, a.y > b.y, a.z > b.z} }
greaterThan_vec4  :: proc "c" (a, b: vec4) -> bvec4 { return {a.x > b.x, a.y > b.y, a.z > b.z, a.w > b.w} }
greaterThan_dvec4  :: proc "c" (a, b: dvec4) -> bvec4 { return {a.x > b.x, a.y > b.y, a.z > b.z, a.w > b.w} }
greaterThan_ivec4 :: proc "c" (a, b: ivec4) -> bvec4 { return {a.x > b.x, a.y > b.y, a.z > b.z, a.w > b.w} }
greaterThan_uvec4 :: proc "c" (a, b: uvec4) -> bvec4 { return {a.x > b.x, a.y > b.y, a.z > b.z, a.w > b.w} }


greaterThanEqual_f32   :: proc "c" (a, b: f32) -> bool { return a >= b }
greaterThanEqual_f64   :: proc "c" (a, b: f64) -> bool { return a >= b }
greaterThanEqual_i32   :: proc "c" (a, b: i32) -> bool { return a >= b }
greaterThanEqual_u32   :: proc "c" (a, b: u32) -> bool { return a >= b }
greaterThanEqual_vec2  :: proc "c" (a, b: vec2) -> bvec2 { return {a.x >= b.x, a.y >= b.y} }
greaterThanEqual_dvec2  :: proc "c" (a, b: dvec2) -> bvec2 { return {a.x >= b.x, a.y >= b.y} }
greaterThanEqual_ivec2 :: proc "c" (a, b: ivec2) -> bvec2 { return {a.x >= b.x, a.y >= b.y} }
greaterThanEqual_uvec2 :: proc "c" (a, b: uvec2) -> bvec2 { return {a.x >= b.x, a.y >= b.y} }
greaterThanEqual_vec3  :: proc "c" (a, b: vec3) -> bvec3 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z} }
greaterThanEqual_dvec3  :: proc "c" (a, b: dvec3) -> bvec3 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z} }
greaterThanEqual_ivec3 :: proc "c" (a, b: ivec3) -> bvec3 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z} }
greaterThanEqual_uvec3 :: proc "c" (a, b: uvec3) -> bvec3 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z} }
greaterThanEqual_vec4  :: proc "c" (a, b: vec4) -> bvec4 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z, a.w >= b.w} }
greaterThanEqual_dvec4  :: proc "c" (a, b: dvec4) -> bvec4 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z, a.w >= b.w} }
greaterThanEqual_ivec4 :: proc "c" (a, b: ivec4) -> bvec4 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z, a.w >= b.w} }
greaterThanEqual_uvec4 :: proc "c" (a, b: uvec4) -> bvec4 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z, a.w >= b.w} }


equal_f32   :: proc "c" (a, b: f32) -> bool { return a == b }
equal_f64   :: proc "c" (a, b: f64) -> bool { return a == b }
equal_i32   :: proc "c" (a, b: i32) -> bool { return a == b }
equal_u32   :: proc "c" (a, b: u32) -> bool { return a == b }
equal_vec2  :: proc "c" (a, b: vec2) -> bvec2 { return {a.x == b.x, a.y == b.y} }
equal_dvec2  :: proc "c" (a, b: dvec2) -> bvec2 { return {a.x == b.x, a.y == b.y} }
equal_ivec2 :: proc "c" (a, b: ivec2) -> bvec2 { return {a.x == b.x, a.y == b.y} }
equal_uvec2 :: proc "c" (a, b: uvec2) -> bvec2 { return {a.x == b.x, a.y == b.y} }
equal_vec3  :: proc "c" (a, b: vec3) -> bvec3 { return {a.x == b.x, a.y == b.y, a.z == b.z} }
equal_dvec3  :: proc "c" (a, b: dvec3) -> bvec3 { return {a.x == b.x, a.y == b.y, a.z == b.z} }
equal_ivec3 :: proc "c" (a, b: ivec3) -> bvec3 { return {a.x == b.x, a.y == b.y, a.z == b.z} }
equal_uvec3 :: proc "c" (a, b: uvec3) -> bvec3 { return {a.x == b.x, a.y == b.y, a.z == b.z} }
equal_vec4  :: proc "c" (a, b: vec4) -> bvec4 { return {a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w} }
equal_dvec4  :: proc "c" (a, b: dvec4) -> bvec4 { return {a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w} }
equal_ivec4 :: proc "c" (a, b: ivec4) -> bvec4 { return {a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w} }
equal_uvec4 :: proc "c" (a, b: uvec4) -> bvec4 { return {a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w} }


notEqual_f32   :: proc "c" (a, b: f32) -> bool { return a != b }
notEqual_f64   :: proc "c" (a, b: f64) -> bool { return a != b }
notEqual_i32   :: proc "c" (a, b: i32) -> bool { return a != b }
notEqual_u32   :: proc "c" (a, b: u32) -> bool { return a != b }
notEqual_vec2  :: proc "c" (a, b: vec2) -> bvec2 { return {a.x != b.x, a.y != b.y} }
notEqual_dvec2  :: proc "c" (a, b: dvec2) -> bvec2 { return {a.x != b.x, a.y != b.y} }
notEqual_ivec2 :: proc "c" (a, b: ivec2) -> bvec2 { return {a.x != b.x, a.y != b.y} }
notEqual_uvec2 :: proc "c" (a, b: uvec2) -> bvec2 { return {a.x != b.x, a.y != b.y} }
notEqual_vec3  :: proc "c" (a, b: vec3) -> bvec3 { return {a.x != b.x, a.y != b.y, a.z != b.z} }
notEqual_dvec3  :: proc "c" (a, b: dvec3) -> bvec3 { return {a.x != b.x, a.y != b.y, a.z != b.z} }
notEqual_ivec3 :: proc "c" (a, b: ivec3) -> bvec3 { return {a.x != b.x, a.y != b.y, a.z != b.z} }
notEqual_uvec3 :: proc "c" (a, b: uvec3) -> bvec3 { return {a.x != b.x, a.y != b.y, a.z != b.z} }
notEqual_vec4  :: proc "c" (a, b: vec4) -> bvec4 { return {a.x != b.x, a.y != b.y, a.z != b.z, a.w != b.w} }
notEqual_dvec4  :: proc "c" (a, b: dvec4) -> bvec4 { return {a.x != b.x, a.y != b.y, a.z != b.z, a.w != b.w} }
notEqual_ivec4 :: proc "c" (a, b: ivec4) -> bvec4 { return {a.x != b.x, a.y != b.y, a.z != b.z, a.w != b.w} }
notEqual_uvec4 :: proc "c" (a, b: uvec4) -> bvec4 { return {a.x != b.x, a.y != b.y, a.z != b.z, a.w != b.w} }


any_bool  :: proc "c" (v: bool) -> bool  { return v }
any_bvec2 :: proc "c" (v: bvec2) -> bool { return v.x || v.y }
any_bvec3 :: proc "c" (v: bvec3) -> bool { return v.x || v.y || v.z }
any_bvec4 :: proc "c" (v: bvec4) -> bool { return v.x || v.y || v.z || v.w }


all_bool  :: proc "c" (v: bool) -> bool  { return v }
all_bvec2 :: proc "c" (v: bvec2) -> bool { return v.x && v.y }
all_bvec3 :: proc "c" (v: bvec3) -> bool { return v.x && v.y && v.z }
all_bvec4 :: proc "c" (v: bvec4) -> bool { return v.x && v.y && v.z && v.w }


not_bool  :: proc "c" (v: bool) -> bool { return !v }
not_bvec2 :: proc "c" (v: bvec2) -> bvec2 { return {!v.x, !v.y} }
not_bvec3 :: proc "c" (v: bvec3) -> bvec3 { return {!v.x, !v.y, !v.z} }
not_bvec4 :: proc "c" (v: bvec4) -> bvec4 { return {!v.x, !v.y, !v.z, !v.w} }



/// Matrix Utilities

identity :: proc "c" ($M: typeid/matrix[$N, N]$T) -> M { return 1 }


mat4Perspective :: proc "c" (fovy, aspect, near, far: f32) -> (m: mat4) {
    tan_half_fovy := tan(0.5 * fovy)
    m[0, 0] = 1 / (aspect*tan_half_fovy)
    m[1, 1] = 1 / (tan_half_fovy)
    m[2, 2] = -(far + near) / (far - near)
    m[3, 2] = -1
    m[2, 3] = -2*far*near / (far - near)
    return
}

mat4PerspectiveInfinite :: proc "c" (fovy, aspect, near: f32) -> (m: mat4) {
    tan_half_fovy := tan(0.5 * fovy)
    m[0, 0] = 1 / (aspect*tan_half_fovy)
    m[1, 1] = 1 / (tan_half_fovy)
    m[2, 2] = -1
    m[3, 2] = -1
    m[2, 3] = -2*near
    return
}

mat4Ortho3d :: proc "c" (left, right, bottom, top, near, far: f32) -> (m: mat4) {
    m[0, 0] = +2 / (right - left)
    m[1, 1] = +2 / (top - bottom)
    m[2, 2] = -2 / (far - near)
    m[0, 3] = -(right + left)   / (right - left)
    m[1, 3] = -(top   + bottom) / (top - bottom)
    m[2, 3] = -(far + near) / (far- near)
    m[3, 3] = 1
    return m
}

mat4LookAt :: proc "c" (eye, centre, up: vec3) -> (m: mat4) {
    f := vec_normalize(centre - eye)
    s := vec_normalize(cross(f, up))
    u := cross(s, f)

    fe := dot(f, eye)
    
    m[0] = {+s.x, +u.x, -f.x, 0}
    m[1] = {+s.y, +u.y, -f.y, 0}
    m[2] = {+s.z, +u.z, -f.z, 0}
    m[3] = {-dot(s, eye), -dot(u, eye), +fe, 1}
    return
}

mat4Rotate :: proc "c" (v: vec3, radians: f32) -> (rot: mat4) {
    c := cos(radians)
    s := sin(radians)

    a := vec_normalize(v)
    t := a * (1-c)

    rot = 1

    rot[0, 0] = c + t[0]*a[0]
    rot[1, 0] = 0 + t[0]*a[1] + s*a[2]
    rot[2, 0] = 0 + t[0]*a[2] - s*a[1]
    rot[3, 0] = 0

    rot[0, 1] = 0 + t[1]*a[0] - s*a[2]
    rot[1, 1] = c + t[1]*a[1]
    rot[2, 1] = 0 + t[1]*a[2] + s*a[0]
    rot[3, 1] = 0

    rot[0, 2] = 0 + t[2]*a[0] + s*a[1]
    rot[1, 2] = 0 + t[2]*a[1] - s*a[0]
    rot[2, 2] = c + t[2]*a[2]
    rot[3, 2] = 0

    return rot
}

mat4Translate :: proc "c" (v: vec3) -> (m: mat4) {
    m = 1
    m[3].xyz = v.xyz
    return
}

mat4Scale :: proc "c" (v: vec3) -> (m: mat4) {
    m[0, 0] = v[0]
    m[1, 1] = v[1]
    m[2, 2] = v[2]
    m[3, 3] = 1
    return
}

mat4Orientation :: proc "c" (normal, up: vec3) -> mat4 {
    if normal == up {
        return 1
    }
    
    rotation_axis := cross(up, normal)
    angle := acos(dot(normal, up))
    
    return mat4Rotate(rotation_axis, angle)
}

mat4FromQuat :: proc "c" (q: quat) -> (m: mat4) {
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

    return
}



dmat4Perspective :: proc "c" (fovy, aspect, near, far: f64) -> (m: dmat4) {
    tan_half_fovy := tan(0.5 * fovy)
    m[0, 0] = 1 / (aspect*tan_half_fovy)
    m[1, 1] = 1 / (tan_half_fovy)
    m[2, 2] = -(far + near) / (far - near)
    m[3, 2] = -1
    m[2, 3] = -2*far*near / (far - near)
    return
}

dmat4PerspectiveInfinite :: proc "c" (fovy, aspect, near: f64) -> (m: dmat4) {
    tan_half_fovy := tan(0.5 * fovy)
    m[0, 0] = 1 / (aspect*tan_half_fovy)
    m[1, 1] = 1 / (tan_half_fovy)
    m[2, 2] = -1
    m[3, 2] = -1
    m[2, 3] = -2*near
    return
}

dmat4Ortho3d :: proc "c" (left, right, bottom, top, near, far: f64) -> (m: dmat4) {
    m[0, 0] = +2 / (right - left)
    m[1, 1] = +2 / (top - bottom)
    m[2, 2] = -2 / (far - near)
    m[0, 3] = -(right + left)   / (right - left)
    m[1, 3] = -(top   + bottom) / (top - bottom)
    m[2, 3] = -(far + near) / (far- near)
    m[3, 3] = 1
    return m
}

dmat4LookAt :: proc "c" (eye, centre, up: dvec3) -> (m: dmat4) {
    f := vec_normalize(centre - eye)
    s := vec_normalize(cross(f, up))
    u := cross(s, f)

    fe := dot(f, eye)
    
    m[0] = {+s.x, +u.x, -f.x, 0}
    m[1] = {+s.y, +u.y, -f.y, 0}
    m[2] = {+s.z, +u.z, -f.z, 0}
    m[3] = {-dot(s, eye), -dot(u, eye), +fe, 1}
    return
}

dmat4Rotate :: proc "c" (v: dvec3, radians: f64) -> (rot: dmat4) {
    c := cos(radians)
    s := sin(radians)

    a := vec_normalize(v)
    t := a * (1-c)

    rot = 1

    rot[0, 0] = c + t[0]*a[0]
    rot[1, 0] = 0 + t[0]*a[1] + s*a[2]
    rot[2, 0] = 0 + t[0]*a[2] - s*a[1]
    rot[3, 0] = 0

    rot[0, 1] = 0 + t[1]*a[0] - s*a[2]
    rot[1, 1] = c + t[1]*a[1]
    rot[2, 1] = 0 + t[1]*a[2] + s*a[0]
    rot[3, 1] = 0

    rot[0, 2] = 0 + t[2]*a[0] + s*a[1]
    rot[1, 2] = 0 + t[2]*a[1] - s*a[0]
    rot[2, 2] = c + t[2]*a[2]
    rot[3, 2] = 0

    return rot
}

dmat4Translate :: proc "c" (v: dvec3) -> (m: dmat4) {
    m = 1
    m[3].xyz = v.xyz
    return
}

dmat4Scale :: proc "c" (v: dvec3) -> (m: dmat4) {
    m[0, 0] = v[0]
    m[1, 1] = v[1]
    m[2, 2] = v[2]
    m[3, 3] = 1
    return
}

dmat4Orientation :: proc "c" (normal, up: dvec3) -> dmat4 {
    if normal == up {
        return 1
    }
    
    rotation_axis := cross(up, normal)
    angle := acos(dot(normal, up))
    
    return dmat4Rotate(rotation_axis, angle)
}

dmat4FromDquat :: proc "c" (q: dquat) -> (m: dmat4) {
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

    return
}


quatAxisAngle :: proc "c" (axis: vec3, radians: f32) -> (q: quat) {
    t := radians*0.5
    v := vec_normalize(axis) * sin(t)
    q.x = v.x
    q.y = v.y
    q.z = v.z
    q.w = cos(t)
    return
}

quatNlerp :: proc "c" (a, b: quat, t: f32) -> (c: quat) {
    c.x = a.x + (b.x-a.x)*t
    c.y = a.y + (b.y-a.y)*t
    c.z = a.z + (b.z-a.z)*t
    c.w = a.w + (b.w-a.w)*t
    return c/quat(builtin.abs(c))
}


quatSlerp :: proc "c" (x, y: quat, t: f32) -> (q: quat) {
    a, b := x, y
    cos_angle := dot(a, b)
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

    angle := acos(cos_angle)
    sin_angle := sin(angle)
    factor_a := sin((1-t) * angle) / sin_angle
    factor_b := sin(t * angle)     / sin_angle

    q.x = factor_a * a.x + factor_b * b.x
    q.y = factor_a * a.y + factor_b * b.y
    q.z = factor_a * a.z + factor_b * b.z
    q.w = factor_a * a.w + factor_b * b.w
    return
}

quatFromMat3 :: proc "c" (m: mat3) -> (q: quat) {
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

    biggest_val := sqrt(four_biggest_squared_minus_1 + 1) * 0.5
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

quatFromMat4 :: proc "c" (m: mat4) -> (q: quat) {
    return quatFromMat3(mat3(m))
}


quatMulVec3 :: proc "c" (q: quat, v: vec3) -> vec3 {
    xyz := vec3{q.x, q.y, q.z}
    t := cross(2.0 * xyz, v)
    return v + q.w*t + cross(xyz, t)
}


dquatAxisAngle :: proc "c" (axis: dvec3, radians: f64) -> (q: dquat) {
    t := radians*0.5
    v := vec_normalize(axis) * sin(t)
    q.x = v.x
    q.y = v.y
    q.z = v.z
    q.w = cos(t)
    return
}

dquatNlerp :: proc "c" (a, b: dquat, t: f64) -> (c: dquat) {
    c.x = a.x + (b.x-a.x)*t
    c.y = a.y + (b.y-a.y)*t
    c.z = a.z + (b.z-a.z)*t
    c.w = a.w + (b.w-a.w)*t
    return c/dquat(builtin.abs(c))
}


dquatSlerp :: proc "c" (x, y: dquat, t: f64) -> (q: dquat) {
    a, b := x, y
    cos_angle := dot(a, b)
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

    angle := acos(cos_angle)
    sin_angle := sin(angle)
    factor_a := sin((1-t) * angle) / sin_angle
    factor_b := sin(t * angle)     / sin_angle

    q.x = factor_a * a.x + factor_b * b.x
    q.y = factor_a * a.y + factor_b * b.y
    q.z = factor_a * a.z + factor_b * b.z
    q.w = factor_a * a.w + factor_b * b.w
    return
}

dquatFromdMat3 :: proc "c" (m: dmat3) -> (q: dquat) {
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

    biggest_val := sqrt(four_biggest_squared_minus_1 + 1) * 0.5
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

dquatFromDmat4 :: proc "c" (m: dmat4) -> (q: dquat) {
    return dquatFromdMat3(dmat3(m))
}


dquatMulDvec3 :: proc "c" (q: dquat, v: dvec3) -> dvec3 {
    xyz := dvec3{q.x, q.y, q.z}
    t := cross(2.0 * xyz, v)
    return v + q.w*t + cross(xyz, t)
}




inverse_mat2  :: proc "c" (m: mat2)  -> mat2  { return inverse_matrix2x2(m) }
inverse_mat3  :: proc "c" (m: mat3)  -> mat3  { return inverse_matrix3x3(m) }
inverse_mat4  :: proc "c" (m: mat4)  -> mat4  { return inverse_matrix4x4(m) }
inverse_dmat2 :: proc "c" (m: dmat2) -> dmat2 { return inverse_matrix2x2(m) }
inverse_dmat3 :: proc "c" (m: dmat3) -> dmat3 { return inverse_matrix3x3(m) }
inverse_dmat4 :: proc "c" (m: dmat4) -> dmat4 { return inverse_matrix4x4(m) }
inverse_quat  :: proc "c" (q: quat)  -> quat  { return 1/q }
inverse_dquat :: proc "c" (q: dquat) -> dquat { return 1/q }


transpose :: intrinsics.transpose


hermitian_adjoint :: proc(m: $M/matrix[$N, N]$T) -> M where intrinsics.type_is_complex(T), N >= 1 {
    return conj(transpose(m))
}


trace :: proc(m: $M/matrix[$N, N]$T) -> (trace: T) {
    for i in 0..<N {
        trace += m[i, i]
    }
    return
}


matrix_minor :: proc(m: $M/matrix[$N, N]$T, #any_int row, column: int) -> (minor: T) where N > 1 {
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


determinant_matrix1x1 :: proc(m: $M/matrix[1, 1]$T) -> (det: T) {
    return m[0, 0]
}


determinant_matrix2x2 :: proc(m: $M/matrix[2, 2]$T) -> (det: T) {
    return m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
}

determinant_matrix3x3 :: proc(m: $M/matrix[3, 3]$T) -> (det: T) {
    a := +m[0, 0] * (m[1, 1] * m[2, 2] - m[1, 2] * m[2, 1])
    b := -m[0, 1] * (m[1, 0] * m[2, 2] - m[1, 2] * m[2, 0])
    c := +m[0, 2] * (m[1, 0] * m[2, 1] - m[1, 1] * m[2, 0])
    return a + b + c
}

determinant_matrix4x4 :: proc(m: $M/matrix[4, 4]$T) -> (det: T) {
    c := cofactor(m)
    #no_bounds_check for i in 0..<4 {
        det += m[0, i] * c[0, i]
    }
    return
}


adjugate_matrix1x1 :: proc(x: $M/matrix[1, 1]$T) -> (y: M) {
    y = x
    return
}


adjugate_matrix2x2 :: proc(x: $M/matrix[2, 2]$T) -> (y: M) {
    y[0, 0] = +x[1, 1]
    y[0, 1] = -x[0, 1]
    y[1, 0] = -x[1, 0]
    y[1, 1] = +x[0, 0]
    return
}


adjugate_matrix3x3 :: proc(m: $M/matrix[3, 3]$T) -> (y: M) {
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


adjugate_matrix4x4 :: proc(x: $M/matrix[4, 4]$T) -> (y: M) {
    for i in 0..<4 {
        for j in 0..<4 {
            sign: T = 1 if (i + j) % 2 == 0 else -1
            y[i, j] = sign * matrix_minor(x, j, i)
        }
    }
    return
}



cofactor_matrix1x1 :: proc(x: $M/matrix[1, 1]$T) -> (y: M) {
    y = x
    return
}


cofactor_matrix2x2 :: proc(x: $M/matrix[2, 2]$T) -> (y: M) {
    y[0, 0] = +x[1, 1]
    y[0, 1] = -x[1, 0]
    y[1, 0] = -x[0, 1]
    y[1, 1] = +x[0, 0]
    return
}


cofactor_matrix3x3 :: proc(m: $M/matrix[3, 3]$T) -> (y: M) {
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



cofactor_matrix4x4 :: proc(x: $M/matrix[4, 4]$T) -> (y: M) {
    for i in 0..<4 {
        for j in 0..<4 {
            sign: T = 1 if (i + j) % 2 == 0 else -1
            y[i, j] = sign * matrix_minor(x, i, j)
        }
    }
    return
}


inverse_transpose_matrix1x1 :: proc(x: $M/matrix[1, 1]$T) -> (y: M) {
    y[0, 0] = 1/x[0, 0]
    return
}


inverse_transpose_matrix2x2 :: proc(x: $M/matrix[2, 2]$T) -> (y: M) {
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


inverse_transpose_matrix3x3 :: proc(x: $M/matrix[3, 3]$T) -> (y: M) #no_bounds_check {
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


inverse_transpose_matrix4x4 :: proc(x: $M/matrix[4, 4]$T) -> (y: M) #no_bounds_check {
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


inverse_matrix1x1 :: proc(x: $M/matrix[1, 1]$T) -> (y: M) {
    y[0, 0] = 1/x[0, 0]
    return
}


inverse_matrix2x2 :: proc(x: $M/matrix[2, 2]$T) -> (y: M) {
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


inverse_matrix3x3 :: proc(x: $M/matrix[3, 3]$T) -> (y: M) #no_bounds_check {
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


inverse_matrix4x4 :: proc(x: $M/matrix[4, 4]$T) -> (y: M) #no_bounds_check {
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

