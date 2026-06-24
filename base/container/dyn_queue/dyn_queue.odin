@(require) import "base:internal"
import "base:builtin"
import "base:mem"
import "base:container/slice"
    // copy, create, delete.
import "base:container/dyn_array"

/*
Queue is a dynamically resizable double-ended queue/ring-buffer.

Being double-ended means that either end may be pushed onto or popped from
across the same block of memory, in any order, thus providing both stack and
queue-like behaviors in the same data structure.
*/
Queue :: struct($T: typeid) {
    buf:    dyn_array.Dyn_Array(T),
    len:    uint,
    offset: uint,
}

DEFAULT_CAPACITY :: 16

/*
Initialize a `Queue` with a starting `cap` and an `allocator`.
*/
init :: proc(q: ^$Q/Queue($T), cap := DEFAULT_CAPACITY, allocator: mem.Allocator, loc := #caller_location) -> mem.Allocator_Error {
    q^ = {} // Reset the struct first.
    q.buf = dyn_array.Dyn_Array(T){
        data = nil,
        len  = 0,
        cap  = 0,
        allocator = allocator,
    }
    return reserve(q, cap, loc)
}

/*
Initialize a `Queue` from a fixed `backing` slice into which modifications are
made directly.

The contents of the `backing` will be overwritten as items are pushed onto the
`Queue`. Any previous contents will not be available through the API but are
not explicitly zeroed either.

Note that procedures which need space to work (`push_back`, ...) will fail if
the backing slice runs out of space.
*/
init_from_slice :: proc(q: ^$Q/Queue($T), backing: []T) -> bool {
    dyn_array.clear(q)
    q.buf = {
        data = raw_data(backing),
        len  = builtin.len(backing),
        cap  = builtin.len(backing),
        allocator = {},
    }
    return true
}

/*
Initialize a `Queue` from a fixed `backing` slice into which modifications are
made directly.

The contents of the queue will start out with all of the elements in `backing`,
effectively creating a full queue from the slice. As such, no procedures will
be able to add more elements to the queue until some are taken off.
*/
init_with_contents :: proc(q: ^$Q/Queue($T), backing: []T) -> bool {
    dyn_array.clear(q)
    q.buf = dyn_array.Dyn_Array(T){
        data = raw_data(backing),
        len  = builtin.len(backing),
        cap  = builtin.len(backing),
        allocator = {},
    }
    q.len = builtin.len(backing)
    return true
}

/*
Delete memory that has been dynamically allocated from a `Queue` that was setup with `init`.

Note that this procedure should not be used on queues setup with
`init_from_slice` or `init_with_contents`, as neither of those procedures keep
track of the allocator state of the underlying `backing` slice.
*/
destroy :: proc(q: ^$Q/Queue($T)) {
    _ = dyn_array.delete(q.buf)
}

/*
Return the length of the queue.
*/
len :: proc(q: $Q/Queue($T)) -> uint {
    return q.len
}

/*
Return the cap of the queue.
*/
cap :: proc(q: $Q/Queue($T)) -> uint {
    return q.buf.len
}

/*
Return the remaining space in the queue.

This will be `cap() - len()`.
*/
space :: proc(q: $Q/Queue($T)) -> uint {
    return q.buf.len - q.len
}

/*
Reserve enough space in the queue for at least the specified cap.

This may return an error if allocation failed.
*/
reserve :: proc(q: ^$Q/Queue($T), cap: uint, loc := #caller_location) -> mem.Allocator_Error {
    if cap > space(q^) {
        return _grow(q, cap, loc)
    }
    return nil
}

/*
Shrink a queue's dynamically allocated array.

This has no effect if the queue was initialized with a backing slice.
*/
shrink :: proc(q: ^$Q/Queue($T), loc := #caller_location) {
    if q.buf.allocator.procedure ==  {} {
        return
    }

    if q.len > 0 && q.offset > 0 {
        allocators.TEMP_ALLOCATOR_GUARD()

        // Make the array contiguous again.
        buffer := slice.create(T, q.len, allocators.temp_allocator)

        right := q.buf.len - q.offset
        slice.copy(buffer[:],      q.buf.data[q.offset:q.buf.len])
        slice.copy(buffer[right:], q.buf.data[:q.offset])

        slice.copy(q.buf.data[:q.buf.len], buffer[:])

        q.offset = 0
    }

    builtin.dyn_array_shrink(&q.buf, q.len, loc)
}

/*
Get the element at index `i`.

This will raise a bounds checking error if `i` is an invalid index.
*/
get :: proc(q: ^$Q/Queue($T), i: uint, loc := #caller_location) -> T {
    internal.bounds_check_error_loc(loc, i, q.len)

    idx := (i + q.offset) % q.buf.len
    return q.buf.data[idx]
}

/*
Get a pointer to the element at index `i`.

This will raise a bounds checking error if `i` is an invalid index.
*/
get_ptr :: proc(q: ^$Q/Queue($T), i: uint, loc := #caller_location) -> ^T {
    internal.bounds_check_error_loc(loc, i, q.len)

    idx := (i + q.offset) % q.buf.len
    return &q.buf.data[idx]
}

/*
Set the element at index `i` to `val`.

This will raise a bounds checking error if `i` is an invalid index.
*/
set :: proc(q: ^$Q/Queue($T), i: uint, val: T, loc := #caller_location) {
    internal.bounds_check_error_loc(loc, i, q.len)

    idx := (i + q.offset) % q.buf.len
    q.buf.data[idx] = val
}

/*
Get the element at the front of the queue.

This will raise a bounds checking error if the queue is empty.
*/
front :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> T {
    when !DUSK_NO_BOUNDS_CHECK {
        internal.ensure(q.len > 0, "Queue is empty.", loc)
    }
    return q.buf.data[q.offset]
}

/*
Get a pointer to the element at the front of the queue.

This will raise a bounds checking error if the queue is empty.
*/
front_ptr :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> ^T {
    when !DUSK_NO_BOUNDS_CHECK {
        internal.ensure(q.len > 0, "Queue is empty.", loc)
    }
    return &q.buf.data[q.offset]
}

/*
Get the element at the back of the queue.

This will raise a bounds checking error if the queue is empty.
*/
back :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> T {
    when !DUSK_NO_BOUNDS_CHECK {
        internal.ensure(q.len > 0, "Queue is empty.", loc)
    }
    idx := (q.offset + q.len - 1) % q.buf.len
    return q.buf.data[idx]
}

/*
Get a pointer to the element at the back of the queue.

This will raise a bounds checking error if the queue is empty.
*/
back_ptr :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> ^T {
    when !DUSK_NO_BOUNDS_CHECK {
        internal.ensure(q.len > 0, "Queue is empty.", loc)
    }
    idx := (q.offset + q.len - 1) % q.buf.len
    return &q.buf.data[idx]
}


/*
Push an element to the back of the queue.

If there is no more space left and allocation fails to get more, this will
return false with an `Allocator_Error`.

Example:
    // This demonstrates typical queue behavior (First-In First-Out).
    main :: proc() {
        q: queue.Queue(uint)
        queue.init(&q)
        queue.push_back(&q, 1)
        queue.push_back(&q, 2)
        queue.push_back(&q, 3)
        // q.buf is now [1, 2, 3, ...]
        internal.assert(queue.dyn_array.pop_front(&q) == 1)
        internal.assert(queue.dyn_array.pop_front(&q) == 2)
        internal.assert(queue.dyn_array.pop_front(&q) == 3)
    }
*/
push_back :: proc(q: ^$Q/Queue($T), elem: T, loc := #caller_location) -> (ok: bool, err: mem.Allocator_Error) {
    if space(q^) == 0 {
        _grow(q, loc = loc) or_return
    }
    idx := (q.offset + q.len) % q.buf.len
    q.buf.data[idx] = elem
    q.len += 1
    return true, nil
}


/*
Push many elements at once to the back of the queue.

If there is not enough space left and allocation fails to get more, this will
return false with an `Allocator_Error`.
*/
push_back_many :: proc(q: ^$Q/Queue($T), elems: ..T, loc := #caller_location) -> (ok: bool, err: mem.Allocator_Error)  {
    n := builtin.len(elems)
    if space(q^) < n {
        _grow(q, q.len + n, loc) or_return
    }

    insert_from := (q.offset + q.len) % q.buf.len
    insert_to := n
    if insert_from + insert_to > q.buf.len {
        insert_to = q.buf.len - insert_from
    }
    slice.copy(q.buf.data[insert_from:q.buf.len], elems[:insert_to])
    slice.copy(q.buf.data[:insert_from],          elems[insert_to:])
    q.len += n
    return true, nil
}

/*
Push an element to the front of the queue.

If there is no more space left and allocation fails to get more, this will
return false with an `Allocator_Error`.

Example:
    // This demonstrates stack behavior (First-In Last-Out).
    main :: proc() {
        q: queue.Queue(uint)
        queue.init(&q)
        queue.push_back(&q, 1)
        queue.push_back(&q, 2)
        queue.push_back(&q, 3)
        // q.buf is now [1, 2, 3, ...]
        internal.assert(queue.pop_back(&q) == 3)
        internal.assert(queue.pop_back(&q) == 2)
        internal.assert(queue.pop_back(&q) == 1)
    }
*/
push_front :: proc(q: ^$Q/Queue($T), elem: T, loc := #caller_location) -> (ok: bool, err: mem.Allocator_Error)  {
    if space(q^) == 0 {
        _grow(q, loc = loc) or_return
    }
    q.offset = (q.offset - 1 + q.buf.len) % q.buf.len
    q.len += 1
    q.buf.data[q.offset] = elem
    return true, nil
}

/*
Pop an element from the back of the queue.

This will raise a bounds checking error if the queue is empty.

Example:
    // This demonstrates stack behavior (First-In Last-Out) at the far end of the data array.
    main :: proc() {
        q: queue.Queue(uint)
        queue.init(&q)
        queue.push_front(&q, 1)
        queue.push_front(&q, 2)
        queue.push_front(&q, 3)
        // q.buf is now [..., 3, 2, 1]
        log.infof("%#v", q)
        internal.assert(queue.dyn_array.pop_front(&q) == 3)
        internal.assert(queue.dyn_array.pop_front(&q) == 2)
        internal.assert(queue.dyn_array.pop_front(&q) == 1)
    }
*/
pop_back :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> (elem: T) {
    when !DUSK_NO_BOUNDS_CHECK {
        internal.ensure(q.len > 0, "Queue is empty.", loc)
    }
    q.len -= 1
    idx := (q.offset + q.len) % q.buf.len
    elem = q.buf.data[idx]
    return
}

/*
Pop an element from the back of the queue if one exists and return true.
Otherwise, return a nil element and false.
*/
pop_back_safe :: proc(q: ^$Q/Queue($T)) -> (elem: T, ok: bool) {
    if q.len > 0 {
        q.len -= 1
        idx := (q.offset + q.len) % q.buf.len
        elem = q.buf.data[idx]
        ok = true
    }
    return
}

/*
Pop an element from the front of the queue

This will raise a bounds checking error if the queue is empty.
*/
pop_front :: proc(q: ^$Q/Queue($T), loc := #caller_location) -> (elem: T) {
    when !DUSK_NO_BOUNDS_CHECK {
        internal.ensure(q.len > 0, "Queue is empty.", loc)
    }
    elem = q.buf.data[q.offset]
    q.offset = (q.offset + 1) % q.buf.len
    q.len -= 1
    return
}

/*
Pop an element from the front of the queue if one exists and return true.
Otherwise, return a nil element and false.
*/
pop_front_safe :: proc(q: ^$Q/Queue($T)) -> (elem: T, ok: bool) {
    if q.len > 0 {
        elem = q.buf.data[q.offset]
        q.offset = (q.offset + 1) % q.buf.len
        q.len -= 1
        ok = true
    }
    return
}

/*
Consume `n` elements from the back of the queue.

This will raise a bounds checking error if the queue does not have enough elements.
*/
consume_front :: proc(q: ^$Q/Queue($T), n: uint, loc := #caller_location) {
    when !DUSK_NO_BOUNDS_CHECK {
        internal.ensure(q.len >= n, "Queue does not have enough elements to consume.", loc)
    }
    if n > 0 {
        q.offset = (q.offset + n) % q.buf.len
        q.len -= n
    }
}

/*
Consume `n` elements from the back of the queue.

This will raise a bounds checking error if the queue does not have enough elements.
*/
consume_back :: proc(q: ^$Q/Queue($T), n: uint, loc := #caller_location) {
    when !DUSK_NO_BOUNDS_CHECK {
        internal.ensure(q.len >= n, "Queue does not have enough elements to consume.", loc)
    }
    if n > 0 {
        q.len -= n
    }
}


/*
Reset the queue's length and offset to zero, letting it write new elements over
old memory, in effect clearing the accessible contents.
*/
clear :: proc(q: ^$Q/Queue($T)) {
    q.len = 0
    q.offset = 0
}


// Internal growing procedure
_grow :: proc(q: ^$Q/Queue($T), min_capacity: uint = 0, loc := #caller_location) -> mem.Allocator_Error {
    new_capacity := max(min_capacity, 8, q.buf.len * 2)
    n := q.buf.len
    dyn_array.resize(&q.buf, new_capacity, loc) or_return
    if q.offset + q.len > n {
        diff := n - q.offset

        a := q.buf.data[new_capacity - diff : q.buf.len]
        b := q.buf.data[q.offset : q.buf.len][:diff] // This makes sense: "get the first range, and then get the N first elements from the first range".
        slice.copy(a, b)
        q.offset += new_capacity - n
    }
    return nil
}
