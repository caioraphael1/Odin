#+no-instrumentation

import "base:internal"
@(require) import "base:intrinsics"

// With Robin Hood hashing a maximum load factor of 75% is ideal.
MAP_LOAD_FACTOR :: 75
// Has to be less than 100% though.
#assert(MAP_LOAD_FACTOR < 100)

// Minimum log2 capacity.
MAP_MIN_LOG2_CAPACITY :: 3 // 8 elements


// NOTE: the default hashing algorithm derives from fnv64a, with some minor modifications to work for `map` type:
//
//     * Convert a `0` result to `1`
//         * "empty entry"
//     * Prevent the top bit from being set
//         * "deleted entry"
//
// Both of these modification are necessary for the implementation of the `map`

INITIAL_HASH_SEED :: 0xcbf29ce484222325

HASH_MASK :: 1 << (8*size_of(uintptr) - 1) -1


// This is safe to change. The log2 size of a cache-line. At minimum it has to
// be six though. Higher cache line sizes are permitted.
MAP_CACHE_LINE_LOG2 :: 6

// The size of a cache-line.
// High performance, cache-friendly, open-addressed Robin Hood hashing hash map
// data structure with various optimizations for Odin.
//
// The core of the hash map data structure is the Raw_Map struct which is a
// type-erased representation of the map. This type-erased representation is
// used in two ways: static and dynamic. When static type information is known,
// the procedures suffixed with _static should be used instead of _dynamic. The
// static procedures are optimized since they have type information. Hashing of
// keys, comparison of keys, and data lookup are all optimized. When type
// information is not known, the procedures suffixed with _dynamic should be
// used. The representation of the map is the same for both static and dynamic,
// and procedures of each can be mixed and matched. The purpose of the dynamic
// representation is to enable reflection and runtime manipulation of the map.
// The dynamic procedures all take an additional Map_Info structure parameter
// which carries runtime values describing the size, alignment, and offset of
// various traits of a given key and value type pair. The Map_Info value can
// be created by calling map_info(K, V) with the key and value typeids.
//
// This map implementation makes extensive use of uintptr for representing
// sizes, lengths, capacities, masks, pointers, offsets, and addresses to avoid
// expensive sign extension and masking that would be generated if types were
// casted all over. The only place regular ints show up is in the cap() and
// len() implementations.
//
// To make this map cache-friendly it uses a novel strategy to ensure keys and
// values of the map are always cache-line aligned and that no single key or
// value of any type ever straddles a cache-line. This cache efficiency makes
// for quick lookups because the linear-probe always addresses data in a cache
// friendly way. This is enabled through the use of a special meta-type called
// a Map_Cell which packs as many values of a given type into a local array adding
// internal padding to round to MAP_CACHE_LINE_SIZE. One other benefit to storing
// the internal data in this manner is false sharing no longer occurs when using
// a map, enabling efficient concurrent access of the map data structure with
// minimal locking if desired.

MAP_CACHE_LINE_SIZE :: 1 << MAP_CACHE_LINE_LOG2

// The minimum cache-line size allowed by this implementation is 64 bytes since
// we need 6 bits in the base pointer to store the integer log2 capacity, which
// at maximum is 63. Odin uses signed integers to represent length and capacity,
// so only 63 bits are needed in the maximum case.
#assert(MAP_CACHE_LINE_SIZE >= 64)


TOMBSTONE_MASK :: 1<<(size_of(Map_Hash)*8 - 1)



// The raw, type-erased representation of a map.
//
// 32-bytes on 64-bit
// 16-bytes on 32-bit
Raw_Map :: struct {
    // A single allocation spanning all keys, values, and hashes.
    // {
    //   k: Map_Cell(K) * (capacity / ks_per_cell)
    //   v: Map_Cell(V) * (capacity / vs_per_cell)
    //   h: Map_Cell(H) * (capacity / hs_per_cell)
    // }
    //
    // The data is allocated assuming 64-u8 alignment, meaning the address is
    // always a multiple of 64. This means we have 6 bits of zeros in the pointer
    // to store the capacity. We can store a value as large as 2^6-1 or 63 in
    // there. This conveniently is the maximum log2 capacity we can have for a map
    // as Odin uses signed integers to represent capacity.
    //
    // Since the hashes are backed by Map_Hash, which is just a 64-bit unsigned
    // integer, the cell structure for hashes is unnecessary because 64/8 is 8 and
    // requires no padding, meaning it can be indexed as a regular array of
    // Map_Hash directly, though for consistency sake it's written as if it were
    // an array of Map_Cell(Map_Hash).
    data:      uintptr,   // 8-bytes on 64-bits, 4-bytes on 32-bits
    len:       uintptr,   // 8-bytes on 64-bits, 4-bytes on 32-bits
    allocator: Allocator, // 16-bytes on 64-bits, 8-bytes on 32-bits
}

// Map_Cell type that packs multiple T in such a way to ensure that each T stays
// aligned by align_of(T) and such that align_of(Map_Cell(T)) % MAP_CACHE_LINE_SIZE == 0
//
// This means a value of type T will never straddle a cache-line.
//
// When multiple Ts can fit in a single cache-line the data array will have more
// than one element. When it cannot, the data array will have one element and
// an array of Map_Cell(T) will be padded to stay a multiple of MAP_CACHE_LINE_SIZE.
//
// We rely on the type system to do all the arithmetic and padding for us here.
//
// The usual array[index] indexing for []T backed by a []Map_Cell(T) becomes a bit
// more involved as there now may be internal padding. The indexing now becomes
//
//  N :: len(Map_Cell(T){}.data)
//  i := index / N
//  j := index % N
//  cell[i].data[j]
//
// However, since len(Map_Cell(T){}.data) is a compile-time constant, there are some
// optimizations we can do to eliminate the need for any divisions as N will
// be bounded by [1, 64).
//
// In the optimal case, len(Map_Cell(T){}.data) = 1 so the cell array can be treated
// as a regular array of T, which is the case for hashes.
Map_Cell :: struct($T: typeid) #align(MAP_CACHE_LINE_SIZE) {
    data: [MAP_CACHE_LINE_SIZE / size_of(T) when 0 < size_of(T) && size_of(T) < MAP_CACHE_LINE_SIZE else 1]T,
}

Map_Hash :: uintptr

// When working with the type-erased structure at runtime we need information
// about the map to make working with it possible. This info structure stores
// that.
//
// `Map_Info` and `Map_Cell_Info` are read only data structures and cannot be
// modified after creation
//
// 32-bytes on 64-bit
// 16-bytes on 32-bit
Map_Info :: struct {
    ks: ^Map_Cell_Info, // 8-bytes on 64-bit, 4-bytes on 32-bit
    vs: ^Map_Cell_Info, // 8-bytes on 64-bit, 4-bytes on 32-bit
    key_hasher: proc(key: rawptr, seed: Map_Hash) -> Map_Hash, // 8-bytes on 64-bit, 4-bytes on 32-bit
    key_equal:  proc(lhs, rhs: rawptr) -> bool,                // 8-bytes on 64-bit, 4-bytes on 32-bit
}


// So we can operate on a cell data structure at runtime without any type
// information, we have a simple table that stores some traits about the cell.
//
// 32-bytes on 64-bit
// 16-bytes on 32-bit
Map_Cell_Info :: struct {
    size_of_type:      uintptr, // 8-bytes on 64-bit, 4-bytes on 32-bits
    align_of_type:     uintptr, // 8-bytes on 64-bit, 4-bytes on 32-bits
    size_of_cell:      uintptr, // 8-bytes on 64-bit, 4-bytes on 32-bits
    elements_per_cell: uintptr, // 8-bytes on 64-bit, 4-bytes on 32-bits
}



map_cap :: #force_inline proc(m: Raw_Map) -> uint {
    // The data uintptr stores the capacity in the lower six bits which gives the
    // a maximum value of 2^6-1, or 63. We store the integer log2 of capacity
    // since our capacity is always a power of two. We only need 63 bits as Odin
    // represents length and capacity as a signed integer.
    return 0 if m.data == 0 else 1 << map_log2_cap(m)
}

map_resize_threshold :: #force_inline proc(m: Raw_Map) -> uintptr {
    return map_load_factor(map_log2_cap(m))
}

map_alloc_dynamic :: proc(info: ^Map_Info, log2_capacity: uintptr, allocator: Allocator, loc := #caller_location) -> (result: Raw_Map, err: Allocator_Error) {
    result.allocator = allocator // set the allocator always
    if log2_capacity == 0 {
        return
    }

    if log2_capacity >= 64 {
        // Overflowed, would be caused by log2_capacity > 64
        return {}, .Out_Of_Memory
    }

    capacity := uintptr(1) << max(log2_capacity, MAP_MIN_LOG2_CAPACITY)

    CACHE_MASK :: MAP_CACHE_LINE_SIZE - 1

    size := uint(map_total_allocation_size(capacity, info))

    data := mem_alloc_non_zeroed(size, MAP_CACHE_LINE_SIZE, allocator, loc) or_return
    data_ptr := uintptr(raw_data(data))
    if data_ptr == 0 {
        err = .Out_Of_Memory
        return
    }
    if intrinsics.expect(data_ptr & CACHE_MASK != 0, false) {
        internal.panic("allocation not aligned to a cache line", loc)
    } else {
        result.data = data_ptr | log2_capacity // Tagged pointer representation for capacity.
        result.len = 0

        map_clear_dynamic(&result, info)
    }
    return
}

map_grow_dynamic :: proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, loc := #caller_location) -> Allocator_Error {
    log2_capacity := map_log2_cap(m^)
    new_capacity := uintptr(1) << max(log2_capacity + 1, MAP_MIN_LOG2_CAPACITY)
    return map_reserve_dynamic(m, info, new_capacity, loc)
}

map_clear_dynamic :: #force_inline proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info) {
    if m.data == 0 {
        return
    }
    _, _, hs, _, _ := map_kvh_data_dynamic(m^, info)
    intrinsics.mem_zero(rawptr(hs), map_cap(m^) * size_of(Map_Hash))
    m.len = 0
}

map_reserve_dynamic :: #force_no_inline proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, new_capacity: uintptr, loc := #caller_location) -> Allocator_Error {
    
    ceil_log2 :: #force_inline proc(x: uintptr) -> uintptr {
        z := intrinsics.count_leading_zeros(x)
        if z > 0 && x & (x-1) != 0 {
            z -= 1
        }
        return size_of(uintptr)*8 - 1 - z
    }

    internal.assert(m.allocator.procedure != nil, "Allocator not defined", loc=loc)

    new_capacity := new_capacity
    old_capacity := uintptr(map_cap(m^))

    if old_capacity >= new_capacity {
        return nil
    }

    // ceiling nearest power of two
    log2_new_capacity := ceil_log2(new_capacity)

    log2_min_cap := max(MAP_MIN_LOG2_CAPACITY, log2_new_capacity)

    if m.data == 0 {
        m^ = map_alloc_dynamic(info, log2_min_cap, m.allocator, loc) or_return
        return nil
    }

    resized := map_alloc_dynamic(info, log2_min_cap, m.allocator, loc) or_return

    ks, vs, hs, _, _ := map_kvh_data_dynamic(m^, info)

    // Cache these loads to avoid hitting them in the for loop.
    n := m.len
    for i in 0..<old_capacity {
        hash := hs[i]
        if map_hash_is_empty(hash) {
            continue
        }
        if map_hash_is_deleted(hash) {
            continue
        }
        k := map_cell_index_dynamic(ks, info.ks, i)
        v := map_cell_index_dynamic(vs, info.vs, i)
        hash = info.key_hasher(rawptr(k), map_seed(resized))
        _ = __map_insert_hash_dynamic(&resized, info, hash, k, v)
        // Only need to do this comparison on each actually added pair, so do not
        // fold it into the for loop comparator as a micro-optimization.
        n -= 1
        if n == 0 {
            break
        }
    }

    map_free_dynamic(m^, info, loc) or_return
    m.data = resized.data
    return nil
}

map_free_dynamic :: #force_no_inline proc(m: Raw_Map, info: ^Map_Info, loc := #caller_location) -> Allocator_Error {
    ptr := rawptr(map_data(m))
    size := uint(map_total_allocation_size(uintptr(map_cap(m)), info))
    err := mem_free_with_size(ptr, size, m.allocator, loc)
    #partial switch err {
    case .None, .Mode_Not_Implemented:
        return nil
    }
    return err
}

map_total_allocation_size :: #force_inline proc(capacity: uintptr, info: ^Map_Info) -> uintptr {
    round :: #force_inline proc(value: uintptr) -> uintptr {
        CACHE_MASK :: MAP_CACHE_LINE_SIZE - 1
        return (value + CACHE_MASK) &~ CACHE_MASK
    }
    INFO_HS := intrinsics.type_map_cell_info(Map_Hash)

    size := uintptr(0)
    size = round(map_cell_index_dynamic(size, info.ks, capacity))
    size = round(map_cell_index_dynamic(size, info.vs, capacity))
    size = round(map_cell_index_dynamic(size, INFO_HS, capacity))
    size = round(map_cell_index_dynamic(size, info.ks, 2)) // Two additional ks for scratch storage
    size = round(map_cell_index_dynamic(size, info.vs, 2)) // Two additional vs for scratch storage
    return size
}

// Query the load factor of the map. This is not actually configurable, but
// some math is needed to compute it. Compute it as a fixed point percentage to
// avoid floating point operations. This division can be optimized out by
// multiplying by the multiplicative inverse of 100.
map_load_factor :: #force_inline proc(log2_capacity: uintptr) -> uintptr {
    return ((uintptr(1) << log2_capacity) * MAP_LOAD_FACTOR) / 100
}

// The data stores the log2 capacity in the lower six bits. This is primarily
// used in the implementation rather than map_cap since the check for data = 0
// isn't necessary in the implementation. cap() on the otherhand needs to work
// when called on an empty map.
map_log2_cap :: #force_inline proc(m: Raw_Map) -> uintptr {
    return m.data & (64 - 1)
}

// Canonicalize the data by removing the tagged capacity stored in the lower six
// bits of the data uintptr.
map_data :: #force_inline proc(m: Raw_Map) -> uintptr {
    return m.data &~ uintptr(64 - 1)
}

map_seed :: #force_inline proc(m: Raw_Map) -> uintptr {
    return __map_seed_from_map_data(map_data(m))
}

// Procedure to check if a slot is empty for a given hash. This is represented
// by the zero value to make the zero value useful. This is a procedure just
// for prose reasons.
map_hash_is_empty :: #force_inline proc(hash: Map_Hash) -> bool {
    return hash == 0
}

map_hash_is_deleted :: #force_no_inline proc(hash: Map_Hash) -> bool {
    // The MSB indicates a tombstone
    return hash & TOMBSTONE_MASK != 0
}


map_kvh_data_dynamic :: proc(m: Raw_Map, #no_alias info: ^Map_Info) -> (ks: uintptr, vs: uintptr, hs: [^]Map_Hash, sk: uintptr, sv: uintptr) {
    INFO_HS := intrinsics.type_map_cell_info(Map_Hash)

    capacity := uintptr(1) << map_log2_cap(m)
    ks   = map_data(m)
    vs   = map_cell_index_dynamic(ks,  info.ks, capacity) // Skip past ks to get start of vs
    hs_ := map_cell_index_dynamic(vs,  info.vs, capacity) // Skip past vs to get start of hs
    sk   = map_cell_index_dynamic(hs_, INFO_HS, capacity) // Skip past hs to get start of sk
    // Need to skip past two elements in the scratch key space to get to the start
    // of the scratch value space, of which there's only two elements as well.
    sv = map_cell_index_dynamic_const(sk, info.ks, 2)

    hs = ([^]Map_Hash)(hs_)
    return
}

map_cell_index_dynamic :: #force_inline proc(base: uintptr, #no_alias info: ^Map_Cell_Info, index: uintptr) -> uintptr {
    // Micro-optimize the common cases to save on integer division.
    elements_per_cell := uintptr(info.elements_per_cell)
    size_of_cell      := uintptr(info.size_of_cell)
    switch elements_per_cell {
    case 1:
        return base + (index * size_of_cell)
    case 2:
        cell_index   := index >> 1
        data_index   := index & 1
        size_of_type := uintptr(info.size_of_type)
        return base + (cell_index * size_of_cell) + (data_index * size_of_type)
    case:
        cell_index   := index / elements_per_cell
        data_index   := index % elements_per_cell
        size_of_type := uintptr(info.size_of_type)
        return base + (cell_index * size_of_cell) + (data_index * size_of_type)
    }
}

// Same as above procedure but with compile-time constant index.
map_cell_index_dynamic_const :: proc(base: uintptr, #no_alias info: ^Map_Cell_Info, $INDEX: uintptr) -> uintptr {
    elements_per_cell := uintptr(info.elements_per_cell)
    size_of_cell      := uintptr(info.size_of_cell)
    size_of_type      := uintptr(info.size_of_type)
    cell_index        := INDEX / elements_per_cell
    data_index        := INDEX % elements_per_cell
    return base + (cell_index * size_of_cell) + (data_index * size_of_type)
}


// This procedure has to stack allocate storage to store local keys during the
// Robin Hood hashing technique where elements are swapped in the backing
// arrays to reduce variance. This swapping can only be done with memcpy since
// there is no type information.
//
// This procedure returns the address of the just inserted value, and will
// return 'nil' if there was no room to insert the entry
map_insert_hash_dynamic_with_key :: proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, h: Map_Hash, ik: uintptr, iv: uintptr) -> (key: uintptr, result: uintptr) {
    h        := h
    pos      := __map_desired_position(m^, h)
    distance := uintptr(0)
    mask     := (uintptr(1) << map_log2_cap(m^)) - 1

    ks, vs, hs, sk, sv := map_kvh_data_dynamic(m^, info)

    // Avoid redundant loads of these values
    size_of_k := info.ks.size_of_type
    size_of_v := info.vs.size_of_type

    k := map_cell_index_dynamic(sk, info.ks, 0)
    v := map_cell_index_dynamic(sv, info.vs, 0)
    intrinsics.mem_copy_non_overlapping(rawptr(k), rawptr(ik), size_of_k)
    intrinsics.mem_copy_non_overlapping(rawptr(v), rawptr(iv), size_of_v)

    // Temporary k and v dynamic storage for swap below
    tk := map_cell_index_dynamic(sk, info.ks, 1)
    tv := map_cell_index_dynamic(sv, info.vs, 1)

    swap_loop: for {
        if distance > mask {
            // Failed to find an empty slot and prevent infinite loop
            internal.panic("unable to insert into a map")
        }

        element_hash := hs[pos]

        if map_hash_is_empty(element_hash) {
            k_dst := map_cell_index_dynamic(ks, info.ks, pos)
            v_dst := map_cell_index_dynamic(vs, info.vs, pos)
            intrinsics.mem_copy_non_overlapping(rawptr(k_dst), rawptr(k), size_of_k)
            intrinsics.mem_copy_non_overlapping(rawptr(v_dst), rawptr(v), size_of_v)
            hs[pos] = h

            if result == 0 {
                key    = k_dst
                result = v_dst
            }
            return
        }

        if map_hash_is_deleted(element_hash) {
            break swap_loop
        }

        if probe_distance := __map_probe_distance(m^, element_hash, pos); distance > probe_distance {
            kp := map_cell_index_dynamic(ks, info.ks, pos)
            vp := map_cell_index_dynamic(vs, info.vs, pos)

            if result == 0 {
                key    = kp
                result = vp
            }

            intrinsics.mem_copy_non_overlapping(rawptr(tk), rawptr(k), size_of_k)
            intrinsics.mem_copy_non_overlapping(rawptr(k),  rawptr(kp), size_of_k)
            intrinsics.mem_copy_non_overlapping(rawptr(kp), rawptr(tk), size_of_k)

            intrinsics.mem_copy_non_overlapping(rawptr(tv), rawptr(v), size_of_v)
            intrinsics.mem_copy_non_overlapping(rawptr(v),  rawptr(vp), size_of_v)
            intrinsics.mem_copy_non_overlapping(rawptr(vp), rawptr(tv), size_of_v)

            th := h
            h = hs[pos]
            hs[pos] = th

            distance = probe_distance
        }

        pos = (pos + 1) & mask
        distance += 1
    }

    // backward shift loop
    hs[pos] = 0
    look_ahead: uintptr = 1
    for {
        la_pos := (pos + look_ahead) & mask
        element_hash := hs[la_pos]

        if map_hash_is_deleted(element_hash) {
            look_ahead += 1
            hs[la_pos] = 0
            continue
        }

        k_dst := map_cell_index_dynamic(ks, info.ks, pos)
        v_dst := map_cell_index_dynamic(vs, info.vs, pos)

        if map_hash_is_empty(element_hash) {
            intrinsics.mem_copy_non_overlapping(rawptr(k_dst), rawptr(k), size_of_k)
            intrinsics.mem_copy_non_overlapping(rawptr(v_dst), rawptr(v), size_of_v)
            hs[pos] = h

            if result == 0 {
                key    = k_dst
                result = v_dst
            }
            return
        }

        k_src := map_cell_index_dynamic(ks, info.ks, la_pos)
        v_src := map_cell_index_dynamic(vs, info.vs, la_pos)
        probe_distance := __map_probe_distance(m^, element_hash, la_pos)

        if probe_distance < look_ahead {
            // probed can be made ideal while placing saved (ending condition)
            if result == 0 {
                key    = k_dst
                result = v_dst
            }
            intrinsics.mem_copy_non_overlapping(rawptr(k_dst), rawptr(k), size_of_k)
            intrinsics.mem_copy_non_overlapping(rawptr(v_dst), rawptr(v), size_of_v)
            hs[pos] = h

            // This will be an ideal move
            pos = (la_pos - probe_distance) & mask
            look_ahead -= probe_distance

            // shift until we hit ideal/empty
            for probe_distance != 0 {
                k_dst = map_cell_index_dynamic(ks, info.ks, pos)
                v_dst = map_cell_index_dynamic(vs, info.vs, pos)

                intrinsics.mem_copy_non_overlapping(rawptr(k_dst), rawptr(k_src), size_of_k)
                intrinsics.mem_copy_non_overlapping(rawptr(v_dst), rawptr(v_src), size_of_v)
                hs[pos] = element_hash
                hs[la_pos] = 0

                pos = (pos + 1) & mask
                la_pos = (la_pos + 1) & mask
                look_ahead = (la_pos - pos) & mask
                element_hash = hs[la_pos]
                if map_hash_is_empty(element_hash) {
                    return
                }

                probe_distance = __map_probe_distance(m^, element_hash, la_pos)
                if probe_distance == 0 {
                    return
                }
                // can be ideal?
                if probe_distance < look_ahead {
                    pos = (la_pos - probe_distance) & mask
                }
                k_src = map_cell_index_dynamic(ks, info.ks, la_pos)
                v_src = map_cell_index_dynamic(vs, info.vs, la_pos)
            }
            return
        } else if distance < probe_distance - look_ahead {
            // shift back probed
            intrinsics.mem_copy_non_overlapping(rawptr(k_dst), rawptr(k_src), size_of_k)
            intrinsics.mem_copy_non_overlapping(rawptr(v_dst), rawptr(v_src), size_of_v)
            hs[pos] = element_hash
            hs[la_pos] = 0
        } else {
            // place saved, save probed
            if result == 0 {
                key    = k_dst
                result = v_dst
            }
            intrinsics.mem_copy_non_overlapping(rawptr(k_dst), rawptr(k), size_of_k)
            intrinsics.mem_copy_non_overlapping(rawptr(v_dst), rawptr(v), size_of_v)
            hs[pos] = h

            intrinsics.mem_copy_non_overlapping(rawptr(k), rawptr(k_src), size_of_k)
            intrinsics.mem_copy_non_overlapping(rawptr(v), rawptr(v_src), size_of_v)
            h = hs[la_pos]
            hs[la_pos] = 0
            distance = probe_distance - look_ahead
        }

        pos = (pos + 1) & mask
        distance += 1
    }
}

// splitmix for uintptr
__map_seed_from_map_data :: #force_inline proc(data: uintptr) -> uintptr {
    when size_of(uintptr) == size_of(u64) {
        mix := data + 0x9e3779b97f4a7c15
        mix = (mix ~ (mix >> 30)) * 0xbf58476d1ce4e5b9
        mix = (mix ~ (mix >> 27)) * 0x94d049bb133111eb
        return mix ~ (mix >> 31)
    } else {
        mix := data + 0x9e3779b9
        mix = (mix ~ (mix >> 16)) * 0x21f0aaad
        mix = (mix ~ (mix >> 15)) * 0x735a2d97
        return mix ~ (mix >> 15)
    }
}


// Computes the desired position in the array. This is just index % capacity,
// but a procedure as there's some math involved here to recover the capacity.
__map_desired_position :: #force_inline proc(m: Raw_Map, hash: Map_Hash) -> uintptr {
    // We do not use map_cap since we know the capacity will not be zero here.
    capacity := uintptr(1) << map_log2_cap(m)
    return uintptr(hash & Map_Hash(capacity - 1))
}

__map_probe_distance :: #force_inline proc(m: Raw_Map, hash: Map_Hash, slot: uintptr) -> uintptr {
    // We do not use map_cap since we know the capacity will not be zero here.
    capacity := uintptr(1) << map_log2_cap(m)
    return (slot + capacity - __map_desired_position(m, hash)) & (capacity - 1)
}

__dynamic_map_get :: proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, h: Map_Hash, key: rawptr) -> (ptr: rawptr) {
    if m.len == 0 {
        return nil
    }
    pos := __map_desired_position(m^, h)
    distance := uintptr(0)
    mask := (uintptr(1) << map_log2_cap(m^)) - 1
    ks, vs, hs, _, _ := map_kvh_data_dynamic(m^, info)
    for {
        element_hash := hs[pos]
        if map_hash_is_empty(element_hash) {
            return nil
        } else if distance > __map_probe_distance(m^, element_hash, pos) {
            return nil
        } else if element_hash == h && info.key_equal(key, rawptr(map_cell_index_dynamic(ks, info.ks, pos))) {
            return rawptr(map_cell_index_dynamic(vs, info.vs, pos))
        }
        pos = (pos + 1) & mask
        distance += 1
    }
}

__dynamic_map_check_grow :: proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, loc := #caller_location) -> (err: Allocator_Error, has_grown: bool) {
    if m.len >= map_resize_threshold(m^) {
        return map_grow_dynamic(m, info, loc), true
    }
    return nil, false
}

__dynamic_map_set :: proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, hash: Map_Hash, key, value: rawptr, loc := #caller_location) -> rawptr {
    if found := __dynamic_map_get(m, info, hash, key); found != nil {
        intrinsics.mem_copy_non_overlapping(found, value, info.vs.size_of_type)
        return found
    }

    hash := hash
    err, has_grown := __dynamic_map_check_grow(m, info, loc)
    if err != nil {
        return nil
    }
    if has_grown {
        hash = info.key_hasher(key, map_seed(m^))
    }

    result := __map_insert_hash_dynamic(m, info, hash, uintptr(key), uintptr(value))
    if result != 0 {
        m.len += 1
    }
    return rawptr(result)
}

__dynamic_map_reserve :: proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, new_capacity: uint, loc := #caller_location) -> Allocator_Error {
    if m == nil {
        return nil
    }
    return map_reserve_dynamic(m, info, uintptr(new_capacity), loc)
}

__map_insert_hash_dynamic :: #force_inline proc(#no_alias m: ^Raw_Map, #no_alias info: ^Map_Info, h: Map_Hash, ik: uintptr, iv: uintptr) -> (result: uintptr) {
    _, result = map_insert_hash_dynamic_with_key(m, info, h, ik, iv)
    return
}

__default_hasher :: #force_inline proc(data: rawptr, seed: uintptr, N: uint) -> uintptr {
    h := u64(seed) + INITIAL_HASH_SEED
    p := ([^]u8)(data)
    for _ in 0..<N {
        h = (h ~ u64(p[0])) * 0x100000001b3
        p = p[1:]
    }
    h &= HASH_MASK
    return uintptr(h) | uintptr(uintptr(h) == 0)
}

__default_hasher_string :: proc(data: rawptr, seed: uintptr) -> uintptr {
    str := (^[]u8)(data)
    return __default_hasher(raw_data(str^), seed, len(str))
}

__default_hasher_cstring :: proc(data: rawptr, seed: uintptr) -> uintptr {
    h := u64(seed) + INITIAL_HASH_SEED
    if ptr := (^[^]u8)(data)^; ptr != nil {
        for ptr[0] != 0 {
            h = (h ~ u64(ptr[0])) * 0x100000001b3
            ptr = ptr[1:]
        }
    }
    h &= HASH_MASK
    return uintptr(h) | uintptr(uintptr(h) == 0)
}

__default_hasher_f64 :: proc(f: f64, seed: uintptr) -> uintptr {
    f := f
    buf: [size_of(f)]u8
    if f == 0 {
        return __default_hasher(&buf, seed, size_of(buf))
    }
    if f != f {
        // TODO(bill): What should the logic be for NaNs?
        return __default_hasher(&f, seed, size_of(f))
    }
    return __default_hasher(&f, seed, size_of(f))
}

__default_hasher_complex128 :: proc(x, y: f64, seed: uintptr) -> uintptr {
    seed := seed
    seed = __default_hasher_f64(x, seed)
    seed = __default_hasher_f64(y, seed)
    return seed
}

__default_hasher_quaternion256 :: proc(x, y, z, w: f64, seed: uintptr) -> uintptr {
    seed := seed
    seed = __default_hasher_f64(x, seed)
    seed = __default_hasher_f64(y, seed)
    seed = __default_hasher_f64(z, seed)
    seed = __default_hasher_f64(w, seed)
    return seed
}
