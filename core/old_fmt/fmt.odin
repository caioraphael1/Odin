import "base:internal"
import "base:strconv"
import "base:container/slice"

import "core:reflect"
import "core:io/string_builder"

// Hex Values:
@(rodata) __DIGITS_LOWER := "0123456789abcdefx"
@(rodata) __DIGITS_UPPER := "0123456789ABCDEFX"

// Formats a value based on its type and formatting verb
//
// Inputs:
// - b: A pointer to an Info struct containing formatting information.
// - v: The value to be formatted.
// - verb: The formatting verb rune.
//
// NOTE: Uses user formatters if available and not ignored.
fmt_value :: proc(b: ^string_builder.Builder, v: any, verb: rune) -> (n: uint) {
    if v.data == nil || v.id == nil {
        _n, _ := string_builder.write_string(b, "<nil>")
        n += _n
        return
    }

    type_info := type_info_of(v.id)
    #partial switch &info in type_info.variant {
    case reflect.Type_Info_Any:
    case reflect.Type_Info_Parameters:

    // case reflect.Type_Info_Named:
    //     n += fmt_named(b, v, verb, info)

    // case reflect.Type_Info_Boolean,
    //     reflect.Type_Info_Integer,
    //     reflect.Type_Info_Rune,
    //     reflect.Type_Info_Float,
    //     reflect.Type_Info_Complex,
    //     reflect.Type_Info_Quaternion,
    //     reflect.Type_Info_String:
    //     n += fmt_arg(v, verb)

    case reflect.Type_Info_Pointer:
        n += fmt_pointer_from_value(b, v, info, verb)

    // case reflect.Type_Info_Soa_Pointer:
    //     ptr := (^internal.Raw_Soa_Pointer)(v.data)^
    //     n += fmt_soa_pointer(b, ptr, verb)

    // case reflect.Type_Info_Multi_Pointer:
    //     n += fmt_multi_pointer(b, v, info, verb)

    // case reflect.Type_Info_Enumerated_Array:
    //     n += fmt_enumerated_array(b, v, info, verb)

    // case reflect.Type_Info_Array:
    //     n := uint(info.count)
    //     ptr := v.data
    //     n += fmt_array(b, ptr, n, uint(info.elem_size), info.elem, verb)

    // case reflect.Type_Info_Slice:
    //     slice := cast(^slice.Raw_Slice)v.data
    //     n := slice.len
    //     ptr := slice.data
    //     n += fmt_array(b, ptr, n, info.elem_size, info.elem, verb)

    // case reflect.Type_Info_Simd_Vector:
    //     n += string_builder.write_byte(b, '<')
    //     defer n += string_builder.write_byte(b, '>')
    //     for i in 0..<info.count {
    //         if i > 0 { 
    //             _n, _ := string_builder.write_string(b, ", ")
    //             n += _n
    //         }

    //         data := uintptr(v.data) + uintptr(i*info.elem_size)
    //         n += fmt_arg(b, any{rawptr(data), info.elem.id}, verb)
    //     }


    // case reflect.Type_Info_Map:
    //     n += fmt_map(b, v, info, verb)

    // case reflect.Type_Info_Struct:
    //     n += fmt_struct(b, v, verb, info, "")

    // case reflect.Type_Info_Union:
    //     n += fmt_union(b, v, verb, info, uint(type_info.size))

    // case reflect.Type_Info_Enum:
    //     n += fmt_enum(b, v, verb)

    // case reflect.Type_Info_Procedure:
    //     ptr := (^rawptr)(v.data)^
    //     if ptr == nil {
    //         _n, _ := string_builder.write_string(b, "nil")
    //         n += _n
    //     } else {
    //         _n, _ := reflect.write_typeid_writer(b, v.id)
    //         n += _n
    //         _n, _ = string_builder.write_string(b, " @ ")
    //         n += _n
    //         n += fmt_pointer(b, ptr, 'p')
    //     }

    // case reflect.Type_Info_Type_Id:
    //     id := (^typeid)(v.data)^
    //     _n, _ := reflect.write_typeid_writer(b, id)
    //     n += _n
    // case reflect.Type_Info_Bit_Set:
    //     n += fmt_bit_set(b, v, verb = verb)

    // case reflect.Type_Info_Matrix:
    //     n += fmt_matrix(b, v, verb, info)

    // case reflect.Type_Info_Bit_Field:
    //     n += fmt_bit_field(b, v, verb, info, "")
    }
    return
}



@(private)
fmt_pointer_from_value :: proc(b: ^string_builder.Builder, v: any, info: reflect.Type_Info_Pointer, verb: rune) -> (n: uint) {
    if v.id == typeid_of(^reflect.Type_Info) {
        _, _ = reflect.write_type_writer(b, (^^reflect.Type_Info)(v.data)^)
    } else {
        ptr := (^rawptr)(v.data)^
        indirection_level: int
        if verb != 'p' && info.elem != nil {
            a := any{ptr, info.elem.id}

            elem := reflect.type_info_base(info.elem)
            if elem != nil {
                #partial switch &e in elem.variant {
                case reflect.Type_Info_Array,
                     reflect.Type_Info_Slice,
                     reflect.Type_Info_Map:
                    if ptr == nil {
                        _, _ = string_builder.write_string(b, "<nil>")
                        return
                    }
                    if indirection_level < 1 {
                        indirection_level += 1
                        defer indirection_level -= 1
                        _, _ = string_builder.write_byte(b, '&')
                        n += fmt_value(b, a, verb)
                        return
                    }

                case reflect.Type_Info_Struct,
                     reflect.Type_Info_Union,
                     reflect.Type_Info_Bit_Field:
                    if ptr == nil {
                        _, _ = string_builder.write_string(b, "<nil>")
                        return
                    }
                    if indirection_level < 1 {
                        indirection_level += 1
                        defer indirection_level -= 1
                        _, _ = string_builder.write_byte(b, '&')
                        n += fmt_value(b, a, verb)
                        return
                    }
                }
            }
        }
        n += fmt_pointer(b, ptr, verb)
    }
    return
}


// Formats a raw pointer with a specific format.
//
// Inputs:
// - b: Pointer to the Info struct containing format settings.
// - p: The raw pointer to format.
// - verb: The format specifier character (e.g. 'p', 'v', 'b', 'o', 'i', 'd', 'z', 'x', 'X').
fmt_pointer :: proc(b: ^string_builder.Builder, p: rawptr, verb: rune) -> (n: uint) {
    u := u64(uintptr(p))
    switch verb {
    case 'p', 'v', 'w':
        if !b.hash {
            _, _ = string_builder.write_string(b, "0x")
        }
        n += _fmt_int(b, u, 16, false, 8*size_of(rawptr), __DIGITS_UPPER)

    case 'b': n += _fmt_int(b, u,  2, false, 8 * size_of(rawptr), __DIGITS_UPPER)
    case 'o': n += _fmt_int(b, u,  8, false, 8 * size_of(rawptr), __DIGITS_UPPER)
    case 'i', 'd': n += _fmt_int(b, u, 10, false, 8 * size_of(rawptr), __DIGITS_UPPER)
    case 'z': n += _fmt_int(b, u, 12, false, 8 * size_of(rawptr), __DIGITS_UPPER)
    case 'x': n += _fmt_int(b, u, 16, false, 8 * size_of(rawptr), __DIGITS_LOWER)
    case 'X': n += _fmt_int(b, u, 16, false, 8 * size_of(rawptr), __DIGITS_UPPER)

    case:
        n += fmt_bad_verb(b, verb, p)
    }
    return
}

// Writes a bad verb error message
//
// Inputs:
// - b: A pointer to an Info structure
// - verb: The invalid format verb
fmt_bad_verb :: proc(b: ^string_builder.Builder, verb: rune, arg: any) -> (n: uint) {
    _, _ = string_builder.write_string(b, "%!")
    _, _ = string_builder.write_rune(b, verb)
    _, _ = string_builder.write_byte(b, '(')
    if arg != nil {
        _, _ = reflect.write_typeid_writer(b, arg.id)
        _, _ = string_builder.write_byte(b, '=')
        _ = fmt_value(b, arg, 'v')
    } else {
        _, _ = string_builder.write_string(b, "<nil>")
    }
    _, _ = string_builder.write_byte(b, ')')
    return
}


// Formats an integer value with specified base, sign, bit size, and digits
//
// Inputs:
// - b: A pointer to an Info structure
// - u: The integer value to format
// - base: The base for integer formatting
// - is_signed: A boolean indicating if the integer is signed
// - bit_size: The bit size of the integer
// - digits: A string containing the digits for formatting
//
// WARNING: May panic if the width and precision are too big, causing a buffer overrun
_fmt_int :: proc(b: ^string_builder.Builder, u: u64, base: uint, is_signed: bool, bit_size: uint, precision: uint, digits: string) -> (n: uint) {
    _, neg := strconv.is_integer_negative(u, is_signed, bit_size)

    BUF_SIZE :: 256
    if b.width_set || b.prec_set {
        width := b.width + b.prec + 3 // 3 extra bytes for sign and prefix
        if width > BUF_SIZE {
            // TODO(bill):????
            internal.panic("_fmt_int: buffer overrun. Width and precision too big")
        }
    }

    start: uint

    if !is_signed {
        switch base {
        case 2:
            _, _ = string_builder.write_byte(b, '0')
            _, _ = string_builder.write_byte(b, 'b')
            start = 2

        case 8:
            _, _ = string_builder.write_byte(b, '0')
            _, _ = string_builder.write_byte(b, 'o')
            start = 2

        case 10:
            // ignore

        case 12:
            _, _ = string_builder.write_byte(b, '0')
            _, _ = string_builder.write_byte(b, 'z')
            start = 2

        case 16:
            _, _ = string_builder.write_byte(b, '0')
            _, _ = string_builder.write_byte(b, 'x')
            start = 2
        case:
            internal.panic("_fmt_int: base is not in [2, 8, 10, 12, 16]")
        }
    }

    if prec == 0 && u == 0 {
        fmt_write_padding(b, b)
        return
    }


    buf: [BUF_SIZE]u8
    flags: strconv.Int_Flags
    s := strconv.write_bits(buf[start:], u, base, is_signed, bit_size, digits, flags)

    
    _pad(b, s)
}


/*

// Formats a named type into a string representation
//
// Inputs:
// - b: Pointer to the formatting Info struct.
// - v: The value to format.
// - verb: The formatting verb.
// - info: The named type information.
//
// NOTE: This procedure supports built-in custom formatters for core library types such as internal.Source_Code_Location, time.Duration, and time.Time.
fmt_named :: proc(b: ^string_builder.Builder, v: any, verb: rune, info: reflect.Type_Info_Named) {
    // Built-in Custom Formatters for core library types
    // TODO: caio
    // if verb != 'w' && fmt_named_buitlin_custom_formatters(b, v, verb, info) {
    //     return
    // }

    #partial switch &base in info.base.variant {
    case reflect.Type_Info_Struct:
        fmt_struct(b, v, verb, base, info.name)
    case reflect.Type_Info_Bit_Field:
        fmt_bit_field(b, v, verb, base, info.name)
    case reflect.Type_Info_Bit_Set:
        fmt_bit_set(b, v, verb = verb)
    case:
        if verb == 'w' {
            #partial switch _ in info.base.variant {
            case reflect.Type_Info_Array,
                reflect.Type_Info_Enumerated_Array,
                reflect.Type_Info_Slice,
                reflect.Type_Info_Struct,
                reflect.Type_Info_Enum,
                reflect.Type_Info_Map,
                reflect.Type_Info_Bit_Set,
                reflect.Type_Info_Simd_Vector,
                reflect.Type_Info_Matrix,
                reflect.Type_Info_Bit_Field:
                _, _ = string_builder.write_string(b, info.name)
            }
        }
        fmt_value(b, any{v.data, info.base.id}, verb)
    }
}

// Formats a union type into a string representation
//
// Inputs:
// - b: Pointer to the formatting Info struct.
// - v: The value to format.
// - verb: The formatting verb.
// - info: The union type information.
// - type_size: The size of the union type.
fmt_union :: proc(b: ^string_builder.Builder, v: any, verb: rune, info: reflect.Type_Info_Union, type_size: uint) {
    if type_size == 0 {
        _, _ = string_builder.write_string(b, "nil")
        return
    }

    if reflect.type_info_union_is_pure_maybe(info) {
        if v.data == nil {
            _, _ = string_builder.write_string(b, "nil")
        } else {
            id := info.variants[0].id
            fmt_arg(b, any{v.data, id}, verb)
        }
        return
    }

    tag: i64 = -1
    tag_ptr := uintptr(v.data) + info.tag_offset
    tag_any := any{rawptr(tag_ptr), info.tag_type.id}

    switch i in tag_any {
    case u8:   tag = i64(i)
    case i8:   tag = i64(i)
    case u16:  tag = i64(i)
    case i16:  tag = i64(i)
    case u32:  tag = i64(i)
    case i32:  tag = i64(i)
    case u64:  tag = i64(i)
    case i64:  tag = i
    case: internal.panic("Invalid union tag type")
    }
    internal.assert(tag >= 0)

    if v.data == nil {
        _, _ = string_builder.write_string(b, "nil")
    } else if info.no_nil {
        id := info.variants[tag].id
        fmt_arg(b, any{v.data, id}, verb)
    } else if tag == 0 {
        _, _ = string_builder.write_string(b, "nil")
    } else {
        id := info.variants[tag-1].id
        fmt_arg(b, any{v.data, id}, verb)
    }
}

// Formats a matrix as a string
//
// Inputs:
// - b: A pointer to an Info struct containing formatting information.
// - v: The matrix value to be formatted.
// - verb: The formatting verb rune.
// - info: A reflect.Type_Info_Matrix struct containing matrix type information.
fmt_matrix :: proc(b: ^string_builder.Builder, v: any, verb: rune, info: reflect.Type_Info_Matrix) {
    if verb == 'w' {
        _ = string_builder.write_byte(b, '{')
    } else {
        _, _ = string_builder.write_string(b, "matrix")
        _ = string_builder.write_byte(b, '[')
    }
    defer _ = string_builder.write_byte(b, ']' if verb != 'w' else '}')

    b.indent += 1

    if b.hash {
        // Printed as it is written
        _ = string_builder.write_byte(b, '\n')
        for row in 0..<info.row_count {
            fmt_write_indent(b)
            for col in 0..<info.column_count {
                if col > 0 { _, _ = string_builder.write_string(b, ", ") }

                offset: uint
                switch info.layout {
                case .Column_Major: offset = uint(row + col * info.elem_stride) * uint(info.elem_size)
                case .Row_Major:    offset = uint(col + row * info.elem_stride) * uint(info.elem_size)
                }

                data := uintptr(v.data) + uintptr(offset)
                fmt_arg(b, any{rawptr(data), info.elem.id}, verb)
            }
            _, _ = string_builder.write_string(b, ",\n")
        }
    } else {
        // Printed in Row-Major layout to match text layout
        row_separator := ", " if verb == 'w' else "; "
        for row in 0..<info.row_count {
            if row > 0 { _, _ = string_builder.write_string(b, row_separator) }
            for col in 0..<info.column_count {
                if col > 0 { _, _ = string_builder.write_string(b, ", ") }

                offset: uint
                switch info.layout {
                case .Column_Major: offset = uint(row + col * info.elem_stride) * uint(info.elem_size)
                case .Row_Major:    offset = uint(col + row * info.elem_stride) * uint(info.elem_size)
                }

                data := uintptr(v.data) + uintptr(offset)
                fmt_arg(b, any{rawptr(data), info.elem.id}, verb)
            }
        }
    }

    b.indent -= 1

    if b.hash {
        fmt_write_indent(b)
    }
}

fmt_bit_field :: proc(b: ^string_builder.Builder, v: any, verb: rune, info: reflect.Type_Info_Bit_Field, type_name: string) {
    read_bits :: proc(ptr: [^]u8, offset, size: uintptr) -> (res: u64) {
        for i in 0..<size {
            j := i+offset
            B := ptr[j/8]
            k := j&7
            if B & (u8(1)<<k) != 0 {
                res |= u64(1)<<u64(i)
            }
        }
        return
    }

    handle_bit_field_tag :: proc(data: rawptr, info: reflect.Type_Info_Bit_Field, idx: uint, verb: ^rune) -> (do_continue: bool) {
        tag := info.tags[idx]
        if vt, ok := reflect.struct_tag_lookup(reflect.Struct_Tag(tag), "fmt"); ok {
            value := strings_tools.trim_space(string(vt))
            switch value {
            case "": return false
            case "-": return true
            }
            r, w := utf8.rune_from_string(value)
            value = value[w:]
            if value == "" || value[0] == ',' {
                verb^ = r
            }
        }
        return false
    }

    _, _ = string_builder.write_string(b, type_name if len(type_name) != 0 || verb == 'w' else "bit_field")
    _ = string_builder.write_byte(b, '{')

    hash   := b.hash;   defer b.hash = hash
    indent := b.indent; defer b.indent -= 1
    do_trailing_comma := hash

    b.indent += 1

    if hash {
        _ = string_builder.write_byte(b, '\n')
    }
    defer {
        if hash {
            for _ in 0..<indent { _ = string_builder.write_byte(b, '\t') }
        }
        _ = string_builder.write_byte(b, '}')
    }


    field_count := -1
    for name, i in info.names[:info.field_count] {
        field_verb := verb
        if handle_bit_field_tag(v.data, info, i, &field_verb) {
            continue
        }

        field_count += 1

        if !do_trailing_comma && field_count > 0 {
            _, _ = string_builder.write_string(b, ", ")
        }
        if hash {
            fmt_write_indent(b)
        }

        _, _ = string_builder.write_string(b, name)
        _, _ = string_builder.write_string(b, " = ")

        bit_offset := info.bit_offsets[i]
        bit_size := info.bit_sizes[i]

        type := info.types[i]
        value := read_bits(([^]u8)(v.data), bit_offset, bit_size)
        if reflect.is_endian_big(type) {
            value <<= u64(8*type.size) - u64(bit_size)
        }

        if !reflect.is_unsigned(reflect.type_info_core(type)) {
            // Sign Extension
            m := u64(1<<(bit_size-1))
            value = (value ~ m) - m
        }

        fmt_value(b, any{&value, type.id}, field_verb)
        if do_trailing_comma { _, _ = string_builder.write_string(b, ",\n") }

    }
}



@(private)
fmt_multi_pointer :: proc(b: ^string_builder.Builder, v: any, info: reflect.Type_Info_Multi_Pointer, verb: rune) {
    ptr := (^rawptr)(v.data)^
    if ptr == nil {
        _, _ = string_builder.write_string(b, "<nil>")
        return
    }
    if verb != 'p' && info.elem != nil {
        a := any{ptr, info.elem.id}

        elem := reflect.type_info_base(info.elem)
        if elem != nil {
            if n, ok := b.optional_len.?; ok {
                b.optional_len = nil
                fmt_array(b, ptr, n, uint(elem.size), elem, verb)
                return
            } else if b.use_nul_termination {
                b.use_nul_termination = false
                fmt_array_nul_terminated(b, ptr, -1, uint(elem.size), elem, verb)
                return
            }

            #partial switch &e in elem.variant {
            case reflect.Type_Info_Integer:
                switch verb {
                case 's', 'q':
                    switch elem.id {
                    case u8:
                        fmt_cstring(b, cstring(ptr), verb)
                        return
                    case u16, u32, rune:
                        n := search_nul_termination(ptr, uint(elem.size), -1)
                        fmt_array(b, ptr, n, uint(elem.size), elem, verb)
                        return
                    }
                }

            case reflect.Type_Info_Array,
                 reflect.Type_Info_Slice,
                 reflect.Type_Info_Map:
                if b.indirection_level < 1 {
                    b.indirection_level += 1
                    defer b.indirection_level -= 1
                    _ = string_builder.write_byte(b, '&')
                    fmt_value(b, a, verb)
                    return
                }

            case reflect.Type_Info_Struct,
                 reflect.Type_Info_Union:
                if b.indirection_level < 1 {
                    b.indirection_level += 1
                    defer b.indirection_level -= 1
                    _ = string_builder.write_byte(b, '&')
                    fmt_value(b, a, verb)
                    return
                }
            }
        }
    }
    fmt_pointer(b, ptr, verb)
}

fmt_enumerated_array :: proc(b: ^string_builder.Builder, v: any, info: reflect.Type_Info_Enumerated_Array, verb: rune) {
    b.record_level += 1
    defer b.record_level -= 1

    if b.hash {
        _ = string_builder.write_byte(b, '[' if verb != 'w' else '{')
        _ = string_builder.write_byte(b, '\n')
        defer {
            fmt_write_indent(b)
            _ = string_builder.write_byte(b, ']' if verb != 'w' else '}')
        }
        indent := b.indent
        b.indent += 1
        defer b.indent = indent

        for i in 0..<info.count {
            fmt_write_indent(b)

            idx, ok := stored_enum_value_to_string(info.index, info.min_value, uint(i))
            if ok {
                _ = string_builder.write_byte(b, '.')
                _, _ = string_builder.write_string(b, idx)
            } else {
                _, _ = string_builder.write_i64(b, i64(info.min_value)+i64(i), 10)
            }
            _, _ = string_builder.write_string(b, " = ")

            data := uintptr(v.data) + uintptr(i*info.elem_size)
            fmt_arg(b, any{rawptr(data), info.elem.id}, verb)

            _, _ = string_builder.write_string(b, ",\n")
        }
    } else {
        _ = string_builder.write_byte(b, '[' if verb != 'w' else '{')
        defer _ = string_builder.write_byte(b, ']' if verb != 'w' else '}')
        for i in 0..<info.count {
            if i > 0 { _, _ = string_builder.write_string(b, ", ") }

            idx, ok := stored_enum_value_to_string(info.index, info.min_value, uint(i))
            if ok {
                _ = string_builder.write_byte(b, '.')
                _, _ = string_builder.write_string(b, idx)
            } else {
                _, _ = string_builder.write_i64(b, i64(info.min_value)+i64(i), 10)
            }
            _, _ = string_builder.write_string(b, " = ")

            data := uintptr(v.data) + uintptr(i*info.elem_size)
            fmt_arg(b, any{rawptr(data), info.elem.id}, verb)
        }
    }
}

fmt_map :: proc(b: ^string_builder.Builder, v: any, info: reflect.Type_Info_Map, verb: rune) {
    switch verb {
    case:
        fmt_bad_verb(b, verb)
    case 'v', 'w':
        if verb == 'v' {
            _, _ = string_builder.write_string(b, "map")
        }
        _ = string_builder.write_byte(b, '[' if verb != 'w' else '{')
        defer _ = string_builder.write_byte(b, ']' if verb != 'w' else '}')


        hash   := b.hash;   defer b.hash = hash
        indent := b.indent; defer b.indent -= 1
        do_trailing_comma := hash

        b.indent += 1
        if hash {
            _ = string_builder.write_byte(b, '\n')
        }
        defer {
            if hash {
                for _ in 0..<indent { _ = string_builder.write_byte(b, '\t') }
            }
        }

        m := (^maps.Raw_Map)(v.data)
        if m != nil {
            if info.map_info == nil {
                return
            }
            map_cap := uintptr(internal.map_cap(m^))
            ks, vs, hs, _, _ := internal.map_kvh_data_dynamic(m^, info.map_info)
            j := 0
            for bucket_index in 0..<map_cap {
                maps.hash_is_valid(hs[bucket_index]) or_continue

                if !do_trailing_comma && j > 0 { _, _ = string_builder.write_string(b, ", ") }
                if hash {
                    fmt_write_indent(b)
                }
                j += 1

                key   := internal.map_cell_index_dynamic(ks, info.map_info.ks, bucket_index)
                value := internal.map_cell_index_dynamic(vs, info.map_info.vs, bucket_index)

                fmt_arg(&Info{writer = b}, any{rawptr(key), info.key.id}, verb)
                if hash {
                    _, _ = string_builder.write_string(b, " = ")
                } else {
                    _, _ = string_builder.write_string(b, "=")
                }
                fmt_arg(b, any{rawptr(value), info.value.id}, verb)

                if do_trailing_comma { _, _ = string_builder.write_string(b, ",\n") }
            }
        }
    }

}

// Formats a NUL-terminated array into a string representation
//
// Inputs:
// - b: Pointer to the formatting Info struct.
// - data: The raw pointer to the array data.
// - max_n: The maximum number of elements to process.
// - elem_size: The size of each element in the array.
// - elem: Pointer to the type information of the array element.
// - verb: The formatting verb.
fmt_array_nul_terminated :: proc(b: ^string_builder.Builder, data: rawptr, max_n: int, elem_size: uint, elem: ^reflect.Type_Info, verb: rune) {
    if data == nil {
        _, _ = string_builder.write_string(b, "<nil>")
        return
    }
    n := search_nul_termination(data, elem_size, max_n)
    fmt_array(b, data, n, elem_size, elem, verb)
}

// Formats an array into a string representation
//
// Inputs:
// - b: Pointer to the formatting Info struct.
// - data: The raw pointer to the array data.
// - n: The number of elements in the array.
// - elem_size: The size of each element in the array.
// - elem: Pointer to the type information of the array element.
// - verb: The formatting verb (e.g. 's','q','p','w').
fmt_array :: proc(b: ^string_builder.Builder, data: rawptr, n: uint, elem_size: uint, elem: ^reflect.Type_Info, verb: rune) {
    if data == nil && n > 0 {
        _, _ = string_builder.write_string(b, "nil")
        return
    }
    if verb == 's' || verb == 'q' {
        print_utf16 :: proc(b: ^string_builder.Builder, s: []$T) where size_of(T) == 2, intrinsics.type_is_integer(T) {
            REPLACEMENT_CHAR :: '\ufffd'
            _surr1           :: 0xd800
            _surr2           :: 0xdc00
            _surr3           :: 0xe000
            _surr_self       :: 0x10000

            for i: uint = 0; i < len(s); i += 1 {
                r := rune(REPLACEMENT_CHAR)

                switch c := s[i]; {
                case c < _surr1, _surr3 <= c:
                    r = rune(c)
                case _surr1 <= c && c < _surr2 && i+1 < len(s) &&
                    _surr2 <= s[i+1] && s[i+1] < _surr3:
                    r1, r2 := rune(c), rune(s[i+1])
                    if _surr1 <= r1 && r1 < _surr2 && _surr2 <= r2 && r2 < _surr3 {
                        r = (r1-_surr1)<<10 | (r2 - _surr2) + _surr_self
                    }
                    i += 1
                }
                _, _ = string_builder.write_rune(b, r)
            }
        }

        print_utf32 :: proc(b: ^string_builder.Builder, s: []$T) where size_of(T) == 4 {
            for r in s {
                _, _ = string_builder.write_rune(b, rune(r))
            }
        }

        switch reflect.type_info_base(elem).id {
        case u8:  fmt_string(b,   string  (([^]u8)(data)[:n]), verb); return
        case u16:   fmt_string16(b, string16(([^]u16) (data)[:n]), verb); return
        case u16le: print_utf16(b, ([^]u16le)(data)[:n]); return
        case u16be: print_utf16(b, ([^]u16be)(data)[:n]); return
        case u32:   print_utf32(b, ([^]u32)(data)[:n]);   return
        case u32le: print_utf32(b, ([^]u32le)(data)[:n]); return
        case u32be: print_utf32(b, ([^]u32be)(data)[:n]); return
        case rune:  print_utf32(b, ([^]rune)(data)[:n]);  return
        }
    }
    if verb == 'p' {
        fmt_pointer(b, data, 'p')
    } else {
        fmt_write_array(b, data, n, elem_size, elem.id, verb)
    }
}



// Formats a struct for output, handling various struct types (e.g., SOA, raw unions)
//
// Inputs:
// - b: A mutable pointer to an Info struct containing formatting state
// - v: The value to be formatted
// - the_verb: The formatting verb to be used (e.g. 'v')
// - info: Type information about the struct
// - type_name: The name of the type being formatted
fmt_struct :: proc(b: ^string_builder.Builder, v: any, the_verb: rune, info: reflect.Type_Info_Struct, type_name: string) {
    if the_verb != 'v' && the_verb != 'w' {
        fmt_bad_verb(b, the_verb)
        return
    }
    if .raw_union in info.flags {
        if _handle_raw_union_tag(b, v, the_verb, info, type_name) {
            return
        }
        if type_name == "" {
            _, _ = string_builder.write_string(b, "(#raw_union)")
        } else {
            _, _ = string_builder.write_string(b, type_name)
            _, _ = string_builder.write_string(b, "{}")
        }
        return
    }

    is_soa := info.soa_kind != .None

    _, _ = string_builder.write_string(b, type_name)
    _ = string_builder.write_byte(b, '[' if is_soa && the_verb == 'v' else '{')
    b.record_level += 1
    defer b.record_level -= 1

    hash   := b.hash;   defer b.hash = hash
    indent := b.indent; defer b.indent -= 1
    do_trailing_comma := hash

    // b.hash = false;
    b.indent += 1

    is_empty := info.field_count == 0

    if !is_soa && hash && !is_empty {
        _ = string_builder.write_byte(b, '\n')
    }
    defer {
        if !is_soa && hash && !is_empty {
            for _ in 0..<indent { _ = string_builder.write_byte(b, '\t') }
        }
        _ = string_builder.write_byte(b, ']' if is_soa && the_verb == 'v' else '}')
    }

    if is_soa {
        fmt_soa_struct_internal(b, v, the_verb, info, type_name, hash, indent)
    } else {
        field_count := -1
        for name, i in info.names[:info.field_count] {
            optional_len: int = -1
            use_nul_termination: bool = false
            verb := the_verb if the_verb == 'w' else 'v'

            new_state := b.state
            new_state.parent_struct = v

            if handle_tag(&new_state, v.data, info, i, &verb, &optional_len, &use_nul_termination) {
                continue
            }
            field_count += 1

            if optional_len >= 0 {
                b.optional_len = uint(optional_len)
            }
            defer if optional_len >= 0 {
                b.optional_len = nil
            }
            b.use_nul_termination = use_nul_termination
            defer b.use_nul_termination = false

            if !do_trailing_comma && field_count > 0 { _, _ = string_builder.write_string(b, ", ") }
            if hash {
                fmt_write_indent(b)
            }

            _, _ = string_builder.write_string(b, name)
            _, _ = string_builder.write_string(b, " = ")

            if t := info.types[i]; reflect.is_any(t) {
                _, _ = string_builder.write_string(b, "any{}")
            } else {
                prev_state := b.state
                b.state = new_state
                data := rawptr(uintptr(v.data) + info.offsets[i])
                fmt_arg(b, any{data, t.id}, verb)
                b.state = prev_state
            }

            if do_trailing_comma { _, _ = string_builder.write_string(b, ",\n") }
        }
    }
}

@(private)
fmt_soa_struct_internal :: proc(b: ^string_builder.Builder, v: any, the_verb: rune, info: reflect.Type_Info_Struct, type_name: string, hash: bool, indent: uint) {
    is_empty := info.field_count == 0

    b.indent += 1
    defer b.indent -= 1

    base_type_name: string
    if v, ok := info.soa_base_type.variant.(reflect.Type_Info_Named); ok {
        base_type_name = v.name
    }

    actual_field_count := info.field_count

    n := uintptr(info.soa_len)

    if info.soa_kind == .Slice {
        actual_field_count = info.field_count-1 // len

        n = uintptr((^uint)(uintptr(v.data) + info.offsets[actual_field_count])^)

    }

    if hash && n > 0 {
        _ = string_builder.write_byte(b, '\n')
    }

    for index in 0..<n {
        if !hash && index > 0 { _, _ = string_builder.write_string(b, ", ") }

        field_count := -1

        if !hash && field_count > 0 { _, _ = string_builder.write_string(b, ", ") }

        if hash {
            b.indent -= 1
            fmt_write_indent(b)
            b.indent += 1
        }
        _, _ = string_builder.write_string(b, base_type_name)
        _ = string_builder.write_byte(b, '{')
        if hash && !is_empty { _ = string_builder.write_byte(b, '\n') }
        defer {
            if hash && !is_empty {
                b.indent -= 1
                fmt_write_indent(b)
                b.indent += 1
            }
            _ = string_builder.write_byte(b, '}')
            if hash { _, _ = string_builder.write_string(b, ",\n") }
        }
        b.record_level += 1
        defer b.record_level -= 1

        for i in 0..<actual_field_count {
            verb := 'v'
            name := info.names[i]
            field_count += 1

            if !hash && field_count > 0 { _, _ = string_builder.write_string(b, ", ") }
            if hash {
                fmt_write_indent(b)
            }

            _, _ = string_builder.write_string(b, name)
            _, _ = string_builder.write_string(b, " = ")

            if info.soa_kind == .Fixed {
                t := info.types[i].variant.(reflect.Type_Info_Array).elem
                t_size := uintptr(t.size)
                if reflect.is_any(t) {
                    _, _ = string_builder.write_string(b, "any{}")
                } else {
                    data := rawptr(uintptr(v.data) + info.offsets[i] + index*t_size)
                    fmt_arg(b, any{data, t.id}, verb)
                }
            } else {
                t := info.types[i].variant.(reflect.Type_Info_Multi_Pointer).elem
                t_size := uintptr(t.size)
                if reflect.is_any(t) {
                    _, _ = string_builder.write_string(b, "any{}")
                } else {
                    field_ptr := (^^u8)(uintptr(v.data) + info.offsets[i])^
                    data := rawptr(uintptr(field_ptr) + index*t_size)
                    fmt_arg(b, any{data, t.id}, verb)
                }
            }

            if hash { _, _ = string_builder.write_string(b, ",\n") }
        }
    }

    if hash && n > 0 {
        for _ in 0..<indent { _ = string_builder.write_byte(b, '\t') }
    }
}


// Formats a complex number based on the given formatting verb
//
// Inputs:
// - b: A pointer to an Info struct containing formatting information.
// - c: The complex128 value to be formatted.
// - bits: The number of bits in the complex number (32 or 64).
// - verb: The formatting verb rune ('f', 'F', 'v', 'h', 'H', 'w').
fmt_complex :: proc(b: ^string_builder.Builder, c: complex128, bits: uint, verb: rune) {
    switch verb {
    case 'f', 'F', 'v', 'h', 'H', 'w':
        r, i := real(c), imag(c)
        fmt_float(b, r, bits/2, verb)
        if _cq_should_print_intermediate_plus(b, i) {
            _, _ = string_builder.write_rune(b, '+')
        }
        fmt_float(b, i, bits/2, verb)
        _, _ = string_builder.write_rune(b, 'i')

    case:
        fmt_bad_verb(b, verb)
        return
    }
}

// Formats a quaternion number based on the given formatting verb
//
// Inputs:
// - b: A pointer to an Info struct containing formatting information.
// - q: The quaternion256 value to be formatted.
// - bits: The number of bits in the quaternion number (64, 128, or 256).
// - verb: The formatting verb rune ('f', 'F', 'v', 'h', 'H', 'w').
fmt_quaternion  :: proc(b: ^string_builder.Builder, q: quaternion256, bits: uint, verb: rune) {
    switch verb {
    case 'f', 'F', 'v', 'h', 'H', 'w':
        r, i, j, k := real(q), imag(q), jmag(q), kmag(q)

        fmt_float(b, r, bits/4, verb)

        if _cq_should_print_intermediate_plus(b, i) {
            _, _ = string_builder.write_rune(b, '+')
        }
        fmt_float(b, i, bits/4, verb)
        _, _ = string_builder.write_rune(b, 'i')

        if _cq_should_print_intermediate_plus(b, j) {
            _, _ = string_builder.write_rune(b, '+')
        }
        fmt_float(b, j, bits/4, verb)
        _, _ = string_builder.write_rune(b, 'j')

        if _cq_should_print_intermediate_plus(b, k) {
            _, _ = string_builder.write_rune(b, '+')
        }
        fmt_float(b, k, bits/4, verb)
        _, _ = string_builder.write_rune(b, 'k')

    case:
        fmt_bad_verb(b, verb)
        return
    }
}

// Formats an argument based on its type and the given formatting verb
//
// Inputs:
// - b: A pointer to an Info struct containing formatting information.
// - arg: The value to be formatted.
// - verb: The formatting verb rune (e.g. 'T').
//
// NOTE: Uses user formatters if available and not ignored.
fmt_arg :: proc(b: ^string_builder.Builder, arg: any, verb: rune) -> (n: uint) {
    if arg == nil {
        _, _ = string_builder.write_string(b, "<nil>")
        return
    }
    b.arg = arg

    if verb == 'T' {
        ti := type_info_of(arg.id)
        switch a in arg {
        case ^reflect.Type_Info: ti = a
        }
        _, _ = reflect.write_type_writer(b, ti)
        return
    }

    if _user_formatters != nil {
        formatter := _user_formatters[arg.id]
        if formatter != nil {
            if ok := formatter(b, arg, verb); !ok {
                fmt_bad_verb(b, verb)
            }
            return
        }
    }

    arg_info := type_info_of(arg.id)
    if info, ok := arg_info.variant.(reflect.Type_Info_Named); ok {
        fmt_named(b, arg, verb, info)
        return
    }

    base_arg := arg
    base_arg.id = reflect.typeid_base(base_arg.id)
    switch &a in base_arg {
    case bool:       fmt_bool(b, a, verb)
    case b8:         fmt_bool(b, bool(a), verb)
    case b16:        fmt_bool(b, bool(a), verb)
    case b32:        fmt_bool(b, bool(a), verb)
    case b64:        fmt_bool(b, bool(a), verb)

    case any:        fmt_arg(b,  a, verb)
    case rune:       fmt_rune(b, a, verb)

    case f16:        fmt_float(b, f64(a), 16, verb)
    case f32:        fmt_float(b, f64(a), 32, verb)
    case f64:        fmt_float(b, a,      64, verb)

    case f16le:      fmt_float(b, f64(a), 16, verb)
    case f32le:      fmt_float(b, f64(a), 32, verb)
    case f64le:      fmt_float(b, f64(a), 64, verb)

    case f16be:      fmt_float(b, f64(a), 16, verb)
    case f32be:      fmt_float(b, f64(a), 32, verb)
    case f64be:      fmt_float(b, f64(a), 64, verb)

    case complex32:  fmt_complex(b, complex128(a), 32, verb)
    case complex64:  fmt_complex(b, complex128(a), 64, verb)
    case complex128: fmt_complex(b, a, 128, verb)

    case quaternion64:  fmt_quaternion(b, quaternion256(a),  64, verb)
    case quaternion128: fmt_quaternion(b, quaternion256(a), 128, verb)
    case quaternion256: fmt_quaternion(b, a, 256, verb)

    case i8:      fmt_int(b, u64(a), true,   8, verb)
    case u8:      fmt_int(b, u64(a), false,  8, verb)
    case i16:     fmt_int(b, u64(a), true,  16, verb)
    case u16:     fmt_int(b, u64(a), false, 16, verb)
    case i32:     fmt_int(b, u64(a), true,  32, verb)
    case u32:     fmt_int(b, u64(a), false, 32, verb)
    case i64:     fmt_int(b, u64(a), true,  64, verb)
    case u64:     fmt_int(b,     a,  false, 64, verb)
    case int:     fmt_int(b, u64(a), true,  8*size_of(int), verb)
    case uint:    fmt_int(b, u64(a), false, 8*size_of(uint), verb)
    case uintptr: fmt_int(b, u64(a), false, 8*size_of(uintptr), verb)

    case string:  fmt_string(b, a, verb)
    case cstring: fmt_cstring(b, a, verb)

    case string16:  fmt_string16(b, a, verb)
    case cstring16: fmt_cstring16(b, a, verb)

    case typeid:  _, _ = reflect.write_typeid_writer(b, a)

    case i16le:     fmt_int(b, u64(a), true,  16, verb)
    case u16le:     fmt_int(b, u64(a), false, 16, verb)
    case i32le:     fmt_int(b, u64(a), true,  32, verb)
    case u32le:     fmt_int(b, u64(a), false, 32, verb)
    case i64le:     fmt_int(b, u64(a), true,  64, verb)
    case u64le:     fmt_int(b, u64(a), false, 64, verb)

    case i16be:     fmt_int(b, u64(a), true,  16, verb)
    case u16be:     fmt_int(b, u64(a), false, 16, verb)
    case i32be:     fmt_int(b, u64(a), true,  32, verb)
    case u32be:     fmt_int(b, u64(a), false, 32, verb)
    case i64be:     fmt_int(b, u64(a), true,  64, verb)
    case u64be:     fmt_int(b, u64(a), false, 64, verb)

    case i128:     fmt_int_128(b, u128(a), true,  128, verb)
    case u128:     fmt_int_128(b,       a, false, 128, verb)

    case i128le:   fmt_int_128(b, u128(a), true,  128, verb)
    case u128le:   fmt_int_128(b, u128(a), false, 128, verb)

    case i128be:   fmt_int_128(b, u128(a), true,  128, verb)
    case u128be:   fmt_int_128(b, u128(a), false, 128, verb)

    case: fmt_value(b, arg, verb)
    }
}


// Formats a boolean value according to the specified format verb
//
// Inputs:
// - b: A pointer to an Info structure
// - b: The boolean value to format
// - verb: The format verb
fmt_bool :: proc(b: ^string_builder.Builder, bl: bool, verb: rune) {
    switch verb {
    case 't', 'v', 'w':
        fmt_string(b, bl ? "true" : "false", 's')
    case:
        fmt_bad_verb(b, verb)
    }
}

// Formats a bit set and writes it to the provided Info structure
//
// Inputs:
// - b: A pointer to the Info structure where the formatted bit set will be written.
// - v: The bit set value to be formatted.
// - name: An optional string for the name of the bit set (default is an empty string).
// - verb: An optional verb to adjust format.
fmt_bit_set :: proc(b: ^string_builder.Builder, v: any, name: string = "", verb: rune = 'v') {
    is_bit_set_different_endian_to_platform :: proc(ti: ^reflect.Type_Info) -> bool {
        if ti == nil {
            return false
        }
        t := reflect.type_info_base(ti)
        #partial switch &info in t.variant {
        case reflect.Type_Info_Integer:
            switch info.endianness {
            case .Platform: return false
            case .Little:   return ODIN_ENDIAN != .Little
            case .Big:      return ODIN_ENDIAN != .Big
            }
        }
        return false
    }

    byte_swap :: bits.byte_swap

    type_info := type_info_of(v.id)
    #partial switch &info in type_info.variant {
    case reflect.Type_Info_Named:
        val := v
        val.id = info.base.id
        fmt_bit_set(b, val, info.name, verb)

    case reflect.Type_Info_Bit_Set:
        bits: u128
        bit_size := u128(8*type_info.size)

        do_byte_swap := is_bit_set_different_endian_to_platform(info.underlying)

        as_arg := verb == 'b' || verb == 'o' || verb == 'd' || verb == 'i' || verb == 'z' || verb == 'x' || verb == 'X'
        if as_arg && !b.width_set {
            b.width_set = true
            b.width = uint(bit_size)
        }

        switch bit_size {
        case  0: bits = 0
        case  8:
            x := (^u8)(v.data)^
            if as_arg {
                fmt_arg(b, x, verb)
                return
            }
            bits = u128(x)
        case 16:
            x := (^u16)(v.data)^
            if do_byte_swap { x = byte_swap(x) }
            if as_arg {
                fmt_arg(b, x, verb)
                return
            }
            bits = u128(x)
        case 32:
            x := (^u32)(v.data)^
            if do_byte_swap { x = byte_swap(x) }
            if as_arg {
                fmt_arg(b, x, verb)
                return
            }
            bits = u128(x)
        case 64:
            x := (^u64)(v.data)^
            if do_byte_swap { x = byte_swap(x) }
            if as_arg {
                fmt_arg(b, x, verb)
                return
            }
            bits = u128(x)
        case 128:
            x := (^u128)(v.data)^
            if do_byte_swap { x = byte_swap(x) }
            if as_arg {
                fmt_arg(b, x, verb)
                return
            }
            bits = x
        case: internal.panic("unknown bit_size size")
        }

        et := reflect.type_info_base(info.elem)

        if verb != 'w' {
            if name != "" {
                _, _ = string_builder.write_string(b, name)
            } else {
                _, _ = reflect.write_type_writer(b, type_info)
            }
        }
        _ = string_builder.write_byte(b, '{')
        defer _ = string_builder.write_byte(b, '}')

        e, is_enum := et.variant.(reflect.Type_Info_Enum)
        commas := 0
        loop: for i in transmute(bit_set[0..<128])bits {
            i := i64(i) + info.lower
            if commas > 0 {
                _, _ = string_builder.write_string(b, ", ")
            }

            if is_enum {
                enum_name: string
                if ti_named, is_named := info.elem.variant.(reflect.Type_Info_Named); is_named {
                    enum_name = ti_named.name
                }
                for ev, evi in e.values {
                    v := u64(ev)
                    if v == u64(i) {
                        if verb == 'w' {
                            _, _ = string_builder.write_string(b, enum_name)
                            _ = string_builder.write_byte(b, '.')
                        }
                        _, _ = string_builder.write_string(b, e.names[evi])
                        commas += 1
                        continue loop
                    }
                }
            }
            _, _ = string_builder.write_i64(b, i, 10)
            commas += 1
        }
    }
}

*/
