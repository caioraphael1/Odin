

string_contain_rune :: proc(s: string, r: rune) -> (result: bool) {
    for c in s {
        if c == r {
            return true
        }
    }
    return false
}


/*
Returns a substring of `s` that starts at rune index `rune_is_start` and goes up to `rune_end`.

Think of it as slicing `s[rune_is_start:rune_end]` but rune-wise.
*/
substring :: proc(s: string, rune_is_start, rune_end: uint) -> (sub: string, ok: bool) {
    if rune_is_start < 0 || rune_end < 0 || rune_end < rune_is_start {
        return
    }

    return _substring(s, int(rune_is_start), int(rune_end))
}

/*
Returns a substring of `s` that starts at rune index `rune_is_start` and goes up to the end of the string.

Think of it as slicing `s[rune_is_start:]` but rune-wise.
*/
substring_from :: proc(s: string, rune_is_start: uint) -> (sub: string, ok: bool) {
    if rune_is_start < 0 {
        return
    }

    return _substring(s, int(rune_is_start), -1)
}

/*
Returns a substring of `s` that goes up to rune index `rune_end`.

Think of it as slicing `s[:rune_end]` but rune-wise.
*/
substring_to :: proc(s: string, rune_end: uint) -> (sub: string, ok: bool) {
    if rune_end < 0 {
        return
    }

    return _substring(s, -1, int(rune_end))
}


@(private)
_substring :: proc(s: string, rune_is_start, rune_end: int) -> (sub: string, ok: bool) {
    sub = s
    ok  = true

    rune_i: int

    if rune_is_start > 0 {
        ok = false
        for _, i in sub {
            if rune_is_start == rune_i {
                ok = true
                sub = sub[i:]
                break
            }
            rune_i += 1
        }
        if !ok { return }
    }

    if rune_end >= rune_is_start {
        ok = false
        for _, i in sub {
            if rune_end == rune_i {
                ok = true
                sub = sub[:i]
                break
            }
            rune_i += 1
        }

        if rune_end == rune_i {
            ok = true
        }
    }

    return
}


/*
Returns a substring of the input string `s` with the specified rune offset and length

Example:
    fmt.println(strings.string_cut("some example text", 0, 4)) // -> "some"
    fmt.println(strings.string_cut("some example text", 2, 2)) // -> "me"
    fmt.println(strings.string_cut("some example text", 5, 7)) // -> "example"
Output:
    some
    me
    example
*/
string_cut :: proc(s: string, rune_offset: uint = 0, rune_length: uint = 0) -> (res: string) {
    s := s; rune_length := rune_length

    count: uint
    for _, offset in s {
        if count == rune_offset {
            s = s[offset:]
            break
        }
        count += 1
    }

    if rune_length < 1 {
        return s
    }

    count = 0
    for _, offset in s {
        if count == rune_length {
            s = s[:offset]
            break
        }
        count += 1
    }
    return s
}
