#+private
#+build linux, darwin, netbsd, openbsd, freebsd, haiku


_terminal_colors_init :: proc() {
    color_depth = get_environment_color()
}

_terminal_colors_deinit :: proc() {
}
