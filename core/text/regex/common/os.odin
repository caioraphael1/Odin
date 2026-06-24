#+build !freestanding
#+build !js


/*
    (c) Copyright 2024 Feoramund <rune@swevencraft.org>.
    Made available under Dusk's license.

    List of contributors:
        Feoramund: Initial implementation.
*/

@(require) import "core:os"

when DUSK_DEBUG_REGEX {
    debug_stream := os.stderr.stream
}
