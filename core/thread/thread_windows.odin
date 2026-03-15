#+build windows
#+private
import "base:internal"
import "base:intrinsics"
import "base:mem"

import "core:sync"
import win32 "core:sys/windows"

_IS_SUPPORTED :: true

Thread_Os_Specific :: struct {
    win32_thread:    win32.HANDLE,
    win32_thread_id: win32.DWORD,
    mutex:           sync.Mutex,
    start_ok:        sync.Sema,
}

_thread_priority_map := [Thread_Priority]i32{
    .Normal = 0,
    .Low = -2,
    .High = +2,
}


_create :: proc(thread: ^Thread, procedure: Thread_Proc, priority: Thread_Priority) -> (err: Thread_Create_Error) {
    _windows_thread_entry_proc :: proc "system" (thread_: rawptr) -> win32.DWORD {        
        thread := (^Thread)(thread_)
        for (.Started not_in sync.atomic_load(&thread.flags)) {
            sync.sema_wait(&thread.start_ok)
        }

        thread.procedure(thread)

        intrinsics.atomic_or(&thread.flags, { .Done })
        if .Self_Cleanup in sync.atomic_load(&thread.flags) {
            _ = win32.CloseHandle(thread.win32_thread)
            thread.win32_thread = win32.INVALID_HANDLE
        }

        return 0
    }

    thread^ = {}

    win32_thread_id: win32.DWORD
    win32_thread := win32.CreateThread(
        lpThreadAttributes = nil,
        dwStackSize        = 0,
        lpStartAddress     = _windows_thread_entry_proc,
        lpParameter        = thread,
        dwCreationFlags    = win32.CREATE_SUSPENDED,
        lpThreadId         = &win32_thread_id,
    )
    if win32_thread == nil {
        return .Create_Failure
    }

    thread.procedure       = procedure
    thread.win32_thread    = win32_thread
    thread.win32_thread_id = win32_thread_id
    thread.id              = int(win32_thread_id)

    ok := win32.SetThreadPriority(win32_thread, _thread_priority_map[priority])
    if !ok {
        return .Set_Thread_Priority_Failure
    }

    return
}

_destroy :: proc(thread: ^Thread) {
    _wait(thread)
    _close(thread)
}


_wait :: proc(thread: ^Thread) {
    sync.mutex_guard(&thread.mutex)

    if .Joined in thread.flags || thread.win32_thread == win32.INVALID_HANDLE {
        return
    }

    for (.Started not_in sync.atomic_load(&thread.flags)) {
        _start(thread)
    }

    _ = win32.WaitForSingleObject(thread.win32_thread, win32.INFINITE)
}

_wait_many :: proc(threads: ..Thread) {
    MAXIMUM_WAIT_OBJECTS :: 64
    handles: [MAXIMUM_WAIT_OBJECTS]win32.HANDLE

    for k := 0; k < len(threads); k += MAXIMUM_WAIT_OBJECTS {
        count := min(len(threads) - k, MAXIMUM_WAIT_OBJECTS)
        j := 0
        for i in 0..<count {
            handle := threads[i+k].win32_thread
            if handle != win32.INVALID_HANDLE {
                handles[j] = handle
                j += 1
            }
        }
        _ = win32.WaitForMultipleObjects(u32(j), &handles[0], true, win32.INFINITE)
    }
}

_close :: proc(thread: ^Thread) {
    sync.mutex_guard(&thread.mutex)

    _ = win32.CloseHandle(thread.win32_thread)
    thread.win32_thread = win32.INVALID_HANDLE
    thread.flags += { .Joined }
}


_terminate :: proc(thread: ^Thread, exit_code: int) {
    _ = win32.TerminateThread(thread.win32_thread, u32(exit_code))
}

_start :: proc(thread: ^Thread) {
    sync.mutex_guard(&thread.mutex)
    
    thread.flags += {.Started}
    _ = win32.ResumeThread(thread.win32_thread)
}

_is_done :: proc(thread: ^Thread) -> bool {
    // NOTE(tetra, 2019-10-31): Apparently using wait_for_single_object and
    // checking if it didn't time out immediately, is not good enough,
    // so we do it this way instead.
    return .Done in sync.atomic_load(&thread.flags)
}

_yield :: proc() {
    _ = win32.SwitchToThread()
}

