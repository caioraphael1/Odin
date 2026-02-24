#+build !js


import "core:log"
import "core:os"
import "core:mem"

// 'fontIndex' controls which font you want to load within a multi-font format such
// as TTC. Leave it as zero if you are loading a single-font format such as TTF.
AddFontPath :: proc(
    ctx: ^FontContext,
    name: string,
    path: string,
    fontIndex: int = 0,
    allocator: mem.Allocator
) -> int {
    data, data_err := os.read_entire_file(path, allocator)

    if data_err != nil {
        log.panicf("FONT: failed to read font at %s", path)
    }

    return AddFontMem(ctx, name, data, true, fontIndex)
}
