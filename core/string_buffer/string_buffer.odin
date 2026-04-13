import "base:container/buffer"
import "base:intrinsics"

import "base:strconv"
import fs "base:container/fixed_string"

import "core:os"

/* 
string_buffer (sb)

IDEA 2
Can only write strings.
Convert stuff to strings and write in the right place. 
Pros:
    - extensive, as the write function only requires strings.
Negs:
    - the syntax is a bit more complex and indirect.

IDEA 2.1
Can only write strings or Fixed_Strings(N); this is done so the syntax is easier to use, but creates an issue around $N.
Convert stuff to strings and write in the right place.
Pros:
    - extensive, as the write function only requires strings.
    - Better syntax.
Negs:
    - Memory waste via using a big and general $N, or using a small and precise $N that breaks extensability, for requiring adding stuff to the union.

IDEA 3
Can only write strings.
Convert stuff to strings and write in the right place. 
1. There's a big RING global buffer inside the lib, where strconv can be perfomed on.
2. Uses a temp global buffer, cleared by a procedure, called manually.
3. There's a temp global buffer that is cleared automatically uppon finishing the formatting.
    - This can be a bit tricky, as not always I want a string to be formatted.
    - Maybe `fmt_uint` for formatting, and strconv for simply getting a string? I don't know, `from_uint` seems to be too useful.
Pros:
    - extensive, as the write function only requires strings.
    - Better syntax (same as idea 2)
Negs:
    - The buffer always exist.
    - It requires calling something to clear the buffer.
*/

/* 
TODO:
"concatenate" might be better than "format"
*/


/* 
BEFORE
    

AFTER
    - write to a buffer ("base:container/buffer")
    - write formated to a buffer (this file + "base:container/fixed_string")
    - copy that to stdout. (this file)
*/


main :: proc() {
    os.init_std_files()

    algo: [256]u8
    buf := buffer.create(raw_data(algo[:]), len(algo), 0)
    ok := buffer.write_string(&buf, "sup!\n")
    trem := from_uint(~uint(0))
    ok = sb_write(&buf, "Caio said '%' and also said '%'  -> %", "hello", "DAMN", fs.as_string(&trem))
    ok = sb_write(&buf, "Caio said '%' and also said '%'  -> %", "hello", "DAMN", from_uint(~uint(0)))
    printb(buffer.slice(buf))
    // eprintb(buffer.slice(buf))

    print("Caio said '%' and also said '%'  -> %\n", "hello", "DAMN", from_uint(~uint(0)))
    print("HERE\nTHERE\n")


    assert(false, "asserting que algo aconteceu aqui '%'", #procedure)
    // ensure(false, "ensuring que algo aconteceu aqui '%'", #procedure)
    // panic("ensuring que algo aconteceu aqui '%'", #procedure)

    // internal.print_string("\ntrue" if ok else "\nfalse")
}


@(optional_results)
print :: proc(format: string, strs: ..String_Type) -> (ok: bool) {
    array: [1024]u8

    buf := buffer.create(raw_data(array[:]), len(array), 0)
    sb_write(&buf, format, ..strs) or_return
    
    return printb(buffer.slice(buf))
}

@(optional_results)
eprint :: proc(format: string, strs: ..String_Type) -> (ok: bool) {
    array: [1024]u8

    buf := buffer.create(raw_data(array[:]), len(array), 0)
    sb_write(&buf, format, ..strs) or_return
    
    return eprintb(buffer.slice(buf))
}

@(optional_results)
printb :: proc(buf: []u8) -> (ok: bool) {
    _, err := os._write(cast(^os.File_Impl)os.stdout, buf)
    return err != nil
}

@(optional_results)
eprintb :: proc(buf: []u8) -> (ok: bool) {
    _, err := os._write(cast(^os.File_Impl)os.stderr, buf)
    return err != nil
}


@(disabled=ODIN_DISABLE_ASSERT)
assert :: proc(condition: bool, format: string, strs: ..String_Type, loc := #caller_location) {
    if !condition {
        print("[ASSERT] ")
        print(format, ..strs)
        intrinsics.trap()
    }
}

ensure :: proc(condition: bool, format: string, strs: ..String_Type, loc := #caller_location) {
    if !condition {
        print("[ENSURE] ")
        print(format, ..strs)
        intrinsics.trap()
    }
}

panic :: proc(format: string, strs: ..String_Type, loc := #caller_location) -> ! {
    print("[PANIC] ")
    print(format, ..strs)
    intrinsics.trap()
}


from_uint :: proc(num: uint) -> (str: fs.Fixed_String(20)/*the biggest uint requires 20 bytes */) {
    s := strconv.write_uint(str.data[:], u64(num), 10)
    str.len += len(s)
    return
}


String_Type :: union {
    string,              // "pointer to a [N]u8"
    fs.Fixed_String(20), // "the [N]u8"
    /*
    1. maybe just keep adding random values, I guess, idk
    2. Use a big enough fixed_string for all values, so all "from_" procs uses the same size.
    */
}

sb_write :: proc(buf: ^buffer.Buffer, format: string, strs: ..String_Type) -> (ok: bool) {
    str_i: uint
    i: uint
    loop: for i < len(format) {
        char := format[i]
        switch char {
        case '%':
            switch &v in strs[str_i] {
            case string:
                buffer.write_string(buf, v) or_return
            case fs.Fixed_String(20):
                buffer.write_string(buf, fs.as_string(&v)) or_return
            }
            str_i += 1
        case:
            buffer.write_byte(buf, char) or_return
        }
        i += 1
    }
    return true
}


/* 
/* Idea 1
Can only write rawptrs.
Convert the rawptr to a pointer to the type specified by the '%s' verb and write in the right place.
Pros:
    - Direct.
Negs:
    - Formatting is tied to the formatting function, not to the type, so it's harded to scale.
    - Requires pointers, which is a bit annoying and can be unsafe.
    - As it requires pointers, constants suffer.
*/

a := "hello"
b := "DAMN"
ok = write_format_old(&buf, "Caio said '%s' and also said '%s'", &a, &b)

write_format_old :: proc(buf: ^buffer.Buffer, format: string, args: ..rawptr) -> (ok: bool) {
    arg_i: uint
    i: uint
    loop: for i < len(format) {
        char := format[i]
        switch char {
        case '%':
            next_char := format[i + 1]
            switch next_char {
            case 's':
                str := transmute(^string)args[arg_i]
                buffer.write_string(buf, str^) or_return
                arg_i += 1
                i += 2
                continue loop
            }
        case:
            buffer.write_byte(buf, char) or_return
        }
        i += 1
    }
    return true
}
*/
