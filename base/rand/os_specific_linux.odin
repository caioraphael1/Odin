#+private
import "base:intrinsics"

_HAS_RAND_BYTES :: true


_rand_bytes :: proc(dst: []byte) {
    when ODIN_ARCH == .amd64 {
        SYS_getrandom :: uintptr(318)
    } else when ODIN_ARCH == .arm64 {
        SYS_getrandom :: uintptr(278)
    } else when ODIN_ARCH == .i386 {
        SYS_getrandom :: uintptr(355)
    } else when ODIN_ARCH == .arm32 {
        SYS_getrandom :: uintptr(384)
    } else when ODIN_ARCH == .riscv64 {
        SYS_getrandom :: uintptr(278)
    } else {
        #panic("base/runtime: no SYS_getrandom definition for target")
    }

    ERR_EINTR :: 4
    ERR_ENOSYS :: 38

    MAX_PER_CALL_BYTES :: 33554431 // 2^25 - 1

    dst := dst
    l := len(dst)

    for l > 0 {
        to_read := min(l, MAX_PER_CALL_BYTES)
        ret := int(intrinsics.syscall(SYS_getrandom, uintptr(raw_data(dst[:to_read])), uintptr(to_read), uintptr(0)))
        switch ret {
        case -ERR_EINTR:
            // Call interupted by a signal handler, just retry the
            // request.
            continue
        case -ERR_ENOSYS:
            // The kernel is apparently prehistoric (< 3.17 circa 2014)
            // and does not support getrandom.
            panic("base/runtime: getrandom not available in kernel")
        case:
            if ret < 0 {
                // All other failures are things that should NEVER happen
                // unless the kernel interface changes (ie: the Linux
                // developers break userland).
                panic("base/runtime: getrandom failed")
            }
        }
        l -= ret
        dst = dst[ret:]
    }
}
