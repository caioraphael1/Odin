/*
    (c) Copyright 2024 Feoramund <rune@swevencraft.org>.
    Made available under Odin's license.

    List of contributors:
        Feoramund: Initial implementation.
*/

import "base:internal"
import "base:intrinsics"
import "base:mem"
import "base:container/dyn_array"

import "core:text/regex/common"
import "core:text/regex/parser"
import "core:text/regex/tokenizer"
import "core:text/regex/virtual_machine"
import "base:unicode"

Token      :: tokenizer.Token
Token_Kind :: tokenizer.Token_Kind
Tokenizer  :: tokenizer.Tokenizer

Rune_Class_Range            :: parser.Rune_Class_Range
Rune_Class_Data             :: parser.Rune_Class_Data

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

Opcode :: virtual_machine.Opcode
Program  :: dyn_array.Dyn_Array(Opcode)

JUMP_SIZE  :: size_of(Opcode) + 1 * size_of(u16)
SPLIT_SIZE :: size_of(Opcode) + 2 * size_of(u16)


Compiler :: struct {
    flags: common.Flags,
    class_data: dyn_array.Dyn_Array(Rune_Class_Data),
}


Error :: enum {
    None,
    Program_Too_Big,
    Too_Many_Classes,
}

classes_are_exact :: proc(q, w: ^Rune_Class_Data) -> bool #no_bounds_check {
    internal.assert(q != nil)
    internal.assert(w != nil)

    if q == w {
        return true
    }

    if q.runes.len != w.runes.len || q.ranges.len != w.ranges.len {
        return false
    }

    for r, i in dyn_array.slice(q.runes) {
        if r != w.runes.data[i] {
            return false
        }
    }

    for r, i in dyn_array.slice(q.ranges) {
        if r.lower != w.ranges.data[i].lower || r.upper != w.ranges.data[i].upper {
            return false
        }
    }

    return true
}

map_all_classes :: proc(tree: Node, collection: ^dyn_array.Dyn_Array(Rune_Class_Data)) {
    if tree == nil {
        return
    }

    switch specific in tree {
    case ^Node_Rune: break
    case ^Node_Wildcard: break
    case ^Node_Anchor: break
    case ^Node_Word_Boundary: break
    case ^Node_Match_All_And_Escape: break

    case ^Node_Concatenation:
        for subnode in dyn_array.slice(specific.nodes) {
            map_all_classes(subnode, collection)
        }

    case ^Node_Repeat_Zero:
        map_all_classes(specific.inner, collection)
    case ^Node_Repeat_Zero_Non_Greedy:
        map_all_classes(specific.inner, collection)
    case ^Node_Repeat_One:
        map_all_classes(specific.inner, collection)
    case ^Node_Repeat_One_Non_Greedy:
        map_all_classes(specific.inner, collection)
    case ^Node_Repeat_N:
        map_all_classes(specific.inner, collection)
    case ^Node_Optional:
        map_all_classes(specific.inner, collection)
    case ^Node_Optional_Non_Greedy:
        map_all_classes(specific.inner, collection)
    case ^Node_Group:
        map_all_classes(specific.inner, collection)

    case ^Node_Alternation:
        map_all_classes(specific.left, collection)
        map_all_classes(specific.right, collection)

    case ^Node_Rune_Class:
        unseen := true
        for &value in dyn_array.slice(collection^) {
            if classes_are_exact(&specific.data, &value) {
                unseen = false
                break
            }
        }

        if unseen {
            _ = dyn_array.append(collection, specific.data)
        }
    }
}

append_raw :: #force_inline proc(code: ^Program, data: $T) {
    // NOTE: This is system-dependent endian.
    for b in transmute([size_of(T)]u8)data {
        _ = dyn_array.append(code, cast(Opcode)b)
    }
}

inject_raw :: #force_inline proc(code: ^Program, start: uint, data: $T) {
    // NOTE: This is system-dependent endian.
    for b, i in transmute([size_of(T)]u8)data {
        _, _ = dyn_array.inject_at(code, start + i, cast(Opcode)b)
    }
}


generate_code :: proc(c: ^Compiler, node: Node, allocator: mem.Allocator) -> (code: Program) {
    if node == nil {
        return
    }

    code.allocator = allocator

    // NOTE: For Jump/Split arguments, we write as i16 and will reinterpret
    // this later when relative jumps are turned into absolute jumps.

    switch specific in node {
    // Atomic Nodes:
    case ^Node_Rune:
        if .Unicode not_in c.flags || specific.data < unicode.MAX_LATIN1 {
            _ = dyn_array.append(&code, Opcode.Byte)
            _ = dyn_array.append(&code, cast(Opcode)specific.data)
        } else {
            _ = dyn_array.append(&code, Opcode.Rune)
            append_raw(&code, specific.data)
        }

    case ^Node_Rune_Class:
        if specific.negating {
            _ = dyn_array.append(&code, Opcode.Rune_Class_Negated)
        } else {
            _ = dyn_array.append(&code, Opcode.Rune_Class)
        }

        index := -1
        for &data, i in dyn_array.slice(c.class_data) {
            if classes_are_exact(&data, &specific.data) {
                index = int(i)
                break
            }
        }
        internal.assert(index != -1, "Unable to find collected Rune_Class_Data index.")

        _ = dyn_array.append(&code, Opcode(index))

    case ^Node_Wildcard:
        _ = dyn_array.append(&code, Opcode.Wildcard)

    case ^Node_Anchor:
        if .Multiline in c.flags {
            if specific.start {
                _ = dyn_array.append(&code, Opcode.Assert_Start_Multiline)
            } else {
                _ = dyn_array.append(&code, Opcode.Multiline_Open)
                _ = dyn_array.append(&code, Opcode.Multiline_Close)
            }
        } else {
            if specific.start {
                _ = dyn_array.append(&code, Opcode.Assert_Start)
            } else {
                _ = dyn_array.append(&code, Opcode.Assert_End)
            }
        }
    case ^Node_Word_Boundary:
        if specific.non_word {
            _ = dyn_array.append(&code, Opcode.Assert_Non_Word_Boundary)
        } else {
            _ = dyn_array.append(&code, Opcode.Assert_Word_Boundary)
        }

    // Compound Nodes:
    case ^Node_Group:
        code = generate_code(c, specific.inner, allocator)

        if specific.capture && .No_Capture not_in c.flags {
            _, _ = dyn_array.inject_at(&code, 0, Opcode.Save)
            _, _ = dyn_array.inject_at(&code, 1, Opcode(2 * specific.capture_id))

            _ = dyn_array.append(&code, Opcode.Save)
            _ = dyn_array.append(&code, Opcode(2 * specific.capture_id + 1))
        }

    case ^Node_Alternation:
        left := generate_code(c, specific.left, allocator)
        right := generate_code(c, specific.right, allocator)

        left_len := left.len

        // Avoiding duplicate allocation by reusing `left`.
        code = left

        _, _ = dyn_array.inject_at(&code, 0, Opcode.Split)
        inject_raw(&code, size_of(u8)               , i16(SPLIT_SIZE))
        inject_raw(&code, size_of(u8) + size_of(i16), i16(SPLIT_SIZE + left_len + JUMP_SIZE))

        _ = dyn_array.append(&code, Opcode.Jump)
        append_raw(&code, i16(right.len + JUMP_SIZE))

        for opcode in dyn_array.slice(right) {
            _ = dyn_array.append(&code, opcode)
        }

    case ^Node_Concatenation:
        for subnode in dyn_array.slice(specific.nodes) {
            subnode_code := generate_code(c, subnode, allocator)
            for opcode in dyn_array.slice(subnode_code) {
                _ = dyn_array.append(&code, opcode)
            }
        }

    case ^Node_Repeat_Zero:
        code = generate_code(c, specific.inner, allocator)
        original_len := code.len

        _, _ = dyn_array.inject_at(&code, 0, Opcode.Split)
        inject_raw(&code, size_of(u8)               , i16(SPLIT_SIZE))
        inject_raw(&code, size_of(u8) + size_of(i16), i16(SPLIT_SIZE + original_len + JUMP_SIZE))

        _ = dyn_array.append(&code, Opcode.Jump)
        append_raw(&code, i16(-original_len - SPLIT_SIZE))

    case ^Node_Repeat_Zero_Non_Greedy:
        code = generate_code(c, specific.inner, allocator)
        original_len := code.len

        _, _ = dyn_array.inject_at(&code, 0, Opcode.Split)
        inject_raw(&code, size_of(u8)               , i16(SPLIT_SIZE + original_len + JUMP_SIZE))
        inject_raw(&code, size_of(u8) + size_of(i16), i16(SPLIT_SIZE))

        _ = dyn_array.append(&code, Opcode.Jump)
        append_raw(&code, i16(-original_len - SPLIT_SIZE))

    case ^Node_Repeat_One:
        code = generate_code(c, specific.inner, allocator)
        original_len := code.len

        _ = dyn_array.append(&code, Opcode.Split)
        append_raw(&code, i16(-original_len))
        append_raw(&code, i16(SPLIT_SIZE))

    case ^Node_Repeat_One_Non_Greedy:
        code = generate_code(c, specific.inner, allocator)
        original_len := code.len

        _ = dyn_array.append(&code, Opcode.Split)
        append_raw(&code, i16(SPLIT_SIZE))
        append_raw(&code, i16(-original_len))

    case ^Node_Repeat_N:
        inside := generate_code(c, specific.inner, allocator)
        original_len := inside.len

        if specific.lower == specific.upper { // {N}
            // e{N} ... evaluates to ... e^N
            for i := 0; i < specific.upper; i += 1 {
                for opcode in dyn_array.slice(inside) {
                    _ = dyn_array.append(&code, opcode)
                }
            }

        } else if specific.lower == -1 && specific.upper > 0 { // {,M}
            // e{,M} ... evaluates to ... e?^M
            for i := 0; i < specific.upper; i += 1 {
                _ = dyn_array.append(&code, Opcode.Split)
                append_raw(&code, i16(SPLIT_SIZE))
                append_raw(&code, i16(SPLIT_SIZE + original_len))
                for opcode in dyn_array.slice(inside) {
                    _ = dyn_array.append(&code, opcode)
                }
            }

        } else if specific.lower >= 0 && specific.upper == -1 { // {N,}
            // e{N,} ... evaluates to ... e^N e*
            for i := 0; i < specific.lower; i += 1 {
                for opcode in dyn_array.slice(inside) {
                    _ = dyn_array.append(&code, opcode)
                }
            }

            _ = dyn_array.append(&code, Opcode.Split)
            append_raw(&code, i16(SPLIT_SIZE))
            append_raw(&code, i16(SPLIT_SIZE + original_len + JUMP_SIZE))

            for opcode in dyn_array.slice(inside) {
                _ = dyn_array.append(&code, opcode)
            }

            _ = dyn_array.append(&code, Opcode.Jump)
            append_raw(&code, i16(-original_len - SPLIT_SIZE))

        } else if specific.lower >= 0 && specific.upper > 0 {
            // e{N,M}  evaluates to ... e^N e?^(M-N)
            for i := 0; i < specific.lower; i += 1 {
                for opcode in dyn_array.slice(inside) {
                    _ = dyn_array.append(&code, opcode)
                }
            }
            for i := 0; i < specific.upper - specific.lower; i += 1 {
                _ = dyn_array.append(&code, Opcode.Split)
                append_raw(&code, i16(SPLIT_SIZE + original_len))
                append_raw(&code, i16(SPLIT_SIZE))
                for opcode in dyn_array.slice(inside) {
                    _ = dyn_array.append(&code, opcode)
                }
            }

        } else {
            internal.panic("RegEx compiler received invalid repetition group.")
        }

    case ^Node_Optional:
        code = generate_code(c, specific.inner, allocator)
        original_len := code.len

        _, _ = dyn_array.inject_at(&code, 0, Opcode.Split)
        inject_raw(&code, size_of(u8)               , i16(SPLIT_SIZE))
        inject_raw(&code, size_of(u8) + size_of(i16), i16(SPLIT_SIZE + original_len))

    case ^Node_Optional_Non_Greedy:
        code = generate_code(c, specific.inner, allocator)
        original_len := code.len

        _, _ = dyn_array.inject_at(&code, 0, Opcode.Split)
        inject_raw(&code, size_of(u8)               , i16(SPLIT_SIZE + original_len))
        inject_raw(&code, size_of(u8) + size_of(i16), i16(SPLIT_SIZE))

    case ^Node_Match_All_And_Escape:
        _ = dyn_array.append(&code, Opcode.Match_All_And_Escape)
    }

    return
}


compile :: proc(tree: Node, flags: common.Flags, allocator: mem.Allocator) -> (code: Program, class_data: dyn_array.Dyn_Array(Rune_Class_Data), err: Error) {
    if tree == nil {
        if .No_Capture not_in flags {
            _ = dyn_array.append(&code, Opcode.Save); _ = dyn_array.append(&code, Opcode(0x00))
            _ = dyn_array.append(&code, Opcode.Save); _ = dyn_array.append(&code, Opcode(0x01))
            _ = dyn_array.append(&code, Opcode.Match)
        } else {
            _ = dyn_array.append(&code, Opcode.Match_And_Exit)
        }
        return
    }

    c: Compiler
    c.flags = flags

    class_data.allocator = allocator
    map_all_classes(tree, &class_data)
    if class_data.len >= uint(common.MAX_CLASSES) {
        err = .Too_Many_Classes
        return
    }
    c.class_data = class_data

    code = generate_code(&c, tree, allocator)

    pc_open: uint

    optimize_opening: {
        // Check if the opening to the pattern is predictable.
        // If so, use one of the optimized Wait opcodes.
        iter := virtual_machine.Opcode_Iterator{ dyn_array.slice(code), 0 }
        seek_loop: for opcode, pc in virtual_machine.iterate_opcodes(&iter) {
            #partial switch opcode {
            case .Byte:
                _, _ = dyn_array.inject_at(&code, pc_open, Opcode.Wait_For_Byte)
                pc_open += size_of(Opcode)
                _, _ = dyn_array.inject_at(&code, pc_open, Opcode(code.data[pc + size_of(Opcode) + pc_open]))
                pc_open += size_of(u8)
                break optimize_opening

            case .Rune:
                operand := intrinsics.unaligned_load(cast(^rune)&code.data[pc+1])
                _, _ = dyn_array.inject_at(&code, pc_open, Opcode.Wait_For_Rune)
                pc_open += size_of(Opcode)
                inject_raw(&code, pc_open, operand)
                pc_open += size_of(rune)
                break optimize_opening

            case .Rune_Class:
                _, _ = dyn_array.inject_at(&code, pc_open, Opcode.Wait_For_Rune_Class)
                pc_open += size_of(Opcode)
                _, _ = dyn_array.inject_at(&code, pc_open, Opcode(code.data[pc + size_of(Opcode) + pc_open]))
                pc_open += size_of(u8)
                break optimize_opening

            case .Rune_Class_Negated:
                _, _ = dyn_array.inject_at(&code, pc_open, Opcode.Wait_For_Rune_Class_Negated)
                pc_open += size_of(Opcode)
                _, _ = dyn_array.inject_at(&code, pc_open, Opcode(code.data[pc + size_of(Opcode) + pc_open]))
                pc_open += size_of(u8)
                break optimize_opening

            case .Save:
                continue

            case .Assert_Start, .Assert_Start_Multiline:
                break optimize_opening

            case:
                break seek_loop
            }
        }

        // `.*?`
        _, _ = dyn_array.inject_at(&code, pc_open, Opcode.Split)
        pc_open += size_of(u8)
        inject_raw(&code, pc_open, i16(SPLIT_SIZE + size_of(u8) + JUMP_SIZE))
        pc_open += size_of(i16)
        inject_raw(&code, pc_open, i16(SPLIT_SIZE))
        pc_open += size_of(i16)

        _, _ = dyn_array.inject_at(&code, pc_open, Opcode.Wildcard)
        pc_open += size_of(u8)

        _, _ = dyn_array.inject_at(&code, pc_open, Opcode.Jump)
        pc_open += size_of(u8)
        inject_raw(&code, pc_open, i16(-i16(size_of(u8)) - i16(SPLIT_SIZE)))
        pc_open += size_of(i16)

    }

    if .No_Capture not_in flags {
        // `(` <generated code>
        _, _ = dyn_array.inject_at(&code, pc_open, Opcode.Save)
        _, _ = dyn_array.inject_at(&code, pc_open + size_of(u8), Opcode(0x00))

        // `)`
        _ = dyn_array.append(&code, Opcode.Save); _ = dyn_array.append(&code, Opcode(0x01))

        _ = dyn_array.append(&code, Opcode.Match)
    } else {
        _ = dyn_array.append(&code, Opcode.Match_And_Exit)
    }

    if code.len >= uint(common.MAX_PROGRAM_SIZE) {
        err = .Program_Too_Big
        return
    }

    // NOTE: No further opcode addition beyond this point, as we've already
    // checked the program size. Removal or transformation is fine.

    // Post-Compile Optimizations:

    // * Jump Extension
    //
    // A:RelJmp(1) -> B:RelJmp(2) => A:RelJmp(2)
    if .No_Optimization not_in flags {
        for passes_left := 1; passes_left > 0; passes_left -= 1 {
            do_another_pass := false

            iter := virtual_machine.Opcode_Iterator{ dyn_array.slice(code), 0 }
            for opcode, pc in virtual_machine.iterate_opcodes(&iter) {
                #partial switch opcode {
                case .Jump:
                    jmp   := cast(^i16)&code.data[pc+size_of(Opcode)]
                    jmp_value := intrinsics.unaligned_load(jmp)
                    if code.data[cast(i16)pc+jmp_value] == .Jump {
                        next_jmp := intrinsics.unaligned_load(cast(^i16)&code.data[cast(i16)pc+jmp_value+i16(size_of(Opcode))])
                        intrinsics.unaligned_store(jmp, jmp_value + next_jmp)
                        do_another_pass = true
                    }
                case .Split:
                    jmp_x := cast(^i16)&code.data[pc+size_of(Opcode)]
                    jmp_x_value := intrinsics.unaligned_load(jmp_x)
                    if code.data[cast(i16)pc+jmp_x_value] == .Jump {
                        next_jmp := intrinsics.unaligned_load(cast(^i16)&code.data[cast(i16)pc+jmp_x_value+i16(size_of(Opcode))])
                        intrinsics.unaligned_store(jmp_x, jmp_x_value + next_jmp)
                        do_another_pass = true
                    }
                    jmp_y := cast(^i16)&code.data[pc+size_of(Opcode)+size_of(i16)]
                    jmp_y_value := intrinsics.unaligned_load(jmp_y)
                    if code.data[cast(i16)pc+jmp_y_value] == .Jump {
                        next_jmp := intrinsics.unaligned_load(cast(^i16)&code.data[cast(i16)pc+jmp_y_value+i16(size_of(Opcode))])
                        intrinsics.unaligned_store(jmp_y, jmp_y_value + next_jmp)
                        do_another_pass = true
                    }
                }
            }

            if do_another_pass {
                passes_left += 1
            }
        }
    }

    // * Relative Jump to Absolute Jump
    //
    // RelJmp{PC +/- N} => AbsJmp{M}
    iter := virtual_machine.Opcode_Iterator{ dyn_array.slice(code), 0 }
    for opcode, pc in virtual_machine.iterate_opcodes(&iter) {
        // NOTE: The virtual machine implementation depends on this.
        #partial switch opcode {
        case .Jump:
            jmp   := cast(^u16)&code.data[pc+size_of(Opcode)]
            intrinsics.unaligned_store(jmp, intrinsics.unaligned_load(jmp) + cast(u16)pc)
        case .Split:
            jmp_x := cast(^u16)&code.data[pc+size_of(Opcode)]
            intrinsics.unaligned_store(jmp_x, intrinsics.unaligned_load(jmp_x) + cast(u16)pc)
            jmp_y := cast(^u16)&code.data[pc+size_of(Opcode)+size_of(i16)]
            intrinsics.unaligned_store(jmp_y, intrinsics.unaligned_load(jmp_y) + cast(u16)pc)
        }
    }

    return
}
