#+ignore

import "base:internal"
import "base:mem"
import "base:mem/allocators"
import "core:io/string_builder"

aprint :: proc(args: []any, sep := " ", allocator: mem.Allocator) -> string {
    str: string_builder.Builder
    string_builder.builder_init(&str, allocator)
    return sbprint(&str, ..args, sep=sep)
}

aprintln :: proc(args: []any, sep := " ", allocator: mem.Allocator) -> string {
    str: string_builder.Builder
    string_builder.builder_init(&str, allocator)
    return sbprintln(&str, ..args, sep=sep)
}

aprintf :: proc(fmt: string, args: []any, allocator: mem.Allocator, newline := false) -> string {
    str: string_builder.Builder
    string_builder.builder_init(&str, allocator)
    return sbprintf(&str, fmt, ..args, newline=newline)
}

aprintfln :: proc(fmt: string, args: []any, allocator: mem.Allocator) -> string {
    return aprintf(fmt, args, allocator, true)
}

tprint :: proc(args: ..any, sep := " ") -> string {
    str: string_builder.Builder
    string_builder.builder_init(&str, allocators.temp_allocator)
    return sbprint(&str, ..args, sep=sep)
}

tprintln :: proc(args: ..any, sep := " ") -> string {
    str: string_builder.Builder
    string_builder.builder_init(&str, allocators.temp_allocator)
    return sbprintln(&str, ..args, sep=sep)
}

tprintf :: proc(fmt: string, args: ..any, newline := false, loc := #caller_location) -> string {
    str: string_builder.Builder
    string_builder.builder_init(&str, allocators.temp_allocator)
    return sbprintf(&str, fmt, ..args, newline=newline)
}

tprintfln :: proc(fmt: string, args: ..any) -> string {
    return tprintf(fmt, ..args, newline=true)
}

bprint :: proc(buf: []u8, args: ..any, sep := " ") -> string {
    sb := string_builder.builder_from_bytes(buf)
    return sbprint(&sb, ..args, sep=sep)
}

bprintln :: proc(buf: []u8, args: ..any, sep := " ") -> string {
    sb := string_builder.builder_from_bytes(buf)
    return sbprintln(&sb, ..args, sep=sep)
}

bprintf :: proc(buf: []u8, fmt: string, args: ..any, newline := false) -> string {
    sb := string_builder.builder_from_bytes(buf)
    return sbprintf(&sb, fmt, ..args, newline=newline)
}

bprintfln :: proc(buf: []u8, fmt: string, args: ..any) -> string {
    return bprintf(buf, fmt, ..args, newline=true)
}

@(disabled=ODIN_DISABLE_ASSERT)
assertf :: proc(condition: bool, fmt: string, args: ..any, loc := #caller_location) {
    if !condition {
        // NOTE(dragos): We are using the same trick as in builtin.assert
        // to improve performance to make the CPU not
        // execute speculatively, making it about an order of
        // magnitude faster
        @(cold)
        internal_assertf :: proc(loc: internal.Source_Code_Location, fmt: string, args: ..any) {
            message := tprintf(fmt, ..args)
            internal.assertion_failure_proc("internal assertion", message, loc)
        }
        internal_assertf(loc, fmt, ..args)
    }
}

ensuref :: proc(condition: bool, fmt: string, args: ..any, loc := #caller_location) {
    if !condition {
        @(cold)
        internal_ensuref :: proc(loc: internal.Source_Code_Location, fmt: string, args: ..any) {
            message := tprintf(fmt, ..args)
            internal.assertion_failure_proc("unsatisfied ensure", message, loc)
        }
        internal_ensuref(loc, fmt, ..args)
    }
}

panicf :: proc(fmt: string, args: ..any, loc := #caller_location) -> ! {
    message := tprintf(fmt, ..args)
    internal.assertion_failure_proc("panic", message, loc)
}

caprint :: proc(args: []any, sep := " ", allocator: mem.Allocator) -> cstring {
    str: string_builder.Builder
    string_builder.builder_init(&str, allocator)
    sbprint(&str, ..args, sep=sep)
    _, _ = string_builder.write_byte(&str, 0)
        // Fix: An error here is being ignored.
    s := string_builder.to_string(&str)
    return cstring(raw_data(s))
}

caprintf :: proc(format: string, args: []any, allocator: mem.Allocator, newline := false) -> cstring {
    str: string_builder.Builder
    string_builder.builder_init(&str, allocator)
    _ = sbprintf(&str, format, ..args, newline=newline)
    _, _ = string_builder.write_byte(&str, 0)
        // Fix: An error here is being ignored.
    s := string_builder.to_string(&str)
    return cstring(raw_data(s))
}

caprintfln :: proc(format: string, args: []any, allocator: mem.Allocator) -> cstring {
    return caprintf(format, args, allocator, true)
}

ctprint :: proc(args: ..any, sep := " ") -> cstring {
    return caprint(args=args, sep=sep, allocator=allocators.temp_allocator)
}

ctprintf :: proc(format: string, args: ..any, newline := false) -> cstring {
    return caprintf(format=format, args=args, allocator=allocators.temp_allocator, newline=newline)
}

ctprintfln :: proc(format: string, args: ..any) -> cstring {
    return caprintf(format=format, args=args, allocator=allocators.temp_allocator, newline=true)
}

@(optional_results)
sbprint :: proc(buf: ^string_builder.Builder, args: ..any, sep := " ") -> string {
    wprint(buf, ..args, sep=sep)
    return string_builder.to_string(buf)
}

@(optional_results)
sbprintln :: proc(buf: ^string_builder.Builder, args: ..any, sep := " ") -> string {
    wprintln(buf, ..args, sep=sep)
    return string_builder.to_string(buf)
}

@(optional_results)
sbprintf :: proc(buf: ^string_builder.Builder, fmt: string, args: ..any, newline := false) -> string {
    wprintf(buf, fmt, ..args, newline=newline)
    return string_builder.to_string(buf)
}

@(optional_results)
sbprintfln :: proc(buf: ^string_builder.Builder, format: string, args: ..any) -> string {
    return sbprintf(buf, format, ..args, newline=true)
}
