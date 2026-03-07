#+build js
#+private

_HAS_RAND_BYTES :: true

foreign import "odin_env"

_rand_bytes :: proc(dst: []byte) {
    foreign odin_env {
        @(link_name = "rand_bytes")
        env_rand_bytes :: proc(buf: []byte) ---
    }

    MAX_PER_CALL_BYTES :: 65536 // 64kiB

    dst := dst
    for len(dst) > 0 {
        to_read := min(len(dst), MAX_PER_CALL_BYTES)
        env_rand_bytes(dst[:to_read])

        dst = dst[to_read:]
    }
}
