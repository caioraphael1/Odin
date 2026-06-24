

/*
	Copyright 2021 zhibog
	Made available under Dusk's license.

	List of contributors:
		zhibog, dotbmp:  Initial implementation.
*/

import "core:crypto"
import "core:io"

// hash_bytes will hash the given input and return the computed digest
// in a newly allocated slice.
hash_string :: proc(algorithm: Algorithm, data: string, allocator: mem.Allocator) -> []u8 {
	return hash_bytes(algorithm, transmute([]u8)(data), allocator)
}

// hash_bytes will hash the given input and return the computed digest
// in a newly allocated slice.
hash_bytes :: proc(algorithm: Algorithm, data: []u8, allocator: mem.Allocator) -> []u8 {
	dst := slice.create(u8, DIGEST_SIZES[algorithm], allocator)
	return hash_bytes_to_buffer(algorithm, data, dst)
}

// hash_string_to_buffer will hash the given input and assign the
// computed digest to the third parameter.  It requires that the
// destination buffer is at least as big as the digest size.  The
// provided destination buffer is returned to match the behavior of
// `hash_string`.
hash_string_to_buffer :: proc(algorithm: Algorithm, data: string, hash: []u8) -> []u8 {
	return hash_bytes_to_buffer(algorithm, transmute([]u8)(data), hash)
}

// hash_bytes_to_buffer will hash the given input and write the
// computed digest into the third parameter.  It requires that the
// destination buffer is at least as big as the digest size.  The
// provided destination buffer is returned to match the behavior of
// `hash_bytes`.
hash_bytes_to_buffer :: proc(algorithm: Algorithm, data, hash: []u8) -> []u8 {
	ctx: Context

	init(&ctx, algorithm)
	update(&ctx, data)
	final(&ctx, hash)

	return hash[:DIGEST_SIZES[algorithm]]
}

// hash_stream will incrementally fully consume a stream, and return the
// computed digest in a newly allocated slice.
hash_stream :: proc(
	algorithm: Algorithm,
	s: io.Stream,
	allocator: mem.Allocator,
) -> (
	[]u8,
	io.Error,
) {
	ctx: Context

	buf: [MAX_BLOCK_SIZE * 4]u8
	defer crypto.zero_explicit(&buf, size_of(buf))

	init(&ctx, algorithm)

	loop: for {
		n, err := io.read(s, buf[:])
		if n > 0 {
			// XXX/yawning: Can io.read return n > 0 and EOF?
			update(&ctx, buf[:n])
		}
		#partial switch err {
		case .None:
		case .EOF:
			break loop
		case:
			return nil, err
		}
	}

	dst := slice.create(u8, DIGEST_SIZES[algorithm], allocator)
	final(&ctx, dst)

	return dst, io.Error.None
}
