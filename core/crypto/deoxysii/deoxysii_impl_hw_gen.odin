#+build !amd64


@(private = "file")
ERR_HW_NOT_SUPPORTED :: "crypto/deoxysii: hardware implementation unsupported"

// is_hardware_accelerated returns true iff hardware accelerated Deoxys-II
// is supported.
is_hardware_accelerated :: proc() -> bool {
	return false
}

@(private)
e_hw :: proc(ctx: ^Context, dst, tag, iv, aad, plaintext: []u8) #no_bounds_check {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}

@(private, require_results)
d_hw :: proc(ctx: ^Context, dst, iv, aad, ciphertext, tag: []u8) -> bool {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}
