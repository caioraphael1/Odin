@(require) import "base:internal"
import "base:builtin"
import "base:mem"
import base_slice "base:container/slice"


DEBUG_HEAP_ARRAY :: #config(DEBUG_HEAP_ARRAY, true)

/*
Just like a Fixed_Array, but on the heap; that's all.

A fixed-size heap-allocated array operated on in a dynamic fashion.
- `data`: The underlying array
- `len`: Amount of items that the `Heap_Array` currently holds
*/
when DEBUG_HEAP_ARRAY {
    Heap_Array :: struct($T: typeid) {
        data: []T,
        len:  uint,
        
        // Debug
        peak: uint,
    }
} else {
    Heap_Array :: struct($T: typeid) {
        data: []T,
        len:  uint,
    }
}


@(disabled=!DEBUG_HEAP_ARRAY)
update_peak :: proc(a: ^Heap_Array($T)) {
    a.peak = max(a.peak, a.len)
}


create :: proc(cap: uint, $T: typeid, allocator: mem.Allocator) -> (heap_array: Heap_Array(T), err: mem.Allocator_Error) {
    heap_array.data = base_slice.create(T, cap, allocator) or_return
    return
}

delete :: proc(a: Heap_Array($T)) -> (err: mem.Allocator_Error) {
    base_slice.delete(a.data) or_return
    return
}


len :: proc(a: Heap_Array($T)) -> uint {
    return a.len
}

cap :: proc(a: Heap_Array($T)) -> uint {
    return builtin.len(a.data)
}


remaining_space :: proc(a: Heap_Array($T)) -> int {
    return builtin.len(a.data) - a.len
}

slice :: proc(a: ^Heap_Array($T)) -> []T {
    return a.data[:a.len]
}

get :: proc(a: Heap_Array($T), index: uint) -> T {
    return a.data[index]
}

get_safe :: proc(a: Heap_Array($T), index: uint) -> (T, bool) #no_bounds_check {
    if index < 0 || index >= a.len {
        return {}, false
    }
    return a.data[index], true
}

get_ptr :: proc(a: ^Heap_Array($T), index: uint) -> ^T {
    return &a.data[index]
}

get_ptr_safe :: proc(a: ^Heap_Array($T), index: uint) -> (^T, bool) #no_bounds_check {
    if index < 0 || index >= a.len {
        return {}, false
    }
    return &a.data[index], true
}

set :: proc(a: ^Heap_Array($T), index: uint, item: T) {
    a.data[index] = item
    update_peak(a)
}

/*
Tries to resize the small-array to the specified length.
The memory of added elements will be zeroed out.
The new length will be:
    - `length` if `length` <= capacity
    - capacity if length > capacity
Example:
    a: fixed_array.Heap_Array(5, int)

    fixed_array.push_back(&a, 1)
    fixed_array.push_back(&a, 2)
    fmt.println(fixed_array.slice(&a))

    fixed_array.dyn_array.resize(&a, 1)
    fmt.println(fixed_array.slice(&a))

    fixed_array.dyn_array.resize(&a, 100)
    fmt.println(fixed_array.slice(&a))
Output:
    [1, 2]
    [1]
    [1, 0, 0, 0, 0]
*/
resize :: proc(a: ^Heap_Array($T), length: uint) -> (ok: bool) {
    
    length := length
    ok = length <= uint(N)
    if !ok {
        length = uint(N)
    }

    prev_len := a.len
    a.len = length
    if prev_len < a.len {
        mem.zero(&a.data[prev_len], size_of(T)*(a.len - prev_len))
    }

    update_peak(a)
    return
}

/*
Tries to resize the small-array to the specified length.
Example:
    a: fixed_array.Heap_Array(5, int)

    fixed_array.push_back(&a, 1)
    fixed_array.push_back(&a, 2)
    fmt.println(fixed_array.slice(&a))

    fixed_array.dyn_array.resize_non_zero(&a, 1)
    fmt.println(fixed_array.slice(&a))

    fixed_array.dyn_array.resize_non_zero(&a, 100)
    fmt.println(fixed_array.slice(&a))
Output:
    [1, 2]
    [1]
    [1, 2, 0, 0, 0]
*/
resize_non_zero :: proc(a: ^Heap_Array($T), length: uint) {
    a.len = min(length, uint(N))

    update_peak(a)
}

/*
Attempts to add the given element to the end.
Example:
    a: fixed_array.Heap_Array(2, int)

    internal.assert(fixed_array.push_back(&a, 1), "this should fit")
    internal.assert(fixed_array.push_back(&a, 2), "this should fit")
    internal.assert(!fixed_array.push_back(&a, 3), "this should not fit")

    fmt.println(fixed_array.slice(&a))
Output:
    [1, 2]
*/
push_back :: proc(a: ^Heap_Array($T), item: T) -> bool {
    if a.len < cap(a^) {
        a.data[a.len] = item
        a.len += 1
        update_peak(a)
        return true
    }
    return false
}
append :: push_back


/*
Attempts to dyn_array.append all elements to the small-array returning
false if there is not enough space to fit all of them.

Example:
    a: fixed_array.Heap_Array(100, int)
    fixed_array.push_back_many(&a, 0, 1, 2, 3, 4)
    fmt.println(fixed_array.slice(&a))
Output:
    [0, 1, 2, 3, 4]
*/
push_back_many :: proc(a: ^Heap_Array($T), items: ..T) -> bool {
    if a.len + uint(builtin.len(items)) <= cap(a^) {
        n := base_slice.copy(a.data[a.len:], items[:])
        a.len += n
        update_peak(a)
        return true
    }
    return false
}
append_many :: push_back_many

/*
Tries to insert an element at the specified position.
Note: Performing this operation will cause pointers obtained
through get_ptr(_save) to reference incorrect elements.
Example:
    arr: fixed_array.Heap_Array(100, rune)
    fixed_array.push(&arr,  'A', 'C', 'D')
    fixed_array.dyn_array.inject_at(&arr, 'B', 1)
    fmt.println(fixed_array.slice(&arr))
Output:
    [A, B, C, D]
*/
inject_at :: proc(a: ^Heap_Array($T), item: T, index: uint) -> bool #no_bounds_check {
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

/*
Attempts to add the given element at the beginning.
This operation assumes that the small-array is not empty.
Note: Performing this operation will cause pointers obtained
through get_ptr(_save) to reference incorrect elements.
Example:
    a: fixed_array.Heap_Array(2, int)

    internal.assert(fixed_array.push_front(&a, 2), "this should fit")
    internal.assert(fixed_array.push_front(&a, 1), "this should fit")
    internal.assert(!fixed_array.push_back(&a, 0), "this should not fit")

    fmt.println(fixed_array.slice(&a))
Output:
    [1, 2]
*/
push_front :: proc(a: ^Heap_Array($T), item: T) -> bool {
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

/*
Removes and returns the last element of the small-array.
This operation assumes that the small-array is not empty.
Example:
    a: fixed_array.Heap_Array(5, int)
    fixed_array.push(&a, 0, 1, 2)

    fmt.println("BEFORE:", fixed_array.slice(&a))
    fixed_array.pop_back(&a)
    fmt.println("AFTER: ", fixed_array.slice(&a))
Output:
    BEFORE: [0, 1, 2]
    AFTER:  [0, 1]
*/
pop_back :: proc(a: ^Heap_Array($T), loc := #caller_location) -> T {
    internal.assert(condition=(N > 0 && a.len > 0), loc=loc)
    item := a.data[a.len-1]
    a.len -= 1
    return item
}

/*
Removes and returns the first element of the small-array.
This operation assumes that the small-array is not empty.
Note: Performing this operation will cause pointers obtained
through get_ptr(_save) to reference incorrect elements.
Example:
    a: fixed_array.Heap_Array(5, int)
    fixed_array.push(&a, 0, 1, 2)

    fmt.println("BEFORE:", fixed_array.slice(&a))
    fixed_array.dyn_array.pop_front(&a)
    fmt.println("AFTER: ", fixed_array.slice(&a))
Output:
    BEFORE: [0, 1, 2]
    AFTER:  [1, 2]
*/
pop_front :: proc(a: ^Heap_Array($T), loc := #caller_location) -> T {
    internal.assert(condition=(N > 0 && a.len > 0), loc=loc)
    item := a.data[0]
    s := slice(a)
    base_slice.copy(s[:], s[1:])
    a.len -= 1
    return item
}

/*
Attempts to remove and return the last element of the small array.
Unlike `pop_back`, it does not assume that the array is non-empty.
Example:
    a: fixed_array.Heap_Array(3, int)
    fixed_array.push(&a, 1)

    el, ok := fixed_array.pop_back_safe(&a)
    internal.assert(ok, "there was an element in the array")

    el, ok = fixed_array.pop_back_safe(&a)
    internal.assert(!ok, "there was NO element in the array")
*/
pop_back_safe :: proc(a: ^Heap_Array($T)) -> (item: T, ok: bool) {
    if N > 0 && a.len > 0 {
        item = a.data[a.len-1]
        a.len -= 1
        ok = true
    }
    return
}

/*
Attempts to remove and return the first element of the small array.
Unlike `dyn_array.pop_front`, it does not assume that the array is non-empty.
Note: Performing this operation will cause pointers obtained
through get_ptr(_save) to reference incorrect elements.
Example:
    a: fixed_array.Heap_Array(3, int)
    fixed_array.push(&a, 1)

    el, ok := fixed_array.dyn_array_pop_front_safe(&a)
    internal.assert(ok, "there was an element in the array")

    el, ok = fixed_array.pop_front_(&a)
    internal.assert(!ok, "there was NO element in the array")
*/
pop_front_safe :: proc(a: ^Heap_Array($T)) -> (item: T, ok: bool) {
    if N > 0 && a.len > 0 {
        item = a.data[0]
        s := slice(a)
        base_slice.copy(s[:], s[1:])
        a.len -= 1
        ok = true
    }
    return
}

/*
Decreases the length of the small-array by the given amount.
The elements are therefore not really removed and can be
recovered by calling `resize`.
Note: This procedure assumes that the array has a sufficient length.
Example:
    a: fixed_array.Heap_Array(3, int)
    fixed_array.push(&a, 0, 1, 2)

    fmt.println("BEFORE:", fixed_array.slice(&a))
    fixed_array.consume(&a, 2)
    fmt.println("AFTER :", fixed_array.slice(&a))
Output:
    BEFORE: [0, 1, 2]
    AFTER : [0]
*/
consume :: proc(a: ^Heap_Array($T), count: uint, loc := #caller_location) {
    internal.assert(a.len >= count, loc=loc)
    a.len -= count
}

/*
Removes the element at the specified index while retaining order.
Note: Performing this operation will cause pointers obtained
through get_ptr(_save) to reference incorrect elements.
Example:
    a: fixed_array.Heap_Array(4, int)
    fixed_array.push(&a, 0, 1, 2, 3)

    fmt.println("BEFORE:", fixed_array.slice(&a))
    fixed_array.dyn_array.ordered_remove(&a, 1)
    fmt.println("AFTER :", fixed_array.slice(&a))
Output:
    BEFORE: [0, 1, 2, 3]
    AFTER : [0, 2, 3]
*/
ordered_remove :: proc(a: ^Heap_Array($T), index: uint, loc := #caller_location) #no_bounds_check {
    internal.bounds_check_error_loc(loc, index, a.len)
    if index+1 < a.len {
        base_slice.copy(a.data[index:], a.data[index+1:])
    }
    a.len -= 1
}

/*
Removes the element at the specified index without retaining order.
Example:
    a: fixed_array.Heap_Array(4, int)
    fixed_array.push(&a, 0, 1, 2, 3)

    fmt.println("BEFORE:", fixed_array.slice(&a))
    fixed_array.dyn_array.unordered_remove(&a, 1)
    fmt.println("AFTER :", fixed_array.slice(&a))
Output:
    BEFORE: [0, 1, 2, 3]
    AFTER : [0, 3, 2]
*/
unordered_remove :: proc(a: ^Heap_Array($T), index: uint, loc := #caller_location) #no_bounds_check {
    internal.bounds_check_error_loc(loc, index, a.len)
    n := a.len-1
    if index != n {
        a.data[index] = a.data[n]
    }
    a.len -= 1
}

unordered_remove_element :: proc(a: ^Heap_Array($T), elem: T, loc := #caller_location) -> (ok: bool){
    if index, found := base_slice.linear_search(slice(a), elem); found {
        unordered_remove(a, index)
        return true
    }
    return false
}

/*
Sets the length of the small-array to 0.

Example:
    a: fixed_array.Heap_Array(4, int)
    fixed_array.push(&a, 0, 1, 2, 3)

    fmt.println("BEFORE:", fixed_array.slice(&a))
    fixed_array.dyn_array.clear(&a)
    fmt.println("AFTER :", fixed_array.slice(&a))
Output:
    BEFORE: [0, 1, 2, 3]
    AFTER : []
*/
clear :: proc(a: ^Heap_Array($T)) {
    _ = resize(a, 0)
}
