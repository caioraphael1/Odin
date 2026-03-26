#+build !amd64


@(private = "file")
ERR_HW_NOT_SUPPORTED :: "crypto/aegis: hardware implementation unsupported"

@(private)
State_HW :: struct {}

// is_hardware_accelerated returns true iff hardware accelerated AEGIS
// is supported.
is_hardware_accelerated :: proc() -> bool {
	return false
}

@(private)
init_hw :: proc(ctx: ^Context, st: ^State_HW, iv: []u8) {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}

@(private)
absorb_hw :: proc(st: ^State_HW, aad: []u8) {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}

@(private)
enc_hw :: proc(st: ^State_HW, dst, src: []u8) {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}

@(private)
dec_hw :: proc(st: ^State_HW, dst, src: []u8) {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}

@(private)
finalize_hw :: proc(st: ^State_HW, tag: []u8, ad_len, msg_len: int) {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}

@(private)
reset_state_hw :: proc(st: ^State_HW) {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}
