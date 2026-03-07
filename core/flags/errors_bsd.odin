#+build netbsd, openbsd
import "base:internal"

Unified_Parse_Error_Reason :: union #shared_nil {
	Parse_Error_Reason,
	mem.Allocator_Error,
}
