
import "core:bytes"

/* 
Returns the byte offset of the first byte `c` in the string s it finds, -1 when not found.
NOTE: Can't find UTF-8 based runes.
Example:
    fmt.println(strings_tools.index_byte("test", 't'))
    fmt.println(strings_tools.index_byte("test", 'e'))
    fmt.println(strings_tools.index_byte("test", 'x'))
    fmt.println(strings_tools.index_byte("teäst", 'ä'))
Output:
    0
    1
    -1
    -1
*/
index_byte :: proc(s: string, c: byte) -> (res: int) {
    return #force_inline bytes.index_byte(transmute([]u8)s, c)
}

/* 
Returns the byte offset of the last byte `c` in the string `s`, -1 when not found.
NOTE: Can't find UTF-8 based runes.

Example:
    import "core:fmt"
    import "core:strings"

    fmt.println(strings_tools.last_index_byte("test", 't'))
    fmt.println(strings_tools.last_index_byte("test", 'e'))
    fmt.println(strings_tools.last_index_byte("test", 'x'))
    fmt.println(strings_tools.last_index_byte("teäst", 'ä'))
Output:
    3
    1
    -1
    -1
*/
last_index_byte :: proc(s: string, c: byte) -> (res: int) {
    return #force_inline bytes.last_index_byte(transmute([]u8)s, c)
}
