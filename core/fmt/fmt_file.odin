#+ignore


#+build !freestanding
#+build !js
#+build !orca


import "core:os"
import "core:os/writer"
import "core:io"
import "core:reflect"

// fprint formats using the default print settings and writes to fd
@(optional_results)
fprint :: proc(fd: ^os.File, args: ..any, sep := " ", flush := true) -> uint {
    buf: [1024]u8
    b: writer.File_Writer
    defer _ = writer.writer_flush(&b)

    writer.writer_init(&b, fd, buf[:])
    w := writer.writer_to_writer(&b)
    return wprint(w, ..args, sep=sep, flush=flush)
}

// fprintln formats using the default print settings and writes to fd
@(optional_results)
fprintln :: proc(fd: ^os.File, args: ..any, sep := " ", flush := true) -> uint {
    buf: [1024]u8
    b: writer.File_Writer
    defer _ = writer.writer_flush(&b)

    writer.writer_init(&b, fd, buf[:])

    w := writer.writer_to_writer(&b)
    return wprintln(w, ..args, sep=sep, flush=flush)
}

// fprintf formats according to the specified format string and writes to fd
@(optional_results)
fprintf :: proc(fd: ^os.File, fmt: string, args: ..any, flush := true, newline := false) -> uint {
    buf: [1024]u8
    b: writer.File_Writer
    defer _ = writer.writer_flush(&b)

    writer.writer_init(&b, fd, buf[:])

    w := writer.writer_to_writer(&b)
    return wprintf(w, fmt, ..args, flush=flush, newline=newline)
}

// fprintfln formats according to the specified format string and writes to fd, followed by a newline.
@(optional_results)
fprintfln :: proc(fd: ^os.File, fmt: string, args: ..any, flush := true) -> uint {
    return fprintf(fd, fmt, ..args, flush=flush, newline=true)
}

fprint_type :: proc(fd: ^os.File, info: ^reflect.Type_Info, flush := true) -> (n: uint, err: io.Error) {
    buf: [1024]u8
    b: writer.File_Writer
    defer _ = writer.writer_flush(&b)

    writer.writer_init(&b, fd, buf[:])

    w := writer.writer_to_writer(&b)
    return wprint_type(w, info, flush=flush)
}

fprint_typeid :: proc(fd: ^os.File, id: typeid, flush := true) -> (n: uint, err: io.Error) {
    buf: [1024]u8
    b: writer.File_Writer
    defer _ = writer.writer_flush(&b)

    writer.writer_init(&b, fd, buf[:])

    w := writer.writer_to_writer(&b)
    return wprint_typeid(w, id, flush=flush)
}

// print formats using the default print settings and writes to os.stdout
@(optional_results)
print    :: proc(args: ..any, sep := " ", flush := true) -> uint { return fprint(os.stdout, ..args, sep=sep, flush=flush) }

// println formats using the default print settings and writes to os.stdout
@(optional_results)
println  :: proc(args: ..any, sep := " ", flush := true) -> uint { return fprintln(os.stdout, ..args, sep=sep, flush=flush) }

// printf formats according to the specified format string and writes to os.stdout
@(optional_results)
printf   :: proc(fmt: string, args: ..any, flush := true) -> uint { return fprintf(os.stdout, fmt, ..args, flush=flush) }

// printfln formats according to the specified format string and writes to os.stdout, followed by a newline.
@(optional_results)
printfln :: proc(fmt: string, args: ..any, flush := true) -> uint { return fprintf(os.stdout, fmt, ..args, flush=flush, newline=true) }


// eprint formats using the default print settings and writes to os.stderr
@(optional_results)
eprint    :: proc(args: ..any, sep := " ", flush := true) -> uint { return fprint(os.stderr, ..args, sep=sep, flush=flush) }

// eprintln formats using the default print settings and writes to os.stderr
@(optional_results)
eprintln  :: proc(args: ..any, sep := " ", flush := true) -> uint { return fprintln(os.stderr, ..args, sep=sep, flush=flush) }

// eprintf formats according to the specified format string and writes to os.stderr
@(optional_results)
eprintf   :: proc(fmt: string, args: ..any, flush := true) -> uint { return fprintf(os.stderr, fmt, ..args, flush=flush) }

// eprintfln formats according to the specified format string and writes to os.stderr, followed by a newline.
@(optional_results)
eprintfln :: proc(fmt: string, args: ..any, flush := true) -> uint { return fprintf(os.stderr, fmt, ..args, flush=flush, newline=true) }
