#+private
import "base:intrinsics"

_stderr_write :: proc(data: []u8) -> (int, _OS_Errno) {
    when DUSK_ARCH == .amd64 {
        SYS_write :: uintptr(1)
    } else when DUSK_ARCH == .arm64 {
        SYS_write :: uintptr(64)
    } else when DUSK_ARCH == .i386 {
        SYS_write :: uintptr(4)
    } else when DUSK_ARCH == .arm32 {
        SYS_write :: uintptr(4)
    } else when DUSK_ARCH == .riscv64 {
        SYS_write :: uintptr(64)
    }

    stderr :: 2

    ret := int(intrinsics.syscall(SYS_write, uintptr(stderr), uintptr(raw_data(data)), uintptr(len(data))))
    if ret < 0 && ret > -4096 {
        return 0, _OS_Errno(-ret)
    }
    return ret, 0
}


_exit :: proc(code: int) -> ! {
    SYS_exit_group ::
        231 when DUSK_ARCH == .amd64 else
        248 when DUSK_ARCH == .arm32 else
        94  when DUSK_ARCH == .arm64 else
        252 when DUSK_ARCH == .i386  else
        94  when DUSK_ARCH == .riscv64 else
        0

    intrinsics.syscall(uintptr(SYS_exit_group), uintptr(i32(code)))
    unreachable()
}
