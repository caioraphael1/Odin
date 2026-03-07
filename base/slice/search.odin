// Utility procedures for working with slices, including sorting and searching them.
@(require) import "base:intrinsics"
@(require) import "base:builtin"
@(require) import "base:mem"



swap :: proc(array: $T/[]$E, a, b: int) {
    when size_of(E) > 8 {
        mem.ptr_swap_non_overlapping(&array[a], &array[b], size_of(E))
    } else {
        array[a], array[b] = array[b], array[a]
    }
}

swap_between :: proc(a, b: $T/[]$E) #no_bounds_check {
    n := min(len(a), len(b))
    if n >= 0 {
        mem.ptr_swap_overlapping(&a[0], &b[0], size_of(E)*n)
    }
}


reverse :: proc(array: $T/[]$E) {
    n := len(array)/2
    for i in 0..<n {
        swap(array, i, len(array)-i-1)
    }
}



contains :: proc(array: $T/[]$E, value: E) -> bool where intrinsics.type_is_comparable(E) {
    _, found := linear_search(array, value)
    return found
}

/*
Searches the given slice for the given element in O(n) time.

If you need a custom search condition, see `linear_search_proc`

Inputs:
- array: The slice to search in.
- key: The element to search for.

Returns:
- index: The index `i`, such that `array[i]` is the first occurrence of `key` in `array`, or -1 if `key` is not present in `array`.

Example:
    index: int
    found: bool

    a := []i32{10, 10, 10, 20}

    index, found = linear_search_reverse(a, 10)
    assert(index == 0 && found == true)

    index, found = linear_search_reverse(a, 30)
    assert(index == -1 && found == false)

    // Note that `index == 1`, since it is relative to `a[2:]`
    index, found = linear_search_reverse(a[2:], 20)
    assert(index == 1 && found == true)
*/

linear_search :: proc(array: $A/[]$T, key: T) -> (index: int, found: bool)
    where intrinsics.type_is_comparable(T) {
    for x, i in array {
        if x == key {
            return i, true
        }
    }
    return -1, false
}

/*
Searches the given slice for the first element satisfying predicate `f` in O(n) time.

Inputs:
- array: The slice to search in.
- f: The search condition.

Returns:
- index: The index `i`, such that `array[i]` is the first `x` in `array` for which `f(x) == true`, or -1 if such `x` does not exist.
*/

linear_search_proc :: proc(array: $A/[]$T, f: proc(T) -> bool) -> (index: int, found: bool) {
    for x, i in array {
        if f(x) {
            return i, true
        }
    }
    return -1, false
}

/*
Searches the given slice for the given element in O(n) time, starting from the
slice end.

If you need a custom search condition, see `linear_search_reverse_proc`

Inputs:
- array: The slice to search in.
- key: The element to search for.

Returns:
- index: The index `i`, such that `array[i]` is the last occurrence of `key` in `array`, or -1 if `key` is not present in `array`.

Example:
    index: int
    found: bool

    a := []i32{10, 10, 10, 20}

    index, found = linear_search_reverse(a, 20)
    assert(index == 3 && found == true)

    index, found = linear_search_reverse(a, 10)
    assert(index == 2 && found == true)

    index, found = linear_search_reverse(a, 30)
    assert(index == -1 && found == false)

    // Note that `index == 1`, since it is relative to `a[2:]`
    index, found = linear_search_reverse(a[2:], 20)
    assert(index == 1 && found == true)
*/

linear_search_reverse :: proc(array: $A/[]$T, key: T) -> (index: int, found: bool)
    where intrinsics.type_is_comparable(T) {
    #reverse for x, i in array {
        if x == key {
            return i, true
        }
    }
    return -1, false
}

/*
Searches the given slice for the last element satisfying predicate `f` in O(n)
time, starting from the slice end.

Inputs:
- array: The slice to search in.
- f: The search condition.

Returns:
- index: The index `i`, such that `array[i]` is the last `x` in `array` for which `f(x) == true`, or -1 if such `x` does not exist.
*/

linear_search_reverse_proc :: proc(array: $A/[]$T, f: proc(T) -> bool) -> (index: int, found: bool) {
    #reverse for x, i in array {
        if f(x) {
            return i, true
        }
    }
    return -1, false
}

/*
Searches the given slice for the given element.
If the slice is not sorted, the returned index is unspecified and meaningless.

If the value is found then the returned int is the index of the matching element.
If there are multiple matches, then any one of the matches could be returned.

If the value is not found then the returned int is the index where a matching
element could be inserted while maintaining sorted order.

For slices of more complex types see: `binary_search_by`

Example:
    /*
    Looks up a series of four elements. The first is found, with a
    uniquely determined position; the second and third are not
    found; the fourth could match any position in `[1, 4]`.
    */

    index: int
    found: bool

    s := []i32{0, 1, 1, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55}

    index, found = slice.binary_search(s, 13)
    assert(index == 9 && found == true)

    index, found = slice.binary_search(s, 4)
    assert(index == 7 && found == false)

    index, found = slice.binary_search(s, 100)
    assert(index == 13 && found == false)

    index, found = slice.binary_search(s, 1)
    assert(index >= 1 && index <= 4 && found == true)
*/

binary_search :: proc(array: $A/[]$T, key: T) -> (index: int, found: bool)
    where intrinsics.type_is_ordered(T) #no_bounds_check {
    return binary_search_by(array, key, cmp_proc(T))
}

/*
Searches the given slice for the given element.
If the slice is not sorted, the returned index is unspecified and meaningless.

If the value is found then the returned int is the index of the matching element.
If there are multiple matches, then any one of the matches could be returned.

If the value is not found then the returned int is the index where a matching
element could be inserted while maintaining sorted order.

The array elements and key may be different types. This allows the filter procedure
to compare keys against a slice of structs, one struct value at a time.

Returns:
- index: int
- found: bool

*/

binary_search_by :: proc(array: $A/[]$T, key: $K, f: proc(T, K) -> Ordering) -> (index: int, found: bool) #no_bounds_check {
    n := len(array)
    left, right := 0, n
    for left < right {
        mid := int(uint(left+right) >> 1)
        if f(array[mid], key) == .Less {
            left = mid+1
        } else {
            // .Equal or .Greater
            right = mid
        }
    }
    return left, left < n && f(array[left], key) == .Equal
}
