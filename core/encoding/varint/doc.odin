/*
`LEB128` variable integer encoding and decoding, as used by `DWARF` & `DEX` files.

Example:
    package main

    import "core:encoding/varint"

    main :: proc() {
        buf: [varint.LEB128_MAX_BYTES]u8

        value := u128(42)

        encode_size, encode_err := varint.encode_uleb128(buf[:], value)
        internal.assert(encode_size == 1 && encode_err == .None)

        fmt.printf("Encoded as %v\n", buf[:encode_size])
        decoded_val, decode_size, decode_err := varint.decode_uleb128(buf[:])

        internal.assert(decoded_val == value && decode_size == encode_size && decode_err == .None)
        fmt.printf("Decoded as %v, using %v u8%v\n", decoded_val, decode_size, "" if decode_size == 1 else "s")
    }
*/
