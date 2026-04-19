#+build !freestanding
#+build !js

import "core:strings_tools"

// Reference documentation:
//
// - [[ https://no-color.org/ ]]
// - [[ https://github.com/termstandard/colors ]]
// - [[ https://invisible-island.net/ncurses/terminfo.src.html ]]


/*
This describes the range of colors that a terminal is capable of supporting.
*/
Color_Depth :: enum {
    None,       // No color support
    Three_Bit,  // 8 colors
    Four_Bit,   // 16 colors
    Eight_Bit,  // 256 colors
    True_Color, // 24-bit true color
}


/*
This is true if the terminal is accepting any form of colored text output.
*/
color_enabled: bool

/*
This value reports the color depth support as reported by the terminal at the
start of the program.
*/
color_depth: Color_Depth


terminal_colors_init :: proc() {
    _terminal_colors_init()

    // We respect `NO_COLOR` specifically as a color-disabler but not as a
    // blanket ban on any terminal manipulation codes, hence why this comes
    // after `_terminal_colors_init` which will allow Windows to enable Virtual
    // Terminal Processing for non-color control sequences.
    if !get_no_color() {
        color_enabled = color_depth > .None
    }
}


terminal_colors_deinit :: proc() {
    _terminal_colors_deinit()
}


@(private)
get_no_color :: proc() -> bool {
    buf: [128]u8
    if no_color, err := lookup_env_buf(buf[:], "NO_COLOR"); err == nil {
        return no_color != ""
    }
    return false
}

@(private)
get_environment_color :: proc() -> Color_Depth {
    buf: [128]u8
    // `COLORTERM` is non-standard but widespread and unambiguous.
    if colorterm, err := lookup_env_buf(buf[:], "COLORTERM"); err == nil {
        // These are the only values that are typically advertised that have
        // anything to do with color depth.
        if colorterm == "truecolor" || colorterm == "24bit" {
            return .True_Color
        }
    }

    if term, err := lookup_env_buf(buf[:], "TERM"); err == nil {
        if strings_tools.contains(term, "-truecolor") {
            return .True_Color
        }
        if strings_tools.contains(term, "-256color") {
            return .Eight_Bit
        }
        if strings_tools.contains(term, "-16color") {
            return .Four_Bit
        }

        // The `terminfo` database, which is stored in binary on *nix
        // platforms, has an undocumented format that is not guaranteed to be
        // portable, so beyond this point, we can only make safe assumptions.
        //
        // This section should only be necessary for terminals that do not
        // define any of the previous environment values.
        //
        // Only a small sampling of some common values are checked here.
        switch term {
        case "ansi", "konsole", "putty", "rxvt", "rxvt-color", "screen",
             "st", "tmux", "vte", "xterm", "xterm-color":
            return .Three_Bit
        }
    }

    return .None
}
