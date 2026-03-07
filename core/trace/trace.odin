
import "base:intrinsics"
import "base:runtime"

Frame :: distinct uintptr

Frame_Location :: struct {
	using loc: runtime.Source_Code_Location,
	allocator: mem.Allocator,
}

delete_frame_location :: proc(fl: Frame_Location) -> mem.Allocator_Error {
	allocator := fl.allocator
    _ = slice.delete(fl.loc.procedure, allocator) or_return
    _ = slice.delete(fl.loc.file_path, allocator) or_return
	return nil
}

Context :: struct {
	in_resolve: bool, // atomic
	impl: _Context,
}

init :: proc(ctx: ^Context) -> bool {
	return _init(ctx)
}

destroy :: proc(ctx: ^Context) -> bool {
	return _destroy(ctx)
}


frames :: proc(ctx: ^Context, skip: uint, frames_buffer: []Frame) -> []Frame {
	return _frames(ctx, skip, frames_buffer)
}


resolve :: proc(ctx: ^Context, frame: Frame, allocator: mem.Allocator) -> (result: Frame_Location) {
	return _resolve(ctx, frame, allocator)
}



in_resolve :: proc(ctx: ^Context) -> bool {
	return intrinsics.atomic_load(&ctx.in_resolve)
}

_format_hex :: proc(buf: []byte, val: uintptr, allocator: mem.Allocator) -> int {
	_digits := "0123456789abcdef"

	shift := (size_of(uintptr) * 8) - 4
	offs := 0

	for shift >= 0 {
		d := (val >> uint(shift)) & 0xf
		buf[offs] = _digits[d]
		shift -= 4
		offs += 1
	}

	return offs
}

_format_missing_proc :: proc(addr: uintptr, allocator: mem.Allocator) -> string {
	PREFIX :: "proc:0x"
	buf, buf_err := slice.create([]byte, len(PREFIX) + 16, allocator)
	copy(buf, PREFIX)

	if buf_err != nil {
		return "OUT_OF_MEMORY"
	}

	offs := len(PREFIX)
	offs += _format_hex(buf[offs:], uintptr(addr), allocator)
	return string(buf[:offs])
}
