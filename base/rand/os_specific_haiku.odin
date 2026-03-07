#+build haiku
#+private


_HAS_RAND_BYTES :: true


foreign import libc "system:c"
foreign libc {
    arc4random_buf :: proc(buf: [^]byte, nbytes: uint) ---
}


_rand_bytes :: proc(dst: []byte) {
    arc4random_buf(raw_data(dst), len(dst))
}
