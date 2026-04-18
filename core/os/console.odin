import "base:intrinsics"
import sb "base:container/string_buffer"

@(optional_results)
print :: proc(strs: ..sb.String_Type) -> (ok: bool) {
    array: [1024]u8

    buf := sb.create(raw_data(array[:]), len(array), 0)
    sb.write(&buf, ..strs) or_return
    
    return printb(sb.slice(buf))
}

@(optional_results)
println :: proc(strs: ..sb.String_Type) -> (ok: bool) {
    array: [1024]u8

    buf := sb.create(raw_data(array[:]), len(array), 0)
    sb.write(&buf, ..strs) or_return
    
    sb.write_byte(&buf, '\n') or_return

    return printb(sb.slice(buf))
}

@(optional_results)
printf :: proc(format: string, strs: ..sb.String_Type) -> (ok: bool) {
    array: [1024]u8

    buf := sb.create(raw_data(array[:]), len(array), 0)
    sb.writef(&buf, format, ..strs) or_return
    
    return printb(sb.slice(buf))
}

@(optional_results)
printfln :: proc(format: string, strs: ..sb.String_Type) -> (ok: bool) {
    array: [1024]u8

    buf := sb.create(raw_data(array[:]), len(array), 0)
    sb.writef(&buf, format, ..strs) or_return

    sb.write_byte(&buf, '\n') or_return
    
    return printb(sb.slice(buf))
}


@(optional_results)
eprint :: proc(strs: ..sb.String_Type) -> (ok: bool) {
    array: [1024]u8

    buf := sb.create(raw_data(array[:]), len(array), 0)
    sb.write(&buf, ..strs) or_return
    
    return eprintb(sb.slice(buf))
}

@(optional_results)
eprintln :: proc(strs: ..sb.String_Type) -> (ok: bool) {
    array: [1024]u8

    buf := sb.create(raw_data(array[:]), len(array), 0)
    sb.write(&buf, ..strs) or_return

    sb.write_byte(&buf, '\n') or_return
    
    return eprintb(sb.slice(buf))
}

@(optional_results)
eprintf :: proc(format: string, strs: ..sb.String_Type) -> (ok: bool) {
    array: [1024]u8

    buf := sb.create(raw_data(array[:]), len(array), 0)
    sb.writef(&buf, format, ..strs) or_return
    
    return eprintb(sb.slice(buf))
}

@(optional_results)
eprintfln :: proc(format: string, strs: ..sb.String_Type) -> (ok: bool) {
    array: [1024]u8

    buf := sb.create(raw_data(array[:]), len(array), 0)
    sb.writef(&buf, format, ..strs) or_return

    sb.write_byte(&buf, '\n') or_return
    
    return eprintb(sb.slice(buf))
}


@(optional_results)
printb :: proc(buf: []u8) -> (ok: bool) {
    _, err := _write(cast(^File_Impl)stdout, buf)
    return err != nil
}

@(optional_results)
eprintb :: proc(buf: []u8) -> (ok: bool) {
    _, err := _write(cast(^File_Impl)stderr, buf)
    return err != nil
}


@(disabled=ODIN_DISABLE_ASSERT)
assert :: proc(condition: bool, strs: ..sb.String_Type, loc := #caller_location) {
    if !condition {
        print("[ASSERT] ")
        println(..strs)
        intrinsics.trap()
    }
}

ensure :: proc(condition: bool, strs: ..sb.String_Type, loc := #caller_location) {
    if !condition {
        print("[ENSURE] ")
        println(..strs)
        intrinsics.trap()
    }
}

panic :: proc(strs: ..sb.String_Type, loc := #caller_location) -> ! {
    print("[PANIC] ")
    println(..strs)
    intrinsics.trap()
}


@(disabled=ODIN_DISABLE_ASSERT)
assertf :: proc(condition: bool, format: string, strs: ..sb.String_Type, loc := #caller_location) {
    if !condition {
        print("[ASSERT] ")
        printfln(format, ..strs)
        intrinsics.trap()
    }
}

ensuref :: proc(condition: bool, format: string, strs: ..sb.String_Type, loc := #caller_location) {
    if !condition {
        print("[ENSURE] ")
        printfln(format, ..strs)
        intrinsics.trap()
    }
}

panicf :: proc(format: string, strs: ..sb.String_Type, loc := #caller_location) -> ! {
    print("[PANIC] ")
    printfln(format, ..strs)
    intrinsics.trap()
}


