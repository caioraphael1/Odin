#+build haiku
#+private


_HAS_RAND_BYTES :: true


foreign import libc "system:c"
foreign libc {
    arc4random_buf :: proc(buf: [^]u8, nbytes: uint) ---
}


_rand_bytes :: proc(dst: []u8) {
    arc4random_buf(raw_data(dst), len(dst))
}
