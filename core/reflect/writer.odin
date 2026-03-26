import "core:strings_tools"
import "core:io"
import "core:io/string_builder"

// Writes a typeid in standard (non-canonical) form to a `string_builder.Builder`
write_typeid_builder :: proc(buf: ^string_builder.Builder, id: typeid, n_written: ^uint = nil) -> (n: uint, err: io.Error) {
    return write_type_writer(string_builder.to_writer(buf), type_info_of(id))
}
// Writes a typeid in standard (non-canonical) form to an `io.Writer`
write_typeid_writer :: proc(writer: io.Writer, id: typeid, n_written: ^uint = nil) -> (n: uint, err: io.Error) {
    return write_type_writer(writer, type_info_of(id), n_written)
}


// Writes a `^Type_Info` in standard (non-canonical) form to a `string_builder.Builder`
write_type_builder :: proc(buf: ^string_builder.Builder, ti: ^Type_Info) -> uint {
    n, _ := write_type_writer(string_builder.to_writer(buf), ti)
    return n
}
// Writes a `^Type_Info` in standard (non-canonical) form to an `io.Writer`
write_type_writer :: #force_no_inline proc(w: io.Writer, ti: ^Type_Info, n_written: ^uint = nil) -> (n: uint, err: io.Error) {
    defer if n_written != nil {
        n_written^ += n
    }
    if ti == nil {
        _ = io.write_string(w, "nil", &n) or_return
        return
    }
    
    switch info in ti.variant {
    case Type_Info_Named:
        _ = io.write_string(w, info.name, &n) or_return
    case Type_Info_Integer:
        switch ti.id {
        case int:     _ = io.write_string(w, "int",     &n) or_return
        case uint:    _ = io.write_string(w, "uint",    &n) or_return
        case uintptr: _ = io.write_string(w, "uintptr", &n) or_return
        case:
            io.write_byte(w, 'i' if info.signed else 'u', &n) or_return
            _ = io.write_i64(w, i64(8*ti.size), 10,       &n) or_return
            switch info.endianness {
            case .Platform: // Okay
            case .Little: _ = io.write_string(w, "le", &n) or_return
            case .Big:    _ = io.write_string(w, "be", &n) or_return
            }
        }
    case Type_Info_Rune:
        _ = io.write_string(w, "rune", &n) or_return
    case Type_Info_Float:
        io.write_byte(w, 'f', &n)               or_return
        _ = io.write_i64(w, i64(8*ti.size), 10, &n) or_return
        switch info.endianness {
        case .Platform: // Okay
        case .Little: _ = io.write_string(w, "le", &n) or_return
        case .Big:    _ = io.write_string(w, "be", &n) or_return
        }
    case Type_Info_Complex:
        _ = io.write_string(w, "complex", &n)       or_return
        _ = io.write_i64(w, i64(8*ti.size), 10, &n) or_return
    case Type_Info_Quaternion:
        _ = io.write_string(w, "quaternion", &n)    or_return
        _ = io.write_i64(w, i64(8*ti.size), 10, &n) or_return
    case Type_Info_String:
        if info.is_cstring {
            io.write_byte(w, 'c', &n) or_return
        }
        _ = io.write_string(w, "string", &n)  or_return
        switch info.encoding {
        case .UTF_8:  /**/
        case .UTF_16: _ = io.write_string(w, "16", &n) or_return
        }
    case Type_Info_Boolean:
        switch ti.id {
        case bool: _ = io.write_string(w, "bool", &n) or_return
        case:
            io.write_byte(w, 'b', &n)               or_return
            _ = io.write_i64(w, i64(8*ti.size), 10, &n) or_return
        }
    case Type_Info_Any:
        _ = io.write_string(w, "any", &n) or_return

    case Type_Info_Type_Id:
        _ = io.write_string(w, "typeid", &n) or_return

    case Type_Info_Pointer:
        if info.elem == nil {
            _ = io.write_string(w, "rawptr", &n) or_return
        } else {
            _ = io.write_string(w, "^", &n) or_return
            _ = write_type_writer(w, info.elem, &n) or_return
        }
    case Type_Info_Multi_Pointer:
        _ = io.write_string(w, "[^]", &n) or_return
        _ = write_type_writer(w, info.elem, &n) or_return
    case Type_Info_Soa_Pointer:
        _ = io.write_string(w, "#soa ^", &n) or_return
        _ = write_type_writer(w, info.elem, &n) or_return
    case Type_Info_Procedure:
        _ = io.write_string(w, "proc", &n) or_return
        if info.params == nil {
            _ = io.write_string(w, "()", &n) or_return
        } else {
            t := info.params.variant.(Type_Info_Parameters)
            _ = io.write_string(w, "(", &n) or_return
            for t, i in t.types {
                if i > 0 {
                    _ = io.write_string(w, ", ", &n) or_return
                }
                _ = write_type_writer(w, t, &n) or_return
            }
            _ = io.write_string(w, ")", &n) or_return
        }
        if info.results != nil {
            _ = io.write_string(w, " -> ", &n)  or_return
            _ = write_type_writer(w, info.results, &n) or_return
        }
    case Type_Info_Parameters:
        count := len(info.names)
        if count != 1 { 
            _ = io.write_string(w, "(", &n) or_return 
        }
        for name, i in info.names {
            if i > 0 { _ = io.write_string(w, ", ", &n) or_return }

            t := info.types[i]

            if len(name) > 0 {
                _ = io.write_string(w, name, &n) or_return
                _ = io.write_string(w, ": ", &n) or_return
            }
            _ = write_type_writer(w, t, &n) or_return
        }
        if count != 1 { 
            _ = io.write_string(w, ")", &n) or_return 
        }

    case Type_Info_Array:
        _ = io.write_string(w, "[",              &n) or_return
        _ = io.write_i64(w, i64(info.count), 10, &n) or_return
        _ = io.write_string(w, "]",              &n) or_return
        _ = write_type_writer(w, info.elem,      &n) or_return

    case Type_Info_Enumerated_Array:
        if info.is_sparse {
            _ = io.write_string(w, "#sparse", &n) or_return
        }
        _ = io.write_string(w, "[",   &n) or_return
        _ = write_type_writer(w, info.index, &n) or_return
        _ = io.write_string(w, "]",   &n) or_return
        _ = write_type_writer(w, info.elem,  &n) or_return

    case Type_Info_Dynamic_Array:
        _ = io.write_string(w, "[dynamic]", &n) or_return
        _ = write_type_writer(w, info.elem, &n) or_return
    case Type_Info_Slice:
        _ = io.write_string(w, "[]", &n) or_return
        _ = write_type_writer(w, info.elem, &n) or_return

    case Type_Info_Map:
        _ = io.write_string(w, "map[", &n) or_return
        _ = write_type_writer(w, info.key,    &n) or_return
        io.write_byte(w, ']',      &n) or_return
        _ = write_type_writer(w, info.value,  &n) or_return

    case Type_Info_Struct:
        switch info.soa_kind {
        case .None: // Ignore
        case .Fixed:
            _ = io.write_string(w, "#soa[",           &n) or_return
            _ = io.write_i64(w, i64(info.soa_len),    10) or_return
            io.write_byte(w, ']',                 &n) or_return
            _ = write_type_writer(w, info.soa_base_type,     &n) or_return
            return
        case .Slice:
            _ = io.write_string(w, "#soa[]",      &n) or_return
            _ = write_type_writer(w, info.soa_base_type, &n) or_return
            return
        case .Dynamic:
            _ = io.write_string(w, "#soa[dynamic]", &n) or_return
            _ = write_type_writer(w, info.soa_base_type, &n) or_return
            return
        }

        _ = io.write_string(w, "struct ", &n) or_return
        if .packed      in info.flags { _ = io.write_string(w, "#packed ",    &n) or_return }
        if .raw_union   in info.flags { _ = io.write_string(w, "#raw_union ", &n) or_return }
        if .all_or_none in info.flags { _ = io.write_string(w, "#all_or_none ", &n) or_return }
        if .align in info.flags {
            _ = io.write_string(w, "#align(",      &n) or_return
            _ = io.write_i64(w, i64(ti.align), 10, &n) or_return
            _ = io.write_string(w, ") ",           &n) or_return
        }
        io.write_byte(w, '{', &n) or_return
        for name, i in info.names[:info.field_count] {
            if i > 0 { _ = io.write_string(w, ", ", &n) or_return }
            _ = io.write_string(w, name,     &n) or_return
            _ = io.write_string(w, ": ",     &n) or_return
            _ = write_type_writer(w, info.types[i], &n) or_return
        }
        io.write_byte(w, '}', &n) or_return

    case Type_Info_Union:
        _ = io.write_string(w, "union ", &n) or_return
        if info.no_nil     { _ = io.write_string(w, "#no_nil ", &n)     or_return }
        if info.shared_nil { _ = io.write_string(w, "#shared_nil ", &n) or_return }
        if info.custom_align {
            _ = io.write_string(w, "#align(",      &n) or_return
            _ = io.write_i64(w, i64(ti.align), 10, &n) or_return
            _ = io.write_string(w, ") ",           &n) or_return
        }
        io.write_byte(w, '{', &n) or_return
        for variant, i in info.variants {
            if i > 0 { _ = io.write_string(w, ", ", &n) or_return }
            _ = write_type_writer(w, variant, &n) or_return
        }
        io.write_byte(w, '}', &n) or_return

    case Type_Info_Enum:
        _ = io.write_string(w, "enum ", &n) or_return
        _ = write_type_writer(w, info.base, &n) or_return
        _ = io.write_string(w, " {", &n) or_return
        for name, i in info.names {
            if i > 0 { _ = io.write_string(w, ", ", &n) or_return }
            _ = io.write_string(w, name, &n) or_return
        }
        io.write_byte(w, '}', &n) or_return

    case Type_Info_Bit_Set:
        _ = io.write_string(w, "bit_set[", &n) or_return
        switch {
        case is_enum(info.elem):
            _ = write_type_writer(w, info.elem, &n) or_return
        case is_rune(info.elem):
            _ = io.write_encoded_rune(w, rune(info.lower), true, &n) or_return
            _ = io.write_string(w, "..=",                        &n) or_return
            _ = io.write_encoded_rune(w, rune(info.upper), true, &n) or_return
        case:
            _ = io.write_i64(w, info.lower, 10, &n) or_return
            _ = io.write_string(w, "..=",       &n) or_return
            _ = io.write_i64(w, info.upper, 10, &n) or_return
        }
        if info.underlying != nil {
            _ = io.write_string(w, "; ",       &n) or_return
            _ = write_type_writer(w, info.underlying, &n) or_return
        }
        io.write_byte(w, ']', &n) or_return

    case Type_Info_Bit_Field:
        _ = io.write_string(w, "bit_field ", &n) or_return
        _ = write_type_writer(w, info.backing_type, &n) or_return
        _ = io.write_string(w, " {",         &n) or_return
        for name, i in info.names[:info.field_count] {
            if i > 0 { _ = io.write_string(w, ", ", &n) or_return }
            _ = io.write_string(w, name,     &n) or_return
            _ = io.write_string(w, ": ",     &n) or_return
            _ = write_type_writer(w, info.types[i], &n) or_return
            _ = io.write_string(w, " | ",    &n) or_return
            _ = io.write_u64(w, u64(info.bit_sizes[i]), 10, &n) or_return
        }
        _ = io.write_string(w, "}", &n) or_return

    case Type_Info_Simd_Vector:
        _ = io.write_string(w, "#simd[",         &n) or_return
        _ = io.write_i64(w, i64(info.count), 10, &n) or_return
        io.write_byte(w, ']',                &n)     or_return
        _ = write_type_writer(w, info.elem,      &n) or_return
        
    case Type_Info_Matrix:
        if info.layout == .Row_Major {
            _ = io.write_string(w, "#row_major ",   &n) or_return
        }
        _ = io.write_string(w, "matrix[",               &n) or_return
        _ = io.write_i64(w, i64(info.row_count), 10,    &n) or_return
        _ = io.write_string(w, ", ",                    &n) or_return
        _ = io.write_i64(w, i64(info.column_count), 10, &n) or_return
        _ = io.write_string(w, "]",                     &n) or_return
        _ = write_type_writer(w, info.elem,             &n) or_return
    }

    return
}
