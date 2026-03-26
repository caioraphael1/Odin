import "base:internal"
import "base:container/slice"
import "base:container/dyn_array"
import "base:container/maps"

// An iterator to dynamically iterate across something that is array-like (or pointer-to-array-like)
// Example:
//  it: int // used as a tracking value
//  for elem, idx in iterate_array(any_array_val, &it) { ... }

iterate_array :: proc(val: any, it: ^uint) -> (elem: any, index: uint, ok: bool) {
    if val == nil || it == nil {
        return
    }

    ti := type_info_base(type_info_of(val.id))
    #partial switch info in ti.variant {
    case Type_Info_Pointer:
        if ptr := (^rawptr)(val.data)^; ptr != nil {
            return iterate_array(any{ptr, info.elem.id}, it)
        }
    case Type_Info_Array:
        if it^ < uint(info.count) {
            elem.data = rawptr(uintptr(val.data) + uintptr(it^ * uint(info.elem_size)))
            elem.id = info.elem.id
            ok = true
            index = it^
            it^ += 1
        }
    case Type_Info_Slice:
        array := (^slice.Raw_Slice)(val.data)
        if it^ < array.len {
            elem.data = rawptr(uintptr(array.data) + uintptr(it^ * uint(info.elem_size)))
            elem.id = info.elem.id
            ok = true
            index = it^
            it^ += 1
        }
    case Type_Info_Dynamic_Array:
        array := (^dyn_array.Dyn_Array(u8))(val.data)
        if it^ < array.len {
            elem.data = rawptr(uintptr(array.data) + uintptr(it^ * info.elem_size))
            elem.id = info.elem.id
            ok = true
            index = it^
            it^ += 1
        }
    }

    return
}

// An iterator to dynamically iterate across map (or pointer-to-map)
// Example:
//  it: int // used as a tracking value
//  for key, val in iterate_map(any_map_val, &it) { ... }

iterate_map :: proc(val: any, it: ^uint) -> (key, value: any, ok: bool) {
    if val == nil || it == nil {
        return
    }
    ti := type_info_base(type_info_of(val.id))
    #partial switch info in ti.variant {
    case Type_Info_Pointer:
        if ptr := (^rawptr)(val.data)^; ptr != nil {
            return iterate_map(any{ptr, info.elem.id}, it)
        }
    case Type_Info_Map:
        if info.map_info == nil {
            break
        }
        rm := (^maps.Raw_Map)(val.data)
        ks, vs, hs, _, _ := internal.map_kvh_data_dynamic(rm^, info.map_info)
        for /**/ ; it^ < internal.map_cap(rm^); it^ += 1 {
            if hash := hs[it^]; maps.hash_is_valid(hash) {
                key_ptr   := internal.map_cell_index_dynamic(ks, info.map_info.ks, uintptr(it^))
                value_ptr := internal.map_cell_index_dynamic(vs, info.map_info.vs, uintptr(it^))

                key.data   = rawptr(key_ptr)
                value.data = rawptr(value_ptr)
                key.id     = info.key.id
                value.id   = info.value.id
                ok = true
                it^ += 1
                break
            }

        }
    }
    return
}

