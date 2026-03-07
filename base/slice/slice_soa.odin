@(require) import "base:intrinsics"
import "base:mem"

/*
    SOA types are implemented with this sort of layout:

    SOA Fixed Array
    struct {
        f0: [N]T0,
        f1: [N]T1,
        f2: [N]T2,
    }

    SOA Slice
    struct {
        f0: ^T0,
        f1: ^T1,
        f2: ^T2,

        len: int,
    }

    SOA Dynamic Array
    struct {
        f0: ^T0,
        f1: ^T1,
        f2: ^T2,

        len: int,
        cap: int,
        allocator: mem.Allocator,
    }

    A footer is used rather than a header purely to simplify access to the fields internally
    i.e. field index of the AOS == SOA
*/


Raw_SOA_Footer_Slice :: struct {
    len: int,
}


create_soa_slice :: proc($T: typeid/#soa[]$E, #any_int length: int, allocator: mem.Allocator, loc := #caller_location) -> (array: T, err: mem.Allocator_Error) {
    return create_soa_aligned(T, length, align_of(E), allocator, loc)
}

create_soa_aligned :: proc($T: typeid/#soa[]$E, #any_int length, alignment: int, allocator: mem.Allocator, loc := #caller_location) -> (array: T, err: mem.Allocator_Error) {
    if length <= 0 {
        return
    }

    footer := raw_soa_footer(&array)
    if size_of(E) == 0 {
        footer.len = length
        return
    }

    max_align := max(alignment, align_of(E))

    ti := type_info_of(typeid_of(T))
    ti = type_info_base(ti)
    si := &ti.variant.(Type_Info_Struct)

    field_count := uintptr(len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E))

    total_size := 0
    for i in 0..<field_count {
        type := si.types[i].variant.(Type_Info_Multi_Pointer).elem
        total_size += type.size * length
        total_size = align_forward_int(total_size, max_align)
    }

    assert(allocator.procedure != nil)

    new_bytes: []byte
    new_bytes, err = allocator.procedure(
        allocator.data, .Alloc, total_size, max_align,
        nil, 0, loc,
    )
    if new_bytes == nil || err != nil {
        return
    }
    new_data := raw_data(new_bytes)

    data := uintptr(&array)
    offset := 0
    for i in 0..<field_count {
        type := si.types[i].variant.(Type_Info_Multi_Pointer).elem

        offset = align_forward_int(offset, max_align)

        (^uintptr)(data)^ = uintptr(new_data) + uintptr(offset)
        data += size_of(rawptr)
        offset += type.size * length
    }
    footer.len = length

    return
}

delete_soa_slice :: proc(array: $T/#soa[]$E, allocator: mem.Allocator, loc := #caller_location) -> mem.Allocator_Error {
    field_count :: len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)
    when field_count != 0 {
        array := array
        ptr := (^rawptr)(&array)^
        _ = free(ptr, allocator, loc) or_return
    }
    return nil
}

raw_soa_footer_slice :: proc(array: ^$T/#soa[]$E) -> (footer: ^Raw_SOA_Footer_Slice) {
    if array == nil {
        return nil
    }
    field_count := uintptr(len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E))
    footer = (^Raw_SOA_Footer_Slice)(uintptr(array) + field_count*size_of(rawptr))
    return
}
