
HAS_RAND_BYTES :: _HAS_RAND_BYTES

rand_bytes :: proc(dst: []byte) {
    when HAS_RAND_BYTES {
        _rand_bytes(dst)
    } else {
        internal.panic("base/runtime: no runtime entropy source")
    }
}
