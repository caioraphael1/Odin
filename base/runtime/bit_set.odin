import "base:intrinsics"

// `card` returns the number of bits that are set in a bit_set—its cardinality
@(builtin)
card :: proc(s: $S/bit_set[$E; $U]) -> int {
    return int(intrinsics.count_ones(transmute(intrinsics.type_bit_set_underlying_type(S))s))
}

