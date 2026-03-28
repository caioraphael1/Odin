#+no-instrumentation

import "base:internal"
@(require) import "base:intrinsics"


/* 
Type_Info_Map :: struct {
    key:      ^Type_Info,
    value:    ^Type_Info,
    map_info: ^Map_Info,
}
*/

// With Robin Hood hashing a maximum load factor, from 0 to 100%; 75% is ideal.
MAP_LOAD_FACTOR :: 75

// Minimum log2 capacity.
MAP_MIN_CAPACITY :: 8


// NOTE: the default hashing algorithm derives from fnv64a, with some minor modifications to work for `map` type:
//
//     * Convert a `0` result to `1`
//         * "empty entry"
//     * Prevent the top bit from being set
//         * "deleted entry"
//
// Both of these modification are necessary for the implementation of the `map`


HASH_MASK :: 1 << (8*size_of(uintptr) - 1) -1


// This is safe to change. The log2 size of a cache-line. At minimum it has to
// be six though. Higher cache line sizes are permitted.
MAP_CACHE_LINE_LOG2 :: 6

// The size of a cache-line.
// High performance, cache-friendly, open-addressed Robin Hood hashing hash map
// data structure with various optimizations for Odin.
//
// The core of the hash map data structure is the Map struct which is a
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



_map_kvh_data_dynamic :: proc(m: Map, info: ^Map_Info) -> (ks: uintptr, vs: uintptr, hs: [^]Map_Hash, sk: uintptr, sv: uintptr) {
    INFO_HS := intrinsics.type_map_cell_info(Map_Hash)

    capacity := m.cap
    ks   = m.data
    vs   = _cell_index_dynamic(ks,  info.ks, capacity) // Skip past ks to get start of vs
    hs_ := _cell_index_dynamic(vs,  info.vs, capacity) // Skip past vs to get start of hs
    sk   = _cell_index_dynamic(hs_, INFO_HS, capacity) // Skip past hs to get start of sk
    // Need to skip past two elements in the scratch key space to get to the start
    // of the scratch value space, of which there's only two elements as well.
    sv = _cell_index_dynamic_const(sk, info.ks, 2)

    hs = ([^]Map_Hash)(hs_)
    return
}

_cell_index_dynamic :: #force_inline proc(base: uintptr, info: ^Map_Cell_Info, index: uintptr) -> uintptr {
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
_cell_index_dynamic_const :: proc(base: uintptr, info: ^Map_Cell_Info, $INDEX: uintptr) -> uintptr {
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
insert_hash_dynamic_with_key :: proc(m: ^Map, info: ^Map_Info, h: Map_Hash, ik: uintptr, iv: uintptr) -> (key: uintptr, result: uintptr) {
    h        := h
    pos      := _desired_position(m^, h)
    distance := uintptr(0)
    mask     := m.cap - 1

    ks, vs, hs, sk, sv := _map_kvh_data_dynamic(m^, info)

    // Avoid redundant loads of these values
    size_of_k := info.ks.size_of_type
    size_of_v := info.vs.size_of_type

    k := _cell_index_dynamic(sk, info.ks, 0)
    v := _cell_index_dynamic(sv, info.vs, 0)
    intrinsics.mem_copy_non_overlapping(rawptr(k), rawptr(ik), size_of_k)
    intrinsics.mem_copy_non_overlapping(rawptr(v), rawptr(iv), size_of_v)

    // Temporary k and v dynamic storage for swap below
    tk := _cell_index_dynamic(sk, info.ks, 1)
    tv := _cell_index_dynamic(sv, info.vs, 1)

    swap_loop: for {
        if distance > mask {
            // Failed to find an empty slot and prevent infinite loop
            internal.panic("unable to insert into a map")
        }

        element_hash := hs[pos]

        if hash_is_empty(element_hash) {
            k_dst := _cell_index_dynamic(ks, info.ks, pos)
            v_dst := _cell_index_dynamic(vs, info.vs, pos)
            intrinsics.mem_copy_non_overlapping(rawptr(k_dst), rawptr(k), size_of_k)
            intrinsics.mem_copy_non_overlapping(rawptr(v_dst), rawptr(v), size_of_v)
            hs[pos] = h

            if result == 0 {
                key    = k_dst
                result = v_dst
            }
            return
        }

        if hash_is_deleted(element_hash) {
            break swap_loop
        }

        if probe_distance := _probe_distance(m^, element_hash, pos); distance > probe_distance {
            kp := _cell_index_dynamic(ks, info.ks, pos)
            vp := _cell_index_dynamic(vs, info.vs, pos)

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

        if hash_is_deleted(element_hash) {
            look_ahead += 1
            hs[la_pos] = 0
            continue
        }

        k_dst := _cell_index_dynamic(ks, info.ks, pos)
        v_dst := _cell_index_dynamic(vs, info.vs, pos)

        if hash_is_empty(element_hash) {
            intrinsics.mem_copy_non_overlapping(rawptr(k_dst), rawptr(k), size_of_k)
            intrinsics.mem_copy_non_overlapping(rawptr(v_dst), rawptr(v), size_of_v)
            hs[pos] = h

            if result == 0 {
                key    = k_dst
                result = v_dst
            }
            return
        }

        k_src := _cell_index_dynamic(ks, info.ks, la_pos)
        v_src := _cell_index_dynamic(vs, info.vs, la_pos)
        probe_distance := _probe_distance(m^, element_hash, la_pos)

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
                k_dst = _cell_index_dynamic(ks, info.ks, pos)
                v_dst = _cell_index_dynamic(vs, info.vs, pos)

                intrinsics.mem_copy_non_overlapping(rawptr(k_dst), rawptr(k_src), size_of_k)
                intrinsics.mem_copy_non_overlapping(rawptr(v_dst), rawptr(v_src), size_of_v)
                hs[pos] = element_hash
                hs[la_pos] = 0

                pos = (pos + 1) & mask
                la_pos = (la_pos + 1) & mask
                look_ahead = (la_pos - pos) & mask
                element_hash = hs[la_pos]
                if hash_is_empty(element_hash) {
                    return
                }

                probe_distance = _probe_distance(m^, element_hash, la_pos)
                if probe_distance == 0 {
                    return
                }
                // can be ideal?
                if probe_distance < look_ahead {
                    pos = (la_pos - probe_distance) & mask
                }
                k_src = _cell_index_dynamic(ks, info.ks, la_pos)
                v_src = _cell_index_dynamic(vs, info.vs, la_pos)
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
