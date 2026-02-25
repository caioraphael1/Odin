

@(require) import "base:intrinsics"
import "core:mem"
import "core:fmt"
import "core:reflect"
import "core:odin/tokenizer"

new_from_positions :: proc($T: typeid, pos, end: tokenizer.Pos, allocator: mem.Allocator) -> ^T {
    n, _ := new(T, allocator)
    n.pos = pos
    n.end = end
    n.derived = n
    base: ^Node = n // dummy check
    _ = base // "Use" type to make -vet happy
    when intrinsics.type_has_field(T, "derived_expr") {
        n.derived_expr = n
    }
    when intrinsics.type_has_field(T, "derived_stmt") {
        n.derived_stmt = n
    }
    return n
}

new_from_pos_and_end_node :: proc($T: typeid, pos: tokenizer.Pos, end: ^Node, allocator: mem.Allocator) -> ^T {
    return new_from_positions(T, pos, end != nil ? end.end : pos, allocator)
}

clone_array :: proc(array: $A/[]^$T, allocator: mem.Allocator) -> A {
    if len(array) == 0 {
        return nil
    }
    res, _ := make_slice(A, len(array), allocator)
    for elem, i in array {
        res[i] = (^T)(clone_node(elem, allocator))
    }
    return res
}

clone_dynamic_array :: proc(array: $A/[dynamic]^$T, allocator: mem.Allocator) -> A {
    if len(array) == 0 {
        return nil
    }
    res, _ := make_dynamic_array_len(A, len(array), allocator)
    for elem, i in array {
        res[i] = (^T)(clone_node(elem, allocator))
    }
    return res
}

clone_expr :: proc(node: ^Expr, allocator: mem.Allocator) -> ^Expr {
    return cast(^Expr)clone_node(node, allocator)
}
clone_stmt :: proc(node: ^Stmt, allocator: mem.Allocator) -> ^Stmt {
    return cast(^Stmt)clone_node(node, allocator)
}
clone_decl :: proc(node: ^Decl, allocator: mem.Allocator) -> ^Decl {
    return cast(^Decl)clone_node(node, allocator)
}
clone_node :: proc(node: ^Node, allocator: mem.Allocator) -> ^Node {
    if node == nil {
        return nil
    }

    size  := size_of(Node)
    align := align_of(Node)
    ti := reflect.union_variant_type_info(node.derived)
    if ti != nil {
        elem := ti.variant.(reflect.Type_Info_Pointer).elem
        size  = elem.size
        align = elem.align
    }

    #partial switch _ in node.derived {
    case ^Package, ^File:
        panic("Cannot clone this node type")
    }

    res := cast(^Node)(mem.alloc(size, align, allocator) or_else nil)
    if res == nil {
        // allocation failure
        return nil
    }
    src: rawptr = node
    if node.derived != nil {
        src = (^rawptr)(&node.derived)^
    }
    mem.copy(res, src, size)
    res_ptr_any: any
    res_ptr_any.data = &res
    res_ptr_any.id = ti.id

    _ = reflect.set_union_value(res.derived, res_ptr_any)

    res_ptr := reflect.deref(res_ptr_any)

    if de := reflect.struct_field_value_by_name(res_ptr, "derived_expr", true); de != nil {
        _ = reflect.set_union_value(de, res_ptr_any)
    }
    if ds := reflect.struct_field_value_by_name(res_ptr, "derived_stmt", true); ds != nil {
        _ = reflect.set_union_value(ds, res_ptr_any)
    }

    if res.derived != nil {
        switch r in res.derived {
        case ^Package, ^File:
        case ^Bad_Expr:
        case ^Ident:
        case ^Implicit:
        case ^Undef:
        case ^Basic_Lit:
        case ^Basic_Directive:
        case ^Comment_Group:

        case ^Ellipsis:
            r.expr = clone_expr(r.expr, allocator)
        case ^Proc_Lit:
            r.type = auto_cast clone_node(r.type, allocator)
            r.body = clone_stmt(r.body, allocator)
        case ^Comp_Lit:
            r.type  = clone_expr(r.type, allocator)
            r.elems = clone_array(r.elems, allocator)

        case ^Tag_Expr:
            r.expr = clone_expr(r.expr, allocator)
        case ^Unary_Expr:
            r.expr = clone_expr(r.expr, allocator)
        case ^Binary_Expr:
            r.left  = clone_expr(r.left, allocator)
            r.right = clone_expr(r.right, allocator)
        case ^Paren_Expr:
            r.expr = clone_expr(r.expr, allocator)
        case ^Selector_Expr:
            r.expr = clone_expr(r.expr, allocator)
            r.field = auto_cast clone_node(r.field, allocator)
        case ^Implicit_Selector_Expr:
            r.field = auto_cast clone_node(r.field, allocator)
        case ^Selector_Call_Expr:
            r.expr = clone_expr(r.expr, allocator)
            r.call = auto_cast clone_node(r.call, allocator)
        case ^Index_Expr:
            r.expr = clone_expr(r.expr, allocator)
            r.index = clone_expr(r.index, allocator)
        case ^Matrix_Index_Expr:
            r.expr         = clone_expr(r.expr, allocator)
            r.row_index    = clone_expr(r.row_index, allocator)
            r.column_index = clone_expr(r.column_index, allocator)
        case ^Deref_Expr:
            r.expr = clone_expr(r.expr, allocator)
        case ^Slice_Expr:
            r.expr = clone_expr(r.expr, allocator)
            r.low  = clone_expr(r.low, allocator)
            r.high = clone_expr(r.high, allocator)
        case ^Call_Expr:
            r.expr = clone_expr(r.expr, allocator)
            r.args = clone_array(r.args, allocator)
        case ^Field_Value:
            r.field = clone_expr(r.field, allocator)
            r.value = clone_expr(r.value, allocator)
        case ^Ternary_If_Expr:
            r.x    = clone_expr(r.x, allocator)
            r.cond = clone_expr(r.cond, allocator)
            r.y    = clone_expr(r.y, allocator)
        case ^Ternary_When_Expr:
            r.x    = clone_expr(r.x, allocator)
            r.cond = clone_expr(r.cond, allocator)
            r.y    = clone_expr(r.y, allocator)
        case ^Or_Else_Expr:
            r.x    = clone_expr(r.x, allocator)
            r.y    = clone_expr(r.y, allocator)
        case ^Or_Return_Expr:
            r.expr = clone_expr(r.expr, allocator)
        case ^Or_Branch_Expr:
            r.expr  = clone_expr(r.expr, allocator)
            r.label = clone_expr(r.label, allocator)
        case ^Type_Assertion:
            r.expr = clone_expr(r.expr, allocator)
            r.type = clone_expr(r.type, allocator)
        case ^Type_Cast:
            r.type = clone_expr(r.type, allocator)
            r.expr = clone_expr(r.expr, allocator)
        case ^Auto_Cast:
            r.expr = clone_expr(r.expr, allocator)
        case ^Inline_Asm_Expr:
            r.param_types        = clone_array(r.param_types, allocator)
            r.return_type        = clone_expr(r.return_type, allocator)
            r.constraints_string = clone_expr(r.constraints_string, allocator)
            r.asm_string         = clone_expr(r.asm_string, allocator)

        case ^Bad_Stmt:
            // empty
        case ^Empty_Stmt:
            // empty
        case ^Expr_Stmt:
            r.expr = clone_expr(r.expr, allocator)
        case ^Tag_Stmt:
            r.stmt = clone_stmt(r.stmt, allocator)

        case ^Assign_Stmt:
            r.lhs = clone_array(r.lhs, allocator)
            r.rhs = clone_array(r.rhs, allocator)
        case ^Block_Stmt:
            r.label = clone_expr(r.label, allocator)
            r.stmts = clone_array(r.stmts, allocator)
        case ^If_Stmt:
            r.label     = clone_expr(r.label, allocator)
            r.init      = clone_stmt(r.init, allocator)
            r.cond      = clone_expr(r.cond, allocator)
            r.body      = clone_stmt(r.body, allocator)
            r.else_stmt = clone_stmt(r.else_stmt, allocator)
        case ^When_Stmt:
            r.cond      = clone_expr(r.cond, allocator)
            r.body      = clone_stmt(r.body, allocator)
            r.else_stmt = clone_stmt(r.else_stmt, allocator)
        case ^Return_Stmt:
            r.results = clone_array(r.results, allocator)
        case ^Defer_Stmt:
            r.stmt = clone_stmt(r.stmt, allocator)
        case ^For_Stmt:
            r.label = clone_expr(r.label, allocator)
            r.init = clone_stmt(r.init, allocator)
            r.cond = clone_expr(r.cond, allocator)
            r.post = clone_stmt(r.post, allocator)
            r.body = clone_stmt(r.body, allocator)
        case ^Range_Stmt:
            r.label = clone_expr(r.label, allocator)
            r.init = clone_stmt(r.init, allocator)
            r.vals = clone_array(r.vals, allocator)
            r.expr = clone_expr(r.expr, allocator)
            r.body = clone_stmt(r.body, allocator)
        case ^Unroll_Range_Stmt:
            r.label = clone_expr(r.label, allocator)
            r.args = clone_array(r.args, allocator)
            r.val0 = clone_expr(r.val0, allocator)
            r.val1 = clone_expr(r.val1, allocator)
            r.expr = clone_expr(r.expr, allocator)
            r.body = clone_stmt(r.body, allocator)
        case ^Case_Clause:
            r.list = clone_array(r.list, allocator)
            r.body = clone_array(r.body, allocator)
        case ^Switch_Stmt:
            r.label = clone_expr(r.label, allocator)
            r.init = clone_stmt(r.init, allocator)
            r.cond = clone_expr(r.cond, allocator)
            r.body = clone_stmt(r.body, allocator)
        case ^Type_Switch_Stmt:
            r.label = clone_expr(r.label, allocator)
            r.tag  = clone_stmt(r.tag, allocator)
            r.expr = clone_expr(r.expr, allocator)
            r.body = clone_stmt(r.body, allocator)
        case ^Branch_Stmt:
            r.label = auto_cast clone_expr(r.label, allocator)
        case ^Using_Stmt:
            r.list = clone_array(r.list, allocator)
        case ^Bad_Decl:
        case ^Value_Decl:
            r.attributes = clone_dynamic_array(r.attributes, allocator)
            r.names      = clone_array(r.names, allocator)
            r.type       = clone_expr(r.type, allocator)
            r.values     = clone_array(r.values, allocator)
        case ^Package_Decl:
        case ^Import_Decl:
        case ^Foreign_Block_Decl:
            r.attributes      = clone_dynamic_array(r.attributes, allocator)
            r.foreign_library = clone_expr(r.foreign_library, allocator)
            r.body            = clone_stmt(r.body, allocator)
        case ^Foreign_Import_Decl:
            r.attributes = clone_dynamic_array(r.attributes, allocator)
            r.name = auto_cast clone_expr(r.name, allocator)
            r.fullpaths  = clone_array(r.fullpaths, allocator)
        case ^Proc_Group:
            r.args = clone_array(r.args, allocator)
        case ^Attribute:
            r.elems = clone_array(r.elems, allocator)
        case ^Field:
            r.names         = clone_array(r.names, allocator)
            r.type          = clone_expr(r.type, allocator)
            r.default_value = clone_expr(r.default_value, allocator)
        case ^Field_List:
            r.list = clone_array(r.list, allocator)
        case ^Typeid_Type:
            r.specialization = clone_expr(r.specialization, allocator)
        case ^Helper_Type:
            r.type = clone_expr(r.type, allocator)
        case ^Distinct_Type:
            r.type = clone_expr(r.type, allocator)
        case ^Poly_Type:
            r.type = auto_cast clone_node(r.type, allocator)
            r.specialization = clone_expr(r.specialization, allocator)
        case ^Proc_Type:
            r.params  = auto_cast clone_node(r.params, allocator)
            r.results = auto_cast clone_node(r.results, allocator)
        case ^Pointer_Type:
            r.elem = clone_expr(r.elem, allocator)
            r.tag  = clone_expr(r.tag, allocator)
        case ^Multi_Pointer_Type:
            r.elem = clone_expr(r.elem, allocator)
        case ^Array_Type:
            r.len  = clone_expr(r.len, allocator)
            r.elem = clone_expr(r.elem, allocator)
        case ^Dynamic_Array_Type:
            r.elem = clone_expr(r.elem, allocator)
        case ^Struct_Type:
            r.poly_params = auto_cast clone_node(r.poly_params, allocator)
            r.align = clone_expr(r.align, allocator)
            r.min_field_align = clone_expr(r.min_field_align, allocator)
            r.max_field_align = clone_expr(r.max_field_align, allocator)
            r.fields = auto_cast clone_node(r.fields, allocator)
        case ^Union_Type:
            r.poly_params = auto_cast clone_node(r.poly_params, allocator)
            r.align = clone_expr(r.align, allocator)
            r.variants = clone_array(r.variants, allocator)
        case ^Enum_Type:
            r.base_type = clone_expr(r.base_type, allocator)
            r.fields = clone_array(r.fields, allocator)
        case ^Bit_Set_Type:
            r.elem = clone_expr(r.elem, allocator)
            r.underlying = clone_expr(r.underlying, allocator)
        case ^Map_Type:
            r.key = clone_expr(r.key, allocator)
            r.value = clone_expr(r.value, allocator)
        case ^Matrix_Type:
            r.row_count = clone_expr(r.row_count, allocator)
            r.column_count = clone_expr(r.column_count, allocator)
            r.elem = clone_expr(r.elem, allocator)
        case ^Relative_Type:
            r.tag = clone_expr(r.tag, allocator)
            r.type = clone_expr(r.type, allocator)
        case ^Bit_Field_Type:
            r.backing_type = clone_expr(r.backing_type, allocator)
            r.fields       = auto_cast clone_array(r.fields, allocator)
        case ^Bit_Field_Field:
            r.name     = clone_expr(r.name, allocator)
            r.type     = clone_expr(r.type, allocator)
            r.bit_size = clone_expr(r.bit_size, allocator)
        case:
            fmt.panicf("Unhandled node kind: %v", r)
        }
    }

    return res
}
