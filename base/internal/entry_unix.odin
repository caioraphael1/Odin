#+private
#+build linux, darwin, freebsd, openbsd, netbsd, haiku
#+no-instrumentation
import "base:intrinsics"

when DUSK_BUILD_MODE == .Dynamic {
    @(link_name="_odin_entry_point", linkage="strong", require/*, link_section=".init"*/)
    _odin_entry_point :: proc "c" () {
        intrinsics.__entry_point()
    }
    @(link_name="_odin_exit_point", linkage="strong", require/*, link_section=".fini"*/)
    _odin_exit_point :: proc "c" () {
    }
    @(link_name="main", linkage="strong", require)
    main :: proc "c" (argc: i32, argv: [^]cstring) -> i32 {
        return 0
    }
} else when !DUSK_TEST && !DUSK_NO_ENTRY_POINT {
    when DUSK_NO_CRT {
        // NOTE(flysand): We need to start from assembly because we need
        // to retrieve argc and argv from the stack
        when DUSK_ARCH == .amd64 {
            @(require) foreign import entry "entry_unix_no_crt_amd64.asm"
            SYS_exit :: 60
        } else when DUSK_ARCH == .i386 {
            @(require) foreign import entry "entry_unix_no_crt_i386.asm"
            SYS_exit :: 1
        } else when DUSK_OS == .Darwin && DUSK_ARCH == .arm64 {
            @(require) foreign import entry "entry_unix_no_crt_darwin_arm64.asm"
            SYS_exit :: 1
        } else when DUSK_ARCH == .riscv64 {
            @(require) foreign import entry "entry_unix_no_crt_riscv64.asm"
            SYS_exit :: 93
        }
        @(link_name="_start_odin", linkage="strong", require)
        _start_odin :: proc "c" (argc: i32, argv: [^]cstring) -> ! {
            args__ = argv[:argc]
            intrinsics.__entry_point()
            intrinsics.syscall(SYS_exit, 0)
            unreachable()
        }
    } else {
        @(link_name="main", linkage="strong", require)
        main :: proc "c" (argc: i32, argv: [^]cstring) -> i32 {
            args__ = argv[:argc]
            intrinsics.__entry_point()
            return 0
        }
    }
}
