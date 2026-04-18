import "base:intrinsics"
import "base:container/str"

@(optional_results)
print :: proc(strs: ..str.String_Type) -> (ok: bool) {
    s: str.String(1024)
    str.write(&s, ..strs) or_return
    
    return printb(str.slice(&s))
}

@(optional_results)
println :: proc(strs: ..str.String_Type) -> (ok: bool) {
    s: str.String(1024)
    str.write(&s, ..strs) or_return
    
    str.write_byte(&s, '\n') or_return

    return printb(str.slice(&s))
}

@(optional_results)
printf :: proc(format: string, strs: ..str.String_Type) -> (ok: bool) {
    s: str.String(1024)
    str.writef(&s, format, ..strs) or_return
    
    return printb(str.slice(&s))
}

@(optional_results)
printfln :: proc(format: string, strs: ..str.String_Type) -> (ok: bool) {
    s: str.String(1024)
    str.writef(&s, format, ..strs) or_return

    str.write_byte(&s, '\n') or_return
    
    return printb(str.slice(&s))
}


@(optional_results)
eprint :: proc(strs: ..str.String_Type) -> (ok: bool) {
    s: str.String(1024)
    str.write(&s, ..strs) or_return
    
    return eprintb(str.slice(&s))
}

@(optional_results)
eprintln :: proc(strs: ..str.String_Type) -> (ok: bool) {
    s: str.String(1024)
    str.write(&s, ..strs) or_return

    str.write_byte(&s, '\n') or_return
    
    return eprintb(str.slice(&s))
}

@(optional_results)
eprintf :: proc(format: string, strs: ..str.String_Type) -> (ok: bool) {
    s: str.String(1024)
    str.writef(&s, format, ..strs) or_return
    
    return eprintb(str.slice(&s))
}

@(optional_results)
eprintfln :: proc(format: string, strs: ..str.String_Type) -> (ok: bool) {
    s: str.String(1024)
    str.writef(&s, format, ..strs) or_return

    str.write_byte(&s, '\n') or_return
    
    return eprintb(str.slice(&s))
}


@(optional_results)
printb :: proc(s: []u8) -> (ok: bool) {
    _, err := _write(cast(^File_Impl)stdout, s)
    return err != nil
}

@(optional_results)
eprintb :: proc(s: []u8) -> (ok: bool) {
    _, err := _write(cast(^File_Impl)stderr, s)
    return err != nil
}


@(disabled=ODIN_DISABLE_ASSERT)
assert :: proc(condition: bool, strs: ..str.String_Type, loc := #caller_location) {
    if !condition {
        print("[ASSERT] ")
        println(..strs)
        intrinsics.trap()
    }
}

ensure :: proc(condition: bool, strs: ..str.String_Type, loc := #caller_location) {
    if !condition {
        print("[ENSURE] ")
        println(..strs)
        intrinsics.trap()
    }
}

panic :: proc(strs: ..str.String_Type, loc := #caller_location) -> ! {
    print("[PANIC] ")
    println(..strs)
    intrinsics.trap()
}


@(disabled=ODIN_DISABLE_ASSERT)
assertf :: proc(condition: bool, format: string, strs: ..str.String_Type, loc := #caller_location) {
    if !condition {
        print("[ASSERT] ")
        printfln(format, ..strs)
        intrinsics.trap()
    }
}

ensuref :: proc(condition: bool, format: string, strs: ..str.String_Type, loc := #caller_location) {
    if !condition {
        print("[ENSURE] ")
        printfln(format, ..strs)
        intrinsics.trap()
    }
}

panicf :: proc(format: string, strs: ..str.String_Type, loc := #caller_location) -> ! {
    print("[PANIC] ")
    printfln(format, ..strs)
    intrinsics.trap()
}


