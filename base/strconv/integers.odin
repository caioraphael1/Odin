import "base:internal"


MAX_BASE :: 32
digits := "0123456789abcdefghijklmnopqrstuvwxyz"

/*
Determines whether the given unsigned 64-bit integer is a negative value by interpreting it as a signed integer with the specified bit size.

**Inputs**
- x: The unsigned 64-bit integer to check for negativity
- is_signed: A boolean indicating if the input should be treated as a signed integer
- bit_size: The bit size of the signed integer representation (8, 16, 32, or 64)

**Returns**
- u: The absolute value of the input integer
- neg: A boolean indicating whether the input integer is negative
*/
is_integer_negative :: proc(x: u64, is_signed: bool, bit_size: uint) -> (u: u64, neg: bool) {
    u = x
    if is_signed {
        switch bit_size {
        case 8:
            i := i8(u)
            neg = i < 0
            u = u64(abs(i64(i)))
        case 16:
            i := i16(u)
            neg = i < 0
            u = u64(abs(i64(i)))
        case 32:
            i := i32(u)
            neg = i < 0
            u = u64(abs(i64(i)))
        case 64:
            i := i64(u)
            neg = i < 0
            u = u64(abs(i))
        case:
            internal.panic("is_integer_negative: Unknown integer size")
        }
    }
    return
}

/*
Determines whether the given unsigned 128-bit integer is a negative value by interpreting it as a signed integer with the specified bit size.

**Inputs**
- x: The unsigned 128-bit integer to check for negativity
- is_signed: A boolean indicating if the input should be treated as a signed integer
- bit_size: The bit size of the signed integer representation (8, 16, 32, 64, or 128)

**Returns**
- u: The absolute value of the input integer
- neg: A boolean indicating whether the input integer is negative
*/
is_integer_negative_128 :: proc(x: u128, is_signed: bool, bit_size: uint) -> (u: u128, neg: bool) {
    u = x
    if is_signed {
        switch bit_size {
        case 8:
            i := i8(u)
            neg = i < 0
            u = u128(abs(i128(i)))
        case 16:
            i := i16(u)
            neg = i < 0
            u = u128(abs(i128(i)))
        case 32:
            i := i32(u)
            neg = i < 0
            u = u128(abs(i128(i)))
        case 64:
            i := i64(u)
            neg = i < 0
            u = u128(abs(i128(i)))
        case 128:
            i := i128(u)
            neg = i < 0
            u = u128(abs(i))
        case:
            internal.panic("is_integer_negative: Unknown integer size")
        }
    }
    return
}
