package odin_parser

import "core:odin/tokenizer"
import "core:odin/ast"
import "core:path/filepath"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "base:mem"
import "base:runtime"

collect_package :: proc(path: string, allocator: mem.Allocator) -> (pkg: ^ast.Package, success: bool) {
    NO_POS :: tokenizer.Pos{}

    pkg_path, pkg_path_err := os.get_absolute_path(path, allocator)
    if pkg_path_err != nil {
        return
    }

    path_pattern := fmt.tprintf("%s/*.odin", pkg_path)
    matches, err := os.glob(path_pattern, allocator)
    defer _ = slice.delete(matches, allocator)

    if err != nil {
        return
    }

    pkg = ast.new_from_positions(ast.Package, NO_POS, NO_POS, allocator)
    pkg.fullpath = pkg_path

    for match in matches {
        fullpath, fullpath_err := os.get_absolute_path(match, allocator)
        if fullpath_err != nil {
            return
        }

        src, src_err := os.read_entire_file_from_path(fullpath, allocator)
        if src_err != nil {
            _ = string_delete(fullpath, allocator)
            return
        }
        if strings.trim_space(string(src)) == "" {
            _ = string_delete(fullpath, allocator)
            _ = slice.delete(src, allocator)
            continue
        }

        file := ast.new_from_positions(ast.File, NO_POS, NO_POS, allocator)
        file.pkg = pkg
        file.src = string(src)
        file.fullpath = fullpath
        pkg.files[fullpath] = file
    }

    success = true
    return
}

parse_package :: proc(pkg: ^ast.Package, p: ^Parser, allocator: mem.Allocator) -> bool {
    p := p
    if p == nil {
        p = &Parser{}
        p^ = default_parser()
    }

    ok := true

    files, _ := slice_create([]^ast.File, len(pkg.files), runtime.temp_allocator)
    i := 0
    for _, file in pkg.files {
        files[i] = file
        i += 1
    }
    slice.sort(files)

    for file in files {
        if !parse_file(p, file, allocator) {
            ok = false
        }
        if pkg.name == "" {
            pkg.name = file.pkg_decl.name
        } else if pkg.name != file.pkg_decl.name {
            error(p, file.pkg_decl.pos, "different package name, expected '%s', got '%s'", pkg.name, file.pkg_decl.name)
        }
    }

    return ok
}

parse_package_from_path :: proc(path: string, p: ^Parser, allocator: mem.Allocator) -> (pkg: ^ast.Package, ok: bool) {
    pkg, ok = collect_package(path, allocator)
    if !ok {
        return
    }
    ok = parse_package(pkg, p, allocator)
    return
}
