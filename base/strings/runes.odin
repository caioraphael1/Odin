
// Returns true if is an ASCII space character ('\t', '\n', '\v', '\f', '\r', ' ')
@(private) _ascii_space := [256]bool{'\t' = true, '\n' = true, '\v' = true, '\f' = true, '\r' = true, ' ' = true}

/*
Returns true when the `r` rune is an ASCII whitespace character.

Inputs:
- r: the rune to test

Returns:
-res: `true` if `r` is a whitespace character, `false` if otherwise
*/
// rune_is_ascii_space :: proc(r: rune) -> (res: bool) {
//     if r < utf8.RUNE_SELF {
//         return _ascii_space[u8(r)]
//     }
//     return false
// }

/*
Returns true when the `r` rune is an ASCII or UTF-8 whitespace character.
*/
rune_is_space :: proc(r: rune) -> (res: bool) {
    if r < 0x2000 {
        switch r {
        case '\t', '\n', '\v', '\f', '\r', ' ', 0x85, 0xa0, 0x1680:
            return true
        }
    } else {
        if r <= 0x200a {
            return true
        }
        switch r {
        case 0x2028, 0x2029, 0x202f, 0x205f, 0x3000:
            return true
        }
    }
    return false
}


/*
Returns true when the `r` rune is `0x0`
Returns true` if `r` is `0x0`, `false` if otherwise
*/
rune_is_null :: proc(r: rune) -> (res: bool) {
    return r == 0x0000
}
