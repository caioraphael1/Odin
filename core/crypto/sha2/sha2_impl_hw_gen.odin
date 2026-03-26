#+build !amd64


@(private = "file")
ERR_HW_NOT_SUPPORTED :: "crypto/sha2: hardware implementation unsupported"

// is_hardware_accelerated_256 returns true iff hardware accelerated
// SHA-224/SHA-256 is supported.
is_hardware_accelerated_256 :: proc() -> bool {
	return false
}

sha256_transf_hw :: proc(ctx: ^Context_256, data: []u8) {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}
