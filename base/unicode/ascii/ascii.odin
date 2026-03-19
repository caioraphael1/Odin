import "../utf8"

@(private) _ascii_space := [256]u8{'\t' = 1, '\n' = 1, '\v' = 1, '\f' = 1, '\r' = 1, ' ' = 1}


is_ascii_space :: proc(r: rune) -> bool {
    if r < utf8.RUNE_SELF {
        return _ascii_space[u8(r)] != 0
    }
    return false
}
