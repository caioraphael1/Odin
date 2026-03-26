#+build windows
#+private

import "base:internal"

_HAS_RAND_BYTES :: true


foreign import bcrypt "system:Bcrypt.lib"
@(default_calling_convention="system")
foreign bcrypt {
    BCryptGenRandom :: proc(hAlgorithm: rawptr, pBuffer: [^]u8, cbBuffer: u32, dwFlags: u32) -> i32 ---
}


_rand_bytes :: proc(dst: []u8) {
    internal.ensure(u64(len(dst)) <= u64(max(u32)), "base/runtime: oversized rand_bytes request")

    BCRYPT_USE_SYSTEM_PREFERRED_RNG :: 0x00000002

    ERROR_INVALID_HANDLE :: 6
    ERROR_INVALID_PARAMETER :: 87

    ret := BCryptGenRandom(nil, raw_data(dst), u32(len(dst)), BCRYPT_USE_SYSTEM_PREFERRED_RNG)
    switch ret {
    case 0:
    case ERROR_INVALID_HANDLE:
        // The handle to the first parameter is invalid.
        // This should not happen here, since we explicitly pass nil to it
        internal.panic("base/runtime: BCryptGenRandom Invalid handle for hAlgorithm")
    case ERROR_INVALID_PARAMETER:
        // One of the parameters was invalid
        internal.panic("base/runtime: BCryptGenRandom Invalid parameter")
    case:
        // Unknown error
        internal.panic("base/runtime: BCryptGenRandom failed")
    }
}
