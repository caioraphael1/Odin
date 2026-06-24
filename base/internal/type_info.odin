#+no-instrumentation
import "base:intrinsics"


//--------------------------------------------------------------------------------------------------
// Type Info
//--------------------------------------------------------------------------------------------------

// IMPORTANT NOTE(bill): `type_info_of` cannot be used within a
// #shared_global_scope due to  the internals of the compiler.
// This could change at a later date if all these data structures are
// implemented within the compiler rather than in this "preload" file

// NOTE(bill): only the ones that are needed (not all types)
// This will be set by the compiler

Type_Info_Enum_Value :: distinct i64

Platform_Endianness :: enum u8 {
    Platform = 0,
    Little   = 1,
    Big      = 2,
}

// Procedure type to test whether two values of the same type are equal
Equal_Proc :: distinct proc(rawptr, rawptr) -> bool
// Procedure type to hash a value, default seed value is 0
Hasher_Proc :: distinct proc(data: rawptr, seed: uintptr = 0) -> uintptr

Type_Info_Struct_Soa_Kind :: enum u8 {
    None    = 0,
    Fixed   = 1,
    Slice   = 2,
}

Type_Info_String_Encoding_Kind :: enum u8 {
    UTF_8  = 0,
    UTF_16 = 1,
}

// Variant Types
Type_Info_Named :: struct {
    name: string,
    base: ^Type_Info,
    pkg:  string,
    loc:  ^Source_Code_Location,
}
Type_Info_Integer    :: struct {signed: bool, endianness: Platform_Endianness}
Type_Info_Rune       :: struct {}
Type_Info_Float      :: struct {endianness: Platform_Endianness}
Type_Info_Complex    :: struct {}
Type_Info_Quaternion :: struct {}
Type_Info_String     :: struct {is_cstring: bool, encoding: Type_Info_String_Encoding_Kind}
Type_Info_Boolean    :: struct {}
Type_Info_Any        :: struct {}
Type_Info_Type_Id    :: struct {}
Type_Info_Pointer :: struct {
    elem: ^Type_Info, // nil -> rawptr
}
Type_Info_Multi_Pointer :: struct {
    elem: ^Type_Info,
}
Type_Info_Procedure :: struct {
    params:     ^Type_Info, // Type_Info_Parameters
    results:    ^Type_Info, // Type_Info_Parameters
    variadic:   bool,
    convention: Calling_Convention,
}
Type_Info_Array :: struct {
    elem:      ^Type_Info,
    elem_size: int,
    count:     int,
}
Type_Info_Enumerated_Array :: struct {
    elem:      ^Type_Info,
    index:     ^Type_Info,
    elem_size: int,
    count:     int,
    min_value: Type_Info_Enum_Value,
    max_value: Type_Info_Enum_Value,
    is_sparse: bool,
}
Type_Info_Slice         :: struct {elem: ^Type_Info, elem_size: uint}

Type_Info_Parameters :: struct { // Only used for procedures parameters and results
    types: []^Type_Info,
    names: []string,
}

Type_Info_Struct_Flags :: distinct bit_set[Type_Info_Struct_Flag; u8]
Type_Info_Struct_Flag :: enum u8 {
    packed      = 0,
    raw_union   = 1,
    all_or_none = 2,
    align       = 3,
    simple      = 4,
}

Type_Info_Struct :: struct {
    // Slice these with `field_count`
    types:         [^]^Type_Info `fmt:"v,field_count"`,
    names:         [^]string     `fmt:"v,field_count"`,
    offsets:       [^]uintptr    `fmt:"v,field_count"`,
    usings:        [^]bool       `fmt:"v,field_count"`,
    tags:          [^]string     `fmt:"v,field_count"`,

    field_count:   i32,

    flags:         Type_Info_Struct_Flags,

    // These are only set iff this structure is an SOA structure
    soa_kind:      Type_Info_Struct_Soa_Kind,
    soa_len:       i32,
    soa_base_type: ^Type_Info,

    equal: Equal_Proc, // set only when the struct has .Comparable set but does not have .Simple_Compare set
}
Type_Info_Union :: struct {
    variants:     []^Type_Info,
    tag_offset:   uintptr,
    tag_type:     ^Type_Info,

    equal: Equal_Proc, // set only when the struct has .Comparable set but does not have .Simple_Compare set

    custom_align: bool,
    no_nil:       bool,
    shared_nil:   bool,
}
Type_Info_Enum :: struct {
    base:   ^Type_Info,
    names:  []string,
    values: []Type_Info_Enum_Value,
}
Type_Info_Map :: struct {
    key:      ^Type_Info,
    value:    ^Type_Info,
    map_info: ^Map_Info,
}
Type_Info_Bit_Set :: struct {
    elem:       ^Type_Info,
    underlying: ^Type_Info, // Possibly nil
    lower:      i64,
    upper:      i64,
}
Type_Info_Simd_Vector :: struct {
    elem:       ^Type_Info,
    elem_size:  int,
    count:      int,
}
Type_Info_Matrix :: struct {
    elem:         ^Type_Info,
    elem_size:    int,
    elem_stride:  int, // elem_stride >= row_count
    row_count:    int,
    column_count: int,
    // Total element count = column_count * elem_stride
    layout: enum u8 {
        Column_Major, // array of column vectors
        Row_Major,    // array of row vectors
    },
}
Type_Info_Soa_Pointer :: struct {
    elem: ^Type_Info,
}
Type_Info_Bit_Field :: struct {
    backing_type: ^Type_Info,
    names:        [^]string     `fmt:"v,field_count"`,
    types:        [^]^Type_Info `fmt:"v,field_count"`,
    bit_sizes:    [^]uintptr    `fmt:"v,field_count"`,
    bit_offsets:  [^]uintptr    `fmt:"v,field_count"`,
    tags:         [^]string     `fmt:"v,field_count"`,
    field_count:  uint,
}

Type_Info_Flag :: enum u8 {
    Comparable     = 0,
    Simple_Compare = 1,
}
Type_Info_Flags :: distinct bit_set[Type_Info_Flag; u32]

Type_Info :: struct {
    size:  int,
    align: int,
    flags: Type_Info_Flags,
    id:    typeid,

    // Caio: This options must match the same as `enum Typeid_Kind : u8 {` from the compiler.
    variant: union {
        Type_Info_Named,
        Type_Info_Integer,
        Type_Info_Rune,
        Type_Info_Float,
        Type_Info_Complex,
        Type_Info_Quaternion,
        Type_Info_String,
        Type_Info_Boolean,
        Type_Info_Any,
        Type_Info_Type_Id,
        Type_Info_Pointer,
        Type_Info_Multi_Pointer,
        Type_Info_Procedure,
        Type_Info_Array,
        Type_Info_Enumerated_Array,
        Type_Info_Slice,
        Type_Info_Parameters,
        Type_Info_Struct,
        Type_Info_Union,
        Type_Info_Enum,
        Type_Info_Map,
        Type_Info_Bit_Set,
        Type_Info_Simd_Vector,
        Type_Info_Matrix,
        Type_Info_Soa_Pointer,
        Type_Info_Bit_Field,
    },
}

// NOTE(bill): only the ones that are needed (not all types)
// This will be set by the compiler
type_table: []^Type_Info


// type_info_base returns the base-type of a `^Type_Info` stripping the `distinct`ness from the first level

type_info_base :: proc(info: ^Type_Info) -> ^Type_Info {
    if info == nil {
        return nil
    }

    base := info
    loop: for {
        #partial switch i in base.variant {
        case Type_Info_Named: base = i.base
        case: break loop
        }
    }
    return base
}


// type_info_core returns the core-type of a `^Type_Info` stripping the `distinct`ness from the first level AND/OR
// returns the backing integer type of an enum or bit_set `^Type_Info`.
// This is also aliased as `type_info_base_without_enum`

type_info_core :: proc(info: ^Type_Info) -> ^Type_Info {
    if info == nil {
        return nil
    }

    base := info
    loop: for {
        #partial switch i in base.variant {
        case Type_Info_Named:     base = i.base
        case Type_Info_Enum:      base = i.base
        case Type_Info_Bit_Field: base = i.backing_type
        case: break loop
        }
    }
    return base
}

// type_info_base_without_enum returns the core-type of a `^Type_Info` stripping the `distinct`ness from the first level AND/OR
// returns the backing integer type of an enum or bit_set `^Type_Info`.
// This is also aliased as `type_info_core`
type_info_base_without_enum :: type_info_core

__type_info_of :: proc(id: typeid) -> ^Type_Info #no_bounds_check {
    n := u64(len(type_table))
    i := transmute(u64)id % n
    for _ in 0..<n {
        ptr := type_table[i]
        if ptr != nil && ptr.id == id {
            return ptr
        }
        i = i+1 if i+1 < n else 0
    }
    return type_table[0]
}

when !DUSK_NO_RTTI {
    // typeid_base returns the base-type of a `typeid` stripping the `distinct`ness from the first level
    typeid_base :: proc(id: typeid) -> typeid {
        ti := type_info_of(id)
        ti = type_info_base(ti)
        return ti.id
    }
    // typeid_core returns the core-type of a `typeid` stripping the `distinct`ness from the first level AND/OR
    // returns the backing integer type of an enum or bit_set `typeid`.
    // This is also aliased as `typeid_base_without_enum`
    typeid_core :: proc(id: typeid) -> typeid {
        ti := type_info_core(type_info_of(id))
        return ti.id
    }

    // typeid_base_without_enum returns the core-type of a `typeid` stripping the `distinct`ness from the first level AND/OR
    // returns the backing integer type of an enum or bit_set `typeid`.
    // This is also aliased as `typeid_core`
    typeid_base_without_enum :: typeid_core
}

/*
Recovers the containing/parent struct from a pointer to one of its fields.
Works by "walking back" to the struct's starting address using the offset between the field and the struct.

Inputs:
- ptr: Pointer to the field of a container struct
- T: The type of the container struct
- field_name: The name of the field in the `T` struct

Returns:
- A pointer to the container struct based on a pointer to a field in it

Example:
    package container_of
    import "base:internal"

    Node :: struct {
        value: iunt,
        prev:  ^Node,
        next:  ^Node,
    }

    main :: proc() {
        node: Node
        field_ptr := &node.next
        container_struct_ptr: ^Node = internal.container_of(field_ptr, Node, "next")
        internal.assert(container_struct_ptr == &node)
        internal.assert(uintptr(field_ptr) - uintptr(container_struct_ptr) == size_of(node.value) + size_of(node.prev))
    }

Output:
    ^Node
*/
container_of :: #force_inline proc(ptr: $P/^$Field_Type, $T: typeid, $field_name: string) -> ^T
    where intrinsics.type_has_field(T, field_name),
          intrinsics.type_field_type(T, field_name) == Field_Type {
    offset :: offset_of_by_string(T, field_name)
    return (^T)(uintptr(ptr) - offset) if ptr != nil else nil
}
