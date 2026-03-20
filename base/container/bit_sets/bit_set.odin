import "base:intrinsics"

// `card` returns the number of bits that are set in a bit_set—its cardinality
card :: proc(s: $S/bit_set[$E; $U]) -> uint {
    return uint(intrinsics.count_ones(transmute(intrinsics.type_bit_set_underlying_type(S))s))
}

