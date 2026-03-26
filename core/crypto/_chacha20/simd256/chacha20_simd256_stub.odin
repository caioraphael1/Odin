#+build !amd64
import "base:intrinsics"
import "core:crypto/_chacha20"

is_performant :: proc() -> bool {
	return false
}

stream_blocks :: proc(ctx: ^_chacha20.Context, dst, src: []u8, nr_blocks: int) {
	internal.panic("crypto/chacha20: simd256 implementation unsupported")
}

hchacha20 :: proc(dst, key, iv: []u8) {
	internal.panic("crypto/chacha20: simd256 implementation unsupported")
}
