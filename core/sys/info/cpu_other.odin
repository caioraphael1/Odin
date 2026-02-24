#+build openbsd, freebsd, netbsd, essence, haiku

@(private)
_cpu_core_count :: proc() -> (physical: int, logical: int, ok: bool) {
    return 0, 0, false
}

when ODIN_ARCH == .arm32 || ODIN_ARCH == .arm64 {
    @(private)
    _cpu_features :: proc() -> (features: CPU_Features) {
        return {}
    }
}
