// A priority queue data structure.
import "base:builtin"
import "base:internal"
import "base:mem"

// Priority Queue.
//
// Important: It needs to be initialized with `less` and `swap` procedures, see `init` and `init_from_dynamic_array`.
// See `doc.odin` for an example.
Priority_Queue :: struct($T: typeid) {
    queue: [dynamic]T,
    
    less:  proc(a, b: T) -> bool,
    swap:  proc(q: []T, i, j: int),
}

DEFAULT_CAPACITY :: 16

default_swap_proc :: proc($T: typeid) -> proc(q: []T, i, j: int) {
    return proc(q: []T, i, j: int) {
        q[i], q[j] = q[j], q[i]
    }
}

init :: proc(pq: ^$Q/Priority_Queue($T), less: proc(a, b: T) -> bool, swap: proc(q: []T, i, j: int), capacity := DEFAULT_CAPACITY, allocator: mem.Allocator) -> (err: mem.Allocator_Error) {
    if pq.queue.allocator.procedure == nil {
        pq.queue.allocator = allocator
    }
    _ = dyn_array.reserve(pq, capacity) or_return
    pq.less = less
    pq.swap = swap
    return .None
}

init_from_dynamic_array :: proc(pq: ^$Q/Priority_Queue($T), queue: [dynamic]T, less: proc(a, b: T) -> bool, swap: proc(q: []T, i, j: int)) {
    pq.queue = queue
    pq.less = less
    pq.swap = swap
    n := builtin.len(pq.queue)
    for i := n/2 - 1; i >= 0; i -= 1 {
        _shift_down(pq, i, n)
    }
}

destroy :: proc(pq: ^$Q/Priority_Queue($T)) {
    dyn_array.clear(pq)
    _ = slice.delete(pq.queue)
}

reserve :: proc(pq: ^$Q/Priority_Queue($T), capacity: int) -> (err: mem.Allocator_Error) {
    return builtin.dyn_array.reserve(&pq.queue, capacity)
}
clear :: proc(pq: ^$Q/Priority_Queue($T)) {
    builtin.dyn_array.clear(&pq.queue)
}
len :: proc(pq: $Q/Priority_Queue($T)) -> int {
    return builtin.len(pq.queue)
}
cap :: proc(pq: $Q/Priority_Queue($T)) -> int {
    return builtin.cap(pq.queue)
}

_shift_down :: proc(pq: ^$Q/Priority_Queue($T), i0, n: int) -> bool {
    // O(n log n)
    if 0 > i0 || i0 > n {
        return false
    }
    
    i := i0
    queue := pq.queue[:]
    
    for {
        j1 := 2*i + 1
        if j1 < 0 || j1 >= n {
            break
        }
        j := j1
        if j2 := j1+1; j2 < n && pq.less(queue[j2], queue[j1]) {
            j = j2
        }
        if !pq.less(queue[j], queue[i]) {
            break
        }
        
        pq.swap(queue, i, j)
        i = j
    }
    return i > i0
}

_shift_up :: proc(pq: ^$Q/Priority_Queue($T), j: int) {
    j := j
    queue := pq.queue[:]
    for 0 <= j {
        i := (j-1)/2
        if i == j || !pq.less(queue[j], queue[i]) {
            break
        }
        pq.swap(queue, i, j)
        j = i
    }
}

// NOTE(bill): When an element at index 'i' has changed its value, this will fix the
// the heap ordering. This is using a basic "heapsort" with shift up and a shift down parts.
fix :: proc(pq: ^$Q/Priority_Queue($T), i: int) {
    if !_shift_down(pq, i, builtin.len(pq.queue)) {
        _shift_up(pq, i)
    }
}

push :: proc(pq: ^$Q/Priority_Queue($T), value: T) -> (err: mem.Allocator_Error) {
    dyn_array.append(&pq.queue, value) or_return
    _shift_up(pq, builtin.len(pq.queue)-1)
    return .None
}

pop :: proc(pq: ^$Q/Priority_Queue($T), loc := #caller_location) -> (value: T) {
    internal.assert(condition=builtin.len(pq.queue)>0, loc=loc)
    
    n := builtin.len(pq.queue)-1
    pq.swap(pq.queue[:], 0, n)
    _shift_down(pq, 0, n)
    return builtin.dyn_array.pop(&pq.queue)
}

dyn_array_pop_safe :: proc(pq: ^$Q/Priority_Queue($T), loc := #caller_location) -> (value: T, ok: bool) {
    if builtin.len(pq.queue) > 0 {
        n := builtin.len(pq.queue)-1
        pq.swap(pq.queue[:], 0, n)
        _shift_down(pq, 0, n)
        return builtin.dyn_array_pop_safe(&pq.queue)
    }
    return
}

remove :: proc(pq: ^$Q/Priority_Queue($T), i: int) -> (value: T, ok: bool) {
    n := builtin.len(pq.queue)
    if 0 <= i && i < n {
        pq.swap(pq.queue[:], i, n-1)
        _shift_down(pq, i, n-1)
        _shift_up(pq, i)
        value, ok = builtin.dyn_array.pop(&pq.queue), true
    }
    return
}

peek_safe :: proc(pq: $Q/Priority_Queue($T), loc := #caller_location) -> (res: T, ok: bool) {
    if builtin.len(pq.queue) > 0 {
        return pq.queue[0], true
    }
    return
}

peek :: proc(pq: $Q/Priority_Queue($T), loc := #caller_location) -> (res: T) {
    internal.assert(condition=builtin.len(pq.queue)>0, loc=loc)

    if builtin.len(pq.queue) > 0 {
        return pq.queue[0]
    }
    return
}
