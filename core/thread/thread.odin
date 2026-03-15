// Multi-threading operations to spawn threads and thread pools.
import "base:internal"
import "base:mem"
@(require) import "base:intrinsics"


IS_SUPPORTED :: _IS_SUPPORTED
MAX_USER_ARGUMENTS :: 8


Thread_Proc :: #type proc(^Thread)


Thread_State :: enum u8 {
    Started,
    Joined,
    Done,
    Self_Cleanup,
}


Thread :: struct {
    using specific:     Thread_Os_Specific,
    flags:              bit_set[Thread_State; u8],

    // Thread ID. Depending on the platform, may start out as 0 (zero) until the thread
    // has had a chance to run.
    id:                 int,

    // The thread procedure.
    procedure:          Thread_Proc,

    // User-supplied pointer, that will be available to the thread once it is
    // started. Should be set after the thread has been created, but before
    // it is started.
    data:               rawptr,

    // User-supplied integer, that will be available to the thread once it is
    // started. Should be set after the thread has been created, but before
    // it is started.
    user_index:         int,

    // User-supplied array of arguments, that will be available to the thread,
    // once it is started. Should be set after the thread has been created,
    // but before it is started.
    user_args:          [MAX_USER_ARGUMENTS]rawptr,

    // The allocator used to allocate data for the thread.
    creation_allocator: mem.Allocator,
}

when IS_SUPPORTED {
    #assert(size_of(Thread{}.user_index) == size_of(uintptr))
}


Thread_Priority :: enum {
    Normal,
    Low,
    High,
}


Thread_Create_Error :: enum {
    None,
    Create_Failure,
    Set_Thread_Priority_Failure,
}

/*
The thread will be in a suspended state, until `start()` procedure is called.
*/
create :: proc(thread: ^Thread, procedure: Thread_Proc, priority := Thread_Priority.Normal) -> (err: Thread_Create_Error) {
    return _create(thread, procedure, priority)
}

/*
Starts a suspended thread.
*/
start :: proc(thread: ^Thread) {
    _start(thread)
}


create_and_start :: proc(thread: ^Thread, procedure: proc(), priority := Thread_Priority.Normal, self_cleanup := false) -> (err: Thread_Create_Error) {
    thread_proc :: proc(t: ^Thread) {
        procedure := cast(proc())t.data
        procedure()
    }

    _create(thread, thread_proc, priority) or_return

    thread.data = rawptr(procedure)
    if self_cleanup {
        intrinsics.atomic_or(&thread.flags, { .Self_Cleanup })
    }
    _start(thread)

    return
}

destroy :: proc(thread: ^Thread) {
    _destroy(thread)
}

wait :: proc(thread: ^Thread) {
    _wait(thread)
}

wait_many :: proc(threads: ..Thread) {
    _wait_many(..threads)
}

close :: proc(thread: ^Thread) {
    _close(thread)
}


/*
Forcibly terminate/cancel a running thread.
*/
terminate :: proc(thread: ^Thread, exit_code: int) {
    _terminate(thread, exit_code)
}

/*
Check if the thread has finished work.
*/
is_done :: proc(thread: ^Thread) -> bool {
    return _is_done(thread)
}

/*
Yield the execution of the current thread to another OS thread or process.
*/
yield :: proc() {
    _yield()
}

