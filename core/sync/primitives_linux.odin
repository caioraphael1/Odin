#+build linux
#+private
import "core:sys/linux"

_current_thread_id :: proc() -> int {
	return cast(int) linux.gettid()
}
