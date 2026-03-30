/*
    (c) Copyright 2024 Feoramund <rune@swevencraft.org>.
    Made available under Odin's license.

    List of contributors:
        Feoramund: Initial implementation.
*/
import "base:container/dyn_array"

import "core:io"

write_node :: proc(w: io.Writer, node: Node) {
    switch specific in node {
    case ^Node_Rune:
        _, _ = io.write_rune(w, specific.data)

    case ^Node_Rune_Class:
        _ = io.write_byte(w, '[')
        if specific.negating {
            _ = io.write_byte(w, '^')
        }
        for r in dyn_array.slice(specific.data.runes) {
            _, _ = io.write_rune(w, r)
        }
        for range in dyn_array.slice(specific.data.ranges) {
            _, _ = io.write_rune(w, range.lower)
            _ = io.write_byte(w, '-')
            _, _ = io.write_rune(w, range.upper)
        }
        _ = io.write_byte(w, ']')

    case ^Node_Wildcard:
        _ = io.write_byte(w, '.')

    case ^Node_Concatenation:
        _, _ = io.write_rune(w, '「')
        for subnode, i in dyn_array.slice(specific.nodes) {
            if i != 0 {
                _, _ = io.write_rune(w, '⋅')
            }
            write_node(w, subnode)
        }
        _, _ = io.write_rune(w, '」')

    case ^Node_Repeat_Zero:
        write_node(w, specific.inner)
        _ = io.write_byte(w, '*')
    case ^Node_Repeat_Zero_Non_Greedy:
        write_node(w, specific.inner)
        _, _ = io.write_string(w, "*?")
    case ^Node_Repeat_One:
        write_node(w, specific.inner)
        _ = io.write_byte(w, '+')
    case ^Node_Repeat_One_Non_Greedy:
        write_node(w, specific.inner)
        _, _ = io.write_string(w, "+?")

    case ^Node_Repeat_N:
        write_node(w, specific.inner)
        if specific.lower == 0 && specific.upper == -1 {
            _ = io.write_byte(w, '*')
        } else if specific.lower == 1 && specific.upper == -1 {
            _ = io.write_byte(w, '+')
        } else {
            _ = io.write_byte(w, '{')
            _, _ = io.write_int(w, specific.lower)
            _ = io.write_byte(w, ',')
            _, _ = io.write_int(w, specific.upper)
            _ = io.write_byte(w, '}')
        }

    case ^Node_Alternation:
        _, _ = io.write_rune(w, '《')
        write_node(w, specific.left)
        _ = io.write_byte(w, '|')
        write_node(w, specific.right)
        _, _ = io.write_rune(w, '》')

    case ^Node_Optional:
        _, _ = io.write_rune(w, '〈')
        write_node(w, specific.inner)
        _ = io.write_byte(w, '?')
        _, _ = io.write_rune(w, '〉')
    case ^Node_Optional_Non_Greedy:
        _, _ = io.write_rune(w, '〈')
        write_node(w, specific.inner)
        _, _ = io.write_string(w, "??")
        _, _ = io.write_rune(w, '〉')

    case ^Node_Group:
        _ = io.write_byte(w, '(')
        if !specific.capture {
            _, _ = io.write_string(w, "?:")
        }
        write_node(w, specific.inner)
        _ = io.write_byte(w, ')')

    case ^Node_Anchor:
        _ = io.write_byte(w, '^' if specific.start else '$')

    case ^Node_Word_Boundary:
        _, _ = io.write_string(w, `\B` if specific.non_word else `\b`)

    case ^Node_Match_All_And_Escape:
        _, _ = io.write_string(w, "《.*$》")

    case nil:
        _, _ = io.write_string(w, "<nil>")
    }
}
