#+build darwin
#+private

_HAS_RAND_BYTES :: true


foreign import libc "system:System"
@(default_calling_convention="c")
foreign libc {
    arc4random_buf :: proc(buf: [^]u8, nbytes: uint) ---
}

// This process used to use Security/RandomCopyBytes, however
// on every version of MacOS (>= 10.12) that we care about,
// arc4random is implemented securely.
_rand_bytes :: proc(dst: []u8) {
    arc4random_buf(raw_data(dst), len(dst))
}
