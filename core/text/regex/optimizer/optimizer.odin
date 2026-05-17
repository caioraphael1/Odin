/*
    (c) Copyright 2024 Feoramund <rune@swevencraft.org>.
    Made available under Odin's license.

    List of contributors:
        Feoramund: Initial implementation.
*/

import "base:container/slice"
import "base:mem"
import "base:container/dyn_array"

@(require) import "core:io"
import "core:os"
import "core:text/regex/common"
import "core:text/regex/parser"

Rune_Class_Range :: parser.Rune_Class_Range

Node                        :: parser.Node
Node_Rune                   :: parser.Node_Rune
Node_Rune_Class             :: parser.Node_Rune_Class
Node_Wildcard               :: parser.Node_Wildcard
Node_Concatenation          :: parser.Node_Concatenation
Node_Alternation            :: parser.Node_Alternation
Node_Repeat_Zero            :: parser.Node_Repeat_Zero
Node_Repeat_Zero_Non_Greedy :: parser.Node_Repeat_Zero_Non_Greedy
Node_Repeat_One             :: parser.Node_Repeat_One
Node_Repeat_One_Non_Greedy  :: parser.Node_Repeat_One_Non_Greedy
Node_Repeat_N               :: parser.Node_Repeat_N
Node_Optional               :: parser.Node_Optional
Node_Optional_Non_Greedy    :: parser.Node_Optional_Non_Greedy
Node_Group                  :: parser.Node_Group
Node_Anchor                 :: parser.Node_Anchor
Node_Word_Boundary          :: parser.Node_Word_Boundary
Node_Match_All_And_Escape   :: parser.Node_Match_All_And_Escape


class_range_sorter :: proc(i, j: Rune_Class_Range) -> bool {
    return i.lower < j.lower
}

optimize_subtree :: proc(tree: Node, flags: common.Flags, allocator: mem.Allocator) -> (result: Node, changes: int) {
    if tree == nil {
        return nil, 0
    }

    result = tree

    switch specific in tree {
    // No direct optimization possible on these nodes:
    case ^Node_Rune: break
    case ^Node_Wildcard: break
    case ^Node_Anchor: break
    case ^Node_Word_Boundary: break
    case ^Node_Match_All_And_Escape: break

    case ^Node_Concatenation:
        // * Composition: Consume All to Anchored End
        //
        // DO: `.*$` =>     <special opcode>
        // DO: `.+$` => `.` <special opcode>
        if .Multiline not_in flags && specific.nodes.len >= 2 {
            i := specific.nodes.len - 2
            wrza: {
                subnode := specific.nodes.data[i].(^Node_Repeat_Zero) or_break wrza
                _ = subnode.inner.(^Node_Wildcard) or_break wrza
                next_node := specific.nodes.data[i+1].(^Node_Anchor) or_break wrza
                if next_node.start == false {
                    specific.nodes.data[i], _ = mem.new(Node_Match_All_And_Escape, allocator)
                    _ = dyn_array.ordered_remove(&specific.nodes, i + 1)
                    changes += 1
                    break
                }
            }
            wroa: {
                subnode := specific.nodes.data[i].(^Node_Repeat_One) or_break wroa
                subsubnode := subnode.inner.(^Node_Wildcard) or_break wroa
                next_node := specific.nodes.data[i+1].(^Node_Anchor) or_break wroa
                if next_node.start == false {
                    specific.nodes.data[i] = subsubnode
                    specific.nodes.data[i+1], _ = mem.new(Node_Match_All_And_Escape, allocator)
                    changes += 1
                    break
                }
            }
        }

        // Only recursive optimizations:
        // Note(Caio): This has to be an int, otherwise we get an underflow.
        #no_bounds_check for i: int; i < int(specific.nodes.len); i += 1 {
            subnode, subnode_changes := optimize_subtree(specific.nodes.data[i], flags, allocator)
            changes += subnode_changes
            if subnode == nil {
                _ = dyn_array.ordered_remove(&specific.nodes, uint(i))
                i -= 1
                changes += 1
            } else {
                specific.nodes.data[i] = subnode
            }
        }

        if specific.nodes.len == 1 {
            result = specific.nodes.data[0]
            changes += 1
        } else if specific.nodes.len == 0 {
            return nil, changes + 1
        }

    case ^Node_Repeat_Zero:
        specific.inner, changes = optimize_subtree(specific.inner, flags, allocator)
        if specific.inner == nil {
            return nil, changes + 1
        }
    case ^Node_Repeat_Zero_Non_Greedy:
        specific.inner, changes = optimize_subtree(specific.inner, flags, allocator)
        if specific.inner == nil {
            return nil, changes + 1
        }
    case ^Node_Repeat_One:
        specific.inner, changes = optimize_subtree(specific.inner, flags, allocator)
        if specific.inner == nil {
            return nil, changes + 1
        }
    case ^Node_Repeat_One_Non_Greedy:
        specific.inner, changes = optimize_subtree(specific.inner, flags, allocator)
        if specific.inner == nil {
            return nil, changes + 1
        }
    case ^Node_Repeat_N:
        specific.inner, changes = optimize_subtree(specific.inner, flags, allocator)
        if specific.inner == nil {
            return nil, changes + 1
        }
    case ^Node_Optional:
        specific.inner, changes = optimize_subtree(specific.inner, flags, allocator)
        if specific.inner == nil {
            return nil, changes + 1
        }
    case ^Node_Optional_Non_Greedy:
        specific.inner, changes = optimize_subtree(specific.inner, flags, allocator)
        if specific.inner == nil {
            return nil, changes + 1
        }

    case ^Node_Group:
        specific.inner, changes = optimize_subtree(specific.inner, flags, allocator)

        if specific.inner == nil {
            return nil, changes + 1
        }

        if !specific.capture {
            result = specific.inner
            changes += 1
        }

    // Full optimization:
    case ^Node_Rune_Class:
        // * Class Simplification
        //
        // DO: `[aab]` => `[ab]`
        // DO: `[aa]`  => `[a]`
        runes_seen: map[rune]bool
        runes_seen.allocator = allocator

        for r in dyn_array.slice(specific.runes) {
            runes_seen[r] = true
        }

        if len(runes_seen) != specific.runes.len {
            dyn_array.clear(&specific.runes)
            for key in runes_seen {
                _ = dyn_array.append(&specific.runes, key)
            }
            changes += 1
        }

        // * Class Reduction
        //
        // DO: `[a]` => `a`
        if !specific.negating && specific.runes.len == 1 && specific.ranges.len == 0 {
            only_rune := specific.runes.data[0]

            node, _ := mem.new(Node_Rune, allocator)
            node.data = only_rune

            return node, changes + 1
        }

        // * Range Construction
        //
        // DO: `[abc]` => `[a-c]`
        slice.sort(dyn_array.slice(specific.runes))
        if specific.runes.len > 1 {
            new_range: Rune_Class_Range
            new_range.lower = specific.runes.data[0]
            new_range.upper = specific.runes.data[0]
            // Note(Caio): This has to be an int, otherwise we get an underflow.
            #no_bounds_check for i: int = 1; i < int(specific.runes.len); i += 1 {
                r := specific.runes.data[i]
                if new_range.lower == -1 {
                    new_range = { r, r }
                    continue
                }

                if r == new_range.lower - 1 {
                    new_range.lower -= 1
                    os.assert(dyn_array.ordered_remove(&specific.runes, uint(i)))
                    i -= 1
                    changes += 1
                } else if r == new_range.upper + 1 {
                    new_range.upper += 1
                    os.assert(dyn_array.ordered_remove(&specific.runes, uint(i)))
                    i -= 1
                    changes += 1
                } else if new_range.lower != new_range.upper {
                    _ = dyn_array.append(&specific.ranges, new_range)
                    new_range = { -1, -1 }
                    changes += 1
                }
            }

            if new_range.lower != new_range.upper {
                _ = dyn_array.append(&specific.ranges, new_range)
                changes += 1
            }
        }

        // * Rune Merging into Range
        //
        // DO: `[aa-c]` => `[a-c]`
        for range in dyn_array.slice(specific.ranges) {
            // Note(Caio): This has to be an int, otherwise we get an underflow.
            #no_bounds_check for i: int; i < int(specific.runes.len); i += 1 {
                r := specific.runes.data[i]
                if range.lower <= r && r <= range.upper {
                    os.assert(dyn_array.ordered_remove(&specific.runes, uint(i)))
                    i -= 1
                    changes += 1
                }
            }
        }

        // * Range Merging
        //
        // DO: `[a-cc-e]` => `[a-e]`
        // DO: `[a-cd-e]` => `[a-e]`
        // DO: `[a-cb-e]` => `[a-e]`
        slice.sort_by(dyn_array.slice(specific.ranges), class_range_sorter)
        // Note(Caio): This has to be an int, otherwise we get an underflow.
        #no_bounds_check for i: int; i < int(specific.ranges.len) - 1; i += 1 {
            for j := i + 1; j < int(specific.ranges.len); j += 1 {
                left_range  := &specific.ranges.data[i]
                right_range :=  specific.ranges.data[j]

                if left_range.upper == right_range.lower     ||
                   left_range.upper == right_range.lower - 1 ||
                   left_range.lower <= right_range.lower && right_range.lower <= left_range.upper {
                    left_range.upper = max(left_range.upper, right_range.upper)
                    os.assert(dyn_array.ordered_remove(&specific.ranges, uint(j)))
                    j -= 1
                    changes += 1
                } else {
                    break
                }
            }
        }

        if specific.ranges.len == 0 {
            specific.ranges = {}
        }
        if specific.runes.len == 0 {
            specific.runes = {}
        }

        // * NOP
        //
        // DO: `[]` => <nil>
        if specific.ranges.len + specific.runes.len == 0 {
            return nil, 1
        }

        slice.sort(dyn_array.slice(specific.runes))
        slice.sort_by(dyn_array.slice(specific.ranges), class_range_sorter)

    case ^Node_Alternation:
        // Perform recursive optimization first.
        left_changes, right_changes: int
        specific.left, left_changes = optimize_subtree(specific.left, flags, allocator)
        specific.right, right_changes = optimize_subtree(specific.right, flags, allocator)
        changes += left_changes + right_changes

        // * Alternation to Optional
        //
        // DO: `a|` => `a?`
        if specific.left != nil && specific.right == nil {
            node, _ := mem.new(Node_Optional, allocator)
            node.inner = specific.left
            return node, 1
        }

        // * Alternation to Optional Non-Greedy
        //
        // DO: `|a` => `a??`
        if specific.right != nil && specific.left == nil {
            node, _ := mem.new(Node_Optional_Non_Greedy, allocator)
            node.inner = specific.right
            return node, 1
        }

        // * NOP
        //
        // DO: `|` => <nil>
        if specific.left == nil && specific.right == nil {
            return nil, 1
        }

        left_rune, left_is_rune := specific.left.(^Node_Rune)
        right_rune, right_is_rune := specific.right.(^Node_Rune)

        if left_is_rune && right_is_rune {
            if left_rune.data == right_rune.data {
                // * Alternation Reduction
                //
                // DO: `a|a` => `a`
                return left_rune, 1
            } else {
                // * Alternation to Class
                //
                // DO: `a|b` => `[ab]`
                node, _ := mem.new(Node_Rune_Class, allocator)
                _ = dyn_array.append(&node.runes, left_rune.data)
                _ = dyn_array.append(&node.runes, right_rune.data)
                return node, 1
            }
        }

        left_wildcard, left_is_wildcard := specific.left.(^Node_Wildcard)
        right_wildcard, right_is_wildcard := specific.right.(^Node_Wildcard)

        // * Class Union
        //
        // DO: `[a0]|[b1]` => `[a0b1]`
        left_class, left_is_class := specific.left.(^Node_Rune_Class)
        right_class, right_is_class := specific.right.(^Node_Rune_Class)
        if left_is_class && right_is_class {
            for r in dyn_array.slice(right_class.runes) {
                _ = dyn_array.append(&left_class.runes, r)
            }
            for range in dyn_array.slice(right_class.ranges) {
                _ = dyn_array.append(&left_class.ranges, range)
            }
            return left_class, 1
        }

        // * Class Union
        //
        // DO: `[a-b]|c` => `[a-bc]`
        if left_is_class && right_is_rune {
            _ = dyn_array.append(&left_class.runes, right_rune.data)
            return left_class, 1
        }

        // * Class Union
        //
        // DO: `a|[b-c]` => `[b-ca]`
        if left_is_rune && right_is_class {
            _ = dyn_array.append(&right_class.runes, left_rune.data)
            return right_class, 1
        }

        // * Wildcard Reduction
        //
        // DO: `a|.` => `.`
        if left_is_rune && right_is_wildcard {
            return right_wildcard, 1
        }

        // * Wildcard Reduction
        //
        // DO: `.|a` => `.`
        if left_is_wildcard && right_is_rune {
            return left_wildcard, 1
        }

        // * Wildcard Reduction
        //
        // DO: `[ab]|.` => `.`
        if left_is_class && right_is_wildcard {
            return right_wildcard, 1
        }

        // * Wildcard Reduction
        //
        // DO: `.|[ab]` => `.`
        if left_is_wildcard && right_is_class {
            return left_wildcard, 1
        }

        left_concatenation, left_is_concatenation := specific.left.(^Node_Concatenation)
        right_concatenation, right_is_concatenation := specific.right.(^Node_Concatenation)

        // * Common Suffix Elimination
        //
        // DO: `blueberry|strawberry` => `(?:blue|straw)berry`
        if left_is_concatenation && right_is_concatenation {
            // Remember that a concatenation could contain any node, not just runes.
            left_len  := left_concatenation.nodes.len
            right_len := right_concatenation.nodes.len
            least_len := min(left_len, right_len)
            same_len: uint
            // Note(Caio): This has to be an int, otherwise we get an underflow.
            for i: int = 1; i <= int(least_len); i += 1 {
                left_subrune,  left_is_subrune  := left_concatenation.nodes.data[int(left_len) - i].(^Node_Rune)
                right_subrune, right_is_subrune := right_concatenation.nodes.data[int(right_len) - i].(^Node_Rune)

                if !left_is_subrune || !right_is_subrune {
                    // One of the nodes isn't a rune; there's nothing more we can do.
                    break
                }

                if left_subrune.data == right_subrune.data {
                    same_len += 1
                } else {
                    // No more similarities.
                    break
                }
            }

            if same_len > 0 {
                // Dissolve this alternation into a concatenation.
                cat_node, _ := mem.new(Node_Concatenation, allocator)
                group_node, _ := mem.new(Node_Group, allocator)
                _ = dyn_array.append(&cat_node.nodes, group_node)

                // Turn the concatenation into the common suffix.
                for i := left_len - same_len; i < left_len; i += 1 {
                    _ = dyn_array.append(&cat_node.nodes, left_concatenation.nodes.data[i])
                }

                // Construct the group of alternating prefixes.
                for i := same_len; i > 0; i -= 1 {
                    _, _ = dyn_array.pop_back(&left_concatenation.nodes)
                    _, _ = dyn_array.pop_back(&right_concatenation.nodes)
                }

                // (Re-using this alternation node.)
                alter_node := specific
                alter_node.left = left_concatenation
                alter_node.right = right_concatenation
                group_node.inner = alter_node

                return cat_node, 1
            }
        }

        // * Common Prefix Elimination
        //
        // DO: `abi|abe` => `ab(?:i|e)`
        if left_is_concatenation && right_is_concatenation {
            // Try to identify a common prefix.
            // Remember that a concatenation could contain any node, not just runes.
            least_len := min(left_concatenation.nodes.len, right_concatenation.nodes.len)
            same_len: int
            // Note(Caio): This has to be an int, otherwise we get an underflow.
            for i: int; i < int(least_len); i += 1 {
                left_subrune,  left_is_subrune  := left_concatenation.nodes.data[i].(^Node_Rune)
                right_subrune, right_is_subrune := right_concatenation.nodes.data[i].(^Node_Rune)

                if !left_is_subrune || !right_is_subrune {
                    // One of the nodes isn't a rune; there's nothing more we can do.
                    break
                }

                if left_subrune.data == right_subrune.data {
                    same_len = i + 1
                } else {
                    // No more similarities.
                    break
                }
            }

            if same_len > 0 {
                cat_node, _ := mem.new(Node_Concatenation, allocator)
                // Note(Caio): This has to be an int, otherwise we get an underflow.
                for i: int; i < int(same_len); i += 1 {
                    _ = dyn_array.append(&cat_node.nodes, left_concatenation.nodes.data[i])
                }
                for i := same_len; i > 0; i -= 1 {
                    _ = dyn_array.ordered_remove(&left_concatenation.nodes, 0)
                    _ = dyn_array.ordered_remove(&right_concatenation.nodes, 0)
                }

                group_node, _ := mem.new(Node_Group, allocator)
                // (Re-using this alternation node.)
                alter_node := specific
                alter_node.left = left_concatenation
                alter_node.right = right_concatenation
                group_node.inner = alter_node

                _ = dyn_array.append(&cat_node.nodes, group_node)
                return cat_node, 1
            }
        }
    }

    return
}

optimize :: proc(tree: Node, flags: common.Flags, allocator: mem.Allocator) -> (result: Node, changes: int) {
    result = tree
    new_changes := 0

    when common.ODIN_DEBUG_REGEX {
        io.write_string(common.debug_stream, "AST before Optimizer: ")
        parser.write_node(common.debug_stream, tree)
        io.write_byte(common.debug_stream, '\n')
    }

    // Keep optimizing until no more changes are seen.
    for {
        result, new_changes = optimize_subtree(result, flags, allocator)
        changes += new_changes
        if new_changes == 0 {
            break
        }
    }

    when common.ODIN_DEBUG_REGEX {
        io.write_string(common.debug_stream, "AST after Optimizer: ")
        parser.write_node(common.debug_stream, result)
        io.write_byte(common.debug_stream, '\n')
    }


    return
}
