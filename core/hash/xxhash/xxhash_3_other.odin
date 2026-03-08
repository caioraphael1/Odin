#+build !amd64
#+build !i386
import "base:internal"

XXH_NATIVE_WIDTH :: min(XXH_MAX_WIDTH,
	2 when internal.HAS_HARDWARE_SIMD else 1)
