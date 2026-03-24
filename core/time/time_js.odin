#+private
#+build js
foreign import "odin_env"

_IS_SUPPORTED :: true

_now :: proc() -> Time {
    foreign odin_env {
        time_now :: proc() -> i64 ---
    }
    return Time{time_now()*1e6}
}

_sleep :: proc(d: Duration) {
    foreign odin_env {
        time_sleep :: proc(ms: u32) ---
    }
    if d > 0 {
        time_sleep(u32(d/1e6))
    }
}

_tick_now :: proc() -> Tick {
    foreign odin_env {
        tick_now :: proc() -> f64 ---
    }
    return Tick{i64(tick_now()*1e6)}
}

_yield :: proc() {
}
