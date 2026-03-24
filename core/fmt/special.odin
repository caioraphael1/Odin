
printf_bytes :: proc(bytes: uint) {
    if bytes > 1_000_000_000 {
        printf("%.4f gb", f32(bytes) / 1_000_000_000.0)
    } else if bytes > 1_000_000 {
        printf("%.4f mb", f32(bytes) / 1_000_000.0)
    } else if bytes > 1_000 {
        printf("%.2f kb", f32(bytes) / 1_000.0)
    } else {
        printf("%v b", bytes)
    }
}
