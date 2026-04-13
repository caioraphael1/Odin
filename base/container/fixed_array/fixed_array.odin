@(require) import "base:internal"
import "base:builtin"
import "base:mem"

import "base:container/new_slice"
import base_slice "base:container/slice"


DEBUG_FIXED_ARRAY :: #config(DEBUG_FIXED_ARRAY, true)

/*
A fixed-size stack-allocated array operated on in a dynamic fashion.
- `data`: The underlying array
- `len`: Amount of items that the `Fixed_Array` currently holds
*/
when DEBUG_FIXED_ARRAY {
    Fixed_Array :: struct($N: u32, $T: typeid) where N >= 0 {
        data: [N]T,
        len:  uint,
        
        // Debug
        peak: uint,
    }
} else {
    Fixed_Array :: struct($N: u32, $T: typeid) where N >= 0 {
        data: [N]T,
        len:  uint,
    }
}


@(disabled=!DEBUG_FIXED_ARRAY)
update_peak :: proc(a: ^Fixed_Array($N, $T)) {
    a.peak = max(a.peak, a.len)
}


len :: proc(a: Fixed_Array($N, $T)) -> uint {
    return a.len
}

cap :: proc(a: Fixed_Array($N, $T)) -> uint {
    return uint(N)
}


remaining_space :: proc(a: Fixed_Array($N, $T)) -> int {
    return uint(N) - a.len
}


slice :: proc(a: ^Fixed_Array($N, $T)) -> []T {
    return a.data[:a.len]
}

new_slice :: proc(a: ^Fixed_Array($N, $T)) -> new_slice.Slice(T) {
    return {
        data = raw_data(a.data),
        len  = a.len,
    }
}


get :: proc(a: Fixed_Array($N, $T), index: uint) -> T {
    return a.data[index]
}

get_safe :: proc(a: Fixed_Array($N, $T), index: uint) -> (T, bool) #no_bounds_check {
    if index < 0 || index >= a.len {
        return {}, false
    }
    return a.data[index], true
}

get_ptr :: proc(a: ^Fixed_Array($N, $T), index: uint) -> ^T {
    return &a.data[index]
}

get_ptr_safe :: proc(a: ^Fixed_Array($N, $T), index: uint) -> (^T, bool) #no_bounds_check {
    if index < 0 || index >= a.len {
        return {}, false
    }
    return &a.data[index], true
}

set :: proc(a: ^Fixed_Array($N, $T), index: uint, item: T) {
    a.data[index] = item
    update_peak(a)
}


resize :: proc(a: ^Fixed_Array($N, $T), length: uint) -> (ok: bool) {
    
    length := length
    ok = length <= uint(N)
    if !ok {
        length = uint(N)
    }

    prev_len := a.len
    a.len = length
   if a.len > prev_len  {
        // Zero only the new region after growth.
        mem.zero(&a.data[prev_len], size_of(T)*(a.len - prev_len))
    }

    update_peak(a)
    return
}

resize_non_zero :: proc(a: ^Fixed_Array($N, $T), length: uint) {
    a.len = min(length, uint(N))

    update_peak(a)
}


push_back :: proc(a: ^Fixed_Array($N, $T), item: T) -> bool {
    if a.len < cap(a^) {
        a.data[a.len] = item
        a.len += 1
        update_peak(a)
        return true
    }
    return false
}
append :: push_back


push_back_many :: proc(a: ^Fixed_Array($N, $T), items: ..T) -> bool {
    if a.len + uint(builtin.len(items)) <= cap(a^) {
        n := base_slice.copy(a.data[a.len:], items[:])
        a.len += n
        update_peak(a)
        return true
    }
    return false
}
append_many :: push_back_many


inject_at :: proc(a: ^Fixed_Array($N, $T), item: T, index: uint) -> bool #no_bounds_check {
    if a.len < cap(a^) && index >= 0 && index <= len(a^) {
        a.len += 1
        for i := a.len - 1; i >= index + 1; i -= 1 {
            a.data[i] = a.data[i - 1]
        }
        a.data[index] = item
        update_peak(a)
        return true
    }
    return false
}


push_front :: proc(a: ^Fixed_Array($N, $T), item: T) -> bool {
    if a.len < cap(a^) {
        a.len += 1
        data := slice(a)
        base_slice.copy(data[1:], data[:])
        data[0] = item
        update_peak(a)
        return true
    }
    return false
}


pop_back :: proc(a: ^Fixed_Array($N, $T), loc := #caller_location) -> T {
    internal.assert(N > 0 && a.len > 0, loc=loc)
    item := a.data[a.len-1]
    a.len -= 1
    return item
}


pop_front :: proc(a: ^Fixed_Array($N, $T), loc := #caller_location) -> T {
    internal.assert(N > 0 && a.len > 0, loc=loc)
    item := a.data[0]
    s := slice(a)
    base_slice.copy(s[:], s[1:])
    a.len -= 1
    return item
}


pop_back_safe :: proc(a: ^Fixed_Array($N, $T)) -> (item: T, ok: bool) {
    if N > 0 && a.len > 0 {
        item = a.data[a.len-1]
        a.len -= 1
        ok = true
    }
    return
}


pop_front_safe :: proc(a: ^Fixed_Array($N, $T)) -> (item: T, ok: bool) {
    if N > 0 && a.len > 0 {
        item = a.data[0]
        s := slice(a)
        base_slice.copy(s[:], s[1:])
        a.len -= 1
        ok = true
    }
    return
}


consume :: proc(a: ^Fixed_Array($N, $T), count: uint, loc := #caller_location) {
    internal.assert(a.len >= count, loc=loc)
    if a.len == 0 { return }
    a.len -= count
}


ordered_remove :: proc(a: ^Fixed_Array($N, $T), index: uint, loc := #caller_location) #no_bounds_check {
    internal.bounds_check_error_loc(loc, index, a.len)
    if index+1 < a.len {
        base_slice.copy(a.data[index:], a.data[index+1:])
    }
    a.len -= 1
}


unordered_remove :: proc(a: ^Fixed_Array($N, $T), index: uint, loc := #caller_location) #no_bounds_check {
    internal.bounds_check_error_loc(loc, index, a.len)
    n := a.len-1
    if index != n {
        a.data[index] = a.data[n]
    }
    a.len -= 1
}

unordered_remove_element :: proc(a: ^Fixed_Array($N, $T), elem: T, loc := #caller_location) -> (ok: bool){
    if index, found := base_slice.linear_search(slice(a), elem); found {
        unordered_remove(a, index)
        return true
    }
    return false
}


clear :: proc(a: ^Fixed_Array($N, $T)) {
    a.len = 0
}
