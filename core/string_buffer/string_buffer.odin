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
BEFORE
    - fmt -> os -> io -> wprintf -> io -> os

    - fmt uses a file, which is transformed to a io.Stream, to then be used to be writen to by the wprintf, calling io functions inside it to append the data to the io.Stream (append to what? that's abstract, but in the end it's a io.Writer, in specific the renamed File_Writer, which contains a []u8 inside it. After all that, a flush function is called from within the wprintf via the os.File -> io.Stream interface, which then executes the file_windows.odin stuff to finally copy the stuff from the File_Writer to the stdout.

AFTER
    - write to a buffer ("base:container/buffer")
    - write formated to a buffer (this file + "base:container/fixed_string")
    - copy that to stdout. (this file)
*/

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
