
// Returns true when the `^Type_Info`s are semantically equivalent types
// Note: The pointers being identical should be enough to check but this is done to make sure in certain cases where it is non-trivial
// and each value wants to be checked directly.

are_types_identical :: proc(a, b: ^Type_Info) -> bool {
    if a == b {
        return true
    }

    if a == nil || b == nil {
        return false
    }

    switch {
    case a.size != b.size, a.align != b.align:
        return false
    }

    switch x in a.variant {
    case Type_Info_Named:
        y := b.variant.(Type_Info_Named) or_return
        return x.base == y.base

    case Type_Info_Integer:
        y := b.variant.(Type_Info_Integer) or_return
        return x.signed == y.signed && x.endianness == y.endianness

    case Type_Info_Rune:
        _, ok := b.variant.(Type_Info_Rune)
        return ok

    case Type_Info_Float:
        _, ok := b.variant.(Type_Info_Float)
        return ok

    case Type_Info_Complex:
        _, ok := b.variant.(Type_Info_Complex)
        return ok

    case Type_Info_Quaternion:
        _, ok := b.variant.(Type_Info_Quaternion)
        return ok

    case Type_Info_Type_Id:
        _, ok := b.variant.(Type_Info_Type_Id)
        return ok

    case Type_Info_String:
        _, ok := b.variant.(Type_Info_String)
        return ok

    case Type_Info_Boolean:
        _, ok := b.variant.(Type_Info_Boolean)
        return ok

    case Type_Info_Any:
        _, ok := b.variant.(Type_Info_Any)
        return ok

    case Type_Info_Pointer:
        y := b.variant.(Type_Info_Pointer) or_return
        return are_types_identical(x.elem, y.elem)

    case Type_Info_Multi_Pointer:
        y := b.variant.(Type_Info_Multi_Pointer) or_return
        return are_types_identical(x.elem, y.elem)

    case Type_Info_Soa_Pointer:
        y := b.variant.(Type_Info_Soa_Pointer) or_return
        return are_types_identical(x.elem, y.elem)


    case Type_Info_Procedure:
        y := b.variant.(Type_Info_Procedure) or_return
        switch {
        case x.variadic   != y.variadic,
             x.convention != y.convention:
            return false
        }

        return are_types_identical(x.params, y.params) && are_types_identical(x.results, y.results)

    case Type_Info_Array:
        y := b.variant.(Type_Info_Array) or_return
        if x.count != y.count { return false }
        return are_types_identical(x.elem, y.elem)

    case Type_Info_Enumerated_Array:
        y := b.variant.(Type_Info_Enumerated_Array) or_return
        if x.count != y.count { return false }
        return are_types_identical(x.index, y.index) &&
               are_types_identical(x.elem, y.elem)

    case Type_Info_Dynamic_Array:
        y := b.variant.(Type_Info_Dynamic_Array) or_return
        return are_types_identical(x.elem, y.elem)

    case Type_Info_Slice:
        y := b.variant.(Type_Info_Slice) or_return
        return are_types_identical(x.elem, y.elem)

    case Type_Info_Parameters:
        y := b.variant.(Type_Info_Parameters) or_return
        if len(x.types) != len(y.types) { return false }
        for _, i in x.types {
            xt, yt := x.types[i], y.types[i]
            if !are_types_identical(xt, yt) {
                return false
            }
        }
        return true

    case Type_Info_Struct:
        y := b.variant.(Type_Info_Struct) or_return
        switch {
        case x.field_count   != y.field_count,
             x.flags         != y.flags,
             x.soa_kind      != y.soa_kind,
             x.soa_base_type != y.soa_base_type,
             x.soa_len       != y.soa_len:
            return false
        }
        for i in 0..<x.field_count {
            xn, yn := x.names[i], y.names[i]
            xt, yt := x.types[i], y.types[i]
            xl, yl := x.tags[i],  y.tags[i]

            if xn != yn { return false }
            if !are_types_identical(xt, yt) { return false }
            if xl != yl { return false }
        }
        return true

    case Type_Info_Union:
        y := b.variant.(Type_Info_Union) or_return
        if len(x.variants) != len(y.variants) { return false }

        for _, i in x.variants {
            xv, yv := x.variants[i], y.variants[i]
            if !are_types_identical(xv, yv) { return false }
        }
        return true

    case Type_Info_Enum:
        // NOTE(bill): Should be handled above
        return false

    case Type_Info_Map:
        y := b.variant.(Type_Info_Map) or_return
        return are_types_identical(x.key, y.key) && are_types_identical(x.value, y.value)

    case Type_Info_Bit_Set:
        y := b.variant.(Type_Info_Bit_Set) or_return
        return x.elem == y.elem && x.lower == y.lower && x.upper == y.upper

    case Type_Info_Simd_Vector:
        y := b.variant.(Type_Info_Simd_Vector) or_return
        return x.count == y.count && x.elem == y.elem
        
    case Type_Info_Matrix:
        y := b.variant.(Type_Info_Matrix) or_return
        if x.row_count != y.row_count { return false }
        if x.column_count != y.column_count { return false }
        if x.layout != y.layout { return false }
        return are_types_identical(x.elem, y.elem)

    case Type_Info_Bit_Field:
        y := b.variant.(Type_Info_Bit_Field) or_return
        if !are_types_identical(x.backing_type, y.backing_type) { return false }
        if x.field_count != y.field_count { return false }
        for _, i in x.names[:x.field_count] {
            if x.names[i] != y.names[i] {
                return false
            }
            if !are_types_identical(x.types[i], y.types[i]) {
                return false
            }
            if x.bit_sizes[i] != y.bit_sizes[i] {
                return false
            }
        }
        return true
    }

    return false
}

// Returns true if the base-type is a signed integer or just a float, false otherwise.

is_signed :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    #partial switch i in type_info_base(info).variant {
    case Type_Info_Integer: return i.signed
    case Type_Info_Float:   return true
    }
    return false
}
// Returns true if the base-type is an usigned integer, false otherwise.

is_unsigned :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    #partial switch i in type_info_base(info).variant {
    case Type_Info_Integer: return !i.signed
    case Type_Info_Float:   return false
    }
    return false
}

// Returns true when it is a 1-byte wide integer type, false otherwise.

is_byte :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    #partial switch i in type_info_base(info).variant {
    case Type_Info_Integer: return info.size == 1
    }
    return false
}


// Returns true the base-type is an integer of any kind, false otherwise.

is_integer :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Integer)
    return ok
}
// Returns true the base-type is a rune, false otherwise.

is_rune :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Rune)
    return ok
}
// Returns true the base-type is a float of any kind, false otherwise.

is_float :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Float)
    return ok
}
// Returns true the base-type is a complex-type of any kind, false otherwise.

is_complex :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Complex)
    return ok
}
// Returns true the base-type is a quaternions any kind, false otherwise.

is_quaternion :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Quaternion)
    return ok
}
// Returns true the base-type is an `any`, false otherwise.

is_any :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Any)
    return ok
}

// Returns true the base-type is a string of any kind (string, cstring, string16, cstring16), false otherwise.

is_string :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_String)
    return ok
}
// Returns true the base-type is a cstring of any kind (cstring, cstring16), false otherwise.

is_cstring :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    v, ok := type_info_base(info).variant.(Type_Info_String)
    return ok && v.is_cstring
}

// Returns true the base-type is a string of any kind (string16, cstring16), false otherwise.

is_string16 :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    v, ok := type_info_base(info).variant.(Type_Info_String)
    return ok && v.encoding == .UTF_16
}
// Returns true the base-type is a cstring of any kind (cstring16), false otherwise.

is_cstring16 :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    v, ok := type_info_base(info).variant.(Type_Info_String)
    return ok && v.is_cstring && v.encoding == .UTF_16
}

// Returns true the base-type is a boolean of any kind, false otherwise.

is_boolean :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Boolean)
    return ok
}
// Returns true the base-type is a pointer-type of any kind (^T or rawptr), false otherwise.

is_pointer :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Pointer)
    return ok
}
// Returns true the base-type is a pointer-type of any kind ([^]T), false otherwise.

is_multi_pointer :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Multi_Pointer)
    return ok
}
// Returns true the base-type is a pointer-type of any kind (#soa^T), false otherwise.

is_soa_pointer :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Soa_Pointer)
    return ok
}
// Returns true when the type is a pointer-like type, false otherwise.

is_pointer_internally :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    #partial switch v in type_info_base(info).variant {
    case Type_Info_Pointer, Type_Info_Multi_Pointer,
         Type_Info_Procedure:
        return true
    case Type_Info_String:
        return v.is_cstring
    }
    return false
}
// Returns true when the type is a procedure type, false otherwise.

is_procedure :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Procedure)
    return ok
}
// Returns true when the type is a fixed-array type ([N]T), false otherwise.

is_array :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Array)
    return ok
}
// Returns true when the type is an enumerated-array type ([Enum]T), false otherwise.

is_enumerated_array :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Enumerated_Array)
    return ok
}
// Returns true when the type is a dynamic-array type (dyn_array.Dyn_Array(T)), false otherwise.

is_dynamic_array :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Dynamic_Array)
    return ok
}
// Returns true when the type is a map type (map[K]V), false otherwise.

is_dynamic_map :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Map)
    return ok
}
// Returns true when the type is a bit_set type, false otherwise.

is_bit_set :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Bit_Set)
    return ok
}
// Returns true when the type is a slice type ([]T), false otherwise.

is_slice :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Slice)
    return ok
}
// Returns true when the type represents a set of parameters for a procedure (inputs or outputs), false otherwise.

is_parameters :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Parameters)
    return ok
}
// Returns true when the type is a struct type, `#raw_union` will be false. All other types will be false otherwise.

is_struct :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    s, ok := type_info_base(info).variant.(Type_Info_Struct)
    return ok && .raw_union not_in s.flags
}
// Returns true when the type is a struct type with `#raw_union` applied, when `#raw_union` is not applied, the value will be false. All other types will be false otherwise.

is_raw_union :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    s, ok := type_info_base(info).variant.(Type_Info_Struct)
    return ok && .raw_union in s.flags
}
// Returns true when the type is a union type (not `#raw_union`), false otherwise.

is_union :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Union)
    return ok
}
// Returns true when the type is an enum type, false otherwise.

is_enum :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Enum)
    return ok
}
// Returns true when the type is a #simd-array type (#simd[N]T), false otherwise.

is_simd_vector :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false }
    _, ok := type_info_base(info).variant.(Type_Info_Simd_Vector)
    return ok
}


// Returns true when the core-type is represented with a platform-native endian type, and returns false otherwise.
// This will also return false when the type is not an integer, pointer, or bit_set.
// If the type is the same as the platform-native endian type (e.g. `u32le` on a little-endian system), this will return false.

is_endian_platform :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false}
    info := info
    info = type_info_core(info)
    #partial switch v in info.variant {
    case Type_Info_Integer:
        return v.endianness == .Platform
    case Type_Info_Bit_Set:
        if v.underlying != nil {
            return is_endian_platform(v.underlying)
        }
        return true
    case Type_Info_Pointer:
        return true
    }
    return false
}

// Returns true when the core-type is represented with a platform-native endian type or the same endianness as the system.
// This will also return false when the type is not an integer, pointer, or bit_set.
// If the type is the same as the platform-native endian type (e.g. `u32le` on a little-endian system), this will return true.

is_endian_little :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false}
    info := info
    info = type_info_core(info)
    #partial switch v in info.variant {
    case Type_Info_Integer:
        if v.endianness == .Platform {
            return ODIN_ENDIAN == .Little
        }
        return v.endianness == .Little
    case Type_Info_Bit_Set:
        if v.underlying != nil {
            return is_endian_platform(v.underlying)
        }
        return ODIN_ENDIAN == .Little
    case Type_Info_Pointer:
        return ODIN_ENDIAN == .Little
    }
    return ODIN_ENDIAN == .Little
}

// Returns true when the core-type is represented with a platform-native endian type or the same endianness as the system.
// This will also return false when the type is not an integer, pointer, or bit_set.
// If the type is the same as the platform-native endian type (e.g. `u32be` on a big-endian system), this will return true.

is_endian_big :: proc(info: ^Type_Info) -> bool {
    if info == nil { return false}
    info := info
    info = type_info_core(info)
    #partial switch v in info.variant {
    case Type_Info_Integer:
        if v.endianness == .Platform {
            return ODIN_ENDIAN == .Big
        }
        return v.endianness == .Big
    case Type_Info_Bit_Set:
        if v.underlying != nil {
            return is_endian_platform(v.underlying)
        }
        return ODIN_ENDIAN == .Big
    case Type_Info_Pointer:
        return ODIN_ENDIAN == .Big
    }
    return ODIN_ENDIAN == .Big
}


// The `^Type_Info` type refers to absolutely no internal pointers, meaning it can be trivially copied
has_no_indirections :: proc(ti: ^Type_Info) -> bool {
    if ti == nil {
        return true
    }

    #partial switch &info in ti.variant {
    case Type_Info_Named:
        return has_no_indirections(info.base)

    case Type_Info_Integer,
         Type_Info_Rune,
         Type_Info_Boolean,
         Type_Info_Float,
         Type_Info_Complex,
         Type_Info_Quaternion,
         Type_Info_Type_Id:
        return true
    case Type_Info_String,
         Type_Info_Any:
        return false

    case Type_Info_Enum:
        return has_no_indirections(info.base)

    case Type_Info_Pointer,
         Type_Info_Multi_Pointer,
         Type_Info_Soa_Pointer,
         Type_Info_Procedure,
         Type_Info_Slice,
         Type_Info_Dynamic_Array,
         Type_Info_Map:
        return false

    case Type_Info_Parameters:
        // If you have gotten here, it's a procedure
        return false

    case Type_Info_Array:
        return has_no_indirections(info.elem)
    case Type_Info_Enumerated_Array:
        return has_no_indirections(info.elem)

    case Type_Info_Simd_Vector:
        return true
    case Type_Info_Matrix:
        return true
    case Type_Info_Bit_Set:
        return true
    case Type_Info_Bit_Field:
        return true

    case Type_Info_Struct:
        for i in 0..<info.field_count {
            has_no_indirections(info.types[i]) or_return
        }
        return true
    case Type_Info_Union:
        for v in info.variants {
            has_no_indirections(v) or_return
        }
        return true
    }

    return false
}
