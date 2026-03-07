#+build wasi
#+private

_HAS_RAND_BYTES :: true

foreign import wasi "wasi_snapshot_preview1"
@(default_calling_convention="contextless")
foreign wasi {
    @(private ="file")
    random_get :: proc(buf: []u8) -> u16 ---
}

_rand_bytes :: proc(dst: []byte) {
    if errno := random_get(dst); errno != 0 {
        panic("base/runtime: wasi.random_get failed")
    }
}
