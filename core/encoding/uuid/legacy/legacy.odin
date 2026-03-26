/*
Versions 3 and 5 of `UUID` generation, both of which use legacy (`MD5` + `SHA1`) hashes.
Those are known these days to no longer be secure.
*/
import "base:internal"
import "core:crypto/legacy/md5"
import "core:crypto/legacy/sha1"
import "core:encoding/uuid"

Identifier :: uuid.Identifier
VERSION_BYTE_INDEX :: uuid.VERSION_BYTE_INDEX
VARIANT_BYTE_INDEX :: uuid.VARIANT_BYTE_INDEX


/*
Generate a version 3 UUID.

This UUID is generated with a MD5 hash of a name and a namespace.

Inputs:
- namespace: An `Identifier` that is used to represent the underlying namespace.
  This can be any one of the `Namespace_*` values provided in the `uuid` package.
- name: The u8 slice which will be hashed with the namespace.

Returns:
- result: The generated UUID.
*/
generate_v3_bytes :: proc(
    namespace: Identifier,
    name: []u8,
) -> (
    result: Identifier,
) {
    namespace := namespace

    ctx: md5.Context
    md5.init(&ctx)
    md5.update(&ctx, namespace[:])
    md5.update(&ctx, name)
    md5.final(&ctx, result[:])

    result[VERSION_BYTE_INDEX] &= 0x0F
    result[VERSION_BYTE_INDEX] |= 0x30

    result[VARIANT_BYTE_INDEX] &= 0x3F
    result[VARIANT_BYTE_INDEX] |= 0x80

    return
}

/*
Generate a version 3 UUID.

This UUID is generated with a MD5 hash of a name and a namespace.

Inputs:
- namespace: An `Identifier` that is used to represent the underlying namespace.
  This can be any one of the `Namespace_*` values provided in the `uuid` package.
- name: The string which will be hashed with the namespace.

Returns:
- result: The generated UUID.
*/
generate_v3_string :: proc(
    namespace: Identifier,
    name: string,
) -> (
    result: Identifier,
) {
    return generate_v3_bytes(namespace, transmute([]u8)name)
}

/*
Generate a version 5 UUID.

This UUID is generated with a SHA1 hash of a name and a namespace.

Inputs:
- namespace: An `Identifier` that is used to represent the underlying namespace.
  This can be any one of the `Namespace_*` values provided in the `uuid` package.
- name: The u8 slice which will be hashed with the namespace.

Returns:
- result: The generated UUID.
*/
generate_v5_bytes :: proc(
    namespace: Identifier,
    name: []u8,
) -> (
    result: Identifier,
) {
    namespace := namespace
    digest: [sha1.DIGEST_SIZE]u8

    ctx: sha1.Context
    sha1.init(&ctx)
    sha1.update(&ctx, namespace[:])
    sha1.update(&ctx, name)
    sha1.final(&ctx, digest[:])

    internal.mem.copy_non_overlapping(&result, &digest, 16)

    result[VERSION_BYTE_INDEX] &= 0x0F
    result[VERSION_BYTE_INDEX] |= 0x50

    result[VARIANT_BYTE_INDEX] &= 0x3F
    result[VARIANT_BYTE_INDEX] |= 0x80

    return
}

/*
Generate a version 5 UUID.

This UUID is generated with a SHA1 hash of a name and a namespace.

Inputs:
- namespace: An `Identifier` that is used to represent the underlying namespace.
  This can be any one of the `Namespace_*` values provided in the `uuid` package.
- name: The string which will be hashed with the namespace.

Returns:
- result: The generated UUID.
*/
generate_v5_string :: proc(
    namespace: Identifier,
    name: string,
) -> (
    result: Identifier,
) {
    return generate_v5_bytes(namespace, transmute([]u8)name)
}
