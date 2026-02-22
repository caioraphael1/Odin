// `HLSL`-like mathematics library plus numerous other utility procedures.
package math_linalg_hlsl

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

FLOAT_EPSILON :: 1e-7
DOUBLE_EPSILON :: 1e-15

// Aliases (not distict) of types
half   :: f16
float  :: f32
double :: f64
int    :: builtin.i32
uint   :: builtin.u32

// Odin matrices are stored internally as Column-Major, which matches the internal layout of HLSL by default
float1x1 :: matrix[1, 1]float
float2x2 :: matrix[2, 2]float
float3x3 :: matrix[3, 3]float
float4x4 :: matrix[4, 4]float

float1x2 :: matrix[1, 2]float
float1x3 :: matrix[1, 3]float
float1x4 :: matrix[1, 4]float
float2x1 :: matrix[2, 1]float
float2x3 :: matrix[2, 3]float
float2x4 :: matrix[2, 4]float
float3x1 :: matrix[3, 1]float
float3x2 :: matrix[3, 2]float
float3x4 :: matrix[3, 4]float
float4x1 :: matrix[4, 1]float
float4x2 :: matrix[4, 2]float
float4x3 :: matrix[4, 3]float

// Half Precision (half) Floating Point Types

half2 :: [2]half
half3 :: [3]half
half4 :: [4]half

half1x1 :: matrix[1, 1]half
half2x2 :: matrix[2, 2]half
half3x3 :: matrix[3, 3]half
half4x4 :: matrix[4, 4]half

half1x2 :: matrix[1, 2]half
half1x3 :: matrix[1, 3]half
half1x4 :: matrix[1, 4]half
half2x1 :: matrix[2, 1]half
half2x3 :: matrix[2, 3]half
half2x4 :: matrix[2, 4]half
half3x1 :: matrix[3, 1]half
half3x2 :: matrix[3, 2]half
half3x4 :: matrix[3, 4]half
half4x1 :: matrix[4, 1]half
half4x2 :: matrix[4, 2]half
half4x3 :: matrix[4, 3]half

float2 :: [2]float
float3 :: [3]float
float4 :: [4]float

int2 :: [2]int
int3 :: [3]int
int4 :: [4]int

uint2 :: [2]uint
uint3 :: [3]uint
uint4 :: [4]uint

bool2 :: [2]bool
bool3 :: [3]bool
bool4 :: [4]bool

// Double Precision (double) Floating Point Types 

double1x1 :: matrix[1, 1]double
double2x2 :: matrix[2, 2]double
double3x3 :: matrix[3, 3]double
double4x4 :: matrix[4, 4]double

double1x2 :: matrix[1, 2]double
double1x3 :: matrix[1, 3]double
double1x4 :: matrix[1, 4]double
double2x1 :: matrix[2, 1]double
double2x3 :: matrix[2, 3]double
double2x4 :: matrix[2, 4]double
double3x1 :: matrix[3, 1]double
double3x2 :: matrix[3, 2]double
double3x4 :: matrix[3, 4]double
double4x1 :: matrix[4, 1]double
double4x2 :: matrix[4, 2]double
double4x3 :: matrix[4, 3]double

double2 :: [2]double
double3 :: [3]double
double4 :: [4]double


int1x1 :: matrix[1, 1]int
int2x2 :: matrix[2, 2]int
int3x3 :: matrix[3, 3]int
int4x4 :: matrix[4, 4]int

int1x2 :: matrix[1, 2]int
int1x3 :: matrix[1, 3]int
int1x4 :: matrix[1, 4]int
int2x1 :: matrix[2, 1]int
int2x3 :: matrix[2, 3]int
int2x4 :: matrix[2, 4]int
int3x1 :: matrix[3, 1]int
int3x2 :: matrix[3, 2]int
int3x4 :: matrix[3, 4]int
int4x1 :: matrix[4, 1]int
int4x2 :: matrix[4, 2]int
int4x3 :: matrix[4, 3]int


    cos_half,
    cos_float,
    cos_double,
    cos_half2,
    cos_half3,
    cos_half4,
    cos_float2,
    cos_float3,
    cos_float4,
    cos_double2,
    cos_double3,
    cos_double4,
}
 cos_half2 :: proc "c" (x: half2) -> half2 { return {cos(x.x), cos(x.y)} }
 cos_half3 :: proc "c" (x: half3) -> half3 { return {cos(x.x), cos(x.y), cos(x.z)} }
 cos_half4 :: proc "c" (x: half4) -> half4 { return {cos(x.x), cos(x.y), cos(x.z), cos(x.w)} }
 cos_float2 :: proc "c" (x: float2) -> float2 { return {cos(x.x), cos(x.y)} }
 cos_float3 :: proc "c" (x: float3) -> float3 { return {cos(x.x), cos(x.y), cos(x.z)} }
 cos_float4 :: proc "c" (x: float4) -> float4 { return {cos(x.x), cos(x.y), cos(x.z), cos(x.w)} }
 cos_double2 :: proc "c" (x: double2) -> double2 { return {cos(x.x), cos(x.y)} }
 cos_double3 :: proc "c" (x: double3) -> double3 { return {cos(x.x), cos(x.y), cos(x.z)} }
 cos_double4 :: proc "c" (x: double4) -> double4 { return {cos(x.x), cos(x.y), cos(x.z), cos(x.w)} }


    sin_half,
    sin_float,
    sin_double,
    sin_half2,
    sin_half3,
    sin_half4,
    sin_float2,
    sin_float3,
    sin_float4,
    sin_double2,
    sin_double3,
    sin_double4,
}
 sin_half2 :: proc "c" (x: half2) -> half2 { return {sin(x.x), sin(x.y)} }
 sin_half3 :: proc "c" (x: half3) -> half3 { return {sin(x.x), sin(x.y), sin(x.z)} }
 sin_half4 :: proc "c" (x: half4) -> half4 { return {sin(x.x), sin(x.y), sin(x.z), sin(x.w)} }
 sin_float2 :: proc "c" (x: float2) -> float2 { return {sin(x.x), sin(x.y)} }
 sin_float3 :: proc "c" (x: float3) -> float3 { return {sin(x.x), sin(x.y), sin(x.z)} }
 sin_float4 :: proc "c" (x: float4) -> float4 { return {sin(x.x), sin(x.y), sin(x.z), sin(x.w)} }
 sin_double2 :: proc "c" (x: double2) -> double2 { return {sin(x.x), sin(x.y)} }
 sin_double3 :: proc "c" (x: double3) -> double3 { return {sin(x.x), sin(x.y), sin(x.z)} }
 sin_double4 :: proc "c" (x: double4) -> double4 { return {sin(x.x), sin(x.y), sin(x.z), sin(x.w)} }


    tan_half,
    tan_float,
    tan_double,
    tan_half2,
    tan_half3,
    tan_half4,
    tan_float2,
    tan_float3,
    tan_float4,
    tan_double2,
    tan_double3,
    tan_double4,
}
 tan_half2 :: proc "c" (x: half2) -> half2 { return {tan(x.x), tan(x.y)} }
 tan_half3 :: proc "c" (x: half3) -> half3 { return {tan(x.x), tan(x.y), tan(x.z)} }
 tan_half4 :: proc "c" (x: half4) -> half4 { return {tan(x.x), tan(x.y), tan(x.z), tan(x.w)} }
 tan_float2 :: proc "c" (x: float2) -> float2 { return {tan(x.x), tan(x.y)} }
 tan_float3 :: proc "c" (x: float3) -> float3 { return {tan(x.x), tan(x.y), tan(x.z)} }
 tan_float4 :: proc "c" (x: float4) -> float4 { return {tan(x.x), tan(x.y), tan(x.z), tan(x.w)} }
 tan_double2 :: proc "c" (x: double2) -> double2 { return {tan(x.x), tan(x.y)} }
 tan_double3 :: proc "c" (x: double3) -> double3 { return {tan(x.x), tan(x.y), tan(x.z)} }
 tan_double4 :: proc "c" (x: double4) -> double4 { return {tan(x.x), tan(x.y), tan(x.z), tan(x.w)} }


    acos_half,
    acos_float,
    acos_double,
    acos_half2,
    acos_half3,
    acos_half4,
    acos_float2,
    acos_float3,
    acos_float4,
    acos_double2,
    acos_double3,
    acos_double4,
}
 acos_half2 :: proc "c" (x: half2) -> half2 { return {acos(x.x), acos(x.y)} }
 acos_half3 :: proc "c" (x: half3) -> half3 { return {acos(x.x), acos(x.y), acos(x.z)} }
 acos_half4 :: proc "c" (x: half4) -> half4 { return {acos(x.x), acos(x.y), acos(x.z), acos(x.w)} }
 acos_float2 :: proc "c" (x: float2) -> float2 { return {acos(x.x), acos(x.y)} }
 acos_float3 :: proc "c" (x: float3) -> float3 { return {acos(x.x), acos(x.y), acos(x.z)} }
 acos_float4 :: proc "c" (x: float4) -> float4 { return {acos(x.x), acos(x.y), acos(x.z), acos(x.w)} }
 acos_double2 :: proc "c" (x: double2) -> double2 { return {acos(x.x), acos(x.y)} }
 acos_double3 :: proc "c" (x: double3) -> double3 { return {acos(x.x), acos(x.y), acos(x.z)} }
 acos_double4 :: proc "c" (x: double4) -> double4 { return {acos(x.x), acos(x.y), acos(x.z), acos(x.w)} }


    asin_half,
    asin_float,
    asin_double,
    asin_half2,
    asin_half3,
    asin_half4,
    asin_float2,
    asin_float3,
    asin_float4,
    asin_double2,
    asin_double3,
    asin_double4,
}
 asin_half2 :: proc "c" (x: half2) -> half2 { return {asin(x.x), asin(x.y)} }
 asin_half3 :: proc "c" (x: half3) -> half3 { return {asin(x.x), asin(x.y), asin(x.z)} }
 asin_half4 :: proc "c" (x: half4) -> half4 { return {asin(x.x), asin(x.y), asin(x.z), asin(x.w)} }
 asin_float2 :: proc "c" (x: float2) -> float2 { return {asin(x.x), asin(x.y)} }
 asin_float3 :: proc "c" (x: float3) -> float3 { return {asin(x.x), asin(x.y), asin(x.z)} }
 asin_float4 :: proc "c" (x: float4) -> float4 { return {asin(x.x), asin(x.y), asin(x.z), asin(x.w)} }
 asin_double2 :: proc "c" (x: double2) -> double2 { return {asin(x.x), asin(x.y)} }
 asin_double3 :: proc "c" (x: double3) -> double3 { return {asin(x.x), asin(x.y), asin(x.z)} }
 asin_double4 :: proc "c" (x: double4) -> double4 { return {asin(x.x), asin(x.y), asin(x.z), asin(x.w)} }


    atan_half,
    atan_float,
    atan_double,
    atan_half2,
    atan_half3,
    atan_half4,
    atan_float2,
    atan_float3,
    atan_float4,
    atan_double2,
    atan_double3,
    atan_double4,
    atan2_float,
    atan2_double,
    atan2_float2,
    atan2_float3,
    atan2_float4,
    atan2_double2,
    atan2_double3,
    atan2_double4,
}
 atan_half2 :: proc "c" (x: half2) -> half2 { return {atan(x.x), atan(x.y)} }
 atan_half3 :: proc "c" (x: half3) -> half3 { return {atan(x.x), atan(x.y), atan(x.z)} }
 atan_half4 :: proc "c" (x: half4) -> half4 { return {atan(x.x), atan(x.y), atan(x.z), atan(x.w)} }
 atan_float2 :: proc "c" (x: float2) -> float2 { return {atan(x.x), atan(x.y)} }
 atan_float3 :: proc "c" (x: float3) -> float3 { return {atan(x.x), atan(x.y), atan(x.z)} }
 atan_float4 :: proc "c" (x: float4) -> float4 { return {atan(x.x), atan(x.y), atan(x.z), atan(x.w)} }
 atan_double2 :: proc "c" (x: double2) -> double2 { return {atan(x.x), atan(x.y)} }
 atan_double3 :: proc "c" (x: double3) -> double3 { return {atan(x.x), atan(x.y), atan(x.z)} }
 atan_double4 :: proc "c" (x: double4) -> double4 { return {atan(x.x), atan(x.y), atan(x.z), atan(x.w)} }


    atan2_half,
    atan2_float,
    atan2_double,
    atan2_half2,
    atan2_half3,
    atan2_half4,
    atan2_float2,
    atan2_float3,
    atan2_float4,
    atan2_double2,
    atan2_double3,
    atan2_double4,
}
 atan2_half2 :: proc "c" (y, x: half2) -> half2 { return {atan2(y.x, x.x), atan2(y.y, x.y)} }
 atan2_half3 :: proc "c" (y, x: half3) -> half3 { return {atan2(y.x, x.x), atan2(y.y, x.y), atan2(y.z, x.z)} }
 atan2_half4 :: proc "c" (y, x: half4) -> half4 { return {atan2(y.x, x.x), atan2(y.y, x.y), atan2(y.z, x.z), atan2(y.w, x.w)} }
 atan2_float2 :: proc "c" (y, x: float2) -> float2 { return {atan2(y.x, x.x), atan2(y.y, x.y)} }
 atan2_float3 :: proc "c" (y, x: float3) -> float3 { return {atan2(y.x, x.x), atan2(y.y, x.y), atan2(y.z, x.z)} }
 atan2_float4 :: proc "c" (y, x: float4) -> float4 { return {atan2(y.x, x.x), atan2(y.y, x.y), atan2(y.z, x.z), atan2(y.w, x.w)} }
 atan2_double2 :: proc "c" (y, x: double2) -> double2 { return {atan2(y.x, x.x), atan2(y.y, x.y)} }
 atan2_double3 :: proc "c" (y, x: double3) -> double3 { return {atan2(y.x, x.x), atan2(y.y, x.y), atan2(y.z, x.z)} }
 atan2_double4 :: proc "c" (y, x: double4) -> double4 { return {atan2(y.x, x.x), atan2(y.y, x.y), atan2(y.z, x.z), atan2(y.w, x.w)} }




    cosh_half,
    cosh_float,
    cosh_double,
    cosh_half2,
    cosh_half3,
    cosh_half4,
    cosh_float2,
    cosh_float3,
    cosh_float4,
    cosh_double2,
    cosh_double3,
    cosh_double4,
}
 cosh_half2 :: proc "c" (x: half2) -> half2 { return {cosh(x.x), cosh(x.y)} }
 cosh_half3 :: proc "c" (x: half3) -> half3 { return {cosh(x.x), cosh(x.y), cosh(x.z)} }
 cosh_half4 :: proc "c" (x: half4) -> half4 { return {cosh(x.x), cosh(x.y), cosh(x.z), cosh(x.w)} }
 cosh_float2 :: proc "c" (x: float2) -> float2 { return {cosh(x.x), cosh(x.y)} }
 cosh_float3 :: proc "c" (x: float3) -> float3 { return {cosh(x.x), cosh(x.y), cosh(x.z)} }
 cosh_float4 :: proc "c" (x: float4) -> float4 { return {cosh(x.x), cosh(x.y), cosh(x.z), cosh(x.w)} }
 cosh_double2 :: proc "c" (x: double2) -> double2 { return {cosh(x.x), cosh(x.y)} }
 cosh_double3 :: proc "c" (x: double3) -> double3 { return {cosh(x.x), cosh(x.y), cosh(x.z)} }
 cosh_double4 :: proc "c" (x: double4) -> double4 { return {cosh(x.x), cosh(x.y), cosh(x.z), cosh(x.w)} }



    sinh_half,
    sinh_float,
    sinh_double,
    sinh_half2,
    sinh_half3,
    sinh_half4,
    sinh_float2,
    sinh_float3,
    sinh_float4,
    sinh_double2,
    sinh_double3,
    sinh_double4,
}
 sinh_half2 :: proc "c" (x: half2) -> half2 { return {sinh(x.x), sinh(x.y)} }
 sinh_half3 :: proc "c" (x: half3) -> half3 { return {sinh(x.x), sinh(x.y), sinh(x.z)} }
 sinh_half4 :: proc "c" (x: half4) -> half4 { return {sinh(x.x), sinh(x.y), sinh(x.z), sinh(x.w)} }
 sinh_float2 :: proc "c" (x: float2) -> float2 { return {sinh(x.x), sinh(x.y)} }
 sinh_float3 :: proc "c" (x: float3) -> float3 { return {sinh(x.x), sinh(x.y), sinh(x.z)} }
 sinh_float4 :: proc "c" (x: float4) -> float4 { return {sinh(x.x), sinh(x.y), sinh(x.z), sinh(x.w)} }
 sinh_double2 :: proc "c" (x: double2) -> double2 { return {sinh(x.x), sinh(x.y)} }
 sinh_double3 :: proc "c" (x: double3) -> double3 { return {sinh(x.x), sinh(x.y), sinh(x.z)} }
 sinh_double4 :: proc "c" (x: double4) -> double4 { return {sinh(x.x), sinh(x.y), sinh(x.z), sinh(x.w)} }


    tanh_half,
    tanh_float,
    tanh_double,
    tanh_half2,
    tanh_half3,
    tanh_half4,
    tanh_float2,
    tanh_float3,
    tanh_float4,
    tanh_double2,
    tanh_double3,
    tanh_double4,
}
 tanh_half2 :: proc "c" (x: half2) -> half2 { return {tanh(x.x), tanh(x.y)} }
 tanh_half3 :: proc "c" (x: half3) -> half3 { return {tanh(x.x), tanh(x.y), tanh(x.z)} }
 tanh_half4 :: proc "c" (x: half4) -> half4 { return {tanh(x.x), tanh(x.y), tanh(x.z), tanh(x.w)} }
 tanh_float2 :: proc "c" (x: float2) -> float2 { return {tanh(x.x), tanh(x.y)} }
 tanh_float3 :: proc "c" (x: float3) -> float3 { return {tanh(x.x), tanh(x.y), tanh(x.z)} }
 tanh_float4 :: proc "c" (x: float4) -> float4 { return {tanh(x.x), tanh(x.y), tanh(x.z), tanh(x.w)} }
 tanh_double2 :: proc "c" (x: double2) -> double2 { return {tanh(x.x), tanh(x.y)} }
 tanh_double3 :: proc "c" (x: double3) -> double3 { return {tanh(x.x), tanh(x.y), tanh(x.z)} }
 tanh_double4 :: proc "c" (x: double4) -> double4 { return {tanh(x.x), tanh(x.y), tanh(x.z), tanh(x.w)} }


    acosh_half,
    acosh_float,
    acosh_double,
    acosh_half2,
    acosh_half3,
    acosh_half4,
    acosh_float2,
    acosh_float3,
    acosh_float4,
    acosh_double2,
    acosh_double3,
    acosh_double4,
}
 acosh_half2 :: proc "c" (x: half2) -> half2 { return {acosh(x.x), acosh(x.y)} }
 acosh_half3 :: proc "c" (x: half3) -> half3 { return {acosh(x.x), acosh(x.y), acosh(x.z)} }
 acosh_half4 :: proc "c" (x: half4) -> half4 { return {acosh(x.x), acosh(x.y), acosh(x.z), acosh(x.w)} }
 acosh_float2 :: proc "c" (x: float2) -> float2 { return {acosh(x.x), acosh(x.y)} }
 acosh_float3 :: proc "c" (x: float3) -> float3 { return {acosh(x.x), acosh(x.y), acosh(x.z)} }
 acosh_float4 :: proc "c" (x: float4) -> float4 { return {acosh(x.x), acosh(x.y), acosh(x.z), acosh(x.w)} }
 acosh_double2 :: proc "c" (x: double2) -> double2 { return {acosh(x.x), acosh(x.y)} }
 acosh_double3 :: proc "c" (x: double3) -> double3 { return {acosh(x.x), acosh(x.y), acosh(x.z)} }
 acosh_double4 :: proc "c" (x: double4) -> double4 { return {acosh(x.x), acosh(x.y), acosh(x.z), acosh(x.w)} }


    asinh_half,
    asinh_float,
    asinh_double,
    asinh_half2,
    asinh_half3,
    asinh_half4,
    asinh_float2,
    asinh_float3,
    asinh_float4,
    asinh_double2,
    asinh_double3,
    asinh_double4,
}
 asinh_half2 :: proc "c" (x: half2) -> half2 { return {asinh(x.x), asinh(x.y)} }
 asinh_half3 :: proc "c" (x: half3) -> half3 { return {asinh(x.x), asinh(x.y), asinh(x.z)} }
 asinh_half4 :: proc "c" (x: half4) -> half4 { return {asinh(x.x), asinh(x.y), asinh(x.z), asinh(x.w)} }
 asinh_float2 :: proc "c" (x: float2) -> float2 { return {asinh(x.x), asinh(x.y)} }
 asinh_float3 :: proc "c" (x: float3) -> float3 { return {asinh(x.x), asinh(x.y), asinh(x.z)} }
 asinh_float4 :: proc "c" (x: float4) -> float4 { return {asinh(x.x), asinh(x.y), asinh(x.z), asinh(x.w)} }
 asinh_double2 :: proc "c" (x: double2) -> double2 { return {asinh(x.x), asinh(x.y)} }
 asinh_double3 :: proc "c" (x: double3) -> double3 { return {asinh(x.x), asinh(x.y), asinh(x.z)} }
 asinh_double4 :: proc "c" (x: double4) -> double4 { return {asinh(x.x), asinh(x.y), asinh(x.z), asinh(x.w)} }


    atanh_half,
    atanh_float,
    atanh_double,
    atanh_half2,
    atanh_half3,
    atanh_half4,
    atanh_float2,
    atanh_float3,
    atanh_float4,
    atanh_double2,
    atanh_double3,
    atanh_double4,
}
 atanh_half2 :: proc "c" (x: half2) -> half2 { return {atanh(x.x), atanh(x.y)} }
 atanh_half3 :: proc "c" (x: half3) -> half3 { return {atanh(x.x), atanh(x.y), atanh(x.z)} }
 atanh_half4 :: proc "c" (x: half4) -> half4 { return {atanh(x.x), atanh(x.y), atanh(x.z), atanh(x.w)} }
 atanh_float2 :: proc "c" (x: float2) -> float2 { return {atanh(x.x), atanh(x.y)} }
 atanh_float3 :: proc "c" (x: float3) -> float3 { return {atanh(x.x), atanh(x.y), atanh(x.z)} }
 atanh_float4 :: proc "c" (x: float4) -> float4 { return {atanh(x.x), atanh(x.y), atanh(x.z), atanh(x.w)} }
 atanh_double2 :: proc "c" (x: double2) -> double2 { return {atanh(x.x), atanh(x.y)} }
 atanh_double3 :: proc "c" (x: double3) -> double3 { return {atanh(x.x), atanh(x.y), atanh(x.z)} }
 atanh_double4 :: proc "c" (x: double4) -> double4 { return {atanh(x.x), atanh(x.y), atanh(x.z), atanh(x.w)} }


    sqrt_half,
    sqrt_float,
    sqrt_double,
    sqrt_half2,
    sqrt_half3,
    sqrt_half4,
    sqrt_float2,
    sqrt_float3,
    sqrt_float4,
    sqrt_double2,
    sqrt_double3,
    sqrt_double4,
}
 sqrt_half2 :: proc "c" (x: half2) -> half2 { return {sqrt(x.x), sqrt(x.y)} }
 sqrt_half3 :: proc "c" (x: half3) -> half3 { return {sqrt(x.x), sqrt(x.y), sqrt(x.z)} }
 sqrt_half4 :: proc "c" (x: half4) -> half4 { return {sqrt(x.x), sqrt(x.y), sqrt(x.z), sqrt(x.w)} }
 sqrt_float2 :: proc "c" (x: float2) -> float2 { return {sqrt(x.x), sqrt(x.y)} }
 sqrt_float3 :: proc "c" (x: float3) -> float3 { return {sqrt(x.x), sqrt(x.y), sqrt(x.z)} }
 sqrt_float4 :: proc "c" (x: float4) -> float4 { return {sqrt(x.x), sqrt(x.y), sqrt(x.z), sqrt(x.w)} }
 sqrt_double2 :: proc "c" (x: double2) -> double2 { return {sqrt(x.x), sqrt(x.y)} }
 sqrt_double3 :: proc "c" (x: double3) -> double3 { return {sqrt(x.x), sqrt(x.y), sqrt(x.z)} }
 sqrt_double4 :: proc "c" (x: double4) -> double4 { return {sqrt(x.x), sqrt(x.y), sqrt(x.z), sqrt(x.w)} }


    rsqrt_half,
    rsqrt_float,
    rsqrt_double,
    rsqrt_half2,
    rsqrt_half3,
    rsqrt_half4,
    rsqrt_float2,
    rsqrt_float3,
    rsqrt_float4,
    rsqrt_double2,
    rsqrt_double3,
    rsqrt_double4,
}
 rsqrt_half2 :: proc "c" (x: half2) -> half2 { return {rsqrt(x.x), rsqrt(x.y)} }
 rsqrt_half3 :: proc "c" (x: half3) -> half3 { return {rsqrt(x.x), rsqrt(x.y), rsqrt(x.z)} }
 rsqrt_half4 :: proc "c" (x: half4) -> half4 { return {rsqrt(x.x), rsqrt(x.y), rsqrt(x.z), rsqrt(x.w)} }
 rsqrt_float2 :: proc "c" (x: float2) -> float2 { return {rsqrt(x.x), rsqrt(x.y)} }
 rsqrt_float3 :: proc "c" (x: float3) -> float3 { return {rsqrt(x.x), rsqrt(x.y), rsqrt(x.z)} }
 rsqrt_float4 :: proc "c" (x: float4) -> float4 { return {rsqrt(x.x), rsqrt(x.y), rsqrt(x.z), rsqrt(x.w)} }
 rsqrt_double2 :: proc "c" (x: double2) -> double2 { return {rsqrt(x.x), rsqrt(x.y)} }
 rsqrt_double3 :: proc "c" (x: double3) -> double3 { return {rsqrt(x.x), rsqrt(x.y), rsqrt(x.z)} }
 rsqrt_double4 :: proc "c" (x: double4) -> double4 { return {rsqrt(x.x), rsqrt(x.y), rsqrt(x.z), rsqrt(x.w)} }


    rcp_half,
    rcp_float,
    rcp_double,
    rcp_half2,
    rcp_half3,
    rcp_half4,
    rcp_float2,
    rcp_float3,
    rcp_float4,
    rcp_double2,
    rcp_double3,
    rcp_double4,
}
 rcp_half2 :: proc "c" (x: half2) -> half2 { return {rcp(x.x), rcp(x.y)} }
 rcp_half3 :: proc "c" (x: half3) -> half3 { return {rcp(x.x), rcp(x.y), rcp(x.z)} }
 rcp_half4 :: proc "c" (x: half4) -> half4 { return {rcp(x.x), rcp(x.y), rcp(x.z), rcp(x.w)} }
 rcp_float2 :: proc "c" (x: float2) -> float2 { return {rcp(x.x), rcp(x.y)} }
 rcp_float3 :: proc "c" (x: float3) -> float3 { return {rcp(x.x), rcp(x.y), rcp(x.z)} }
 rcp_float4 :: proc "c" (x: float4) -> float4 { return {rcp(x.x), rcp(x.y), rcp(x.z), rcp(x.w)} }
 rcp_double2 :: proc "c" (x: double2) -> double2 { return {rcp(x.x), rcp(x.y)} }
 rcp_double3 :: proc "c" (x: double3) -> double3 { return {rcp(x.x), rcp(x.y), rcp(x.z)} }
 rcp_double4 :: proc "c" (x: double4) -> double4 { return {rcp(x.x), rcp(x.y), rcp(x.z), rcp(x.w)} }



    pow_half,
    pow_float,
    pow_double,
    pow_half2,
    pow_half3,
    pow_half4,
    pow_float2,
    pow_float3,
    pow_float4,
    pow_double2,
    pow_double3,
    pow_double4,
}
 pow_half2 :: proc "c" (x, y: half2) -> half2 { return {pow(x.x, y.x), pow(x.y, y.y)} }
 pow_half3 :: proc "c" (x, y: half3) -> half3 { return {pow(x.x, y.x), pow(x.y, y.y), pow(x.z, y.z)} }
 pow_half4 :: proc "c" (x, y: half4) -> half4 { return {pow(x.x, y.x), pow(x.y, y.y), pow(x.z, y.z), pow(x.w, y.w)} }
 pow_float2 :: proc "c" (x, y: float2) -> float2 { return {pow(x.x, y.x), pow(x.y, y.y)} }
 pow_float3 :: proc "c" (x, y: float3) -> float3 { return {pow(x.x, y.x), pow(x.y, y.y), pow(x.z, y.z)} }
 pow_float4 :: proc "c" (x, y: float4) -> float4 { return {pow(x.x, y.x), pow(x.y, y.y), pow(x.z, y.z), pow(x.w, y.w)} }
 pow_double2 :: proc "c" (x, y: double2) -> double2 { return {pow(x.x, y.x), pow(x.y, y.y)} }
 pow_double3 :: proc "c" (x, y: double3) -> double3 { return {pow(x.x, y.x), pow(x.y, y.y), pow(x.z, y.z)} }
 pow_double4 :: proc "c" (x, y: double4) -> double4 { return {pow(x.x, y.x), pow(x.y, y.y), pow(x.z, y.z), pow(x.w, y.w)} }




    exp_half,
    exp_float,
    exp_double,
    exp_half2,
    exp_half3,
    exp_half4,
    exp_float2,
    exp_float3,
    exp_float4,
    exp_double2,
    exp_double3,
    exp_double4,
}
 exp_half2 :: proc "c" (x: half2) -> half2 { return {exp(x.x), exp(x.y)} }
 exp_half3 :: proc "c" (x: half3) -> half3 { return {exp(x.x), exp(x.y), exp(x.z)} }
 exp_half4 :: proc "c" (x: half4) -> half4 { return {exp(x.x), exp(x.y), exp(x.z), exp(x.w)} }
 exp_float2 :: proc "c" (x: float2) -> float2 { return {exp(x.x), exp(x.y)} }
 exp_float3 :: proc "c" (x: float3) -> float3 { return {exp(x.x), exp(x.y), exp(x.z)} }
 exp_float4 :: proc "c" (x: float4) -> float4 { return {exp(x.x), exp(x.y), exp(x.z), exp(x.w)} }
 exp_double2 :: proc "c" (x: double2) -> double2 { return {exp(x.x), exp(x.y)} }
 exp_double3 :: proc "c" (x: double3) -> double3 { return {exp(x.x), exp(x.y), exp(x.z)} }
 exp_double4 :: proc "c" (x: double4) -> double4 { return {exp(x.x), exp(x.y), exp(x.z), exp(x.w)} }




    log_half,
    log_float,
    log_double,
    log_half2,
    log_half3,
    log_half4,
    log_float2,
    log_float3,
    log_float4,
    log_double2,
    log_double3,
    log_double4,
}
 log_half2 :: proc "c" (x: half2) -> half2 { return {log(x.x), log(x.y)} }
 log_half3 :: proc "c" (x: half3) -> half3 { return {log(x.x), log(x.y), log(x.z)} }
 log_half4 :: proc "c" (x: half4) -> half4 { return {log(x.x), log(x.y), log(x.z), log(x.w)} }
 log_float2 :: proc "c" (x: float2) -> float2 { return {log(x.x), log(x.y)} }
 log_float3 :: proc "c" (x: float3) -> float3 { return {log(x.x), log(x.y), log(x.z)} }
 log_float4 :: proc "c" (x: float4) -> float4 { return {log(x.x), log(x.y), log(x.z), log(x.w)} }
 log_double2 :: proc "c" (x: double2) -> double2 { return {log(x.x), log(x.y)} }
 log_double3 :: proc "c" (x: double3) -> double3 { return {log(x.x), log(x.y), log(x.z)} }
 log_double4 :: proc "c" (x: double4) -> double4 { return {log(x.x), log(x.y), log(x.z), log(x.w)} }



    log2_half,
    log2_float,
    log2_double,
    log2_half2,
    log2_half3,
    log2_half4,
    log2_float2,
    log2_float3,
    log2_float4,
    log2_double2,
    log2_double3,
    log2_double4,
}
 log2_half2 :: proc "c" (x: half2) -> half2 { return {log2(x.x), log2(x.y)} }
 log2_half3 :: proc "c" (x: half3) -> half3 { return {log2(x.x), log2(x.y), log2(x.z)} }
 log2_half4 :: proc "c" (x: half4) -> half4 { return {log2(x.x), log2(x.y), log2(x.z), log2(x.w)} }
 log2_float2 :: proc "c" (x: float2) -> float2 { return {log2(x.x), log2(x.y)} }
 log2_float3 :: proc "c" (x: float3) -> float3 { return {log2(x.x), log2(x.y), log2(x.z)} }
 log2_float4 :: proc "c" (x: float4) -> float4 { return {log2(x.x), log2(x.y), log2(x.z), log2(x.w)} }
 log2_double2 :: proc "c" (x: double2) -> double2 { return {log2(x.x), log2(x.y)} }
 log2_double3 :: proc "c" (x: double3) -> double3 { return {log2(x.x), log2(x.y), log2(x.z)} }
 log2_double4 :: proc "c" (x: double4) -> double4 { return {log2(x.x), log2(x.y), log2(x.z), log2(x.w)} }




    log10_half,
    log10_float,
    log10_double,
    log10_half2,
    log10_half3,
    log10_half4,
    log10_float2,
    log10_float3,
    log10_float4,
    log10_double2,
    log10_double3,
    log10_double4,
}
 log10_half2 :: proc "c" (x: half2) -> half2 { return {log10(x.x), log10(x.y)} }
 log10_half3 :: proc "c" (x: half3) -> half3 { return {log10(x.x), log10(x.y), log10(x.z)} }
 log10_half4 :: proc "c" (x: half4) -> half4 { return {log10(x.x), log10(x.y), log10(x.z), log10(x.w)} }
 log10_float2 :: proc "c" (x: float2) -> float2 { return {log10(x.x), log10(x.y)} }
 log10_float3 :: proc "c" (x: float3) -> float3 { return {log10(x.x), log10(x.y), log10(x.z)} }
 log10_float4 :: proc "c" (x: float4) -> float4 { return {log10(x.x), log10(x.y), log10(x.z), log10(x.w)} }
 log10_double2 :: proc "c" (x: double2) -> double2 { return {log10(x.x), log10(x.y)} }
 log10_double3 :: proc "c" (x: double3) -> double3 { return {log10(x.x), log10(x.y), log10(x.z)} }
 log10_double4 :: proc "c" (x: double4) -> double4 { return {log10(x.x), log10(x.y), log10(x.z), log10(x.w)} }





    exp2_half,
    exp2_float,
    exp2_double,
    exp2_half2,
    exp2_half3,
    exp2_half4,
    exp2_float2,
    exp2_float3,
    exp2_float4,
    exp2_double2,
    exp2_double3,
    exp2_double4,
}
 exp2_half2 :: proc "c" (x: half2) -> half2 { return {exp2(x.x), exp2(x.y)} }
 exp2_half3 :: proc "c" (x: half3) -> half3 { return {exp2(x.x), exp2(x.y), exp2(x.z)} }
 exp2_half4 :: proc "c" (x: half4) -> half4 { return {exp2(x.x), exp2(x.y), exp2(x.z), exp2(x.w)} }
 exp2_float2 :: proc "c" (x: float2) -> float2 { return {exp2(x.x), exp2(x.y)} }
 exp2_float3 :: proc "c" (x: float3) -> float3 { return {exp2(x.x), exp2(x.y), exp2(x.z)} }
 exp2_float4 :: proc "c" (x: float4) -> float4 { return {exp2(x.x), exp2(x.y), exp2(x.z), exp2(x.w)} }
 exp2_double2 :: proc "c" (x: double2) -> double2 { return {exp2(x.x), exp2(x.y)} }
 exp2_double3 :: proc "c" (x: double3) -> double3 { return {exp2(x.x), exp2(x.y), exp2(x.z)} }
 exp2_double4 :: proc "c" (x: double4) -> double4 { return {exp2(x.x), exp2(x.y), exp2(x.z), exp2(x.w)} }



    sign_half,
    sign_int,
    sign_uint,
    sign_float,
    sign_double,
    sign_half2,
    sign_half3,
    sign_half4,
    sign_float2,
    sign_float3,
    sign_float4,
    sign_double2,
    sign_double3,
    sign_double4,
    sign_int2,
    sign_int3,
    sign_int4,
    sign_uint2,
    sign_uint3,
    sign_uint4,
}
 sign_int :: proc "c" (x: int) -> int { return -1 if x < 0 else +1 if x > 0 else 0 }
 sign_uint :: proc "c" (x: uint) -> uint { return +1 if x > 0 else 0 }
 sign_half2 :: proc "c" (x: half2) -> half2 { return {sign(x.x), sign(x.y)} }
 sign_half3 :: proc "c" (x: half3) -> half3 { return {sign(x.x), sign(x.y), sign(x.z)} }
 sign_half4 :: proc "c" (x: half4) -> half4 { return {sign(x.x), sign(x.y), sign(x.z), sign(x.w)} }
 sign_float2 :: proc "c" (x: float2) -> float2 { return {sign(x.x), sign(x.y)} }
 sign_float3 :: proc "c" (x: float3) -> float3 { return {sign(x.x), sign(x.y), sign(x.z)} }
 sign_float4 :: proc "c" (x: float4) -> float4 { return {sign(x.x), sign(x.y), sign(x.z), sign(x.w)} }
 sign_double2 :: proc "c" (x: double2) -> double2 { return {sign(x.x), sign(x.y)} }
 sign_double3 :: proc "c" (x: double3) -> double3 { return {sign(x.x), sign(x.y), sign(x.z)} }
 sign_double4 :: proc "c" (x: double4) -> double4 { return {sign(x.x), sign(x.y), sign(x.z), sign(x.w)} }
 sign_int2 :: proc "c" (x: int2) -> int2 { return {sign(x.x), sign(x.y)} }
 sign_int3 :: proc "c" (x: int3) -> int3 { return {sign(x.x), sign(x.y), sign(x.z)} }
 sign_int4 :: proc "c" (x: int4) -> int4 { return {sign(x.x), sign(x.y), sign(x.z), sign(x.w)} }
 sign_uint2 :: proc "c" (x: uint2) -> uint2 { return {sign(x.x), sign(x.y)} }
 sign_uint3 :: proc "c" (x: uint3) -> uint3 { return {sign(x.x), sign(x.y), sign(x.z)} }
 sign_uint4 :: proc "c" (x: uint4) -> uint4 { return {sign(x.x), sign(x.y), sign(x.z), sign(x.w)} }


    floor_half,
    floor_float,
    floor_double,
    floor_half2,
    floor_half3,
    floor_half4,
    floor_float2,
    floor_float3,
    floor_float4,
    floor_double2,
    floor_double3,
    floor_double4,
}
 floor_half2 :: proc "c" (x: half2) -> half2 { return {floor(x.x), floor(x.y)} }
 floor_half3 :: proc "c" (x: half3) -> half3 { return {floor(x.x), floor(x.y), floor(x.z)} }
 floor_half4 :: proc "c" (x: half4) -> half4 { return {floor(x.x), floor(x.y), floor(x.z), floor(x.w)} }
 floor_float2 :: proc "c" (x: float2) -> float2 { return {floor(x.x), floor(x.y)} }
 floor_float3 :: proc "c" (x: float3) -> float3 { return {floor(x.x), floor(x.y), floor(x.z)} }
 floor_float4 :: proc "c" (x: float4) -> float4 { return {floor(x.x), floor(x.y), floor(x.z), floor(x.w)} }
 floor_double2 :: proc "c" (x: double2) -> double2 { return {floor(x.x), floor(x.y)} }
 floor_double3 :: proc "c" (x: double3) -> double3 { return {floor(x.x), floor(x.y), floor(x.z)} }
 floor_double4 :: proc "c" (x: double4) -> double4 { return {floor(x.x), floor(x.y), floor(x.z), floor(x.w)} }


    round_half,
    round_float,
    round_double,
    round_half2,
    round_half3,
    round_half4,
    round_float2,
    round_float3,
    round_float4,
    round_double2,
    round_double3,
    round_double4,
}
 round_half2 :: proc "c" (x: half2) -> half2 { return {round(x.x), round(x.y)} }
 round_half3 :: proc "c" (x: half3) -> half3 { return {round(x.x), round(x.y), round(x.z)} }
 round_half4 :: proc "c" (x: half4) -> half4 { return {round(x.x), round(x.y), round(x.z), round(x.w)} }
 round_float2 :: proc "c" (x: float2) -> float2 { return {round(x.x), round(x.y)} }
 round_float3 :: proc "c" (x: float3) -> float3 { return {round(x.x), round(x.y), round(x.z)} }
 round_float4 :: proc "c" (x: float4) -> float4 { return {round(x.x), round(x.y), round(x.z), round(x.w)} }
 round_double2 :: proc "c" (x: double2) -> double2 { return {round(x.x), round(x.y)} }
 round_double3 :: proc "c" (x: double3) -> double3 { return {round(x.x), round(x.y), round(x.z)} }
 round_double4 :: proc "c" (x: double4) -> double4 { return {round(x.x), round(x.y), round(x.z), round(x.w)} }



    ceil_half,
    ceil_float,
    ceil_double,
    ceil_half2,
    ceil_half3,
    ceil_half4,
    ceil_float2,
    ceil_float3,
    ceil_float4,
    ceil_double2,
    ceil_double3,
    ceil_double4,
}
 ceil_half2 :: proc "c" (x: half2) -> half2 { return {ceil(x.x), ceil(x.y)} }
 ceil_half3 :: proc "c" (x: half3) -> half3 { return {ceil(x.x), ceil(x.y), ceil(x.z)} }
 ceil_half4 :: proc "c" (x: half4) -> half4 { return {ceil(x.x), ceil(x.y), ceil(x.z), ceil(x.w)} }
 ceil_float2 :: proc "c" (x: float2) -> float2 { return {ceil(x.x), ceil(x.y)} }
 ceil_float3 :: proc "c" (x: float3) -> float3 { return {ceil(x.x), ceil(x.y), ceil(x.z)} }
 ceil_float4 :: proc "c" (x: float4) -> float4 { return {ceil(x.x), ceil(x.y), ceil(x.z), ceil(x.w)} }
 ceil_double2 :: proc "c" (x: double2) -> double2 { return {ceil(x.x), ceil(x.y)} }
 ceil_double3 :: proc "c" (x: double3) -> double3 { return {ceil(x.x), ceil(x.y), ceil(x.z)} }
 ceil_double4 :: proc "c" (x: double4) -> double4 { return {ceil(x.x), ceil(x.y), ceil(x.z), ceil(x.w)} }


 isfinite_half  :: proc "c" (x: half)  -> bool  { return !isinf_half(x) }
 isfinite_half2 :: proc "c" (x: half2) -> bool2 { return {isfinite_half(x.x), isfinite_half(x.y)} }
 isfinite_half3 :: proc "c" (x: half3) -> bool3 { return {isfinite_half(x.x), isfinite_half(x.y), isfinite_half(x.z)} }
 isfinite_half4 :: proc "c" (x: half4) -> bool4 { return {isfinite_half(x.x), isfinite_half(x.y), isfinite_half(x.z), isfinite_half(x.w)} }
 isfinite_float  :: proc "c" (x: float)  -> bool  { return !isinf_float(x) }
 isfinite_float2 :: proc "c" (x: float2) -> bool2 { return {isfinite_float(x.x), isfinite_float(x.y)} }
 isfinite_float3 :: proc "c" (x: float3) -> bool3 { return {isfinite_float(x.x), isfinite_float(x.y), isfinite_float(x.z)} }
 isfinite_float4 :: proc "c" (x: float4) -> bool4 { return {isfinite_float(x.x), isfinite_float(x.y), isfinite_float(x.z), isfinite_float(x.w)} }
 isfinite_double  :: proc "c" (x: double)  -> bool  { return !isinf_double(x) }
 isfinite_double2 :: proc "c" (x: double2) -> bool2 { return {isfinite_double(x.x), isfinite_double(x.y)} }
 isfinite_double3 :: proc "c" (x: double3) -> bool3 { return {isfinite_double(x.x), isfinite_double(x.y), isfinite_double(x.z)} }
 isfinite_double4 :: proc "c" (x: double4) -> bool4 { return {isfinite_double(x.x), isfinite_double(x.y), isfinite_double(x.z), isfinite_double(x.w)} }

// isfinite is the opposite of isinf and returns true if the number is neither positive-infinite or negative-infinite

    isfinite_half,
    isfinite_half2,
    isfinite_half3,
    isfinite_half4,
    isfinite_float,
    isfinite_float2,
    isfinite_float3,
    isfinite_float4,
    isfinite_double,
    isfinite_double2,
    isfinite_double3,
    isfinite_double4,
}


 isinf_half  :: proc "c" (x: half)  -> bool  { return x * 0.5 == x }
 isinf_half2 :: proc "c" (x: half2) -> bool2 { return {isinf_half(x.x), isinf_half(x.y)} }
 isinf_half3 :: proc "c" (x: half3) -> bool3 { return {isinf_half(x.x), isinf_half(x.y), isinf_half(x.z)} }
 isinf_half4 :: proc "c" (x: half4) -> bool4 { return {isinf_half(x.x), isinf_half(x.y), isinf_half(x.z), isinf_half(x.w)} }
 isinf_float  :: proc "c" (x: float)  -> bool  { return x * 0.5 == x }
 isinf_float2 :: proc "c" (x: float2) -> bool2 { return {isinf_float(x.x), isinf_float(x.y)} }
 isinf_float3 :: proc "c" (x: float3) -> bool3 { return {isinf_float(x.x), isinf_float(x.y), isinf_float(x.z)} }
 isinf_float4 :: proc "c" (x: float4) -> bool4 { return {isinf_float(x.x), isinf_float(x.y), isinf_float(x.z), isinf_float(x.w)} }
 isinf_double  :: proc "c" (x: double)  -> bool  { return x * 0.5 == x }
 isinf_double2 :: proc "c" (x: double2) -> bool2 { return {isinf_double(x.x), isinf_double(x.y)} }
 isinf_double3 :: proc "c" (x: double3) -> bool3 { return {isinf_double(x.x), isinf_double(x.y), isinf_double(x.z)} }
 isinf_double4 :: proc "c" (x: double4) -> bool4 { return {isinf_double(x.x), isinf_double(x.y), isinf_double(x.z), isinf_double(x.w)} }

// isinf is the opposite of isfinite and returns true if the number is either positive-infinite or negative-infinite

    isinf_half,
    isinf_half2,
    isinf_half3,
    isinf_half4,
    isinf_float,
    isinf_float2,
    isinf_float3,
    isinf_float4,
    isinf_double,
    isinf_double2,
    isinf_double3,
    isinf_double4,
}


 isnan_half2 :: proc "c" (x: half2) -> bool2 { return {isnan_half(x.x), isnan_half(x.y)} }
 isnan_half3 :: proc "c" (x: half3) -> bool3 { return {isnan_half(x.x), isnan_half(x.y), isnan_half(x.z)} }
 isnan_half4 :: proc "c" (x: half4) -> bool4 { return {isnan_half(x.x), isnan_half(x.y), isnan_half(x.z), isnan_half(x.w)} }
 isnan_float2 :: proc "c" (x: float2) -> bool2 { return {isnan_float(x.x), isnan_float(x.y)} }
 isnan_float3 :: proc "c" (x: float3) -> bool3 { return {isnan_float(x.x), isnan_float(x.y), isnan_float(x.z)} }
 isnan_float4 :: proc "c" (x: float4) -> bool4 { return {isnan_float(x.x), isnan_float(x.y), isnan_float(x.z), isnan_float(x.w)} }
 isnan_double2 :: proc "c" (x: double2) -> bool2 { return {isnan_double(x.x), isnan_double(x.y)} }
 isnan_double3 :: proc "c" (x: double3) -> bool3 { return {isnan_double(x.x), isnan_double(x.y), isnan_double(x.z)} }
 isnan_double4 :: proc "c" (x: double4) -> bool4 { return {isnan_double(x.x), isnan_double(x.y), isnan_double(x.z), isnan_double(x.w)} }

// isnan returns true if the input value is the special case of Not-A-Number

    isnan_half,
    isnan_half2,
    isnan_half3,
    isnan_half4,
    isnan_float,
    isnan_float2,
    isnan_float3,
    isnan_float4,
    isnan_double,
    isnan_double2,
    isnan_double3,
    isnan_double4,
}


    fmod_half,
    fmod_float,
    fmod_double,
    fmod_half2,
    fmod_half3,
    fmod_half4,
    fmod_float2,
    fmod_float3,
    fmod_float4,
    fmod_double2,
    fmod_double3,
    fmod_double4,
}
 fmod_half2 :: proc "c" (x, y: half2) -> half2 { return {fmod(x.x, y.x), fmod(x.y, y.y)} }
 fmod_half3 :: proc "c" (x, y: half3) -> half3 { return {fmod(x.x, y.x), fmod(x.y, y.y), fmod(x.z, y.z)} }
 fmod_half4 :: proc "c" (x, y: half4) -> half4 { return {fmod(x.x, y.x), fmod(x.y, y.y), fmod(x.z, y.z), fmod(x.w, y.w)} }
 fmod_float2 :: proc "c" (x, y: float2) -> float2 { return {fmod(x.x, y.x), fmod(x.y, y.y)} }
 fmod_float3 :: proc "c" (x, y: float3) -> float3 { return {fmod(x.x, y.x), fmod(x.y, y.y), fmod(x.z, y.z)} }
 fmod_float4 :: proc "c" (x, y: float4) -> float4 { return {fmod(x.x, y.x), fmod(x.y, y.y), fmod(x.z, y.z), fmod(x.w, y.w)} }
 fmod_double2 :: proc "c" (x, y: double2) -> double2 { return {fmod(x.x, y.x), fmod(x.y, y.y)} }
 fmod_double3 :: proc "c" (x, y: double3) -> double3 { return {fmod(x.x, y.x), fmod(x.y, y.y), fmod(x.z, y.z)} }
 fmod_double4 :: proc "c" (x, y: double4) -> double4 { return {fmod(x.x, y.x), fmod(x.y, y.y), fmod(x.z, y.z), fmod(x.w, y.w)} }



    frac_half,
    frac_float,
    frac_double,
    frac_half2,
    frac_half3,
    frac_half4,
    frac_float2,
    frac_float3,
    frac_float4,
    frac_double2,
    frac_double3,
    frac_double4,
}
 frac_half2 :: proc "c" (x: half2) -> half2 { return {frac(x.x), frac(x.y)} }
 frac_half3 :: proc "c" (x: half3) -> half3 { return {frac(x.x), frac(x.y), frac(x.z)} }
 frac_half4 :: proc "c" (x: half4) -> half4 { return {frac(x.x), frac(x.y), frac(x.z), frac(x.w)} }
 frac_float2 :: proc "c" (x: float2) -> float2 { return {frac(x.x), frac(x.y)} }
 frac_float3 :: proc "c" (x: float3) -> float3 { return {frac(x.x), frac(x.y), frac(x.z)} }
 frac_float4 :: proc "c" (x: float4) -> float4 { return {frac(x.x), frac(x.y), frac(x.z), frac(x.w)} }
 frac_double2 :: proc "c" (x: double2) -> double2 { return {frac(x.x), frac(x.y)} }
 frac_double3 :: proc "c" (x: double3) -> double3 { return {frac(x.x), frac(x.y), frac(x.z)} }
 frac_double4 :: proc "c" (x: double4) -> double4 { return {frac(x.x), frac(x.y), frac(x.z), frac(x.w)} }




    radians_half,
    radians_float,
    radians_double,
    radians_half2,
    radians_half3,
    radians_half4,
    radians_float2,
    radians_float3,
    radians_float4,
    radians_double2,
    radians_double3,
    radians_double4,
}
 radians_half  :: proc "c" (degrees: half)  -> half  { return degrees * TAU / 360.0 }
 radians_float  :: proc "c" (degrees: float)  -> float  { return degrees * TAU / 360.0 }
 radians_double  :: proc "c" (degrees: double)  -> double  { return degrees * TAU / 360.0 }
 radians_half2 :: proc "c" (degrees: half2) -> half2 { return degrees * TAU / 360.0 }
 radians_half3 :: proc "c" (degrees: half3) -> half3 { return degrees * TAU / 360.0 }
 radians_half4 :: proc "c" (degrees: half4) -> half4 { return degrees * TAU / 360.0 }
 radians_float2 :: proc "c" (degrees: float2) -> float2 { return degrees * TAU / 360.0 }
 radians_float3 :: proc "c" (degrees: float3) -> float3 { return degrees * TAU / 360.0 }
 radians_float4 :: proc "c" (degrees: float4) -> float4 { return degrees * TAU / 360.0 }
 radians_double2 :: proc "c" (degrees: double2) -> double2 { return degrees * TAU / 360.0 }
 radians_double3 :: proc "c" (degrees: double3) -> double3 { return degrees * TAU / 360.0 }
 radians_double4 :: proc "c" (degrees: double4) -> double4 { return degrees * TAU / 360.0 }



    degrees_half,
    degrees_float,
    degrees_double,
    degrees_half2,
    degrees_half3,
    degrees_half4,
    degrees_float2,
    degrees_float3,
    degrees_float4,
    degrees_double2,
    degrees_double3,
    degrees_double4,
}
 degrees_half  :: proc "c" (radians: half)  -> half  { return radians * 360.0 / TAU }
 degrees_float  :: proc "c" (radians: float)  -> float  { return radians * 360.0 / TAU }
 degrees_double  :: proc "c" (radians: double)  -> double  { return radians * 360.0 / TAU }
 degrees_half2 :: proc "c" (radians: half2) -> half2 { return radians * 360.0 / TAU }
 degrees_half3 :: proc "c" (radians: half3) -> half3 { return radians * 360.0 / TAU }
 degrees_half4 :: proc "c" (radians: half4) -> half4 { return radians * 360.0 / TAU }
 degrees_float2 :: proc "c" (radians: float2) -> float2 { return radians * 360.0 / TAU }
 degrees_float3 :: proc "c" (radians: float3) -> float3 { return radians * 360.0 / TAU }
 degrees_float4 :: proc "c" (radians: float4) -> float4 { return radians * 360.0 / TAU }
 degrees_double2 :: proc "c" (radians: double2) -> double2 { return radians * 360.0 / TAU }
 degrees_double3 :: proc "c" (radians: double3) -> double3 { return radians * 360.0 / TAU }
 degrees_double4 :: proc "c" (radians: double4) -> double4 { return radians * 360.0 / TAU }


    min_half,
    min_int,  
    min_uint,  
    min_float,  
    min_double,
    min_half2,
    min_half3,
    min_half4,
    min_float2, 
    min_float3, 
    min_float4, 
    min_double2, 
    min_double3, 
    min_double4, 
    min_int2,
    min_int3,
    min_int4,
    min_uint2,
    min_uint3,
    min_uint4,
}
 min_int  :: proc "c" (x, y: int) -> int   { return builtin.min(x, y) }
 min_uint  :: proc "c" (x, y: uint) -> uint   { return builtin.min(x, y) }
 min_half  :: proc "c" (x, y: half) -> half   { return builtin.min(x, y) }
 min_float  :: proc "c" (x, y: float) -> float   { return builtin.min(x, y) }
 min_double  :: proc "c" (x, y: double) -> double   { return builtin.min(x, y) }
 min_half2 :: proc "c" (x, y: half2) -> half2 { return {min(x.x, y.x), min(x.y, y.y)} }
 min_half3 :: proc "c" (x, y: half3) -> half3 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z)} }
 min_half4 :: proc "c" (x, y: half4) -> half4 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z), min(x.w, y.w)} }
 min_float2 :: proc "c" (x, y: float2) -> float2 { return {min(x.x, y.x), min(x.y, y.y)} }
 min_float3 :: proc "c" (x, y: float3) -> float3 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z)} }
 min_float4 :: proc "c" (x, y: float4) -> float4 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z), min(x.w, y.w)} }
 min_double2 :: proc "c" (x, y: double2) -> double2 { return {min(x.x, y.x), min(x.y, y.y)} }
 min_double3 :: proc "c" (x, y: double3) -> double3 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z)} }
 min_double4 :: proc "c" (x, y: double4) -> double4 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z), min(x.w, y.w)} }
 min_int2 :: proc "c" (x, y: int2) -> int2 { return {min(x.x, y.x), min(x.y, y.y)} }
 min_int3 :: proc "c" (x, y: int3) -> int3 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z)} }
 min_int4 :: proc "c" (x, y: int4) -> int4 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z), min(x.w, y.w)} }
 min_uint2 :: proc "c" (x, y: uint2) -> uint2 { return {min(x.x, y.x), min(x.y, y.y)} }
 min_uint3 :: proc "c" (x, y: uint3) -> uint3 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z)} }
 min_uint4 :: proc "c" (x, y: uint4) -> uint4 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z), min(x.w, y.w)} }



    max_int,  
    max_uint,
    max_half,
    max_float,  
    max_double,
    max_half2,
    max_half3,
    max_half4,
    max_float2, 
    max_float3, 
    max_float4, 
    max_double2, 
    max_double3, 
    max_double4, 
    max_int2,
    max_int3,
    max_int4,
    max_uint2,
    max_uint3,
    max_uint4,
}
 max_int  :: proc "c" (x, y: int) -> int   { return builtin.max(x, y) }
 max_uint  :: proc "c" (x, y: uint) -> uint   { return builtin.max(x, y) }
 max_float  :: proc "c" (x, y: float) -> float   { return builtin.max(x, y) }
 max_half  :: proc "c" (x, y: half) -> half   { return builtin.max(x, y) }
 max_double  :: proc "c" (x, y: double) -> double   { return builtin.max(x, y) }
 max_half2 :: proc "c" (x, y: half2) -> half2 { return {max(x.x, y.x), max(x.y, y.y)} }
 max_half3 :: proc "c" (x, y: half3) -> half3 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z)} }
 max_half4 :: proc "c" (x, y: half4) -> half4 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z), max(x.w, y.w)} }
 max_float2 :: proc "c" (x, y: float2) -> float2 { return {max(x.x, y.x), max(x.y, y.y)} }
 max_float3 :: proc "c" (x, y: float3) -> float3 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z)} }
 max_float4 :: proc "c" (x, y: float4) -> float4 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z), max(x.w, y.w)} }
 max_double2 :: proc "c" (x, y: double2) -> double2 { return {max(x.x, y.x), max(x.y, y.y)} }
 max_double3 :: proc "c" (x, y: double3) -> double3 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z)} }
 max_double4 :: proc "c" (x, y: double4) -> double4 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z), max(x.w, y.w)} }
 max_int2 :: proc "c" (x, y: int2) -> int2 { return {max(x.x, y.x), max(x.y, y.y)} }
 max_int3 :: proc "c" (x, y: int3) -> int3 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z)} }
 max_int4 :: proc "c" (x, y: int4) -> int4 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z), max(x.w, y.w)} }
 max_uint2 :: proc "c" (x, y: uint2) -> uint2 { return {max(x.x, y.x), max(x.y, y.y)} }
 max_uint3 :: proc "c" (x, y: uint3) -> uint3 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z)} }
 max_uint4 :: proc "c" (x, y: uint4) -> uint4 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z), max(x.w, y.w)} }




    clamp_int, 
    clamp_uint, 
    clamp_half,
    clamp_float,
    clamp_double,
    clamp_half2,
    clamp_half3,
    clamp_half4,
    clamp_float2, 
    clamp_float3, 
    clamp_float4, 
    clamp_double2, 
    clamp_double3, 
    clamp_double4, 
    clamp_int2,
    clamp_int3,
    clamp_int4,
    clamp_uint2,
    clamp_uint3,
    clamp_uint4,
}
 clamp_int  :: proc "c" (x, y, z: int) -> int   { return builtin.clamp(x, y, z) }
 clamp_uint  :: proc "c" (x, y, z: uint) -> uint   { return builtin.clamp(x, y, z) }
 clamp_half  :: proc "c" (x, y, z: half) -> half   { return builtin.clamp(x, y, z) }
 clamp_float  :: proc "c" (x, y, z: float) -> float   { return builtin.clamp(x, y, z) }
 clamp_double  :: proc "c" (x, y, z: double) -> double   { return builtin.clamp(x, y, z) }
 clamp_half2 :: proc "c" (x, y, z: half2) -> half2 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y)} }
 clamp_half3 :: proc "c" (x, y, z: half3) -> half3 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z)} }
 clamp_half4 :: proc "c" (x, y, z: half4) -> half4 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z), clamp(x.w, y.w, z.w)} }
 clamp_float2 :: proc "c" (x, y, z: float2) -> float2 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y)} }
 clamp_float3 :: proc "c" (x, y, z: float3) -> float3 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z)} }
 clamp_float4 :: proc "c" (x, y, z: float4) -> float4 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z), clamp(x.w, y.w, z.w)} }
 clamp_double2 :: proc "c" (x, y, z: double2) -> double2 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y)} }
 clamp_double3 :: proc "c" (x, y, z: double3) -> double3 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z)} }
 clamp_double4 :: proc "c" (x, y, z: double4) -> double4 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z), clamp(x.w, y.w, z.w)} }
 clamp_int2 :: proc "c" (x, y, z: int2) -> int2 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y)} }
 clamp_int3 :: proc "c" (x, y, z: int3) -> int3 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z)} }
 clamp_int4 :: proc "c" (x, y, z: int4) -> int4 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z), clamp(x.w, y.w, z.w)} }
 clamp_uint2 :: proc "c" (x, y, z: uint2) -> uint2 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y)} }
 clamp_uint3 :: proc "c" (x, y, z: uint3) -> uint3 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z)} }
 clamp_uint4 :: proc "c" (x, y, z: uint4) -> uint4 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z), clamp(x.w, y.w, z.w)} }


    saturate_int,
    saturate_uint,
    saturate_half,
    saturate_float,
    saturate_double,
    saturate_half2,
    saturate_half3,
    saturate_half4,
    saturate_float2,
    saturate_float3,
    saturate_float4,
    saturate_double2,
    saturate_double3,
    saturate_double4,
    saturate_int2,
    saturate_int3,
    saturate_int4,
    saturate_uint2,
    saturate_uint3,
    saturate_uint4,
}
 saturate_int  :: proc "c" (v: int) -> int   { return builtin.clamp(v, 0, 1) }
 saturate_uint  :: proc "c" (v: uint) -> uint   { return builtin.clamp(v, 0, 1) }
 saturate_half  :: proc "c" (v: half) -> half   { return builtin.clamp(v, 0, 1) }
 saturate_float  :: proc "c" (v: float) -> float   { return builtin.clamp(v, 0, 1) }
 saturate_double  :: proc "c" (v: double) -> double   { return builtin.clamp(v, 0, 1) }
 saturate_half2 :: proc "c" (v: half2) -> half2 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1)} }
 saturate_half3 :: proc "c" (v: half3) -> half3 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1)} }
 saturate_half4 :: proc "c" (v: half4) -> half4 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1), builtin.clamp(v.w, 0, 1)} }
 saturate_float2 :: proc "c" (v: float2) -> float2 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1)} }
 saturate_float3 :: proc "c" (v: float3) -> float3 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1)} }
 saturate_float4 :: proc "c" (v: float4) -> float4 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1), builtin.clamp(v.w, 0, 1)} }
 saturate_double2 :: proc "c" (v: double2) -> double2 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1)} }
 saturate_double3 :: proc "c" (v: double3) -> double3 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1)} }
 saturate_double4 :: proc "c" (v: double4) -> double4 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1), builtin.clamp(v.w, 0, 1)} }
 saturate_int2 :: proc "c" (v: int2) -> int2 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1)} }
 saturate_int3 :: proc "c" (v: int3) -> int3 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1)} }
 saturate_int4 :: proc "c" (v: int4) -> int4 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1), builtin.clamp(v.w, 0, 1)} }
 saturate_uint2 :: proc "c" (v: uint2) -> uint2 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1)} }
 saturate_uint3 :: proc "c" (v: uint3) -> uint3 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1)} }
 saturate_uint4 :: proc "c" (v: uint4) -> uint4 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1), builtin.clamp(v.w, 0, 1)} }



    lerp_half,
    lerp_float,
    lerp_double,
    lerp_half2,
    lerp_half3,
    lerp_half4,
    lerp_float2,
    lerp_float3,
    lerp_float4,
    lerp_double2,
    lerp_double3,
    lerp_double4,
}
 lerp_half  :: proc "c" (x, y, t: half) -> half   { return x*(1-t) + y*t }
 lerp_float  :: proc "c" (x, y, t: float) -> float   { return x*(1-t) + y*t }
 lerp_double  :: proc "c" (x, y, t: double) -> double   { return x*(1-t) + y*t }
 lerp_half2 :: proc "c" (x, y, t: half2) -> half2 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, t.y)} }
 lerp_half3 :: proc "c" (x, y, t: half3) -> half3 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, t.y), lerp(x.z, y.z, t.z)} }
 lerp_half4 :: proc "c" (x, y, t: half4) -> half4 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, y.y), lerp(x.z, y.z, t.z), lerp(x.w, y.w, t.w)} }
 lerp_float2 :: proc "c" (x, y, t: float2) -> float2 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, t.y)} }
 lerp_float3 :: proc "c" (x, y, t: float3) -> float3 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, t.y), lerp(x.z, y.z, t.z)} }
 lerp_float4 :: proc "c" (x, y, t: float4) -> float4 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, y.y), lerp(x.z, y.z, t.z), lerp(x.w, y.w, t.w)} }
 lerp_double2 :: proc "c" (x, y, t: double2) -> double2 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, t.y)} }
 lerp_double3 :: proc "c" (x, y, t: double3) -> double3 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, t.y), lerp(x.z, y.z, t.z)} }
 lerp_double4 :: proc "c" (x, y, t: double4) -> double4 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, y.y), lerp(x.z, y.z, t.z), lerp(x.w, y.w, t.w)} }



    step_half,
    step_float,
    step_double,
    step_half2,
    step_half3,
    step_half4,
    step_float2,
    step_float3,
    step_float4,
    step_double2,
    step_double3,
    step_double4,
}
 step_half  :: proc "c" (edge, x: half) -> half   { return 0 if x < edge else 1 }
 step_float  :: proc "c" (edge, x: float) -> float   { return 0 if x < edge else 1 }
 step_double  :: proc "c" (edge, x: double) -> double   { return 0 if x < edge else 1 }
 step_half2 :: proc "c" (edge, x: half2) -> half2 { return {step(edge.x, x.x), step(edge.y, x.y)} }
 step_half3 :: proc "c" (edge, x: half3) -> half3 { return {step(edge.x, x.x), step(edge.y, x.y), step(edge.z, x.z)} }
 step_half4 :: proc "c" (edge, x: half4) -> half4 { return {step(edge.x, x.x), step(edge.y, x.y), step(edge.z, x.z), step(edge.w, x.w)} }
 step_float2 :: proc "c" (edge, x: float2) -> float2 { return {step(edge.x, x.x), step(edge.y, x.y)} }
 step_float3 :: proc "c" (edge, x: float3) -> float3 { return {step(edge.x, x.x), step(edge.y, x.y), step(edge.z, x.z)} }
 step_float4 :: proc "c" (edge, x: float4) -> float4 { return {step(edge.x, x.x), step(edge.y, x.y), step(edge.z, x.z), step(edge.w, x.w)} }
 step_double2 :: proc "c" (edge, x: double2) -> double2 { return {step(edge.x, x.x), step(edge.y, x.y)} }
 step_double3 :: proc "c" (edge, x: double3) -> double3 { return {step(edge.x, x.x), step(edge.y, x.y), step(edge.z, x.z)} }
 step_double4 :: proc "c" (edge, x: double4) -> double4 { return {step(edge.x, x.x), step(edge.y, x.y), step(edge.z, x.z), step(edge.w, x.w)} }


    smoothstep_half,
    smoothstep_float,
    smoothstep_double,
    smoothstep_half2,
    smoothstep_half3,
    smoothstep_half4,
    smoothstep_float2,
    smoothstep_float3,
    smoothstep_float4,
    smoothstep_double2,
    smoothstep_double3,
    smoothstep_double4,
}
 smoothstep_half :: proc "c" (edge0, edge1, x: half) -> half {
    y := clamp(((x-edge0) / (edge1 - edge0)), 0, 1)
    return y * y * (3 - 2*y)
}
 smoothstep_float :: proc "c" (edge0, edge1, x: float) -> float {
    y := clamp(((x-edge0) / (edge1 - edge0)), 0, 1)
    return y * y * (3 - 2*y)
}
 smoothstep_double :: proc "c" (edge0, edge1, x: double) -> double {
    y := clamp(((x-edge0) / (edge1 - edge0)), 0, 1)
    return y * y * (3 - 2*y)
}
 smoothstep_half2  :: proc "c" (edge0, edge1, x: half2) -> half2   { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y)} }
 smoothstep_half3  :: proc "c" (edge0, edge1, x: half3) -> half3   { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y), smoothstep(edge0.z, edge1.z, x.z)} }
 smoothstep_half4  :: proc "c" (edge0, edge1, x: half4) -> half4   { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y), smoothstep(edge0.z, edge1.z, x.z), smoothstep(edge0.w, edge1.w, x.w)} }
 smoothstep_float2  :: proc "c" (edge0, edge1, x: float2) -> float2   { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y)} }
 smoothstep_float3  :: proc "c" (edge0, edge1, x: float3) -> float3   { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y), smoothstep(edge0.z, edge1.z, x.z)} }
 smoothstep_float4  :: proc "c" (edge0, edge1, x: float4) -> float4   { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y), smoothstep(edge0.z, edge1.z, x.z), smoothstep(edge0.w, edge1.w, x.w)} }
 smoothstep_double2 :: proc "c" (edge0, edge1, x: double2) -> double2 { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y)} }
 smoothstep_double3 :: proc "c" (edge0, edge1, x: double3) -> double3 { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y), smoothstep(edge0.z, edge1.z, x.z)} }
 smoothstep_double4 :: proc "c" (edge0, edge1, x: double4) -> double4 { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y), smoothstep(edge0.z, edge1.z, x.z), smoothstep(edge0.w, edge1.w, x.w)} }



    abs_int,
    abs_uint,
    abs_half,
    abs_float,
    abs_double,
    abs_half2,
    abs_half3,
    abs_half4,
    abs_float2,
    abs_float3,
    abs_float4,
    abs_double2,
    abs_double3,
    abs_double4,
    abs_int2,
    abs_int3,
    abs_int4,
    abs_uint2,
    abs_uint3,
    abs_uint4,
}
 abs_int  :: proc "c" (x: int)  -> int  { return builtin.abs(x) }
 abs_uint  :: proc "c" (x: uint)  -> uint  { return x }
 abs_half  :: proc "c" (x: half)  -> half  { return builtin.abs(x) }
 abs_float  :: proc "c" (x: float)  -> float  { return builtin.abs(x) }
 abs_double  :: proc "c" (x: double)  -> double  { return builtin.abs(x) }
 abs_half2 :: proc "c" (x: half2) -> half2 { return {abs(x.x), abs(x.y)} }
 abs_half3 :: proc "c" (x: half3) -> half3 { return {abs(x.x), abs(x.y), abs(x.z)} }
 abs_half4 :: proc "c" (x: half4) -> half4 { return {abs(x.x), abs(x.y), abs(x.z), abs(x.w)} }
 abs_float2 :: proc "c" (x: float2) -> float2 { return {abs(x.x), abs(x.y)} }
 abs_float3 :: proc "c" (x: float3) -> float3 { return {abs(x.x), abs(x.y), abs(x.z)} }
 abs_float4 :: proc "c" (x: float4) -> float4 { return {abs(x.x), abs(x.y), abs(x.z), abs(x.w)} }
 abs_double2 :: proc "c" (x: double2) -> double2 { return {abs(x.x), abs(x.y)} }
 abs_double3 :: proc "c" (x: double3) -> double3 { return {abs(x.x), abs(x.y), abs(x.z)} }
 abs_double4 :: proc "c" (x: double4) -> double4 { return {abs(x.x), abs(x.y), abs(x.z), abs(x.w)} }
 abs_int2 :: proc "c" (x: int2) -> int2 { return {abs(x.x), abs(x.y)} }
 abs_int3 :: proc "c" (x: int3) -> int3 { return {abs(x.x), abs(x.y), abs(x.z)} }
 abs_int4 :: proc "c" (x: int4) -> int4 { return {abs(x.x), abs(x.y), abs(x.z), abs(x.w)} }
 abs_uint2 :: proc "c" (x: uint2) -> uint2 { return x }
 abs_uint3 :: proc "c" (x: uint3) -> uint3 { return x }
 abs_uint4 :: proc "c" (x: uint4) -> uint4 { return x }


    dot_int,
    dot_uint,
    dot_half,
    dot_float,
    dot_double,
    dot_half2,
    dot_half3,
    dot_half4,
    dot_float2,
    dot_float3,
    dot_float4,
    dot_double2,
    dot_double3,
    dot_double4,
    dot_int2,
    dot_int3,
    dot_int4,
    dot_uint2,
    dot_uint3,
    dot_uint4,
}
 dot_int  :: proc "c" (a, b: int)  -> int { return a*b }
 dot_uint  :: proc "c" (a, b: uint)  -> uint { return a*b }
 dot_half  :: proc "c" (a, b: half)  -> half { return a*b }
 dot_float  :: proc "c" (a, b: float)  -> float { return a*b }
 dot_double  :: proc "c" (a, b: double)  -> double { return a*b }
 dot_half2 :: proc "c" (a, b: half2) -> half { return a.x*b.x + a.y*b.y }
 dot_half3 :: proc "c" (a, b: half3) -> half { return a.x*b.x + a.y*b.y + a.z*b.z }
 dot_half4 :: proc "c" (a, b: half4) -> half { return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w }
 dot_float2 :: proc "c" (a, b: float2) -> float { return a.x*b.x + a.y*b.y }
 dot_float3 :: proc "c" (a, b: float3) -> float { return a.x*b.x + a.y*b.y + a.z*b.z }
 dot_float4 :: proc "c" (a, b: float4) -> float { return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w }
 dot_double2 :: proc "c" (a, b: double2) -> double { return a.x*b.x + a.y*b.y }
 dot_double3 :: proc "c" (a, b: double3) -> double { return a.x*b.x + a.y*b.y + a.z*b.z }
 dot_double4 :: proc "c" (a, b: double4) -> double { return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w }
 dot_int2 :: proc "c" (a, b: int2) -> int { return a.x*b.x + a.y*b.y }
 dot_int3 :: proc "c" (a, b: int3) -> int { return a.x*b.x + a.y*b.y + a.z*b.z }
 dot_int4 :: proc "c" (a, b: int4) -> int { return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w }
 dot_uint2 :: proc "c" (a, b: uint2) -> uint { return a.x*b.x + a.y*b.y }
 dot_uint3 :: proc "c" (a, b: uint3) -> uint { return a.x*b.x + a.y*b.y + a.z*b.z }
 dot_uint4 :: proc "c" (a, b: uint4) -> uint { return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w }


    length_half,
    length_float,
    length_double,
    length_half2,
    length_half3,
    length_half4,
    length_float2,
    length_float3,
    length_float4,
    length_double2,
    length_double3,
    length_double4,
}
 length_half  :: proc "c" (x: half)  -> half { return builtin.abs(x) }
 length_float  :: proc "c" (x: float)  -> float { return builtin.abs(x) }
 length_double  :: proc "c" (x: double)  -> double { return builtin.abs(x) }
 length_half2 :: proc "c" (x: half2) -> half { return sqrt(x.x*x.x + x.y*x.y) }
 length_half3 :: proc "c" (x: half3) -> half { return sqrt(x.x*x.x + x.y*x.y + x.z*x.z) }
 length_half4 :: proc "c" (x: half4) -> half { return sqrt(x.x*x.x + x.y*x.y + x.z*x.z + x.w*x.w) }
 length_float2 :: proc "c" (x: float2) -> float { return sqrt(x.x*x.x + x.y*x.y) }
 length_float3 :: proc "c" (x: float3) -> float { return sqrt(x.x*x.x + x.y*x.y + x.z*x.z) }
 length_float4 :: proc "c" (x: float4) -> float { return sqrt(x.x*x.x + x.y*x.y + x.z*x.z + x.w*x.w) }
 length_double2 :: proc "c" (x: double2) -> double { return sqrt(x.x*x.x + x.y*x.y) }
 length_double3 :: proc "c" (x: double3) -> double { return sqrt(x.x*x.x + x.y*x.y + x.z*x.z) }
 length_double4 :: proc "c" (x: double4) -> double { return sqrt(x.x*x.x + x.y*x.y + x.z*x.z + x.w*x.w) }



    distance_half,
    distance_float,
    distance_double,
    distance_half2,
    distance_half3,
    distance_half4,
    distance_float2,
    distance_float3,
    distance_float4,
    distance_double2,
    distance_double3,
    distance_double4,
}
 distance_half  :: proc "c" (x, y: half)  -> half { return length(y-x) }
 distance_float  :: proc "c" (x, y: float)  -> float { return length(y-x) }
 distance_double  :: proc "c" (x, y: double)  -> double { return length(y-x) }
 distance_half2 :: proc "c" (x, y: half2) -> half { return length(y-x) }
 distance_half3 :: proc "c" (x, y: half3) -> half { return length(y-x) }
 distance_half4 :: proc "c" (x, y: half4) -> half { return length(y-x) }
 distance_float2 :: proc "c" (x, y: float2) -> float { return length(y-x) }
 distance_float3 :: proc "c" (x, y: float3) -> float { return length(y-x) }
 distance_float4 :: proc "c" (x, y: float4) -> float { return length(y-x) }
 distance_double2 :: proc "c" (x, y: double2) -> double { return length(y-x) }
 distance_double3 :: proc "c" (x, y: double3) -> double { return length(y-x) }
 distance_double4 :: proc "c" (x, y: double4) -> double { return length(y-x) }



    cross_half3,
    cross_float3,
    cross_double3,
    cross_int3,
}

 cross_half3 :: proc "c" (a, b: half3) -> (c: half3) {
    c.x = a.y*b.z - b.y*a.z
    c.y = a.z*b.x - b.z*a.x
    c.z = a.x*b.y - b.x*a.y
    return
}
 cross_float3 :: proc "c" (a, b: float3) -> (c: float3) {
    c.x = a.y*b.z - b.y*a.z
    c.y = a.z*b.x - b.z*a.x
    c.z = a.x*b.y - b.x*a.y
    return
}
 cross_double3 :: proc "c" (a, b: double3) -> (c: double3) {
    c.x = a.y*b.z - b.y*a.z
    c.y = a.z*b.x - b.z*a.x
    c.z = a.x*b.y - b.x*a.y
    return
}
 cross_int3 :: proc "c" (a, b: int3) -> (c: int3) {
    c.x = a.y*b.z - b.y*a.z
    c.y = a.z*b.x - b.z*a.x
    c.z = a.x*b.y - b.x*a.y
    return
}


    normalize_half,
    normalize_float,
    normalize_double,
    normalize_half2,
    normalize_half3,
    normalize_half4,
    normalize_float2,
    normalize_float3,
    normalize_float4,
    normalize_double2,
    normalize_double3,
    normalize_double4,
}
 normalize_half  :: proc "c" (x: half)  -> half  { return 1.0 }
 normalize_float  :: proc "c" (x: float)  -> float  { return 1.0 }
 normalize_double  :: proc "c" (x: double)  -> double  { return 1.0 }
 normalize_half2 :: proc "c" (x: half2) -> half2 { return x / length(x) }
 normalize_half3 :: proc "c" (x: half3) -> half3 { return x / length(x) }
 normalize_half4 :: proc "c" (x: half4) -> half4 { return x / length(x) }
 normalize_float2 :: proc "c" (x: float2) -> float2 { return x / length(x) }
 normalize_float3 :: proc "c" (x: float3) -> float3 { return x / length(x) }
 normalize_float4 :: proc "c" (x: float4) -> float4 { return x / length(x) }
 normalize_double2 :: proc "c" (x: double2) -> double2 { return x / length(x) }
 normalize_double3 :: proc "c" (x: double3) -> double3 { return x / length(x) }
 normalize_double4 :: proc "c" (x: double4) -> double4 { return x / length(x) }



    faceforward_half,
    faceforward_float,
    faceforward_double,
    faceforward_half2,
    faceforward_half3,
    faceforward_half4,
    faceforward_float2,
    faceforward_float3,
    faceforward_float4,
    faceforward_double2,
    faceforward_double3,
    faceforward_double4,
}
 faceforward_half  :: proc "c" (N, I, Nref: half)  -> half  { return N if dot(I, Nref) < 0 else -N }
 faceforward_float  :: proc "c" (N, I, Nref: float)  -> float  { return N if dot(I, Nref) < 0 else -N }
 faceforward_double  :: proc "c" (N, I, Nref: double)  -> double  { return N if dot(I, Nref) < 0 else -N }
 faceforward_half2 :: proc "c" (N, I, Nref: half2) -> half2 { return N if dot(I, Nref) < 0 else -N }
 faceforward_half3 :: proc "c" (N, I, Nref: half3) -> half3 { return N if dot(I, Nref) < 0 else -N }
 faceforward_half4 :: proc "c" (N, I, Nref: half4) -> half4 { return N if dot(I, Nref) < 0 else -N }
 faceforward_float2 :: proc "c" (N, I, Nref: float2) -> float2 { return N if dot(I, Nref) < 0 else -N }
 faceforward_float3 :: proc "c" (N, I, Nref: float3) -> float3 { return N if dot(I, Nref) < 0 else -N }
 faceforward_float4 :: proc "c" (N, I, Nref: float4) -> float4 { return N if dot(I, Nref) < 0 else -N }
 faceforward_double2 :: proc "c" (N, I, Nref: double2) -> double2 { return N if dot(I, Nref) < 0 else -N }
 faceforward_double3 :: proc "c" (N, I, Nref: double3) -> double3 { return N if dot(I, Nref) < 0 else -N }
 faceforward_double4 :: proc "c" (N, I, Nref: double4) -> double4 { return N if dot(I, Nref) < 0 else -N }



    reflect_half,
    reflect_float,
    reflect_double,
    reflect_half2,
    reflect_half3,
    reflect_half4,
    reflect_float2,
    reflect_float3,
    reflect_float4,
    reflect_double2,
    reflect_double3,
    reflect_double4,
}
 reflect_half  :: proc "c" (I, N: half)  -> half  { return I - 2*N*dot(N, I) }
 reflect_float  :: proc "c" (I, N: float)  -> float  { return I - 2*N*dot(N, I) }
 reflect_double  :: proc "c" (I, N: double)  -> double  { return I - 2*N*dot(N, I) }
 reflect_half2 :: proc "c" (I, N: half2) -> half2 { return I - 2*N*dot(N, I) }
 reflect_half3 :: proc "c" (I, N: half3) -> half3 { return I - 2*N*dot(N, I) }
 reflect_half4 :: proc "c" (I, N: half4) -> half4 { return I - 2*N*dot(N, I) }
 reflect_float2 :: proc "c" (I, N: float2) -> float2 { return I - 2*N*dot(N, I) }
 reflect_float3 :: proc "c" (I, N: float3) -> float3 { return I - 2*N*dot(N, I) }
 reflect_float4 :: proc "c" (I, N: float4) -> float4 { return I - 2*N*dot(N, I) }
 reflect_double2 :: proc "c" (I, N: double2) -> double2 { return I - 2*N*dot(N, I) }
 reflect_double3 :: proc "c" (I, N: double3) -> double3 { return I - 2*N*dot(N, I) }
 reflect_double4 :: proc "c" (I, N: double4) -> double4 { return I - 2*N*dot(N, I) }





    refract_half,
    refract_float,
    refract_double,
    refract_half2,
    refract_half3,
    refract_half4,
    refract_float2,
    refract_float3,
    refract_float4,
    refract_double2,
    refract_double3,
    refract_double4,
}

refract_half  :: proc "c" (i, n, eta: half) -> half {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * half(int(cost2 > 0))
}

refract_float  :: proc "c" (i, n, eta: float) -> float {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * float(int(cost2 > 0))
}

refract_double  :: proc "c" (i, n, eta: double) -> double {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * double(int(cost2 > 0))
}

refract_half2  :: proc "c" (i, n, eta: half2) -> half2 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * half2{half(int(cost2.x > 0)), half(int(cost2.y > 0))}
}

refract_half3  :: proc "c" (i, n, eta: half3) -> half3 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * half3{half(int(cost2.x > 0)), half(int(cost2.y > 0)), half(int(cost2.z > 0))}
}

refract_half4  :: proc "c" (i, n, eta: half4) -> half4 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * half4{half(int(cost2.x > 0)), half(int(cost2.y > 0)), half(int(cost2.z > 0)), half(int(cost2.w > 0))}
}

refract_float2  :: proc "c" (i, n, eta: float2) -> float2 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * float2{float(int(cost2.x > 0)), float(int(cost2.y > 0))}
}

refract_float3  :: proc "c" (i, n, eta: float3) -> float3 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * float3{float(int(cost2.x > 0)), float(int(cost2.y > 0)), float(int(cost2.z > 0))}
}

refract_float4  :: proc "c" (i, n, eta: float4) -> float4 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * float4{float(int(cost2.x > 0)), float(int(cost2.y > 0)), float(int(cost2.z > 0)), float(int(cost2.w > 0))}
}

refract_double2  :: proc "c" (i, n, eta: double2) -> double2 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * double2{double(int(cost2.x > 0)), double(int(cost2.y > 0))}
}

refract_double3  :: proc "c" (i, n, eta: double3) -> double3 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * double3{double(int(cost2.x > 0)), double(int(cost2.y > 0)), double(int(cost2.z > 0))}
}

refract_double4  :: proc "c" (i, n, eta: double4) -> double4 {
    cosi := dot(-i, n)
    cost2 := 1 - eta*eta*(1 - cosi*cosi)
    t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
    return t * double4{double(int(cost2.x > 0)), double(int(cost2.y > 0)), double(int(cost2.z > 0)), double(int(cost2.w > 0))}
}


    scalarTripleProduct_half3,
    scalarTripleProduct_float3,
    scalarTripleProduct_double3,
    scalarTripleProduct_int3,
}
 scalarTripleProduct_half3 :: proc "c" (a, b, c: half3) -> half  { return dot(a, cross(b, c)) }
 scalarTripleProduct_float3 :: proc "c" (a, b, c: float3) -> float  { return dot(a, cross(b, c)) }
 scalarTripleProduct_double3 :: proc "c" (a, b, c: double3) -> double  { return dot(a, cross(b, c)) }
 scalarTripleProduct_int3 :: proc "c" (a, b, c: int3) -> int  { return dot(a, cross(b, c)) }


    vectorTripleProduct_half3,
    vectorTripleProduct_float3,
    vectorTripleProduct_double3,
    vectorTripleProduct_int3,   
}
 vectorTripleProduct_half3 :: proc "c" (a, b, c: half3) -> half3 { return cross(a, cross(b, c)) }
 vectorTripleProduct_float3 :: proc "c" (a, b, c: float3) -> float3 { return cross(a, cross(b, c)) }
 vectorTripleProduct_double3 :: proc "c" (a, b, c: double3) -> double3 { return cross(a, cross(b, c)) }
 vectorTripleProduct_int3 :: proc "c" (a, b, c: int3) -> int3 { return cross(a, cross(b, c)) }


// Vector Relational Procedures


    lessThan_half,
    lessThan_float,
    lessThan_double,
    lessThan_int,
    lessThan_uint,
    lessThan_half2,
    lessThan_float2,
    lessThan_double2,
    lessThan_int2,
    lessThan_uint2,
    lessThan_half3,
    lessThan_float3,
    lessThan_double3,
    lessThan_int3,
    lessThan_uint3,
    lessThan_half4,
    lessThan_float4,
    lessThan_double4,
    lessThan_int4,
    lessThan_uint4,
}
 lessThan_half   :: proc "c" (a, b: half) -> bool { return a < b }
 lessThan_float   :: proc "c" (a, b: float) -> bool { return a < b }
 lessThan_double   :: proc "c" (a, b: double) -> bool { return a < b }
 lessThan_int   :: proc "c" (a, b: int) -> bool { return a < b }
 lessThan_uint   :: proc "c" (a, b: uint) -> bool { return a < b }
 lessThan_half2  :: proc "c" (a, b: half2) -> bool2 { return {a.x < b.x, a.y < b.y} }
 lessThan_float2  :: proc "c" (a, b: float2) -> bool2 { return {a.x < b.x, a.y < b.y} }
 lessThan_double2 :: proc "c" (a, b: double2) -> bool2 { return {a.x < b.x, a.y < b.y} }
 lessThan_int2 :: proc "c" (a, b: int2) -> bool2 { return {a.x < b.x, a.y < b.y} }
 lessThan_uint2 :: proc "c" (a, b: uint2) -> bool2 { return {a.x < b.x, a.y < b.y} }
 lessThan_half3  :: proc "c" (a, b: half3) -> bool3 { return {a.x < b.x, a.y < b.y, a.z < b.z} }
 lessThan_float3  :: proc "c" (a, b: float3) -> bool3 { return {a.x < b.x, a.y < b.y, a.z < b.z} }
 lessThan_double3  :: proc "c" (a, b: double3) -> bool3 { return {a.x < b.x, a.y < b.y, a.z < b.z} }
 lessThan_int3 :: proc "c" (a, b: int3) -> bool3 { return {a.x < b.x, a.y < b.y, a.z < b.z} }
 lessThan_uint3 :: proc "c" (a, b: uint3) -> bool3 { return {a.x < b.x, a.y < b.y, a.z < b.z} }
 lessThan_half4  :: proc "c" (a, b: half4) -> bool4 { return {a.x < b.x, a.y < b.y, a.z < b.z, a.w < b.w} }
 lessThan_float4  :: proc "c" (a, b: float4) -> bool4 { return {a.x < b.x, a.y < b.y, a.z < b.z, a.w < b.w} }
 lessThan_double4  :: proc "c" (a, b: double4) -> bool4 { return {a.x < b.x, a.y < b.y, a.z < b.z, a.w < b.w} }
 lessThan_int4 :: proc "c" (a, b: int4) -> bool4 { return {a.x < b.x, a.y < b.y, a.z < b.z, a.w < b.w} }
 lessThan_uint4 :: proc "c" (a, b: uint4) -> bool4 { return {a.x < b.x, a.y < b.y, a.z < b.z, a.w < b.w} }



    lessThanEqual_half,
    lessThanEqual_float,
    lessThanEqual_double,
    lessThanEqual_int,
    lessThanEqual_uint,
    lessThanEqual_half2,
    lessThanEqual_float2,
    lessThanEqual_double2,
    lessThanEqual_int2,
    lessThanEqual_uint2,
    lessThanEqual_half3,
    lessThanEqual_float3,
    lessThanEqual_double3,
    lessThanEqual_int3,
    lessThanEqual_uint3,
    lessThanEqual_half4,
    lessThanEqual_float4,
    lessThanEqual_double4,
    lessThanEqual_int4,
    lessThanEqual_uint4,
}
 lessThanEqual_half   :: proc "c" (a, b: half) -> bool { return a <= b }
 lessThanEqual_float   :: proc "c" (a, b: float) -> bool { return a <= b }
 lessThanEqual_double   :: proc "c" (a, b: double) -> bool { return a <= b }
 lessThanEqual_int   :: proc "c" (a, b: int) -> bool { return a <= b }
 lessThanEqual_uint   :: proc "c" (a, b: uint) -> bool { return a <= b }
 lessThanEqual_half2  :: proc "c" (a, b: half2) -> bool2 { return {a.x <= b.x, a.y <= b.y} }
 lessThanEqual_float2  :: proc "c" (a, b: float2) -> bool2 { return {a.x <= b.x, a.y <= b.y} }
 lessThanEqual_double2  :: proc "c" (a, b: double2) -> bool2 { return {a.x <= b.x, a.y <= b.y} }
 lessThanEqual_int2 :: proc "c" (a, b: int2) -> bool2 { return {a.x <= b.x, a.y <= b.y} }
 lessThanEqual_uint2 :: proc "c" (a, b: uint2) -> bool2 { return {a.x <= b.x, a.y <= b.y} }
 lessThanEqual_half3  :: proc "c" (a, b: half3) -> bool3 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z} }
 lessThanEqual_float3  :: proc "c" (a, b: float3) -> bool3 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z} }
 lessThanEqual_double3  :: proc "c" (a, b: double3) -> bool3 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z} }
 lessThanEqual_int3 :: proc "c" (a, b: int3) -> bool3 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z} }
 lessThanEqual_uint3 :: proc "c" (a, b: uint3) -> bool3 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z} }
 lessThanEqual_half4  :: proc "c" (a, b: half4) -> bool4 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z, a.w <= b.w} }
 lessThanEqual_float4  :: proc "c" (a, b: float4) -> bool4 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z, a.w <= b.w} }
 lessThanEqual_double4  :: proc "c" (a, b: double4) -> bool4 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z, a.w <= b.w} }
 lessThanEqual_int4 :: proc "c" (a, b: int4) -> bool4 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z, a.w <= b.w} }
 lessThanEqual_uint4 :: proc "c" (a, b: uint4) -> bool4 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z, a.w <= b.w} }



    greaterThan_half,
    greaterThan_float,
    greaterThan_double,
    greaterThan_int,
    greaterThan_uint,
    greaterThan_half2,
    greaterThan_float2,
    greaterThan_double2,
    greaterThan_int2,
    greaterThan_uint2,
    greaterThan_half3,
    greaterThan_float3,
    greaterThan_double3,
    greaterThan_int3,
    greaterThan_uint3,
    greaterThan_half4,
    greaterThan_float4,
    greaterThan_double4,
    greaterThan_int4,
    greaterThan_uint4,
}
 greaterThan_half   :: proc "c" (a, b: half) -> bool { return a > b }
 greaterThan_float   :: proc "c" (a, b: float) -> bool { return a > b }
 greaterThan_double   :: proc "c" (a, b: double) -> bool { return a > b }
 greaterThan_int   :: proc "c" (a, b: int) -> bool { return a > b }
 greaterThan_uint   :: proc "c" (a, b: uint) -> bool { return a > b }
 greaterThan_half2  :: proc "c" (a, b: half2) -> bool2 { return {a.x > b.x, a.y > b.y} }
 greaterThan_float2  :: proc "c" (a, b: float2) -> bool2 { return {a.x > b.x, a.y > b.y} }
 greaterThan_double2  :: proc "c" (a, b: double2) -> bool2 { return {a.x > b.x, a.y > b.y} }
 greaterThan_int2 :: proc "c" (a, b: int2) -> bool2 { return {a.x > b.x, a.y > b.y} }
 greaterThan_uint2 :: proc "c" (a, b: uint2) -> bool2 { return {a.x > b.x, a.y > b.y} }
 greaterThan_half3  :: proc "c" (a, b: half3) -> bool3 { return {a.x > b.x, a.y > b.y, a.z > b.z} }
 greaterThan_float3  :: proc "c" (a, b: float3) -> bool3 { return {a.x > b.x, a.y > b.y, a.z > b.z} }
 greaterThan_double3  :: proc "c" (a, b: double3) -> bool3 { return {a.x > b.x, a.y > b.y, a.z > b.z} }
 greaterThan_int3 :: proc "c" (a, b: int3) -> bool3 { return {a.x > b.x, a.y > b.y, a.z > b.z} }
 greaterThan_uint3 :: proc "c" (a, b: uint3) -> bool3 { return {a.x > b.x, a.y > b.y, a.z > b.z} }
 greaterThan_half4  :: proc "c" (a, b: half4) -> bool4 { return {a.x > b.x, a.y > b.y, a.z > b.z, a.w > b.w} }
 greaterThan_float4  :: proc "c" (a, b: float4) -> bool4 { return {a.x > b.x, a.y > b.y, a.z > b.z, a.w > b.w} }
 greaterThan_double4  :: proc "c" (a, b: double4) -> bool4 { return {a.x > b.x, a.y > b.y, a.z > b.z, a.w > b.w} }
 greaterThan_int4 :: proc "c" (a, b: int4) -> bool4 { return {a.x > b.x, a.y > b.y, a.z > b.z, a.w > b.w} }
 greaterThan_uint4 :: proc "c" (a, b: uint4) -> bool4 { return {a.x > b.x, a.y > b.y, a.z > b.z, a.w > b.w} }



    greaterThanEqual_half,
    greaterThanEqual_float,
    greaterThanEqual_double,
    greaterThanEqual_int,
    greaterThanEqual_uint,
    greaterThanEqual_half2,
    greaterThanEqual_float2,
    greaterThanEqual_double2,
    greaterThanEqual_int2,
    greaterThanEqual_uint2,
    greaterThanEqual_half3,
    greaterThanEqual_float3,
    greaterThanEqual_double3,
    greaterThanEqual_int3,
    greaterThanEqual_uint3,
    greaterThanEqual_half4,
    greaterThanEqual_float4,
    greaterThanEqual_double4,
    greaterThanEqual_int4,
    greaterThanEqual_uint4,
}
 greaterThanEqual_half   :: proc "c" (a, b: half) -> bool { return a >= b }
 greaterThanEqual_float   :: proc "c" (a, b: float) -> bool { return a >= b }
 greaterThanEqual_double   :: proc "c" (a, b: double) -> bool { return a >= b }
 greaterThanEqual_int   :: proc "c" (a, b: int) -> bool { return a >= b }
 greaterThanEqual_uint   :: proc "c" (a, b: uint) -> bool { return a >= b }
 greaterThanEqual_half2  :: proc "c" (a, b: half2) -> bool2 { return {a.x >= b.x, a.y >= b.y} }
 greaterThanEqual_float2  :: proc "c" (a, b: float2) -> bool2 { return {a.x >= b.x, a.y >= b.y} }
 greaterThanEqual_double2  :: proc "c" (a, b: double2) -> bool2 { return {a.x >= b.x, a.y >= b.y} }
 greaterThanEqual_int2 :: proc "c" (a, b: int2) -> bool2 { return {a.x >= b.x, a.y >= b.y} }
 greaterThanEqual_uint2 :: proc "c" (a, b: uint2) -> bool2 { return {a.x >= b.x, a.y >= b.y} }
 greaterThanEqual_half3  :: proc "c" (a, b: half3) -> bool3 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z} }
 greaterThanEqual_float3  :: proc "c" (a, b: float3) -> bool3 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z} }
 greaterThanEqual_double3  :: proc "c" (a, b: double3) -> bool3 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z} }
 greaterThanEqual_int3 :: proc "c" (a, b: int3) -> bool3 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z} }
 greaterThanEqual_uint3 :: proc "c" (a, b: uint3) -> bool3 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z} }
 greaterThanEqual_half4  :: proc "c" (a, b: half4) -> bool4 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z, a.w >= b.w} }
 greaterThanEqual_float4  :: proc "c" (a, b: float4) -> bool4 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z, a.w >= b.w} }
 greaterThanEqual_double4  :: proc "c" (a, b: double4) -> bool4 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z, a.w >= b.w} }
 greaterThanEqual_int4 :: proc "c" (a, b: int4) -> bool4 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z, a.w >= b.w} }
 greaterThanEqual_uint4 :: proc "c" (a, b: uint4) -> bool4 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z, a.w >= b.w} }



    equal_half,
    equal_float,
    equal_double,
    equal_int,
    equal_uint,
    equal_half2,
    equal_float2,
    equal_double2,
    equal_int2,
    equal_uint2,
    equal_half3,
    equal_float3,
    equal_double3,
    equal_int3,
    equal_uint3,
    equal_half4,
    equal_float4,
    equal_double4,
    equal_int4,
    equal_uint4,
}
 equal_half   :: proc "c" (a, b: half) -> bool { return a == b }
 equal_float   :: proc "c" (a, b: float) -> bool { return a == b }
 equal_double   :: proc "c" (a, b: double) -> bool { return a == b }
 equal_int   :: proc "c" (a, b: int) -> bool { return a == b }
 equal_uint   :: proc "c" (a, b: uint) -> bool { return a == b }
 equal_half2  :: proc "c" (a, b: half2) -> bool2 { return {a.x == b.x, a.y == b.y} }
 equal_float2  :: proc "c" (a, b: float2) -> bool2 { return {a.x == b.x, a.y == b.y} }
 equal_double2  :: proc "c" (a, b: double2) -> bool2 { return {a.x == b.x, a.y == b.y} }
 equal_int2 :: proc "c" (a, b: int2) -> bool2 { return {a.x == b.x, a.y == b.y} }
 equal_uint2 :: proc "c" (a, b: uint2) -> bool2 { return {a.x == b.x, a.y == b.y} }
 equal_half3  :: proc "c" (a, b: half3) -> bool3 { return {a.x == b.x, a.y == b.y, a.z == b.z} }
 equal_float3  :: proc "c" (a, b: float3) -> bool3 { return {a.x == b.x, a.y == b.y, a.z == b.z} }
 equal_double3  :: proc "c" (a, b: double3) -> bool3 { return {a.x == b.x, a.y == b.y, a.z == b.z} }
 equal_int3 :: proc "c" (a, b: int3) -> bool3 { return {a.x == b.x, a.y == b.y, a.z == b.z} }
 equal_uint3 :: proc "c" (a, b: uint3) -> bool3 { return {a.x == b.x, a.y == b.y, a.z == b.z} }
 equal_half4  :: proc "c" (a, b: half4) -> bool4 { return {a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w} }
 equal_float4  :: proc "c" (a, b: float4) -> bool4 { return {a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w} }
 equal_double4  :: proc "c" (a, b: double4) -> bool4 { return {a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w} }
 equal_int4 :: proc "c" (a, b: int4) -> bool4 { return {a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w} }
 equal_uint4 :: proc "c" (a, b: uint4) -> bool4 { return {a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w} }


    notEqual_half,
    notEqual_float,
    notEqual_double,
    notEqual_int,
    notEqual_uint,
    notEqual_half2,
    notEqual_float2,
    notEqual_double2,
    notEqual_int2,
    notEqual_uint2,
    notEqual_half3,
    notEqual_float3,
    notEqual_double3,
    notEqual_int3,
    notEqual_uint3,
    notEqual_half4,
    notEqual_float4,
    notEqual_double4,
    notEqual_int4,
    notEqual_uint4,
}
 notEqual_half   :: proc "c" (a, b: half) -> bool { return a != b }
 notEqual_float   :: proc "c" (a, b: float) -> bool { return a != b }
 notEqual_double   :: proc "c" (a, b: double) -> bool { return a != b }
 notEqual_int   :: proc "c" (a, b: int) -> bool { return a != b }
 notEqual_uint   :: proc "c" (a, b: uint) -> bool { return a != b }
 notEqual_half2  :: proc "c" (a, b: half2) -> bool2 { return {a.x != b.x, a.y != b.y} }
 notEqual_float2  :: proc "c" (a, b: float2) -> bool2 { return {a.x != b.x, a.y != b.y} }
 notEqual_double2  :: proc "c" (a, b: double2) -> bool2 { return {a.x != b.x, a.y != b.y} }
 notEqual_int2 :: proc "c" (a, b: int2) -> bool2 { return {a.x != b.x, a.y != b.y} }
 notEqual_uint2 :: proc "c" (a, b: uint2) -> bool2 { return {a.x != b.x, a.y != b.y} }
 notEqual_half3  :: proc "c" (a, b: half3) -> bool3 { return {a.x != b.x, a.y != b.y, a.z != b.z} }
 notEqual_float3  :: proc "c" (a, b: float3) -> bool3 { return {a.x != b.x, a.y != b.y, a.z != b.z} }
 notEqual_double3  :: proc "c" (a, b: double3) -> bool3 { return {a.x != b.x, a.y != b.y, a.z != b.z} }
 notEqual_int3 :: proc "c" (a, b: int3) -> bool3 { return {a.x != b.x, a.y != b.y, a.z != b.z} }
 notEqual_uint3 :: proc "c" (a, b: uint3) -> bool3 { return {a.x != b.x, a.y != b.y, a.z != b.z} }
 notEqual_half4  :: proc "c" (a, b: half4) -> bool4 { return {a.x != b.x, a.y != b.y, a.z != b.z, a.w != b.w} }
 notEqual_float4  :: proc "c" (a, b: float4) -> bool4 { return {a.x != b.x, a.y != b.y, a.z != b.z, a.w != b.w} }
 notEqual_double4  :: proc "c" (a, b: double4) -> bool4 { return {a.x != b.x, a.y != b.y, a.z != b.z, a.w != b.w} }
 notEqual_int4 :: proc "c" (a, b: int4) -> bool4 { return {a.x != b.x, a.y != b.y, a.z != b.z, a.w != b.w} }
 notEqual_uint4 :: proc "c" (a, b: uint4) -> bool4 { return {a.x != b.x, a.y != b.y, a.z != b.z, a.w != b.w} }


any_bool  :: proc "c" (v: bool) -> bool  { return v }
any_bool2 :: proc "c" (v: bool2) -> bool { return v.x || v.y }
any_bool3 :: proc "c" (v: bool3) -> bool { return v.x || v.y || v.z }
any_bool4 :: proc "c" (v: bool4) -> bool { return v.x || v.y || v.z || v.w }


all_bool  :: proc "c" (v: bool) -> bool  { return v }
all_bool2 :: proc "c" (v: bool2) -> bool { return v.x && v.y }
all_bool3 :: proc "c" (v: bool3) -> bool { return v.x && v.y && v.z }
all_bool4 :: proc "c" (v: bool4) -> bool { return v.x && v.y && v.z && v.w }


not_bool  :: proc "c" (v: bool) -> bool { return !v }
not_bool2 :: proc "c" (v: bool2) -> bool2 { return {!v.x, !v.y} }
not_bool3 :: proc "c" (v: bool3) -> bool3 { return {!v.x, !v.y, !v.z} }
not_bool4 :: proc "c" (v: bool4) -> bool4 { return {!v.x, !v.y, !v.z, !v.w} }




inverse_half1x1  :: proc "c" (m: half1x1)  -> half1x1  { return inverse_matrix1x1(m) }
inverse_half2x2  :: proc "c" (m: half2x2)  -> half2x2  { return inverse_matrix2x2(m) }
inverse_half3x3  :: proc "c" (m: half3x3)  -> half3x3  { return inverse_matrix3x3(m) }
inverse_half4x4  :: proc "c" (m: half4x4)  -> half4x4  { return inverse_matrix4x4(m) }
inverse_float1x1  :: proc "c" (m: float1x1)  -> float1x1  { return inverse_matrix1x1(m) }
inverse_float2x2  :: proc "c" (m: float2x2)  -> float2x2  { return inverse_matrix2x2(m) }
inverse_float3x3  :: proc "c" (m: float3x3)  -> float3x3  { return inverse_matrix3x3(m) }
inverse_float4x4  :: proc "c" (m: float4x4)  -> float4x4  { return inverse_matrix4x4(m) }
inverse_double1x1 :: proc "c" (m: double1x1) -> double1x1 { return inverse_matrix1x1(m) }
inverse_double2x2 :: proc "c" (m: double2x2) -> double2x2 { return inverse_matrix2x2(m) }
inverse_double3x3 :: proc "c" (m: double3x3) -> double3x3 { return inverse_matrix3x3(m) }
inverse_double4x4 :: proc "c" (m: double4x4) -> double4x4 { return inverse_matrix4x4(m) }


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


ashalf_half     :: proc "c" (v: half)       -> half    { return half(v) }
ashalf_float     :: proc "c" (v: float)     -> half    { return half(v) }
ashalf_double    :: proc "c" (v: double)    -> half    { return half(v) }
ashalf_int       :: proc "c" (v: int)       -> half    { return half(v) }
ashalf_uint      :: proc "c" (v: uint)      -> half    { return half(v) }
ashalf_half1x1  :: proc "c" (v: half1x1)   -> half1x1 { return half1x1(v) }
ashalf_half2x2  :: proc "c" (v: half2x2)   -> half2x2 { return half2x2(v) }
ashalf_half3x3  :: proc "c" (v: half3x3)   -> half3x3 { return half3x3(v) }
ashalf_half4x4  :: proc "c" (v: half4x4)   -> half4x4 { return half4x4(v) }
ashalf_half1x2  :: proc "c" (v: half1x2)   -> half1x2 { return half1x2(v) }
ashalf_half1x3  :: proc "c" (v: half1x3)   -> half1x3 { return half1x3(v) }
ashalf_half1x4  :: proc "c" (v: half1x4)   -> half1x4 { return half1x4(v) }
ashalf_half2x1  :: proc "c" (v: half2x1)   -> half2x1 { return half2x1(v) }
ashalf_half2x3  :: proc "c" (v: half2x3)   -> half2x3 { return half2x3(v) }
ashalf_half2x4  :: proc "c" (v: half2x4)   -> half2x4 { return half2x4(v) }
ashalf_half3x1  :: proc "c" (v: half3x1)   -> half3x1 { return half3x1(v) }
ashalf_half3x2  :: proc "c" (v: half3x2)   -> half3x2 { return half3x2(v) }
ashalf_half3x4  :: proc "c" (v: half3x4)   -> half3x4 { return half3x4(v) }
ashalf_half4x1  :: proc "c" (v: half4x1)   -> half4x1 { return half4x1(v) }
ashalf_half4x2  :: proc "c" (v: half4x2)   -> half4x2 { return half4x2(v) }
ashalf_half4x3  :: proc "c" (v: half4x3)   -> half4x3 { return half4x3(v) }
ashalf_half2    :: proc "c" (v: half2)     -> half2   { return half2(v) }
ashalf_half3    :: proc "c" (v: half3)     -> half3   { return half3(v) }
ashalf_half4    :: proc "c" (v: half4)     -> half4   { return half4(v) }
ashalf_float1x1  :: proc "c" (v: float1x1)   -> half1x1 { return half1x1(v) }
ashalf_float2x2  :: proc "c" (v: float2x2)   -> half2x2 { return half2x2(v) }
ashalf_float3x3  :: proc "c" (v: float3x3)   -> half3x3 { return half3x3(v) }
ashalf_float4x4  :: proc "c" (v: float4x4)   -> half4x4 { return half4x4(v) }
ashalf_float1x2  :: proc "c" (v: float1x2)   -> half1x2 { return half1x2(v) }
ashalf_float1x3  :: proc "c" (v: float1x3)   -> half1x3 { return half1x3(v) }
ashalf_float1x4  :: proc "c" (v: float1x4)   -> half1x4 { return half1x4(v) }
ashalf_float2x1  :: proc "c" (v: float2x1)   -> half2x1 { return half2x1(v) }
ashalf_float2x3  :: proc "c" (v: float2x3)   -> half2x3 { return half2x3(v) }
ashalf_float2x4  :: proc "c" (v: float2x4)   -> half2x4 { return half2x4(v) }
ashalf_float3x1  :: proc "c" (v: float3x1)   -> half3x1 { return half3x1(v) }
ashalf_float3x2  :: proc "c" (v: float3x2)   -> half3x2 { return half3x2(v) }
ashalf_float3x4  :: proc "c" (v: float3x4)   -> half3x4 { return half3x4(v) }
ashalf_float4x1  :: proc "c" (v: float4x1)   -> half4x1 { return half4x1(v) }
ashalf_float4x2  :: proc "c" (v: float4x2)   -> half4x2 { return half4x2(v) }
ashalf_float4x3  :: proc "c" (v: float4x3)   -> half4x3 { return half4x3(v) }
ashalf_float2    :: proc "c" (v: float2)     -> half2   { return half2{half(v.x), half(v.y)} }
ashalf_float3    :: proc "c" (v: float3)     -> half3   { return half3{half(v.x), half(v.y), half(v.z)}  }
ashalf_float4    :: proc "c" (v: float4)     -> half4   { return half4{half(v.x), half(v.y), half(v.z), half(v.w)} }
ashalf_int2      :: proc "c" (v: int2)      -> half2   { return half2{half(v.x), half(v.y)} }
ashalf_int3      :: proc "c" (v: int3)      -> half3   { return half3{half(v.x), half(v.y), half(v.z)} }
ashalf_int4      :: proc "c" (v: int4)      -> half4   { return half4{half(v.x), half(v.y), half(v.z), half(v.w)} }
ashalf_uint2     :: proc "c" (v: uint2)     -> half2   { return half2{half(v.x), half(v.y)} }
ashalf_uint3     :: proc "c" (v: uint3)     -> half3   { return half3{half(v.x), half(v.y), half(v.z)} }
ashalf_uint4     :: proc "c" (v: uint4)     -> half4   { return half4{half(v.x), half(v.y), half(v.z), half(v.w)} }
ashalf_bool2     :: proc "c" (v: bool2)     -> half2   { return half2{half(int(v.x)), half(int(v.y))} }
ashalf_bool3     :: proc "c" (v: bool3)     -> half3   { return half3{half(int(v.x)), half(int(v.y)), half(int(v.z))} }
ashalf_bool4     :: proc "c" (v: bool4)     -> half4   { return half4{half(int(v.x)), half(int(v.y)), half(int(v.z)), half(int(v.w))} }
ashalf_double1x1 :: proc "c" (v: double1x1) -> half1x1 { return half1x1(v) }
ashalf_double2x2 :: proc "c" (v: double2x2) -> half2x2 { return half2x2(v) }
ashalf_double3x3 :: proc "c" (v: double3x3) -> half3x3 { return half3x3(v) }
ashalf_double4x4 :: proc "c" (v: double4x4) -> half4x4 { return half4x4(v) }
ashalf_double1x2 :: proc "c" (v: double1x2) -> half1x2 { return half1x2(v) }
ashalf_double1x3 :: proc "c" (v: double1x3) -> half1x3 { return half1x3(v) }
ashalf_double1x4 :: proc "c" (v: double1x4) -> half1x4 { return half1x4(v) }
ashalf_double2x1 :: proc "c" (v: double2x1) -> half2x1 { return half2x1(v) }
ashalf_double2x3 :: proc "c" (v: double2x3) -> half2x3 { return half2x3(v) }
ashalf_double2x4 :: proc "c" (v: double2x4) -> half2x4 { return half2x4(v) }
ashalf_double3x1 :: proc "c" (v: double3x1) -> half3x1 { return half3x1(v) }
ashalf_double3x2 :: proc "c" (v: double3x2) -> half3x2 { return half3x2(v) }
ashalf_double3x4 :: proc "c" (v: double3x4) -> half3x4 { return half3x4(v) }
ashalf_double4x1 :: proc "c" (v: double4x1) -> half4x1 { return half4x1(v) }
ashalf_double4x2 :: proc "c" (v: double4x2) -> half4x2 { return half4x2(v) }
ashalf_double4x3 :: proc "c" (v: double4x3) -> half4x3 { return half4x3(v) }
ashalf_double2   :: proc "c" (v: double2)   -> half2   { return half2{half(v.x), half(v.y)} }
ashalf_double3   :: proc "c" (v: double3)   -> half3   { return half3{half(v.x), half(v.y), half(v.z)} }
ashalf_double4   :: proc "c" (v: double4)   -> half4   { return half4{half(v.x), half(v.y), half(v.z), half(v.w)} }


asfloat_half     :: proc "c" (v: half)     -> float    { return float(v) }
asfloat_float     :: proc "c" (v: float)     -> float    { return float(v) }
asfloat_double    :: proc "c" (v: double)    -> float    { return float(v) }
asfloat_int       :: proc "c" (v: int)       -> float    { return float(v) }
asfloat_uint      :: proc "c" (v: uint)      -> float    { return float(v) }
asfloat_half1x1  :: proc "c" (v: half1x1)  -> float1x1 { return float1x1(v) }
asfloat_half2x2  :: proc "c" (v: half2x2)  -> float2x2 { return float2x2(v) }
asfloat_half3x3  :: proc "c" (v: half3x3)  -> float3x3 { return float3x3(v) }
asfloat_half4x4  :: proc "c" (v: half4x4)  -> float4x4 { return float4x4(v) }
asfloat_half1x2  :: proc "c" (v: half1x2)  -> float1x2 { return float1x2(v) }
asfloat_half1x3  :: proc "c" (v: half1x3)  -> float1x3 { return float1x3(v) }
asfloat_half1x4  :: proc "c" (v: half1x4)  -> float1x4 { return float1x4(v) }
asfloat_half2x1  :: proc "c" (v: half2x1)  -> float2x1 { return float2x1(v) }
asfloat_half2x3  :: proc "c" (v: half2x3)  -> float2x3 { return float2x3(v) }
asfloat_half2x4  :: proc "c" (v: half2x4)  -> float2x4 { return float2x4(v) }
asfloat_half3x1  :: proc "c" (v: half3x1)  -> float3x1 { return float3x1(v) }
asfloat_half3x2  :: proc "c" (v: half3x2)  -> float3x2 { return float3x2(v) }
asfloat_half3x4  :: proc "c" (v: half3x4)  -> float3x4 { return float3x4(v) }
asfloat_half4x1  :: proc "c" (v: half4x1)  -> float4x1 { return float4x1(v) }
asfloat_half4x2  :: proc "c" (v: half4x2)  -> float4x2 { return float4x2(v) }
asfloat_half4x3  :: proc "c" (v: half4x3)  -> float4x3 { return float4x3(v) }
asfloat_half2    :: proc "c" (v: half2)    -> float2   { return float2{float(v.x), float(v.y)} }
asfloat_half3    :: proc "c" (v: half3)    -> float3   { return float3{float(v.x), float(v.y), float(v.z)} }
asfloat_half4    :: proc "c" (v: half4)    -> float4   { return float4{float(v.x), float(v.y), float(v.z), float(v.w)} }
asfloat_float1x1  :: proc "c" (v: float1x1)  -> float1x1 { return float1x1(v) }
asfloat_float2x2  :: proc "c" (v: float2x2)  -> float2x2 { return float2x2(v) }
asfloat_float3x3  :: proc "c" (v: float3x3)  -> float3x3 { return float3x3(v) }
asfloat_float4x4  :: proc "c" (v: float4x4)  -> float4x4 { return float4x4(v) }
asfloat_float1x2  :: proc "c" (v: float1x2)  -> float1x2 { return float1x2(v) }
asfloat_float1x3  :: proc "c" (v: float1x3)  -> float1x3 { return float1x3(v) }
asfloat_float1x4  :: proc "c" (v: float1x4)  -> float1x4 { return float1x4(v) }
asfloat_float2x1  :: proc "c" (v: float2x1)  -> float2x1 { return float2x1(v) }
asfloat_float2x3  :: proc "c" (v: float2x3)  -> float2x3 { return float2x3(v) }
asfloat_float2x4  :: proc "c" (v: float2x4)  -> float2x4 { return float2x4(v) }
asfloat_float3x1  :: proc "c" (v: float3x1)  -> float3x1 { return float3x1(v) }
asfloat_float3x2  :: proc "c" (v: float3x2)  -> float3x2 { return float3x2(v) }
asfloat_float3x4  :: proc "c" (v: float3x4)  -> float3x4 { return float3x4(v) }
asfloat_float4x1  :: proc "c" (v: float4x1)  -> float4x1 { return float4x1(v) }
asfloat_float4x2  :: proc "c" (v: float4x2)  -> float4x2 { return float4x2(v) }
asfloat_float4x3  :: proc "c" (v: float4x3)  -> float4x3 { return float4x3(v) }
asfloat_float2    :: proc "c" (v: float2)    -> float2   { return float2(v) }
asfloat_float3    :: proc "c" (v: float3)    -> float3   { return float3(v) }
asfloat_float4    :: proc "c" (v: float4)    -> float4   { return float4(v) }
asfloat_int2      :: proc "c" (v: int2)      -> float2   { return float2{float(v.x), float(v.y)} }
asfloat_int3      :: proc "c" (v: int3)      -> float3   { return float3{float(v.x), float(v.y), float(v.z)} }
asfloat_int4      :: proc "c" (v: int4)      -> float4   { return float4{float(v.x), float(v.y), float(v.z), float(v.w)} }
asfloat_uint2     :: proc "c" (v: uint2)     -> float2   { return float2{float(v.x), float(v.y)} }
asfloat_uint3     :: proc "c" (v: uint3)     -> float3   { return float3{float(v.x), float(v.y), float(v.z)} }
asfloat_uint4     :: proc "c" (v: uint4)     -> float4   { return float4{float(v.x), float(v.y), float(v.z), float(v.w)} }
asfloat_bool2     :: proc "c" (v: bool2)     -> float2   { return float2{float(int(v.x)), float(int(v.y))} }
asfloat_bool3     :: proc "c" (v: bool3)     -> float3   { return float3{float(int(v.x)), float(int(v.y)), float(int(v.z))} }
asfloat_bool4     :: proc "c" (v: bool4)     -> float4   { return float4{float(int(v.x)), float(int(v.y)), float(int(v.z)), float(int(v.w))} }
asfloat_double1x1 :: proc "c" (v: double1x1) -> float1x1 { return float1x1(v) }
asfloat_double2x2 :: proc "c" (v: double2x2) -> float2x2 { return float2x2(v) }
asfloat_double3x3 :: proc "c" (v: double3x3) -> float3x3 { return float3x3(v) }
asfloat_double4x4 :: proc "c" (v: double4x4) -> float4x4 { return float4x4(v) }
asfloat_double1x2 :: proc "c" (v: double1x2) -> float1x2 { return float1x2(v) }
asfloat_double1x3 :: proc "c" (v: double1x3) -> float1x3 { return float1x3(v) }
asfloat_double1x4 :: proc "c" (v: double1x4) -> float1x4 { return float1x4(v) }
asfloat_double2x1 :: proc "c" (v: double2x1) -> float2x1 { return float2x1(v) }
asfloat_double2x3 :: proc "c" (v: double2x3) -> float2x3 { return float2x3(v) }
asfloat_double2x4 :: proc "c" (v: double2x4) -> float2x4 { return float2x4(v) }
asfloat_double3x1 :: proc "c" (v: double3x1) -> float3x1 { return float3x1(v) }
asfloat_double3x2 :: proc "c" (v: double3x2) -> float3x2 { return float3x2(v) }
asfloat_double3x4 :: proc "c" (v: double3x4) -> float3x4 { return float3x4(v) }
asfloat_double4x1 :: proc "c" (v: double4x1) -> float4x1 { return float4x1(v) }
asfloat_double4x2 :: proc "c" (v: double4x2) -> float4x2 { return float4x2(v) }
asfloat_double4x3 :: proc "c" (v: double4x3) -> float4x3 { return float4x3(v) }
asfloat_double2   :: proc "c" (v: double2)   -> float2   { return float2{float(v.x), float(v.y)} }
asfloat_double3   :: proc "c" (v: double3)   -> float3   { return float3{float(v.x), float(v.y), float(v.z)} }
asfloat_double4   :: proc "c" (v: double4)   -> float4   { return float4{float(v.x), float(v.y), float(v.z), float(v.w)} }


asdouble_half     :: proc "c" (v: half)     -> double    { return double(v) }
asdouble_float     :: proc "c" (v: float)     -> double    { return double(v) }
asdouble_double    :: proc "c" (v: double)    -> double    { return double(v) }
asdouble_int       :: proc "c" (v: int)       -> double    { return double(v) }
asdouble_uint      :: proc "c" (v: uint)      -> double    { return double(v) }
asdouble_half1x1  :: proc "c" (v: half1x1)  -> double1x1 { return double1x1(v) }
asdouble_half2x2  :: proc "c" (v: half2x2)  -> double2x2 { return double2x2(v) }
asdouble_half3x3  :: proc "c" (v: half3x3)  -> double3x3 { return double3x3(v) }
asdouble_half4x4  :: proc "c" (v: half4x4)  -> double4x4 { return double4x4(v) }
asdouble_half1x2  :: proc "c" (v: half1x2)  -> double1x2 { return double1x2(v) }
asdouble_half1x3  :: proc "c" (v: half1x3)  -> double1x3 { return double1x3(v) }
asdouble_half1x4  :: proc "c" (v: half1x4)  -> double1x4 { return double1x4(v) }
asdouble_half2x1  :: proc "c" (v: half2x1)  -> double2x1 { return double2x1(v) }
asdouble_half2x3  :: proc "c" (v: half2x3)  -> double2x3 { return double2x3(v) }
asdouble_half2x4  :: proc "c" (v: half2x4)  -> double2x4 { return double2x4(v) }
asdouble_half3x1  :: proc "c" (v: half3x1)  -> double3x1 { return double3x1(v) }
asdouble_half3x2  :: proc "c" (v: half3x2)  -> double3x2 { return double3x2(v) }
asdouble_half3x4  :: proc "c" (v: half3x4)  -> double3x4 { return double3x4(v) }
asdouble_half4x1  :: proc "c" (v: half4x1)  -> double4x1 { return double4x1(v) }
asdouble_half4x2  :: proc "c" (v: half4x2)  -> double4x2 { return double4x2(v) }
asdouble_half4x3  :: proc "c" (v: half4x3)  -> double4x3 { return double4x3(v) }
asdouble_half2    :: proc "c" (v: half2)    -> double2   { return double2{double(v.x), double(v.y)} }
asdouble_half3    :: proc "c" (v: half3)    -> double3   { return double3{double(v.x), double(v.y), double(v.z)} }
asdouble_half4    :: proc "c" (v: half4)    -> double4   { return double4{double(v.x), double(v.y), double(v.z), double(v.w)} }
asdouble_float1x1  :: proc "c" (v: float1x1)  -> double1x1 { return double1x1(v) }
asdouble_float2x2  :: proc "c" (v: float2x2)  -> double2x2 { return double2x2(v) }
asdouble_float3x3  :: proc "c" (v: float3x3)  -> double3x3 { return double3x3(v) }
asdouble_float4x4  :: proc "c" (v: float4x4)  -> double4x4 { return double4x4(v) }
asdouble_float1x2  :: proc "c" (v: float1x2)  -> double1x2 { return double1x2(v) }
asdouble_float1x3  :: proc "c" (v: float1x3)  -> double1x3 { return double1x3(v) }
asdouble_float1x4  :: proc "c" (v: float1x4)  -> double1x4 { return double1x4(v) }
asdouble_float2x1  :: proc "c" (v: float2x1)  -> double2x1 { return double2x1(v) }
asdouble_float2x3  :: proc "c" (v: float2x3)  -> double2x3 { return double2x3(v) }
asdouble_float2x4  :: proc "c" (v: float2x4)  -> double2x4 { return double2x4(v) }
asdouble_float3x1  :: proc "c" (v: float3x1)  -> double3x1 { return double3x1(v) }
asdouble_float3x2  :: proc "c" (v: float3x2)  -> double3x2 { return double3x2(v) }
asdouble_float3x4  :: proc "c" (v: float3x4)  -> double3x4 { return double3x4(v) }
asdouble_float4x1  :: proc "c" (v: float4x1)  -> double4x1 { return double4x1(v) }
asdouble_float4x2  :: proc "c" (v: float4x2)  -> double4x2 { return double4x2(v) }
asdouble_float4x3  :: proc "c" (v: float4x3)  -> double4x3 { return double4x3(v) }
asdouble_float2    :: proc "c" (v: float2)    -> double2   { return double2{double(v.x), double(v.y)} }
asdouble_float3    :: proc "c" (v: float3)    -> double3   { return double3{double(v.x), double(v.y), double(v.z)} }
asdouble_float4    :: proc "c" (v: float4)    -> double4   { return double4{double(v.x), double(v.y), double(v.z), double(v.w)} }
asdouble_int2      :: proc "c" (v: int2)      -> double2   { return double2{double(v.x), double(v.y)} }
asdouble_int3      :: proc "c" (v: int3)      -> double3   { return double3{double(v.x), double(v.y), double(v.z)} }
asdouble_int4      :: proc "c" (v: int4)      -> double4   { return double4{double(v.x), double(v.y), double(v.z), double(v.w)} }
asdouble_uint2     :: proc "c" (v: uint2)     -> double2   { return double2{double(v.x), double(v.y)} }
asdouble_uint3     :: proc "c" (v: uint3)     -> double3   { return double3{double(v.x), double(v.y), double(v.z)} }
asdouble_uint4     :: proc "c" (v: uint4)     -> double4   { return double4{double(v.x), double(v.y), double(v.z), double(v.w)} }
asdouble_bool2     :: proc "c" (v: bool2)     -> double2   { return double2{double(int(v.x)), double(int(v.y))} }
asdouble_bool3     :: proc "c" (v: bool3)     -> double3   { return double3{double(int(v.x)), double(int(v.y)), double(int(v.z))} }
asdouble_bool4     :: proc "c" (v: bool4)     -> double4   { return double4{double(int(v.x)), double(int(v.y)), double(int(v.z)), double(int(v.w))} }
asdouble_double1x1 :: proc "c" (v: double1x1) -> double1x1 { return double1x1(v) }
asdouble_double2x2 :: proc "c" (v: double2x2) -> double2x2 { return double2x2(v) }
asdouble_double3x3 :: proc "c" (v: double3x3) -> double3x3 { return double3x3(v) }
asdouble_double4x4 :: proc "c" (v: double4x4) -> double4x4 { return double4x4(v) }
asdouble_double1x2 :: proc "c" (v: double1x2) -> double1x2 { return double1x2(v) }
asdouble_double1x3 :: proc "c" (v: double1x3) -> double1x3 { return double1x3(v) }
asdouble_double1x4 :: proc "c" (v: double1x4) -> double1x4 { return double1x4(v) }
asdouble_double2x1 :: proc "c" (v: double2x1) -> double2x1 { return double2x1(v) }
asdouble_double2x3 :: proc "c" (v: double2x3) -> double2x3 { return double2x3(v) }
asdouble_double2x4 :: proc "c" (v: double2x4) -> double2x4 { return double2x4(v) }
asdouble_double3x1 :: proc "c" (v: double3x1) -> double3x1 { return double3x1(v) }
asdouble_double3x2 :: proc "c" (v: double3x2) -> double3x2 { return double3x2(v) }
asdouble_double3x4 :: proc "c" (v: double3x4) -> double3x4 { return double3x4(v) }
asdouble_double4x1 :: proc "c" (v: double4x1) -> double4x1 { return double4x1(v) }
asdouble_double4x2 :: proc "c" (v: double4x2) -> double4x2 { return double4x2(v) }
asdouble_double4x3 :: proc "c" (v: double4x3) -> double4x3 { return double4x3(v) }
asdouble_double2   :: proc "c" (v: double2)   -> double2   { return double2{double(v.x), double(v.y)} }
asdouble_double3   :: proc "c" (v: double3)   -> double3   { return double3{double(v.x), double(v.y), double(v.z)} }
asdouble_double4   :: proc "c" (v: double4)   -> double4   { return double4{double(v.x), double(v.y), double(v.z), double(v.w)} }


asint_half     :: proc "c" (v: half)     -> int    { return int(v) }
asint_float     :: proc "c" (v: float)     -> int    { return int(v) }
asint_double    :: proc "c" (v: double)    -> int    { return int(v) }
asint_int       :: proc "c" (v: int)       -> int    { return int(v) }
asint_uint      :: proc "c" (v: uint)      -> int    { return int(v) }
asint_half1x1  :: proc "c" (v: half1x1)  -> int1x1 { return int1x1(v) }
asint_half2x2  :: proc "c" (v: half2x2)  -> int2x2 { return int2x2(v) }
asint_half3x3  :: proc "c" (v: half3x3)  -> int3x3 { return int3x3(v) }
asint_half4x4  :: proc "c" (v: half4x4)  -> int4x4 { return int4x4(v) }
asint_half1x2  :: proc "c" (v: half1x2)  -> int1x2 { return int1x2(v) }
asint_half1x3  :: proc "c" (v: half1x3)  -> int1x3 { return int1x3(v) }
asint_half1x4  :: proc "c" (v: half1x4)  -> int1x4 { return int1x4(v) }
asint_half2x1  :: proc "c" (v: half2x1)  -> int2x1 { return int2x1(v) }
asint_half2x3  :: proc "c" (v: half2x3)  -> int2x3 { return int2x3(v) }
asint_half2x4  :: proc "c" (v: half2x4)  -> int2x4 { return int2x4(v) }
asint_half3x1  :: proc "c" (v: half3x1)  -> int3x1 { return int3x1(v) }
asint_half3x2  :: proc "c" (v: half3x2)  -> int3x2 { return int3x2(v) }
asint_half3x4  :: proc "c" (v: half3x4)  -> int3x4 { return int3x4(v) }
asint_half4x1  :: proc "c" (v: half4x1)  -> int4x1 { return int4x1(v) }
asint_half4x2  :: proc "c" (v: half4x2)  -> int4x2 { return int4x2(v) }
asint_half4x3  :: proc "c" (v: half4x3)  -> int4x3 { return int4x3(v) }
asint_half2    :: proc "c" (v: half2)    -> int2   { return int2{int(v.x), int(v.y)} }
asint_half3    :: proc "c" (v: half3)    -> int3   { return int3{int(v.x), int(v.y), int(v.z)} }
asint_half4    :: proc "c" (v: half4)    -> int4   { return int4{int(v.x), int(v.y), int(v.z), int(v.w)} }
asint_float1x1  :: proc "c" (v: float1x1)  -> int1x1 { return int1x1(v) }
asint_float2x2  :: proc "c" (v: float2x2)  -> int2x2 { return int2x2(v) }
asint_float3x3  :: proc "c" (v: float3x3)  -> int3x3 { return int3x3(v) }
asint_float4x4  :: proc "c" (v: float4x4)  -> int4x4 { return int4x4(v) }
asint_float1x2  :: proc "c" (v: float1x2)  -> int1x2 { return int1x2(v) }
asint_float1x3  :: proc "c" (v: float1x3)  -> int1x3 { return int1x3(v) }
asint_float1x4  :: proc "c" (v: float1x4)  -> int1x4 { return int1x4(v) }
asint_float2x1  :: proc "c" (v: float2x1)  -> int2x1 { return int2x1(v) }
asint_float2x3  :: proc "c" (v: float2x3)  -> int2x3 { return int2x3(v) }
asint_float2x4  :: proc "c" (v: float2x4)  -> int2x4 { return int2x4(v) }
asint_float3x1  :: proc "c" (v: float3x1)  -> int3x1 { return int3x1(v) }
asint_float3x2  :: proc "c" (v: float3x2)  -> int3x2 { return int3x2(v) }
asint_float3x4  :: proc "c" (v: float3x4)  -> int3x4 { return int3x4(v) }
asint_float4x1  :: proc "c" (v: float4x1)  -> int4x1 { return int4x1(v) }
asint_float4x2  :: proc "c" (v: float4x2)  -> int4x2 { return int4x2(v) }
asint_float4x3  :: proc "c" (v: float4x3)  -> int4x3 { return int4x3(v) }
asint_float2    :: proc "c" (v: float2)    -> int2   { return int2{int(v.x), int(v.y)} }
asint_float3    :: proc "c" (v: float3)    -> int3   { return int3{int(v.x), int(v.y), int(v.z)} }
asint_float4    :: proc "c" (v: float4)    -> int4   { return int4{int(v.x), int(v.y), int(v.z), int(v.w)} }
asint_int2      :: proc "c" (v: int2)      -> int2   { return int2{int(v.x), int(v.y)} }
asint_int3      :: proc "c" (v: int3)      -> int3   { return int3{int(v.x), int(v.y), int(v.z)} }
asint_int4      :: proc "c" (v: int4)      -> int4   { return int4{int(v.x), int(v.y), int(v.z), int(v.w)} }
asint_uint2     :: proc "c" (v: uint2)     -> int2   { return int2{int(v.x), int(v.y)} }
asint_uint3     :: proc "c" (v: uint3)     -> int3   { return int3{int(v.x), int(v.y), int(v.z)} }
asint_uint4     :: proc "c" (v: uint4)     -> int4   { return int4{int(v.x), int(v.y), int(v.z), int(v.w)} }
asint_bool2     :: proc "c" (v: bool2)     -> int2   { return int2{int(int(v.x)), int(int(v.y))} }
asint_bool3     :: proc "c" (v: bool3)     -> int3   { return int3{int(int(v.x)), int(int(v.y)), int(int(v.z))} }
asint_bool4     :: proc "c" (v: bool4)     -> int4   { return int4{int(int(v.x)), int(int(v.y)), int(int(v.z)), int(int(v.w))} }
asint_double1x1 :: proc "c" (v: double1x1) -> int1x1 { return int1x1(v) }
asint_double2x2 :: proc "c" (v: double2x2) -> int2x2 { return int2x2(v) }
asint_double3x3 :: proc "c" (v: double3x3) -> int3x3 { return int3x3(v) }
asint_double4x4 :: proc "c" (v: double4x4) -> int4x4 { return int4x4(v) }
asint_double1x2 :: proc "c" (v: double1x2) -> int1x2 { return int1x2(v) }
asint_double1x3 :: proc "c" (v: double1x3) -> int1x3 { return int1x3(v) }
asint_double1x4 :: proc "c" (v: double1x4) -> int1x4 { return int1x4(v) }
asint_double2x1 :: proc "c" (v: double2x1) -> int2x1 { return int2x1(v) }
asint_double2x3 :: proc "c" (v: double2x3) -> int2x3 { return int2x3(v) }
asint_double2x4 :: proc "c" (v: double2x4) -> int2x4 { return int2x4(v) }
asint_double3x1 :: proc "c" (v: double3x1) -> int3x1 { return int3x1(v) }
asint_double3x2 :: proc "c" (v: double3x2) -> int3x2 { return int3x2(v) }
asint_double3x4 :: proc "c" (v: double3x4) -> int3x4 { return int3x4(v) }
asint_double4x1 :: proc "c" (v: double4x1) -> int4x1 { return int4x1(v) }
asint_double4x2 :: proc "c" (v: double4x2) -> int4x2 { return int4x2(v) }
asint_double4x3 :: proc "c" (v: double4x3) -> int4x3 { return int4x3(v) }
asint_double2   :: proc "c" (v: double2)   -> int2   { return int2{int(v.x), int(v.y)} }
asint_double3   :: proc "c" (v: double3)   -> int3   { return int3{int(v.x), int(v.y), int(v.z)} }
asint_double4   :: proc "c" (v: double4)   -> int4   { return int4{int(v.x), int(v.y), int(v.z), int(v.w)} }


asuint_half     :: proc "c" (v: half)     -> uint    { return uint(v) }
asuint_float     :: proc "c" (v: float)     -> uint    { return uint(v) }
asuint_double    :: proc "c" (v: double)    -> uint    { return uint(v) }
asuint_int       :: proc "c" (v: int)       -> uint    { return uint(v) }
asuint_uint      :: proc "c" (v: uint)      -> uint    { return uint(v) }
asuint_half2    :: proc "c" (v: half2)    -> uint2   { return uint2{uint(v.x), uint(v.y)} }
asuint_half3    :: proc "c" (v: half3)    -> uint3   { return uint3{uint(v.x), uint(v.y), uint(v.z)} }
asuint_half4    :: proc "c" (v: half4)    -> uint4   { return uint4{uint(v.x), uint(v.y), uint(v.z), uint(v.w)} }
asuint_float2    :: proc "c" (v: float2)    -> uint2   { return uint2{uint(v.x), uint(v.y)} }
asuint_float3    :: proc "c" (v: float3)    -> uint3   { return uint3{uint(v.x), uint(v.y), uint(v.z)} }
asuint_float4    :: proc "c" (v: float4)    -> uint4   { return uint4{uint(v.x), uint(v.y), uint(v.z), uint(v.w)} }
asuint_int2      :: proc "c" (v: int2)      -> uint2   { return uint2{uint(v.x), uint(v.y)} }
asuint_int3      :: proc "c" (v: int3)      -> uint3   { return uint3{uint(v.x), uint(v.y), uint(v.z)} }
asuint_int4      :: proc "c" (v: int4)      -> uint4   { return uint4{uint(v.x), uint(v.y), uint(v.z), uint(v.w)} }
asuint_uint2     :: proc "c" (v: uint2)     -> uint2   { return uint2{uint(v.x), uint(v.y)} }
asuint_uint3     :: proc "c" (v: uint3)     -> uint3   { return uint3{uint(v.x), uint(v.y), uint(v.z)} }
asuint_uint4     :: proc "c" (v: uint4)     -> uint4   { return uint4{uint(v.x), uint(v.y), uint(v.z), uint(v.w)} }
asuint_bool2     :: proc "c" (v: bool2)     -> uint2   { return uint2{uint(uint(v.x)), uint(uint(v.y))} }
asuint_bool3     :: proc "c" (v: bool3)     -> uint3   { return uint3{uint(uint(v.x)), uint(uint(v.y)), uint(uint(v.z))} }
asuint_bool4     :: proc "c" (v: bool4)     -> uint4   { return uint4{uint(uint(v.x)), uint(uint(v.y)), uint(uint(v.z)), uint(uint(v.w))} }
asuint_double2   :: proc "c" (v: double2)   -> uint2   { return uint2{uint(v.x), uint(v.y)} }
asuint_double3   :: proc "c" (v: double3)   -> uint3   { return uint3{uint(v.x), uint(v.y), uint(v.z)} }
asuint_double4   :: proc "c" (v: double4)   -> uint4   { return uint4{uint(v.x), uint(v.y), uint(v.z), uint(v.w)} }


// TODO(bill): All of the `mul` procedures
