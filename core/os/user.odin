import "base:internal"
import "base:mem"

// ```
// Windows:  C:\Users\Alice
// macOS:    /Users/Alice
// Linux:    /home/alice
// ```

user_home_dir :: proc(allocator: mem.Allocator) -> (dir: string, err: Error) {
    return _user_home_dir(allocator)
}

// Files that applications can regenerate/refetch at a loss of speed, e.g. shader caches
//
// Sometimes deleted for system maintenance
//
// ```
// Windows:  C:\Users\Alice\AppData\Local
// macOS:    /Users/Alice/Library/Caches
// Linux:    /home/alice/.cache
// ```

user_cache_dir :: proc(allocator: mem.Allocator) -> (dir: string, err: Error) {
    return _user_cache_dir(allocator)
}

// User-hidden application data
//
// ```
// Windows:  C:\Users\Alice\AppData\Local ("C:\Users\Alice\AppData\Roaming" if `roaming`)
// macOS:    /Users/Alice/Library/Application Support
// Linux:    /home/alice/.local/share
// ```
//
// NOTE: (Windows only) `roaming` is for syncing across multiple devices within a *domain network*

user_data_dir :: proc(allocator: mem.Allocator, roaming := false) -> (dir: string, err: Error) {
    return _user_data_dir(allocator, roaming)
}

// Non-essential application data, e.g. history, ui layout state
//
// ```
// Windows:  C:\Users\Alice\AppData\Local
// macOS:    /Users/Alice/Library/Application Support
// Linux:    /home/alice/.local/state
// ```

user_state_dir :: proc(allocator: mem.Allocator) -> (dir: string, err: Error) {
    return _user_state_dir(allocator)
}

// Application log files
//
// ```
// Windows:  C:\Users\Alice\AppData\Local
// macOS:    /Users/Alice/Library/Logs
// Linux:    /home/alice/.local/state
// ```

user_log_dir :: proc(allocator: mem.Allocator) -> (dir: string, err: Error) {
    return _user_log_dir(allocator)
}

// Application settings/preferences
//
// ```
// Windows:  C:\Users\Alice\AppData\Local ("C:\Users\Alice\AppData\Roaming" if `roaming`)
// macOS:    /Users/Alice/Library/Application Support
// Linux:    /home/alice/.config
// ```
//
// NOTE: (Windows only) `roaming` is for syncing across multiple devices within a *domain network*

user_config_dir :: proc(allocator: mem.Allocator, roaming := false) -> (dir: string, err: Error) {
    return _user_config_dir(allocator, roaming)
}

// ```
// Windows:  C:\Users\Alice\Music
// macOS:    /Users/Alice/Music
// Linux:    /home/alice/Music
// ```

user_music_dir :: proc(allocator: mem.Allocator) -> (dir: string, err: Error) {
    return _user_music_dir(allocator)
}

// ```
// Windows:  C:\Users\Alice\Desktop
// macOS:    /Users/Alice/Desktop
// Linux:    /home/alice/Desktop
// ```

user_desktop_dir :: proc(allocator: mem.Allocator) -> (dir: string, err: Error) {
    return _user_desktop_dir(allocator)
}

// ```
// Windows:  C:\Users\Alice\Documents
// macOS:    /Users/Alice/Documents
// Linux:    /home/alice/Documents
// ```

user_documents_dir :: proc(allocator: mem.Allocator) -> (dir: string, err: Error) {
    return _user_documents_dir(allocator)
}

// ```
// Windows:  C:\Users\Alice\Downloads
// macOS:    /Users/Alice/Downloads
// Linux:    /home/alice/Downloads
// ```

user_downloads_dir :: proc(allocator: mem.Allocator) -> (dir: string, err: Error) {
    return _user_downloads_dir(allocator)
}

// ```
// Windows:  C:\Users\Alice\Pictures
// macOS:    /Users/Alice/Pictures
// Linux:    /home/alice/Pictures
// ```

user_pictures_dir :: proc(allocator: mem.Allocator) -> (dir: string, err: Error) {
    return _user_pictures_dir(allocator)
}

// ```
// Windows:  C:\Users\Alice\Public
// macOS:    /Users/Alice/Public
// Linux:    /home/alice/Public
// ```

user_public_dir :: proc(allocator: mem.Allocator) -> (dir: string, err: Error) {
    return _user_public_dir(allocator)
}

// ```
// Windows:  C:\Users\Alice\Videos
// macOS:    /Users/Alice/Movies
// Linux:    /home/alice/Videos
// ```

user_videos_dir :: proc(allocator: mem.Allocator) -> (dir: string, err: Error) {
    return _user_videos_dir(allocator)
}
