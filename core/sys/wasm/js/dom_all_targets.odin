#+build !js
import "base:internal"


get_element_value_string :: proc(id: string, buf: []u8) -> string {
	internal.panic("vendor:wasm/js not supported on non JS targets")
}


get_element_min_max :: proc(id: string) -> (min, max: f64) {
	internal.panic("vendor:wasm/js not supported on non JS targets")
}


Rect :: struct {
	x, y, width, height: f64,
}

get_bounding_client_rect :: proc(id: string) -> (rect: Rect) {
	internal.panic("vendor:wasm/js not supported on non JS targets")
}

window_get_rect :: proc() -> (rect: Rect) {
	internal.panic("vendor:wasm/js not supported on non JS targets")
}

window_get_scroll :: proc() -> (x, y: f64) {
	internal.panic("vendor:wasm/js not supported on non JS targets")
}
