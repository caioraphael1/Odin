#+build !netbsd
#+build !openbsd
import "base:internal"
import "core:net"

Unified_Parse_Error_Reason :: union #shared_nil {
	Parse_Error_Reason,
	mem.Allocator_Error,
	net.Parse_Endpoint_Error,
}
