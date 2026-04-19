#+private

import win32 "core:sys/windows"


_old_modes: [2]struct{
    handle: win32.DWORD,
    mode:   win32.DWORD,
    } = {
    { win32.STD_OUTPUT_HANDLE, 0 },
    { win32.STD_ERROR_HANDLE,  0 },
}

_terminal_colors_init :: proc() {
    vtp_enabled: bool

    for &v in _old_modes {
        handle := win32.GetStdHandle(v.handle)
        if handle == win32.INVALID_HANDLE || handle == nil {
            return
        }
        if win32.GetConsoleMode(handle, &v.mode) {
            _ = win32.SetConsoleMode(handle, v.mode | win32.ENABLE_PROCESSED_OUTPUT | win32.ENABLE_VIRTUAL_TERMINAL_PROCESSING)

            new_mode: win32.DWORD
            _ = win32.GetConsoleMode(handle, &new_mode)

            if new_mode & (win32.ENABLE_PROCESSED_OUTPUT | win32.ENABLE_VIRTUAL_TERMINAL_PROCESSING) != 0 {
                vtp_enabled = true
            }
        }
    }

    if vtp_enabled {
        // This color depth is available on Windows 10 since build 10586.
        color_depth = .Four_Bit
    } else {

        // The user may be on a non-default terminal emulator.
        color_depth = get_environment_color()
    }
}

_terminal_colors_deinit :: proc() {
    // Restore to previous console modes
    for v in _old_modes {
        handle := win32.GetStdHandle(v.handle)
        if handle == win32.INVALID_HANDLE || handle == nil {
            return
        }
        
        _ = win32.SetConsoleMode(handle, v.mode)
    }
}
