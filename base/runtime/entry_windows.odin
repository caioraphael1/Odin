#+private
#+build windows
#+no-instrumentation
package runtime

import "base:intrinsics"

when ODIN_BUILD_MODE == .Dynamic {
    @(link_name="DllMain", linkage="strong", require)
    DllMain :: proc "system" (hinstDLL: rawptr, fdwReason: u32, lpReserved: rawptr) -> b32 {
        context = {}

        // Populate Windows DLL-specific globals
        dll_forward_reason = DLL_Forward_Reason(fdwReason)
        dll_instance       = hinstDLL

        switch dll_forward_reason {
        case .Process_Attach:
            intrinsics.__entry_point()
        case .Process_Detach:
        case .Thread_Attach:
            break
        case .Thread_Detach:
            break
        }
        return true
    }
} else when !ODIN_TEST && !ODIN_NO_ENTRY_POINT {
    when ODIN_ARCH == .i386 && !ODIN_NO_CRT {
        // Windows i386 with CRT: libcmt provides mainCRTStartup which calls _main
        // Note: "c" calling convention adds underscore prefix automatically on i386
        @(link_name="main", linkage="strong", require)
        main :: proc "c" (argc: i32, argv: [^]cstring) -> i32 {
            context = {}
            args__ = argv[:argc]
            intrinsics.__entry_point()
            return 0
        }
    } else when ODIN_NO_CRT {
        @(link_name="mainCRTStartup", linkage="strong", require)
        mainCRTStartup :: proc "system" () -> i32 {
            context = {}
            intrinsics.__entry_point()
            return 0
        }
    } else {
        @(link_name="main", linkage="strong", require)
        main :: proc "c" (argc: i32, argv: [^]cstring) -> i32 {
            context = {}
            args__ = argv[:argc]
            intrinsics.__entry_point()
            return 0
        }
    }
}
