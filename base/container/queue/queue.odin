@(require) import "base:internal"
import "base:builtin"
import base_slice "base:container/slice"
    // copy


Queue :: struct($N: u32, $T: typeid) where N >= 0 {
    data:   [N]T,
    len:    uint,
    offset: uint,
}


len :: proc(q: $Q/Queue($N, $T)) -> int {
    return int(q.len)
}

cap :: proc(q: $Q/Queue($N, $T)) -> int {
    return builtin.len(q.data)
}

remaining_space :: proc(q: $Q/Queue($N, $T)) -> int {
    return builtin.len(q.data) - int(q.len)
}

get :: proc(q: ^$Q/Queue($N, $T), #any_int i: int, loc := #caller_location) -> T {
    internal.bounds_check_error_loc(loc, i, int(q.len))

    idx := (uint(i) + q.offset) % builtin.len(q.data)
    return q.data[idx]
}

get_ptr :: proc(q: ^$Q/Queue($N, $T), #any_int i: int, loc := #caller_location) -> ^T {
    internal.bounds_check_error_loc(loc, i, int(q.len))

    idx := (uint(i) + q.offset) % builtin.len(q.data)
    return &q.data[idx]
}

set :: proc(q: ^$Q/Queue($N, $T), #any_int i: int, val: T, loc := #caller_location) {
    internal.bounds_check_error_loc(loc, i, int(q.len))

    idx := (uint(i) + q.offset) % builtin.len(q.data)
    q.data[idx] = val
}

front :: proc(q: ^$Q/Queue($N, $T), loc := #caller_location) -> T {
    when !ODIN_NO_BOUNDS_CHECK {
        internal.ensure(q.len > 0, "Queue is empty.", loc)
    }
    return q.data[q.offset]
}

front_ptr :: proc(q: ^$Q/Queue($N, $T), loc := #caller_location) -> ^T {
    when !ODIN_NO_BOUNDS_CHECK {
        internal.ensure(q.len > 0, "Queue is empty.", loc)
    }
    return &q.data[q.offset]
}

back :: proc(q: ^$Q/Queue($N, $T), loc := #caller_location) -> T {
    when !ODIN_NO_BOUNDS_CHECK {
        internal.ensure(q.len > 0, "Queue is empty.", loc)
    }
    idx := (q.offset + uint(q.len - 1))%builtin.len(q.data)
    return q.data[idx]
}

back_ptr :: proc(q: ^$Q/Queue($N, $T), loc := #caller_location) -> ^T {
    when !ODIN_NO_BOUNDS_CHECK {
        internal.ensure(q.len > 0, "Queue is empty.", loc)
    }
    idx := (q.offset + uint(q.len - 1)) % builtin.len(q.data)
    return &q.data[idx]
}

push_back :: proc(q: ^$Q/Queue($N, $T), elem: T, loc := #caller_location) -> (ok: bool) {
    if remaining_space(q^) == 0 {
        return false
    }
    idx := (q.offset + uint(q.len)) % builtin.len(q.data)
    q.data[idx] = elem
    q.len += 1
    return true
}

push_front :: proc(q: ^$Q/Queue($N, $T), elem: T, loc := #caller_location) -> (ok: bool)  {
    if remaining_space(q^) == 0 {
        return false
    }
    q.offset = uint(q.offset - 1 + builtin.len(q.data)) % builtin.len(q.data)
    q.len += 1
    q.data[q.offset] = elem
    return true
}

pop_back :: proc(q: ^$Q/Queue($N, $T), loc := #caller_location) -> (elem: T) {
    when !ODIN_NO_BOUNDS_CHECK {
        internal.ensure(q.len > 0, "Queue is empty.", loc)
    }
    q.len -= 1
    idx := (q.offset + uint(q.len)) % builtin.len(q.data)
    elem = q.data[idx]
    return
}

pop_back_safe :: proc(q: ^$Q/Queue($N, $T)) -> (elem: T, ok: bool) {
    if q.len > 0 {
        q.len -= 1
        idx := (q.offset + uint(q.len)) % builtin.len(q.data)
        elem = q.data[idx]
        ok = true
    }
    return
}

pop_front :: proc(q: ^$Q/Queue($N, $T), loc := #caller_location) -> (elem: T) {
    when !ODIN_NO_BOUNDS_CHECK {
        internal.ensure(q.len > 0, "Queue is empty.", loc)
    }
    elem = q.data[q.offset]
    q.offset = (q.offset + 1) % builtin.len(q.data)
    q.len -= 1
    return
}

pop_front_safe :: proc(q: ^$Q/Queue($N, $T)) -> (elem: T, ok: bool) {
    if q.len > 0 {
        elem = q.data[q.offset]
        q.offset = (q.offset + 1) % builtin.len(q.data)
        q.len -= 1
        ok = true
    }
    return
}

push_back_elems :: proc(q: ^$Q/Queue($N, $T), elems: ..T, loc := #caller_location) -> (ok: bool)  {
    n := uint(builtin.len(elems))
    if remaining_space(q^) < int(n) {
        return false
    }

    sz := uint(builtin.len(q.data))
    insert_from := (q.offset + q.len) % sz
    insert_to := n
    if insert_from + insert_to > sz {
        insert_to = sz - insert_from
    }
    base_slice.copy(q.data[insert_from:], elems[:insert_to])
    base_slice.copy(q.data[:insert_from], elems[insert_to:])
    q.len += n
    return true
}

consume_front :: proc(q: ^$Q/Queue($N, $T), n: int, loc := #caller_location) {
    when !ODIN_NO_BOUNDS_CHECK {
        internal.ensure(q.len >= uint(n), "Queue does not have enough elements to consume.", loc)
    }
    if n > 0 {
        nu := uint(n)
        q.offset = (q.offset + nu) % builtin.len(q.data)
        q.len -= nu
    }
}

consume_back :: proc(q: ^$Q/Queue($N, $T), n: int, loc := #caller_location) {
    when !ODIN_NO_BOUNDS_CHECK {
        internal.ensure(q.len >= uint(n), "Queue does not have enough elements to consume.", loc)
    }
    if n > 0 {
        q.len -= uint(n)
    }
}

clear :: proc(q: ^$Q/Queue($N, $T)) {
    q.len = 0
    q.offset = 0
}
