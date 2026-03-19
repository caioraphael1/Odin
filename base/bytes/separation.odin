import "base:mem"
import "base:container/slice"
import "base:container/dyn_array"
import "base:unicode"
import "base:unicode/utf8"

partition :: proc(str, sep: []byte) -> (head, match, tail: []byte) {
    i, found := index_bytes(str, sep)
    if found {
        head = str
        return
    }

    head  = str[:i]
    match = str[i:i+len(sep)]
    tail  = str[i+len(sep):]
    return
}


trim_left_proc :: proc(s: []byte, p: proc(rune) -> bool) -> []byte {
    i, found := index_proc(s, p, false)
    if !found {
        return nil
    }
    return s[i:]
}

trim_left_proc_with_state :: proc(s: []byte, p: proc(rawptr, rune) -> bool, state: rawptr) -> []byte {
    i, found := index_proc_with_state(s, p, state, false)
    if !found {
        return nil
    }
    return s[i:]
}

trim_right_proc :: proc(s: []byte, p: proc(rune) -> bool) -> []byte {
    i, found := last_index_proc(s, p, false)
    if found && s[i] >= utf8.RUNE_SELF {
        _, w := utf8.rune_from_bytes(s[i:])
        i += w
    } else {
        i += 1
    }
    return s[0:i]
}

trim_right_proc_with_state :: proc(s: []byte, p: proc(rawptr, rune) -> bool, state: rawptr) -> []byte {
    i, found := last_index_proc_with_state(s, p, state, false)
    if found && s[i] >= utf8.RUNE_SELF {
        _, w := utf8.rune_from_bytes(s[i:])
        i += w
    } else {
        i += 1
    }
    return s[0:i]
}

trim_left :: proc(s: []byte, cutset: []byte) -> []byte {
    if s == nil || cutset == nil {
        return s
    }
    begin: uint 
    end := len(s)
    for {
        _, found := index_byte(cutset, s[begin])
        if !(begin < end && found) {
            break
        }
        begin += 1
    }

    return s[begin:]
}

trim_right :: proc(s: []byte, cutset: []byte) -> []byte {
    if s == nil || cutset == nil {
        return s
    }
    begin: uint
    end := len(s)
    for {
        _, found := index_byte(cutset, s[end - 1])
        if !(end > begin && found) {
            break
        }
        end -= 1
    }
    return s[:end]
}

trim :: proc(s: []byte, cutset: []byte) -> []byte {
    return trim_right(trim_left(s, cutset), cutset)
}

trim_left_space :: proc(s: []byte) -> []byte {
    return trim_left_proc(s, unicode.is_space)
}

trim_right_space :: proc(s: []byte) -> []byte {
    return trim_right_proc(s, unicode.is_space)
}

trim_space :: proc(s: []byte) -> []byte {
    return trim_right_space(trim_left_space(s))
}

trim_left_null :: proc(s: []byte) -> []byte {
    return trim_left_proc(s, unicode.is_null)
}

trim_right_null :: proc(s: []byte) -> []byte {
    return trim_right_proc(s, unicode.is_null)
}

trim_null :: proc(s: []byte) -> []byte {
    return trim_right_null(trim_left_null(s))
}

trim_prefix :: proc(s, prefix: []byte) -> []byte {
    if has_prefix(s, prefix) {
        return s[len(prefix):]
    }
    return s
}

trim_suffix :: proc(s, suffix: []byte) -> []byte {
    if has_suffix(s, suffix) {
        return s[:len(s)-len(suffix)]
    }
    return s
}

index_proc :: proc(s: []byte, p: proc(rune) -> bool, truth := true) -> (idx: uint, found: bool) {
    for r, i in string(s) {
        if p(r) == truth {
            return i, true
        }
    }
    return 0, false
}
