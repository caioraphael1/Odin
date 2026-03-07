// The `Odin` file parser to be used in tooling.
package odin_parser

import "core:odin/ast"
import "core:odin/tokenizer"

import "core:fmt"
import "base:mem"

Warning_Handler :: #type proc(pos: tokenizer.Pos, fmt: string, args: ..any)
Error_Handler   :: #type proc(pos: tokenizer.Pos, fmt: string, args: ..any)

Flag :: enum u32 {
    Optional_Semicolons,
}

Flags :: distinct bit_set[Flag; u32]


Parser :: struct {
    file: ^ast.File,
    tok: tokenizer.Tokenizer,

    // If .Optional_Semicolons is true, semicolons are completely as statement terminators
    // different to .Insert_Semicolon in tok.flags
    flags: Flags,

    warn: Warning_Handler,
    err:  Error_Handler,

    prev_tok: tokenizer.Token,
    curr_tok: tokenizer.Token,

    // >= 0: In Expression
    // <  0: In Control Clause
    // NOTE(bill): Used to prevent type literals in control clauses
    expr_level:       int,
    allow_range:      bool, // NOTE(bill): Ranges are only allowed in certain cases
    allow_in_expr:    bool, // NOTE(bill): in expression are only allowed in certain cases
    in_foreign_block: bool,
    allow_type:       bool,

    lead_comment: ^ast.Comment_Group,
    line_comment: ^ast.Comment_Group,

    curr_proc: ^ast.Node,

    error_count: int,

    fix_count: int,
    fix_prev_pos: tokenizer.Pos,

    peeking: bool,
}

MAX_FIX_COUNT :: 10

Stmt_Allow_Flag :: enum {
    In,
    Label,
}
Stmt_Allow_Flags :: distinct bit_set[Stmt_Allow_Flag]


Import_Decl_Kind :: enum {
    Standard,
    Using,
}



default_warning_handler :: proc(pos: tokenizer.Pos, msg: string, args: ..any) {
    fmt.eprintf("%s(%d:%d): Warning: ", pos.file, pos.line, pos.column)
    fmt.eprintf(msg, ..args)
    fmt.eprintf("\n")
}
default_error_handler :: proc(pos: tokenizer.Pos, msg: string, args: ..any) {
    fmt.eprintf("%s(%d:%d): ", pos.file, pos.line, pos.column)
    fmt.eprintf(msg, ..args)
    fmt.eprintf("\n")
}

warn :: proc(p: ^Parser, pos: tokenizer.Pos, msg: string, args: ..any) {
    if p.warn != nil {
        p.warn(pos, msg, ..args)
    }
    p.file.syntax_warning_count += 1
}

error :: proc(p: ^Parser, pos: tokenizer.Pos, msg: string, args: ..any) {
    if p.err != nil {
        p.err(pos, msg, ..args)
    }
    p.file.syntax_error_count += 1
    p.error_count += 1
}


end_pos :: proc(tok: tokenizer.Token) -> tokenizer.Pos {
    pos := tok.pos
    pos.offset += len(tok.text)

    if (tok.kind == .Comment && tok.text[:2] == "/*") || (tok.kind == .String && tok.text[:1] == "`") {
        for i := 0; i < len(tok.text); i += 1 {
            c := tok.text[i]
            if c == '\n' {
                pos.line += 1
                pos.column = 1
            } else {
                pos.column += 1
            }
        }
    } else {
        pos.column += len(tok.text)
    }
    return pos
}

default_parser :: proc(flags := Flags{.Optional_Semicolons}) -> Parser {
    return Parser {
        flags = flags,
        err  = default_error_handler,
        warn = default_warning_handler,
    }
}

is_package_name_reserved :: proc(name: string) -> bool {
    switch name {
    case "builtin", "intrinsics":
        return true
    }
    return false
}

parse_file :: proc(p: ^Parser, file: ^ast.File, allocator: mem.Allocator) -> bool {
    zero_parser: {
        p.prev_tok         = {}
        p.curr_tok         = {}
        p.expr_level       = 0
        p.allow_range      = false
        p.allow_in_expr    = false
        p.in_foreign_block = false
        p.allow_type       = false
        p.lead_comment     = nil
        p.line_comment     = nil
    }

    p.tok.flags += {.Insert_Semicolon}

    p.file = file
    tokenizer.init(&p.tok, file.src, file.fullpath, p.err)
    if p.tok.ch <= 0 {
        return true
    }


    _ = advance_token(p, allocator)
    consume_comment_groups(p, p.prev_tok, allocator)

    docs := p.lead_comment

    invalid_pre_package_token: Maybe(tokenizer.Token)

    for p.curr_tok.kind != .Package && p.curr_tok.kind != .EOF {
        if p.curr_tok.kind == .Comment {
            consume_comment_groups(p, p.prev_tok, allocator)
        } else if p.curr_tok.kind == .File_Tag {
            _ = dyn_array.append(&p.file.tags, p.curr_tok)
            _ = advance_token(p, allocator)
        } else {
            if invalid_pre_package_token == nil {
                invalid_pre_package_token = p.curr_tok
            }

            _ = advance_token(p, allocator)
        }
    }

    if p.curr_tok.kind != .Package {
        t := invalid_pre_package_token.? or_else p.curr_tok
        error(p, t.pos, "Expected a package declaration at the start of the file")
        return false
    }
    
    p.file.pkg_token = expect_token(p, .Package, allocator)
    
    if ippt, ok := invalid_pre_package_token.?; ok {
        error(p, ippt.pos, "Expected only comments or lines starting with '#+' before the package declaration")
        return false
    }
    
    pkg_name := expect_token_after(p, .Ident, "package", allocator)
    if pkg_name.kind == .Ident {
        switch name := pkg_name.text; {
        case is_blank_ident_string(name):
            error(p, pkg_name.pos, "invalid package name '_'")
        case is_package_name_reserved(name), file.pkg != nil && file.pkg.kind != .Runtime && name == "runtime":
            error(p, pkg_name.pos, "use of reserved package name '%s'", name)
        }
    }
    p.file.pkg_name = pkg_name.text

    pd := ast.new_from_positions(ast.Package_Decl, pkg_name.pos, end_pos(p.prev_tok), allocator)
    pd.docs    = docs
    pd.token   = p.file.pkg_token
    pd.name    = pkg_name.text
    pd.comment = p.line_comment
    p.file.pkg_decl = pd
    p.file.docs = docs

    _ = expect_semicolon(p, pd, allocator)

    if p.file.syntax_error_count > 0 {
        return false
    }

    p.file.decls, _ = make_dynamic_array([dynamic]^ast.Stmt, allocator)

    for p.curr_tok.kind != .EOF {
        stmt := parse_stmt(p, allocator)
        if stmt != nil {
            if _, ok := stmt.derived.(^ast.Empty_Stmt); !ok {
                _ = dyn_array.append(&p.file.decls, stmt)
                if es, es_ok := stmt.derived.(^ast.Expr_Stmt); es_ok && es.expr != nil {
                    if _, pl_ok := es.expr.derived.(^ast.Proc_Lit); pl_ok {
                        error(p, stmt.pos, "procedure literal evaluated but not used")
                    }
                }
            }
        }
    }

    return true
}

peek_token_kind :: proc(p: ^Parser, kind: tokenizer.Token_Kind, lookahead: int, allocator: mem.Allocator) -> (ok: bool) {
    prev_parser := p^
    p.peeking = true

    defer {
        p^ = prev_parser
        p.peeking = false
    }

    p.tok.err = nil
    for i := 0; i <= lookahead; i += 1 {
        _ = advance_token(p, allocator)
    }
    ok = p.curr_tok.kind == kind

    return
}

peek_token :: proc(p: ^Parser, lookahead: int, allocator: mem.Allocator) -> (tok: tokenizer.Token) {
    prev_parser := p^
    p.peeking = true

    defer {
        p^ = prev_parser
        p.peeking = false
    }

    p.tok.err = nil
    for i := 0; i <= lookahead; i += 1 {
        _ = advance_token(p, allocator)
    }
    tok = p.curr_tok
    return
}
skip_possible_newline :: proc(p: ^Parser, allocator: mem.Allocator) -> bool {
    if tokenizer.is_newline(p.curr_tok) {
        _ = advance_token(p, allocator)
        return true
    }
    return false
}

skip_possible_newline_for_literal :: proc(p: ^Parser, allocator: mem.Allocator) -> bool {
    if .Optional_Semicolons not_in p.flags {
        return false
    }

    curr_pos := p.curr_tok.pos
    if tokenizer.is_newline(p.curr_tok) {
        next := peek_token(p, 0, allocator)
        if curr_pos.line+1 >= next.pos.line {
            #partial switch next.kind {
            case .Open_Brace, .Else, .Where:
                _ = advance_token(p, allocator)
                return true
            }
        }
    }

    return false
}


next_token0 :: proc(p: ^Parser) -> bool {
    p.curr_tok = tokenizer.scan(&p.tok)
    if p.curr_tok.kind == .EOF {
        // error(p, p.curr_tok.pos, "token is EOF");
        return false
    }
    return true
}

consume_comment :: proc(p: ^Parser) -> (tok: tokenizer.Token, end_line: int) {
    tok = p.curr_tok
    assert(tok.kind == .Comment)
    end_line = tok.pos.line

    if tok.text[1] == '*' {
        for c in tok.text {
            if c == '\n' {
                end_line += 1
            }
        }
    }

    _ = next_token0(p)
    if p.curr_tok.pos.line > tok.pos.line {
        end_line += 1
    }

    return
}

consume_comment_group :: proc(p: ^Parser, n: int, allocator: mem.Allocator) -> (comments: ^ast.Comment_Group, end_line: int) {
    list: [dynamic]tokenizer.Token
    list.allocator = allocator
    end_line = p.curr_tok.pos.line
    for p.curr_tok.kind == .Comment &&
        p.curr_tok.pos.line <= end_line+n {
        comment: tokenizer.Token
        comment, end_line = consume_comment(p)
        _ = dyn_array.append(&list, comment)
    }

    if len(list) > 0 && !p.peeking {
        comments = ast.new_from_positions(ast.Comment_Group, list[0].pos, end_pos(list[len(list)-1]), allocator)
        comments.list = list[:]
        _ = dyn_array.append(&p.file.comments, comments)
    }

    return
}

consume_comment_groups :: proc(p: ^Parser, prev: tokenizer.Token, allocator: mem.Allocator) {
    if p.curr_tok.kind != .Comment {
        return
    }
    comment: ^ast.Comment_Group
    end_line := 0

    if p.curr_tok.pos.line == prev.pos.line {
        comment, end_line = consume_comment_group(p, 0, allocator)
        if p.curr_tok.pos.line != end_line ||
           p.curr_tok.pos.line == prev.pos.line+1 ||
           p.curr_tok.kind == .EOF {
            p.line_comment = comment
        }
    }

    end_line = -1
    for p.curr_tok.kind == .Comment {
        comment, end_line = consume_comment_group(p, 1, allocator)
    }
    if end_line+1 >= p.curr_tok.pos.line || end_line < 0 {
        p.lead_comment = comment
    }

    assert(p.curr_tok.kind != .Comment)
}

advance_token :: proc(p: ^Parser, allocator: mem.Allocator) -> tokenizer.Token {
    p.lead_comment = nil
    p.line_comment = nil
    p.prev_tok = p.curr_tok
    prev := p.prev_tok

    if next_token0(p) {
        consume_comment_groups(p, prev, allocator)
    }
    return prev
}

expect_token :: proc(p: ^Parser, kind: tokenizer.Token_Kind, allocator: mem.Allocator) -> tokenizer.Token {
    prev := p.curr_tok
    if prev.kind != kind {
        e := tokenizer.to_string(kind)
        g := tokenizer.token_to_string(prev)
        error(p, prev.pos, "expected '%s', got '%s'", e, g)
    }
    _ = advance_token(p, allocator)
    return prev
}

expect_token_after :: proc(p: ^Parser, kind: tokenizer.Token_Kind, msg: string, allocator: mem.Allocator) -> tokenizer.Token {
    prev := p.curr_tok
    if prev.kind != kind {
        e := tokenizer.to_string(kind)
        g := tokenizer.token_to_string(prev)
        error(p, prev.pos, "expected '%s' after %s, got '%s'", e, msg, g)
    }
    _ = advance_token(p, allocator)
    return prev
}

expect_operator :: proc(p: ^Parser, allocator: mem.Allocator) -> tokenizer.Token {
    prev := p.curr_tok
    #partial switch prev.kind {
    case .If, .When, .Or_Else:
        // okay
    case:
        if !tokenizer.is_operator(prev.kind) {
            g := tokenizer.token_to_string(prev)
            error(p, prev.pos, "expected an operator, got '%s'", g)
        }
    }
    _ = advance_token(p, allocator)
    return prev
}

allow_token :: proc(p: ^Parser, kind: tokenizer.Token_Kind, allocator: mem.Allocator) -> bool {
    if p.curr_tok.kind == kind {
        _ = advance_token(p, allocator)
        return true
    }
    return false
}

end_of_line_pos :: proc(p: ^Parser, tok: tokenizer.Token) -> tokenizer.Pos {
    offset := clamp(tok.pos.offset, 0, len(p.tok.src)-1)
    s := p.tok.src[offset:]
    pos := tok.pos
    pos.column -= 1
    for len(s) != 0 && s[0] != 0 && s[0] != '\n' {
        s = s[1:]
        pos.column += 1
    }
    return pos
}

expect_closing_brace_of_field_list :: proc(p: ^Parser, allocator: mem.Allocator) -> tokenizer.Token {
    return expect_closing_token_of_field_list(p, .Close_Brace, "field list", allocator)
}

expect_closing_token_of_field_list :: proc(p: ^Parser, closing_kind: tokenizer.Token_Kind, msg: string, allocator: mem.Allocator) -> tokenizer.Token {
    token := p.curr_tok
    if allow_token(p, closing_kind, allocator) {
        return token
    }
    if allow_token(p, .Semicolon, allocator) && !tokenizer.is_newline(token) {
        str := tokenizer.token_to_string(token)
        error(p, end_of_line_pos(p, p.prev_tok), "expected a comma, got %s", str)
    }
    expect_closing := expect_token_after(p, closing_kind, msg, allocator)

    if expect_closing.kind != closing_kind {
        for p.curr_tok.kind != closing_kind && p.curr_tok.kind != .EOF && !is_non_inserted_semicolon(p.curr_tok) {
            _ = advance_token(p, allocator)
        }
        return p.curr_tok
    } 

    return expect_closing
}

expect_closing_parentheses_of_field_list :: proc(p: ^Parser, allocator: mem.Allocator) -> tokenizer.Token {
    token := p.curr_tok
    if allow_token(p, .Close_Paren, allocator) {
        return token
    }

    if allow_token(p, .Semicolon, allocator) && !tokenizer.is_newline(token) {
        str := tokenizer.token_to_string(token)
        error(p, end_of_line_pos(p, p.prev_tok), "expected a comma, got %s", str)
    }

    for p.curr_tok.kind != .Close_Paren && p.curr_tok.kind != .EOF && !is_non_inserted_semicolon(p.curr_tok) {
        _ = advance_token(p, allocator)
    }

    return expect_token(p, .Close_Paren, allocator)
}

is_non_inserted_semicolon :: proc(tok: tokenizer.Token) -> bool {
    return tok.kind == .Semicolon && tok.text != "\n"
}

is_blank_ident_string :: proc(str: string) -> bool {
    return str == "_"
}
is_blank_ident_token :: proc(tok: tokenizer.Token) -> bool {
    if tok.kind == .Ident {
        return is_blank_ident_string(tok.text)
    }
    return false
}

is_blank_ident_node :: proc(node: ^ast.Node) -> bool {
    if ident, ok := node.derived.(^ast.Ident); ok {
        return is_blank_ident_string(ident.name)
    }
    return true
}

fix_advance_to_next_stmt :: proc(p: ^Parser, allocator: mem.Allocator) {
    for {
        #partial switch t := p.curr_tok; t.kind {
        case .EOF, .Semicolon:
            return

        case .Package, .Foreign, .Import,
             .If, .For, .When, .Return, .Switch,
             .Defer, .Using,
             .Break, .Continue, .Fallthrough,
             .Hash:


            if t.pos == p.fix_prev_pos && p.fix_count < MAX_FIX_COUNT {
                p.fix_count += 1
                return
            }
            if t.pos.offset < p.fix_prev_pos.offset {
                p.fix_prev_pos = t.pos
                p.fix_count = 0
                return
            }
        }
        _ = advance_token(p, allocator)
    }
}


is_semicolon_optional_for_node :: proc(p: ^Parser, node: ^ast.Node) -> bool {
    if node == nil {
        return false
    }

    if .Optional_Semicolons in p.flags {
        return true
    }

    #partial switch n in node.derived {
    case ^ast.Empty_Stmt, ^ast.Block_Stmt:
        return true

    case ^ast.If_Stmt, ^ast.When_Stmt,
         ^ast.For_Stmt, ^ast.Range_Stmt, ^ast.Inline_Range_Stmt,
         ^ast.Switch_Stmt, ^ast.Type_Switch_Stmt:
        return true

    case ^ast.Helper_Type:
        return is_semicolon_optional_for_node(p, n.type)
    case ^ast.Distinct_Type:
        return is_semicolon_optional_for_node(p, n.type)
    case ^ast.Pointer_Type:
        return is_semicolon_optional_for_node(p, n.elem)
    case ^ast.Struct_Type, ^ast.Union_Type, ^ast.Enum_Type, ^ast.Bit_Set_Type, ^ast.Bit_Field_Type:
        // Require semicolon within a procedure body
        return p.curr_proc == nil
    case ^ast.Proc_Lit:
        return true

    case ^ast.Package_Decl, ^ast.Import_Decl, ^ast.Foreign_Import_Decl:
        return true

    case ^ast.Foreign_Block_Decl:
        return is_semicolon_optional_for_node(p, n.body)

    case ^ast.Value_Decl:
        if n.is_mutable {
            return false
        }
        if len(n.values) > 0 {
            return is_semicolon_optional_for_node(p, n.values[len(n.values)-1])
        }
    }

    return false
}

expect_semicolon_newline_error :: proc(p: ^Parser, token: tokenizer.Token, s: ^ast.Node) {
    if .Optional_Semicolons not_in p.flags && .Insert_Semicolon in p.tok.flags && token.text == "\n" {
        #partial switch token.kind {
        case .Close_Brace:
        case .Close_Paren:
        case .Else:
            return
        }
        if is_semicolon_optional_for_node(p, s) {
            return
        }

        tok := token
        tok.pos.column -= 1
        error(p, tok.pos, "expected ';', got newline")
    }
}


expect_semicolon :: proc(p: ^Parser, node: ^ast.Node, allocator: mem.Allocator) -> bool {
    if allow_token(p, .Semicolon, allocator) {
        expect_semicolon_newline_error(p, p.prev_tok, node)
        return true
    }

    prev := p.prev_tok
    if prev.kind == .Semicolon {
        expect_semicolon_newline_error(p, p.prev_tok, node)
        return true
    }

    if p.curr_tok.kind == .EOF {
        return true
    }

    if node != nil {
        if .Insert_Semicolon in p.tok.flags  {
            #partial switch p.curr_tok.kind {
            case .Close_Brace, .Close_Paren, .Else, .EOF:
                return true
            }

            if is_semicolon_optional_for_node(p, node) {
                return true
            }
        } else if prev.pos.line != p.curr_tok.pos.line {
            if is_semicolon_optional_for_node(p, node) {
                return true
            }
        } else {
            #partial switch p.curr_tok.kind {
            case .Close_Brace, .Close_Paren, .Else:
                return true
            case .EOF:
                if is_semicolon_optional_for_node(p, node) {
                    return true
                }
            }
        }
    } else {
        if p.curr_tok.kind == .EOF {
            return true
        }
    }

    error(p, prev.pos, "expected ';', got %s", tokenizer.token_to_string(p.curr_tok))
    fix_advance_to_next_stmt(p, allocator)
    return false
}

new_blank_ident :: proc(p: ^Parser, pos: tokenizer.Pos, allocator: mem.Allocator) -> ^ast.Ident {
    tok: tokenizer.Token
    tok.pos = pos
    i := ast.new_from_positions(ast.Ident, pos, end_pos(tok), allocator)
    i.name = "_"
    return i
}

parse_ident :: proc(p: ^Parser, allocator: mem.Allocator) -> ^ast.Ident {
    tok := p.curr_tok
    pos := tok.pos
    name := "_"
    if tok.kind == .Ident {
        name = tok.text
        _ = advance_token(p, allocator)
    } else {
        _ = expect_token(p, .Ident, allocator)
    }
    i := ast.new_from_positions(ast.Ident, pos, end_pos(tok), allocator)
    i.name = name
    return i
}

parse_stmt_list :: proc(p: ^Parser, allocator: mem.Allocator) -> []^ast.Stmt {
    list: [dynamic]^ast.Stmt
    list.allocator = allocator
    for p.curr_tok.kind != .Case &&
        p.curr_tok.kind != .Close_Brace &&
        p.curr_tok.kind != .EOF  {
        stmt := parse_stmt(p, allocator)
        if stmt != nil {
            if _, ok := stmt.derived.(^ast.Empty_Stmt); !ok {
                _ = dyn_array.append(&list, stmt)
                if es, es_ok := stmt.derived.(^ast.Expr_Stmt); es_ok && es.expr != nil {
                    if _, pl_ok := es.expr.derived.(^ast.Proc_Lit); pl_ok {
                        error(p, stmt.pos, "procedure literal evaluated but not used")
                    }
                }
            }
        }
    }
    return list[:]
}

parse_block_stmt :: proc(p: ^Parser, is_when: bool, allocator: mem.Allocator) -> ^ast.Stmt {
    _ = skip_possible_newline_for_literal(p, allocator)
    if !is_when && p.curr_proc == nil {
        error(p, p.curr_tok.pos, "you cannot use a block statement in the file scope")
    }
    return parse_body(p, allocator)
}

parse_when_stmt :: proc(p: ^Parser, allocator: mem.Allocator) -> ^ast.When_Stmt {
    tok := expect_token(p, .When, allocator)

    cond: ^ast.Expr
    body: ^ast.Stmt
    else_stmt: ^ast.Stmt

    prev_level := p.expr_level
    p.expr_level = -1
    prev_allow_in_expr := p.allow_in_expr
    p.allow_in_expr = true

    cond = parse_expr(p, false, allocator)

    p.allow_in_expr = prev_allow_in_expr
    p.expr_level = prev_level

    if cond == nil {
        error(p, p.curr_tok.pos, "expected a condition for when statement")
    }
    if allow_token(p, .Do, allocator) {
        body = convert_stmt_to_body(p, parse_stmt(p, allocator), allocator)
        if cond.pos.line != body.pos.line {
            error(p, body.pos, "the body of a 'do' must be on the same line as when statement")
        }
    } else {
        body = parse_block_stmt(p, true, allocator)
    }

    _ = skip_possible_newline_for_literal(p, allocator)
    if p.curr_tok.kind == .Else {
        else_tok := expect_token(p, .Else, allocator)
        #partial switch p.curr_tok.kind {
        case .When:
            else_stmt = parse_when_stmt(p, allocator)
        case .Open_Brace:
            else_stmt = parse_block_stmt(p, true, allocator)
        case .Do:
            _ = expect_token(p, .Do, allocator)
            else_stmt = convert_stmt_to_body(p, parse_stmt(p, allocator), allocator)
            if else_tok.pos.line != else_stmt.pos.line {
                error(p, else_stmt.pos, "the body of a 'do' must be on the same line as 'else'")
            }
        case:
            error(p, p.curr_tok.pos, "expected when statement block statement")
            else_stmt = ast.new_from_positions(ast.Bad_Stmt, p.curr_tok.pos, end_pos(p.curr_tok), allocator)
        }
    }

    end := body.end
    if else_stmt != nil {
        end = else_stmt.end
    }
    when_stmt := ast.new_from_positions(ast.When_Stmt, tok.pos, end, allocator)
    when_stmt.when_pos  = tok.pos
    when_stmt.cond      = cond
    when_stmt.body      = body
    when_stmt.else_stmt = else_stmt
    return when_stmt
}

convert_stmt_to_expr :: proc(p: ^Parser, stmt: ^ast.Stmt, kind: string, allocator: mem.Allocator) -> ^ast.Expr {
    if stmt == nil {
        return nil
    }
    if es, ok := stmt.derived.(^ast.Expr_Stmt); ok {
        return es.expr
    }
    error(p, stmt.pos, "expected %s, found a simple statement", kind)
    return ast.new_from_positions(ast.Bad_Expr, p.curr_tok.pos, end_pos(p.curr_tok), allocator)
}

parse_if_stmt :: proc(p: ^Parser, allocator: mem.Allocator) -> ^ast.If_Stmt {
    tok := expect_token(p, .If, allocator)

    init: ^ast.Stmt
    cond: ^ast.Expr
    body: ^ast.Stmt
    else_stmt: ^ast.Stmt

    prev_level := p.expr_level
    p.expr_level = -1
    prev_allow_in_expr := p.allow_in_expr
    p.allow_in_expr = true
    if allow_token(p, .Semicolon, allocator) {
        cond = parse_expr(p, false, allocator)
    } else {
        init = parse_simple_stmt(p, nil, allocator)
        if parse_control_statement_semicolon_separator(p, allocator) {
            cond = parse_expr(p, false, allocator)
        } else {
            cond = convert_stmt_to_expr(p, init, "boolean expression", allocator)
            init = nil
        }
    }

    p.expr_level = prev_level
    p.allow_in_expr = prev_allow_in_expr

    if cond == nil {
        error(p, p.curr_tok.pos, "expected a condition for if statement")

    }
    if allow_token(p, .Do, allocator) {
        body = convert_stmt_to_body(p, parse_stmt(p, allocator), allocator)
        if cond.pos.line != body.pos.line {
            error(p, body.pos, "the body of a 'do' must be on the same line as the if condition")
        }
    } else {
        body = parse_block_stmt(p, false, allocator)
    }

    else_tok := p.curr_tok.pos

    _ = skip_possible_newline_for_literal(p, allocator)
    if p.curr_tok.kind == .Else {
        else_tok := expect_token(p, .Else, allocator)
        #partial switch p.curr_tok.kind {
        case .If:
            else_stmt = parse_if_stmt(p, allocator)
        case .Open_Brace:
            else_stmt = parse_block_stmt(p, false, allocator)
        case .Do:
            _ = expect_token(p, .Do, allocator)
            else_stmt = convert_stmt_to_body(p, parse_stmt(p, allocator), allocator)
            if else_tok.pos.line != else_stmt.pos.line {
                error(p, body.pos, "the body of a 'do' must be on the same line as 'else'")
            }
        case:
            error(p, p.curr_tok.pos, "expected if statement block statement")
            else_stmt = ast.new_from_positions(ast.Bad_Stmt, p.curr_tok.pos, end_pos(p.curr_tok), allocator)
        }
    }
    
    end: tokenizer.Pos
    if body != nil {
        end = body.end
    }
    if else_stmt != nil {
        end = else_stmt.end
    }
    if_stmt := ast.new_from_positions(ast.If_Stmt, tok.pos, end, allocator)
    if_stmt.if_pos    = tok.pos
    if_stmt.init      = init
    if_stmt.cond      = cond
    if_stmt.body      = body
    if_stmt.else_stmt = else_stmt
    if_stmt.else_pos = else_tok
    return if_stmt
}

parse_control_statement_semicolon_separator :: proc(p: ^Parser, allocator: mem.Allocator) -> bool {
    tok := peek_token(p, 0, allocator)
    if tok.kind != .Open_Brace {
        return allow_token(p, .Semicolon, allocator)
    }
    if p.curr_tok.text == ";" {
        return allow_token(p, .Semicolon, allocator)
    }
    return false

}

parse_for_stmt :: proc(p: ^Parser, allocator: mem.Allocator) -> ^ast.Stmt {
    if p.curr_proc == nil {
        error(p, p.curr_tok.pos, "you cannot use a for statement in the file scope")
    }

    tok := expect_token(p, .For, allocator)

    init: ^ast.Stmt
    cond: ^ast.Stmt
    post: ^ast.Stmt
    body: ^ast.Stmt
    is_range := false

    general_conds: if p.curr_tok.kind != .Open_Brace && p.curr_tok.kind != .Do {
        prev_level := p.expr_level
        defer p.expr_level = prev_level
        p.expr_level = -1

        if p.curr_tok.kind == .In {
            in_tok := expect_token(p, .In, allocator)
            rhs: ^ast.Expr

            prev_allow_range := p.allow_range
            p.allow_range = true
            rhs = parse_expr(p, false, allocator)
            p.allow_range = prev_allow_range

            if allow_token(p, .Do, allocator) {
                body = convert_stmt_to_body(p, parse_stmt(p, allocator), allocator)
                if tok.pos.line != body.pos.line {
                    error(p, body.pos, "the body of a 'do' must be on the same line as 'else'")
                }

            } else {
                body = parse_body(p, allocator)
            }

            range_stmt := ast.new_from_pos_and_end_node(ast.Range_Stmt, tok.pos, body, allocator)
            range_stmt.for_pos = tok.pos
            range_stmt.in_pos = in_tok.pos
            range_stmt.expr = rhs
            range_stmt.body = body
            return range_stmt
        }

        if p.curr_tok.kind != .Semicolon {
            cond = parse_simple_stmt(p, {Stmt_Allow_Flag.In}, allocator)
            if as, ok := cond.derived.(^ast.Assign_Stmt); ok && as.op.kind == .In {
                is_range = true
            }
        }

        if !is_range && parse_control_statement_semicolon_separator(p, allocator) {
            init = cond
            cond = nil


            if p.curr_tok.kind == .Open_Brace || p.curr_tok.kind == .Do {
                error(p, p.curr_tok.pos, "Expected ';', followed by a condition expression and post statement, got %s", tokenizer.tokens[p.curr_tok.kind])
            } else {
                if p.curr_tok.kind != .Semicolon {
                    if p.curr_tok.kind == .Ident {
                        next_token := peek_token(p, 0, allocator)
                        if next_token.kind == .In || next_token.kind == .Comma {
                            cond = parse_simple_stmt(p, {.In}, allocator)
                            as := cond.derived_stmt.(^ast.Assign_Stmt)
                            assert(as.op.kind == .In)
                            is_range = true
                            break general_conds
                        }
                    }

                    cond = parse_simple_stmt(p, nil, allocator)
                }

                if p.curr_tok.text != ";" {
                    error(p, p.curr_tok.pos, "Expected ';', got %s", tokenizer.token_to_string(p.curr_tok))
                } else {
                    _ = expect_semicolon(p, nil, allocator)
                }

                if p.curr_tok.kind != .Open_Brace && p.curr_tok.kind != .Do {
                    post = parse_simple_stmt(p, nil, allocator)
                }
            }
        }
    }

    if allow_token(p, .Do, allocator) {
        body = convert_stmt_to_body(p, parse_stmt(p, allocator), allocator)
        if tok.pos.line != body.pos.line {
            error(p, body.pos, "the body of a 'do' must be on the same line as the 'for' token")
        }
    } else {
        _ = allow_token(p, .Semicolon, allocator)
        body = parse_body(p, allocator)
    }


    if is_range {
        assign_stmt := cond.derived.(^ast.Assign_Stmt)
        vals := assign_stmt.lhs[:]

        rhs: ^ast.Expr
        if len(assign_stmt.rhs) > 0 {
            rhs = assign_stmt.rhs[0]
        }

        range_stmt := ast.new_from_pos_and_end_node(ast.Range_Stmt, tok.pos, body, allocator)
        range_stmt.for_pos = tok.pos
        range_stmt.init = init
        range_stmt.vals = vals
        range_stmt.in_pos = assign_stmt.op.pos
        range_stmt.expr = rhs
        range_stmt.body = body
        return range_stmt
    }

    cond_expr := convert_stmt_to_expr(p, cond, "boolean expression", allocator)
    for_stmt := ast.new_from_pos_and_end_node(ast.For_Stmt, tok.pos, body, allocator)
    for_stmt.for_pos = tok.pos
    for_stmt.init = init
    for_stmt.cond = cond_expr
    for_stmt.post = post
    for_stmt.body = body
    return for_stmt
}

parse_case_clause :: proc(p: ^Parser, is_type_switch: bool, allocator: mem.Allocator) -> ^ast.Case_Clause {
    tok := expect_token(p, .Case, allocator)

    list: []^ast.Expr

    if p.curr_tok.kind != .Colon {
        prev_allow_range, prev_allow_in_expr := p.allow_range, p.allow_in_expr
        defer p.allow_range, p.allow_in_expr = prev_allow_range, prev_allow_in_expr
        p.allow_range, p.allow_in_expr = !is_type_switch, !is_type_switch

        list = parse_rhs_expr_list(p, allocator)
    }

    terminator := expect_token(p, .Colon, allocator)

    stmts := parse_stmt_list(p, allocator)

    cc := ast.new_from_positions(ast.Case_Clause, tok.pos, end_pos(p.prev_tok), allocator)
    cc.list = list
    cc.terminator = terminator
    cc.body = stmts
    cc.case_pos = tok.pos
    return cc
}

parse_switch_stmt :: proc(p: ^Parser, allocator: mem.Allocator) -> ^ast.Stmt {
    tok := expect_token(p, .Switch, allocator)

    init: ^ast.Stmt
    tag:  ^ast.Stmt
    is_type_switch := false
    clauses: [dynamic]^ast.Stmt
    clauses.allocator = allocator

    if p.curr_tok.kind != .Open_Brace {
        prev_level := p.expr_level
        defer p.expr_level = prev_level
        p.expr_level = -1

        if p.curr_tok.kind == .In {
            in_tok := expect_token(p, .In, allocator)
            is_type_switch = true

            lhs, _ := slice.create([]^ast.Expr, 1, allocator)
            rhs, _ := slice.create([]^ast.Expr, 1, allocator)
            lhs[0] = new_blank_ident(p, tok.pos, allocator)
            rhs[0] = parse_expr(p, true, allocator)

            as := ast.new_from_pos_and_end_node(ast.Assign_Stmt, tok.pos, rhs[0], allocator)
            as.lhs = lhs
            as.op  = in_tok
            as.rhs = rhs
            tag = as
        } else {
            tag = parse_simple_stmt(p, {Stmt_Allow_Flag.In}, allocator)
            if as, ok := tag.derived.(^ast.Assign_Stmt); ok && as.op.kind == .In {
                is_type_switch = true
            } else if parse_control_statement_semicolon_separator(p, allocator) {
                init = tag
                tag = nil
                if p.curr_tok.kind != .Open_Brace {
                    tag = parse_simple_stmt(p, nil, allocator)
                }
            }
        }
    }


    _ = skip_possible_newline(p, allocator)
    open := expect_token(p, .Open_Brace, allocator)

    for p.curr_tok.kind == .Case {
        clause := parse_case_clause(p, is_type_switch, allocator)
        _ = dyn_array.append(&clauses, clause)
    }

    close := expect_token(p, .Close_Brace, allocator)

    body := ast.new_from_positions(ast.Block_Stmt, open.pos, end_pos(close), allocator)
    body.stmts = clauses[:]

    if is_type_switch {
        ts := ast.new_from_pos_and_end_node(ast.Type_Switch_Stmt, tok.pos, body, allocator)
        ts.tag  = tag
        ts.body = body
        ts.switch_pos = tok.pos
        return ts
    } else {
        cond := convert_stmt_to_expr(p, tag, "switch expression", allocator)
        ts := ast.new_from_pos_and_end_node(ast.Switch_Stmt, tok.pos, body, allocator)
        ts.init = init
        ts.cond = cond
        ts.body = body
        ts.switch_pos = tok.pos
        return ts
    }
}

parse_attribute :: proc(p: ^Parser, tok: tokenizer.Token, open_kind, close_kind: tokenizer.Token_Kind, docs: ^ast.Comment_Group, allocator: mem.Allocator) -> ^ast.Stmt {
    elems: [dynamic]^ast.Expr

    open, close: tokenizer.Token

    if p.curr_tok.kind == .Ident {
        elem := parse_ident(p, allocator)
        _ = dyn_array.append(&elems, elem)
    } else {
        open = expect_token(p, open_kind, allocator)
        p.expr_level += 1
        for p.curr_tok.kind != close_kind &&
            p.curr_tok.kind != .EOF {
            elem: ^ast.Expr
            elem = parse_ident(p, allocator)
            if p.curr_tok.kind == .Eq {
                eq := expect_token(p, .Eq, allocator)
                value := parse_value(p, allocator)
                fv := ast.new_from_pos_and_end_node(ast.Field_Value, elem.pos, value, allocator)
                fv.field = elem
                fv.sep   = eq.pos
                fv.value = value

                elem = fv
            }
            _ = dyn_array.append(&elems, elem)

            allow_token(p, .Comma, allocator) or_break
        }
        p.expr_level -= 1
        close = expect_token_after(p, close_kind, "attribute", allocator)
    }

    attribute := ast.new_from_positions(ast.Attribute, tok.pos, end_pos(close), allocator)
    attribute.tok   = tok.kind
    attribute.open  = open.pos
    attribute.elems = elems[:]
    attribute.close = close.pos

    _ = skip_possible_newline(p, allocator)

    decl := parse_stmt(p, allocator)
    #partial switch d in decl.derived_stmt {
    case ^ast.Value_Decl:
        if d.docs == nil { d.docs = docs }
        _ = dyn_array.append(&d.attributes, attribute)
    case ^ast.Foreign_Block_Decl:
        if d.docs == nil { d.docs = docs }
        _ = dyn_array.append(&d.attributes, attribute)
    case ^ast.Foreign_Import_Decl:
        if d.docs == nil { d.docs = docs }
        _ = dyn_array.append(&d.attributes, attribute)
    case ^ast.Import_Decl:
        if d.docs == nil { d.docs = docs }
        _ = dyn_array.append(&d.attributes, attribute)
    case:
        error(p, decl.pos, "expected a value or foreign declaration after an attribute")
        _ = mem.free(attribute, allocator)
        _ = dyn_array.delete(elems)
    }
    return decl

}

parse_foreign_block_decl :: proc(p: ^Parser, allocator: mem.Allocator) -> ^ast.Stmt {
    decl := parse_stmt(p, allocator)
    #partial switch _ in decl.derived_stmt {
    case ^ast.Empty_Stmt, ^ast.Bad_Stmt, ^ast.Bad_Decl:
        // Ignore
        return nil
    case ^ast.When_Stmt, ^ast.Value_Decl:
        return decl
    }

    error(p, decl.pos, "foreign blocks only allow procedure and variable declarations")

    return nil

}

parse_foreign_block :: proc(p: ^Parser, tok: tokenizer.Token, allocator: mem.Allocator) -> ^ast.Foreign_Block_Decl {
    docs := p.lead_comment

    foreign_library: ^ast.Expr
    #partial switch p.curr_tok.kind {
    case .Open_Brace:
        i := ast.new_from_positions(ast.Ident, tok.pos, end_pos(tok), allocator)
        i.name = "_"
        foreign_library = i
    case:
        foreign_library = parse_ident(p, allocator)
    }

    decls: [dynamic]^ast.Stmt
    decls.allocator = allocator

    prev_in_foreign_block := p.in_foreign_block
    defer p.in_foreign_block = prev_in_foreign_block
    p.in_foreign_block = true

    _ = skip_possible_newline_for_literal(p, allocator)
    open := expect_token(p, .Open_Brace, allocator)
    for p.curr_tok.kind != .Close_Brace && p.curr_tok.kind != .EOF {
        decl := parse_foreign_block_decl(p, allocator)
        if decl != nil {
            _ = dyn_array.append(&decls, decl)
        }
    }
    close := expect_token(p, .Close_Brace, allocator)

    body := ast.new_from_positions(ast.Block_Stmt, open.pos, end_pos(close), allocator)
    body.open = open.pos
    body.stmts = decls[:]
    body.close = close.pos

    decl := ast.new_from_pos_and_end_node(ast.Foreign_Block_Decl, tok.pos, body, allocator)
    decl.docs            = docs
    decl.tok             = tok
    decl.foreign_library = foreign_library
    decl.body            = body
    return decl
}


parse_foreign_decl :: proc(p: ^Parser, allocator: mem.Allocator) -> ^ast.Decl {
    docs := p.lead_comment
    tok := expect_token(p, .Foreign, allocator)

    #partial switch p.curr_tok.kind {
    case .Ident, .Open_Brace:
        return parse_foreign_block(p, tok, allocator)

    case .Import:
        import_tok := expect_token(p, .Import, allocator)
        name: ^ast.Ident
        if p.curr_tok.kind == .Ident {
            name = parse_ident(p, allocator)
        }

        if name != nil && is_blank_ident_node(name) {
            error(p, name.pos, "illegal foreign import name: '_'")
        }

        fullpaths: [dynamic]^ast.Expr
        if allow_token(p, .Open_Brace, allocator) {
            for p.curr_tok.kind != .Close_Brace &&
                p.curr_tok.kind != .EOF {
                path := parse_expr(p, false, allocator)
                _ = dyn_array.append(&fullpaths, path)

                allow_token(p, .Comma, allocator) or_break
            }
            _ = expect_token(p, .Close_Brace, allocator)
        } else {
            path := expect_token(p, .String, allocator)
            _ = dyn_array.reserve(&fullpaths, 1)
            bl := ast.new_from_positions(ast.Basic_Lit, path.pos, end_pos(path), allocator)
            bl.tok = path
            _ = dyn_array.append(&fullpaths, bl)
        }

        if len(fullpaths) == 0 {
            error(p, import_tok.pos, "foreign import without any paths")
        }

        decl := ast.new_from_positions(ast.Foreign_Import_Decl, tok.pos, end_pos(p.prev_tok), allocator)
        decl.docs            = docs
        decl.foreign_tok     = tok
        decl.import_tok      = import_tok
        decl.name            = name
        decl.fullpaths       = fullpaths[:]
        _ = expect_semicolon(p, decl, allocator)
        decl.comment = p.line_comment
        return decl
    }

    error(p, tok.pos, "invalid foreign declaration")
    return ast.new_from_positions(ast.Bad_Decl, tok.pos, end_pos(tok), allocator)
}


parse_unrolled_for_loop :: proc(p: ^Parser, inline_tok: tokenizer.Token, allocator: mem.Allocator) -> ^ast.Stmt {
    val0, val1: ^ast.Expr
    in_tok: tokenizer.Token
    expr: ^ast.Expr
    body: ^ast.Stmt
    args: [dynamic]^ast.Expr

    if allow_token(p, .Open_Paren, allocator) {
        p.expr_level += 1
        if p.curr_tok.kind == .Close_Paren {
            error(p, p.curr_tok.pos, "#unroll expected at least 1 argument, got 0")
        } else {
            args, _ = make_dynamic_array([dynamic]^ast.Expr, allocator)
            for p.curr_tok.kind != .Close_Paren &&
                p.curr_tok.kind != .EOF {
                arg := parse_value(p, allocator)

                if p.curr_tok.kind == .Eq {
                    eq := expect_token(p, .Eq, allocator)
                    if arg != nil {
                        if _, ok := arg.derived.(^ast.Ident); !ok {
                            error(p, arg.pos, "expected an identifier for 'key=value'")
                        }
                    }
                    value := parse_value(p, allocator)
                    fv := ast.new_from_pos_and_end_node(ast.Field_Value, arg.pos, value, allocator)
                    fv.field = arg
                    fv.sep   = eq.pos
                    fv.value = value

                    arg = fv
                }

                _ = dyn_array.append(&args, arg)

                allow_token(p, .Comma, allocator) or_break
            }
        }

        p.expr_level -= 1
        _ = expect_token_after(p, .Close_Paren, "#unroll", allocator)
    }

    for_tok := expect_token(p, .For, allocator)

    bad_stmt := false

    if p.curr_tok.kind != .In {
        idents := parse_ident_list(p, false, allocator)
        switch len(idents) {
        case 1:
            val0 = idents[0]
        case 2:
            val0, val1 = idents[0], idents[1]
        case:
            error(p, for_tok.pos, "expected either 1 or 2 identifiers")
            bad_stmt = true
        }
    }

    in_tok = expect_token(p, .In, allocator)

    prev_allow_range := p.allow_range
    prev_level := p.expr_level
    p.allow_range = true
    p.expr_level = -1

    expr = parse_expr(p, false, allocator)

    p.expr_level = prev_level
    p.allow_range = prev_allow_range

    if allow_token(p, .Do, allocator) {
        body = convert_stmt_to_body(p, parse_stmt(p, allocator), allocator)
        if for_tok.pos.line != body.pos.line {
            error(p, body.pos, "the body of a 'do' must be on the same line as the 'for' token")
        }
    } else {
        body = parse_block_stmt(p, false, allocator)
    }

    if bad_stmt {
        return ast.new_from_positions(ast.Bad_Stmt, inline_tok.pos, end_pos(p.prev_tok), allocator)
    }

    range_stmt := ast.new_from_pos_and_end_node(ast.Inline_Range_Stmt, inline_tok.pos, body, allocator)
    range_stmt.unroll_pos = inline_tok.pos
    range_stmt.args = args[:]
    range_stmt.for_pos = for_tok.pos
    range_stmt.val0 = val0
    range_stmt.val1 = val1
    range_stmt.in_pos = in_tok.pos
    range_stmt.expr = expr
    range_stmt.body = body
    return range_stmt
}

parse_stmt :: proc(p: ^Parser, allocator: mem.Allocator) -> ^ast.Stmt {
    #partial switch p.curr_tok.kind {
    case .Inline:
        if peek_token_kind(p, .For, 0, allocator) {
            inline_tok := expect_token(p, .Inline, allocator)
            return parse_unrolled_for_loop(p, inline_tok, allocator)
        }
        fallthrough
    // Operands
    case .No_Inline,
         .Context, // Also allows for 'context = '
         .Proc,
         .Ident,
         .Integer, .Float, .Imag,
         .Rune, .String,
         .Open_Paren,
         .Pointer,
         .Asm, // Inline assembly
         // Unary Expressions
         .Add, .Sub, .Xor, .Not, .And:

        s := parse_simple_stmt(p, {Stmt_Allow_Flag.Label}, allocator)
        _ = expect_semicolon(p, s, allocator)
        return s


    case .Foreign: return parse_foreign_decl(p, allocator)
    case .Import:  return parse_import_decl(p, .Standard, allocator)
    case .If:      return parse_if_stmt(p, allocator)
    case .When:    return parse_when_stmt(p, allocator)
    case .For:     return parse_for_stmt(p, allocator)
    case .Switch:  return parse_switch_stmt(p, allocator)

    case .Defer:
        tok := advance_token(p, allocator)
        stmt := parse_stmt(p, allocator)
        #partial switch s in stmt.derived_stmt {
        case ^ast.Empty_Stmt:
            error(p, s.pos, "empty statement after defer (e.g. ';')")
        case ^ast.Defer_Stmt:
            error(p, s.pos, "you cannot defer a defer statement")
            stmt = s.stmt
        case ^ast.Return_Stmt:
            error(p, s.pos, "you cannot defer a return statement")
        }
        ds := ast.new_from_pos_and_end_node(ast.Defer_Stmt, tok.pos, stmt, allocator)
        ds.stmt = stmt
        return ds

    case .Return:
        tok := advance_token(p, allocator)

        if p.expr_level > 0 {
            error(p, tok.pos, "you cannot use a return statement within an expression")
        }

        results: [dynamic]^ast.Expr
        for p.curr_tok.kind != .Semicolon && p.curr_tok.kind != .Close_Brace {
            result := parse_expr(p, false, allocator)
            _ = dyn_array.append(&results, result)
            if p.curr_tok.kind != .Comma ||
               p.curr_tok.kind == .EOF {
                break
            }
            _ = advance_token(p, allocator)
        }

        end := end_pos(tok)
        if len(results) > 0 {
            end = results[len(results)-1].end
        }

        rs := ast.new_from_positions(ast.Return_Stmt, tok.pos, end, allocator)
        rs.results = results[:]
        _ = expect_semicolon(p, rs, allocator)
        return rs

    case .Break, .Continue, .Fallthrough:
        tok := advance_token(p, allocator)
        label: ^ast.Ident
        if tok.kind != .Fallthrough && p.curr_tok.kind == .Ident {
            label = parse_ident(p, allocator)
        }
        s := ast.new_from_pos_and_end_node(ast.Branch_Stmt, tok.pos, label, allocator)
        s.tok = tok
        s.label = label
        _ = expect_semicolon(p, s, allocator)
        return s

    case .Using:
        docs := p.lead_comment
        tok := expect_token(p, .Using, allocator)

        if p.curr_tok.kind == .Import {
            return parse_import_decl(p, .Using, allocator)
        }

        list := parse_lhs_expr_list(p, allocator)
        if len(list) == 0 {
            error(p, tok.pos, "illegal use of 'using' statement")
            _ = expect_semicolon(p, nil, allocator)
            return ast.new_from_positions(ast.Bad_Stmt, tok.pos, end_pos(p.prev_tok), allocator)
        }

        if p.curr_tok.kind != .Colon {
            end := list[len(list)-1]
            _ = expect_semicolon(p, end, allocator)
            us := ast.new_from_pos_and_end_node(ast.Using_Stmt, tok.pos, end, allocator)
            us.list = list
            return us
        }
        _ = expect_token_after(p, .Colon, "identifier list", allocator)
        decl := parse_value_decl(p, list, docs, allocator)
        if decl != nil {
            #partial switch d in decl.derived_stmt {
            case ^ast.Value_Decl:
                d.is_using = true
                return decl
            }
        }

        error(p, tok.pos, "illegal use of 'using' statement")
        return ast.new_from_positions(ast.Bad_Stmt, tok.pos, end_pos(p.prev_tok), allocator)

    case .At:
        docs := p.lead_comment
        tok := advance_token(p, allocator)
        return parse_attribute(p, tok, .Open_Paren, .Close_Paren, docs, allocator)

    case .Hash:
        tok := expect_token(p, .Hash, allocator)
        tag := expect_token(p, .Ident, allocator)
        name := tag.text

        switch name {
        case "bounds_check", "no_bounds_check":
            stmt := parse_stmt(p, allocator)
            switch name {
            case "bounds_check":
                stmt.state_flags += {.Bounds_Check}
            case "no_bounds_check":
                stmt.state_flags += {.No_Bounds_Check}
            }
            return stmt
        case "type_assert", "no_type_assert":
            stmt := parse_stmt(p, allocator)
            switch name {
            case "type_assert":
                stmt.state_flags += {.Type_Assert}
            case "no_type_assert":
                stmt.state_flags += {.No_Type_Assert}
            }
            return stmt
        case "partial":
            stmt := parse_stmt(p, allocator)
            #partial switch s in stmt.derived_stmt {
            case ^ast.Switch_Stmt:      s.partial = true
            case ^ast.Type_Switch_Stmt: s.partial = true
            case: error(p, stmt.pos, "#partial can only be applied to a switch statement")
            }
            return stmt
        case "assert", "panic":
            bd := ast.new_from_positions(ast.Basic_Directive, tok.pos, end_pos(tag), allocator)
            bd.tok  = tok
            bd.name = name
            ce := parse_call_expr(p, bd, allocator)
            es := ast.new_from_pos_and_end_node(ast.Expr_Stmt, ce.pos, ce, allocator)
            es.expr = ce
            return es

        case "force_inline", "force_no_inline", "must_tail":
            expr := parse_inlining_or_tailing_operand(p, true, tag, allocator)
            es := ast.new_from_pos_and_end_node(ast.Expr_Stmt, expr.pos, expr, allocator)
            es.expr = expr
            return es
        case "unroll":
            return parse_unrolled_for_loop(p, tag, allocator)
        case "reverse":
            stmt := parse_stmt(p, allocator)

            if range, is_range := stmt.derived.(^ast.Range_Stmt); is_range {
                if range.reverse {
                    error(p, range.pos, "#reverse already applied to a 'for in' statement")
                }
                range.reverse = true
            } else {
                error(p, stmt.pos, "#reverse can only be applied to a 'for in' statement")
            }
            return stmt
        case "include":
            error(p, tag.pos, "#include is not a valid import declaration kind. Did you meant 'import'?")
            return ast.new_from_positions(ast.Bad_Stmt, tok.pos, end_pos(tag), allocator)
        case:
            stmt := parse_stmt(p, allocator)
            end := stmt.pos if stmt != nil else end_pos(tok)
            te := ast.new_from_positions(ast.Tag_Stmt, tok.pos, end, allocator)
            te.op   = tok
            te.name = name
            te.stmt = stmt

            fix_advance_to_next_stmt(p, allocator)
            return te
        }
    case .Open_Brace:
        return parse_block_stmt(p, false, allocator)

    case .Semicolon:
        tok := advance_token(p, allocator)
        s := ast.new_from_positions(ast.Empty_Stmt, tok.pos, end_pos(tok), allocator)
        return s
    }


    #partial switch p.curr_tok.kind {
    case .Else:
        token := expect_token(p, .Else, allocator)
        error(p, token.pos, "'else' unattached to an 'if' statement")
        #partial switch p.curr_tok.kind {
        case .If:
            return parse_if_stmt(p, allocator)
        case .When:
            return parse_when_stmt(p, allocator)
        case .Open_Brace:
            return parse_block_stmt(p, true, allocator)
        case .Do:
            _ = expect_token(p, .Do, allocator)
            return convert_stmt_to_body(p, parse_stmt(p, allocator), allocator)
        case:
            fix_advance_to_next_stmt(p, allocator)
            return ast.new_from_positions(ast.Bad_Stmt, token.pos, end_pos(p.curr_tok), allocator)
        }
    }


    tok := advance_token(p, allocator)
    error(p, tok.pos, "expected a statement, got %s", tokenizer.token_to_string(tok))
    fix_advance_to_next_stmt(p, allocator)
    s := ast.new_from_positions(ast.Bad_Stmt, tok.pos, end_pos(tok), allocator)
    return s
}


token_precedence :: proc(p: ^Parser, kind: tokenizer.Token_Kind) -> int {
    #partial switch kind {
    case .Question, .If, .When, .Or_Else:
        return 1
    case .Ellipsis, .Range_Half, .Range_Full:
        if !p.allow_range {
            return 0
        }
        return 2
    case .Cmp_Or:
        return 3
    case .Cmp_And:
        return 4
    case .Cmp_Eq, .Not_Eq,
         .Lt, .Gt,
         .Lt_Eq, .Gt_Eq:
        return 5
    case .In, .Not_In:
        if p.expr_level < 0 && !p.allow_in_expr {
            return 0
        }
        fallthrough
    case .Add, .Sub, .Or, .Xor:
        return 6
    case .Mul, .Quo,
         .Mod, .Mod_Mod,
         .And, .And_Not,
         .Shl, .Shr:
        return 7
    }
    return 0
}

parse_type_or_ident :: proc(p: ^Parser, allocator: mem.Allocator) -> ^ast.Expr {
    prev_allow_type := p.allow_type
    prev_expr_level := p.expr_level
    defer {
        p.allow_type = prev_allow_type
        p.expr_level = prev_expr_level
    }

    p.allow_type = true
    p.expr_level = -1

    lhs := true
    return parse_atom_expr(p, parse_operand(p, lhs, allocator), lhs, allocator)
}
parse_type :: proc(p: ^Parser, allocator: mem.Allocator) -> ^ast.Expr {
    type := parse_type_or_ident(p, allocator)
    if type == nil {
        error(p, p.curr_tok.pos, "expected a type")
        return ast.new_from_positions(ast.Bad_Expr, p.curr_tok.pos, end_pos(p.curr_tok), allocator)
    }
    return type
}

parse_body :: proc(p: ^Parser, allocator: mem.Allocator) -> ^ast.Block_Stmt {
    prev_expr_level := p.expr_level
    defer p.expr_level = prev_expr_level

    p.expr_level = 0
    open := expect_token(p, .Open_Brace, allocator)
    stmts := parse_stmt_list(p, allocator)
    close := expect_token(p, .Close_Brace, allocator)

    bs := ast.new_from_positions(ast.Block_Stmt, open.pos, end_pos(close), allocator)
    bs.open = open.pos
    bs.stmts = stmts
    bs.close = close.pos
    return bs
}

convert_stmt_to_body :: proc(p: ^Parser, stmt: ^ast.Stmt, allocator: mem.Allocator) -> ^ast.Stmt {
    #partial switch s in stmt.derived_stmt {
    case ^ast.Block_Stmt:
        error(p, stmt.pos, "expected a normal statement rather than a block statement")
        return stmt
    case ^ast.Empty_Stmt:
        error(p, stmt.pos, "expected a non-empty statement")
    }

    bs := ast.new_from_pos_and_end_node(ast.Block_Stmt, stmt.pos, stmt, allocator)
    bs.open = stmt.pos
    bs.stmts, _ = slice.create([]^ast.Stmt, 1, allocator)
    bs.stmts[0] = stmt
    bs.close = stmt.end
    bs.uses_do = true
    return bs
}

new_ast_field :: proc(names: []^ast.Expr, type: ^ast.Expr, default_value: ^ast.Expr, allocator: mem.Allocator) -> ^ast.Field {
    pos, end: tokenizer.Pos

    if len(names) > 0 {
        pos = names[0].pos
        if default_value != nil {
            end = default_value.end
        } else if type != nil {
            end = type.end
        } else {
            end = names[len(names)-1].pos
        }
    } else {
        if type != nil {
            pos = type.pos
        } else if default_value != nil {
            pos = default_value.pos
        }

        if default_value != nil {
            end = default_value.end
        } else if type != nil {
            end = type.end
        }
    }

    field := ast.new_from_positions(ast.Field, pos, end, allocator)
    field.names = names
    field.type  = type
    field.default_value = default_value
    return field
}

Expr_And_Flags :: struct {
    expr:  ^ast.Expr,
    flags: ast.Field_Flags,
}

convert_to_ident_list :: proc(p: ^Parser, list: []Expr_And_Flags, ignore_flags, allow_poly_names: bool, allocator: mem.Allocator) -> []^ast.Expr {
    idents, _ := dyn_array.create_len_cap([dynamic]^ast.Expr, 0, len(list), allocator)

    for ident, i in list {
        if !ignore_flags {
            if i != 0 {
                error(p, ident.expr.pos, "illegal use of prefixes in parameter list")
            }
        }

        id: ^ast.Expr = ident.expr

        #partial switch n in ident.expr.derived_expr {
        case ^ast.Ident:
        case ^ast.Bad_Expr:
        case ^ast.Poly_Type:
            if allow_poly_names {
                if n.specialization == nil {
                    break
                } else {
                    error(p, ident.expr.pos, "expected a polymorphic identifier without an specialization")
                }
            } else {
                error(p, ident.expr.pos, "expected a non-polymorphic identifier")
            }
        case:
            error(p, ident.expr.pos, "expected an identifier")
            id = ast.new_from_positions(ast.Ident, ident.expr.pos, ident.expr.end, allocator)
        }

        _ = dyn_array.append(&idents, id)
    }

    return idents[:]
}

is_token_field_prefix :: proc(p: ^Parser, allocator: mem.Allocator) -> ast.Field_Flag {
    #partial switch p.curr_tok.kind {
    case .EOF:
        return .Invalid
    case .Using:
        _ = advance_token(p, allocator)
        return .Using
    case .Hash:
        tok: tokenizer.Token
        _ = advance_token(p, allocator)
        tok = p.curr_tok
        _ = advance_token(p, allocator)
        if tok.kind == .Ident {
            for kf in ast.field_hash_flag_strings {
                if kf.key == tok.text {
                    return kf.flag
                }
            }
        }
        return .Unknown
    }
    return .Invalid
}

parse_field_prefixes :: proc(p: ^Parser, allocator: mem.Allocator) -> (flags: ast.Field_Flags) {
    counts: [len(ast.Field_Flag)]int

    for {
        kind := is_token_field_prefix(p, allocator)
        if kind == .Invalid {
            break
        }

        if kind == .Unknown {
            error(p, p.curr_tok.pos, "unknown prefix kind '#%s'", p.curr_tok.text)
            continue
        }

        counts[kind] += 1
    }

    for kind in ast.Field_Flag {
        count := counts[kind]
        if kind == .Invalid || kind == .Unknown {
            // Ignore
        } else {
            if count > 1 { error(p, p.curr_tok.pos, "multiple '%s' in this field list", ast.field_flag_strings[kind]) }
            if count > 0 { flags += {kind} }
        }
    }

    return
}

check_field_flag_prefixes :: proc(p: ^Parser, name_count: int, allowed_flags, set_flags: ast.Field_Flags) -> (flags: ast.Field_Flags) {
    flags = set_flags
    if name_count > 1 && .Using in flags {
        error(p, p.curr_tok.pos, "cannot apply 'using' to more than one of the same type")
        flags -= {.Using}
    }

    for flag in ast.Field_Flag {
        if flag not_in allowed_flags && flag in flags {
            #partial switch flag {
            case .Unknown, .Invalid:
                // ignore
            case .Tags, .Ellipsis, .Results, .Default_Parameters, .Typeid_Token:
                panic("Impossible prefixes")
            case:
                error(p, p.curr_tok.pos, "'%s' is not allowed within this field list", ast.field_flag_strings[flag])
            }
            flags -= {flag}
        }
    }

    return flags
}

parse_var_type :: proc(p: ^Parser, flags: ast.Field_Flags, allocator: mem.Allocator) -> ^ast.Expr {
    if .Ellipsis in flags && p.curr_tok.kind == .Ellipsis {
        tok := advance_token(p, allocator)
        type := parse_type_or_ident(p, allocator)
        if type == nil {
            error(p, tok.pos, "variadic field missing type after '..'")
            type = ast.new_from_positions(ast.Bad_Expr, tok.pos, end_pos(tok), allocator)
        }
        e := ast.new_from_pos_and_end_node(ast.Ellipsis, type.pos, type, allocator)
        e.tok = tok.kind
        e.expr = type
        return e
    }
    type: ^ast.Expr
    if .Typeid_Token in flags && p.curr_tok.kind == .Typeid {
        tok := expect_token(p, .Typeid, allocator)
        specialization: ^ast.Expr
        end := tok.pos
        if allow_token(p, .Quo, allocator) {
            specialization = parse_type(p, allocator)
            end = specialization.end
        }

        ti := ast.new_from_positions(ast.Typeid_Type, tok.pos, end, allocator)
        ti.tok = tok.kind
        ti.specialization = specialization
        type = ti
    } else {
        type = parse_type(p, allocator)
    }

    return type
}

check_procedure_name_list :: proc(p: ^Parser, names: []^ast.Expr) -> bool {
    if len(names) == 0 {
        return false
    }

    _, first_is_polymorphic := names[0].derived.(^ast.Poly_Type)
    any_polymorphic_names := first_is_polymorphic

    for i := 1; i < len(names); i += 1 {
        name := names[i]

        if first_is_polymorphic {
            if _, ok := name.derived.(^ast.Poly_Type); ok {
                any_polymorphic_names = true
            } else {
                error(p, name.pos, "mixture of polymorphic and non-polymorphic identifiers")
                return any_polymorphic_names
            }
        } else {
            if _, ok := name.derived.(^ast.Poly_Type); ok {
                any_polymorphic_names = true
                error(p, name.pos, "mixture of polymorphic and non-polymorphic identifiers")
                return any_polymorphic_names
            } else {
                // Okay
            }
        }
    }

    return any_polymorphic_names
}

parse_ident_list :: proc(p: ^Parser, allow_poly_names: bool, allocator: mem.Allocator) -> []^ast.Expr {
    list: [dynamic]^ast.Expr
    list.allocator = allocator
    for {
        if allow_poly_names && p.curr_tok.kind == .Dollar {
            tok := expect_token(p, .Dollar, allocator)
            ident := parse_ident(p, allocator)
            if is_blank_ident_node(ident) {
                error(p, ident.pos, "invalid polymorphic type definition with a blank identifier")
            }
            poly_name := ast.new_from_pos_and_end_node(ast.Poly_Type, tok.pos, ident, allocator)
            poly_name.type = ident
            _ = dyn_array.append(&list, poly_name)
        } else {
            ident := parse_ident(p, allocator)
            _ = dyn_array.append(&list, ident)
        }
        if p.curr_tok.kind != .Comma ||
           p.curr_tok.kind == .EOF {
            break
        }
        _ = advance_token(p, allocator)
    }

    return list[:]
}



parse_field_list :: proc(p: ^Parser, follow: tokenizer.Token_Kind, allowed_flags: ast.Field_Flags, allocator: mem.Allocator) -> (field_list: ^ast.Field_List, total_name_count: int) {
    handle_field :: proc(p: ^Parser,
                         seen_ellipsis: ^bool, fields: ^[dynamic]^ast.Field,
                         docs: ^ast.Comment_Group,
                         names: []^ast.Expr,
                         allowed_flags, set_flags: ast.Field_Flags,
                         allocator: mem.Allocator
                         ) -> bool {

        expect_field_separator :: proc(p: ^Parser, param: ^ast.Expr, allocator: mem.Allocator) -> bool {
            tok := p.curr_tok
            if allow_token(p, .Comma, allocator) {
                return true
            }
            if allow_token(p, .Semicolon, allocator) {
                if !tokenizer.is_newline(tok) {
                    error(p, tok.pos, "expected a comma, got a semicolon")
                }
                return true
            }
            return false
        }
        is_type_ellipsis :: proc(type: ^ast.Expr) -> bool {
            if type == nil {
                return false
            }
            _, ok := type.derived.(^ast.Ellipsis)
            return ok
        }

        is_signature := (allowed_flags & ast.Field_Flags_Signature_Params) == ast.Field_Flags_Signature_Params

        any_polymorphic_names := check_procedure_name_list(p, names)
        flags := check_field_flag_prefixes(p, len(names), allowed_flags, set_flags)

        type:          ^ast.Expr
        default_value: ^ast.Expr
        tag: tokenizer.Token

        _ = expect_token_after(p, .Colon, "field list", allocator)
        if p.curr_tok.kind != .Eq {
            type = parse_var_type(p, allowed_flags, allocator)
            tt := ast.unparen_expr(type)
            if is_signature && !any_polymorphic_names {
                if ti, ok := tt.derived.(^ast.Typeid_Type); ok && ti.specialization != nil {
                    error(p, tt.pos, "specialization of typeid is not allowed without polymorphic names")
                }
            }
        }

        if allow_token(p, .Eq, allocator) {
            default_value = parse_expr(p, false, allocator)
            if .Default_Parameters not_in allowed_flags {
                error(p, p.curr_tok.pos, "default parameters are only allowed for procedures")
                default_value = nil
            }
        }

        if default_value != nil && len(names) > 1 {
            error(p, p.curr_tok.pos, "default parameters can only be applied to single values")
        }

        if allowed_flags == ast.Field_Flags_Struct && default_value != nil {
            error(p, default_value.pos, "default parameters are not allowed for structs")
            default_value = nil
        }

        if is_type_ellipsis(type) {
            if seen_ellipsis^ {
                error(p, type.pos, "extra variadic parameter after ellipsis")
            }
            seen_ellipsis^ = true
            if len(names) != 1 {
                error(p, type.pos, "variadic parameters can only have one field name")
            }
        } else if seen_ellipsis^ && default_value == nil {
            error(p, p.curr_tok.pos, "extra parameter after ellipsis without a default value")
        }

        if type != nil && default_value == nil {
            if p.curr_tok.kind == .String {
                tag = expect_token(p, .String, allocator)
                if .Tags not_in allowed_flags {
                    error(p, tag.pos, "Field tags are only allowed within structures")
                }
            }
        }

        ok := expect_field_separator(p, type, allocator)

        field := new_ast_field(names, type, default_value, allocator)
        field.tag     = tag
        field.docs    = docs
        field.flags   = flags
        field.comment = p.line_comment
        _ = dyn_array.append(fields, field)

        return ok
    }


    start_tok := p.curr_tok

    docs := p.lead_comment

    fields: [dynamic]^ast.Field

    list: [dynamic]Expr_And_Flags
    defer _ = dyn_array.delete(list)

    seen_ellipsis := false

    allow_typeid_token := .Typeid_Token in allowed_flags
    allow_poly_names := allow_typeid_token

    for p.curr_tok.kind != follow &&
        p.curr_tok.kind != .Colon &&
        p.curr_tok.kind != .EOF {
        prefix_flags := parse_field_prefixes(p, allocator)
        param := parse_var_type(p, allowed_flags & {.Typeid_Token, .Ellipsis}, allocator)
        if _, ok := param.derived.(^ast.Ellipsis); ok {
            if seen_ellipsis {
                error(p, param.pos, "extra variadic parameter after ellipsis")
            }
            seen_ellipsis = true
        } else if seen_ellipsis {
            error(p, param.pos, "extra parameter after ellipsis")
        }

        eaf := Expr_And_Flags{param, prefix_flags}
        _ = dyn_array.append(&list, eaf)
        allow_token(p, .Comma, allocator) or_break
    }

    if p.curr_tok.kind != .Colon {
        for eaf in list {
            type := eaf.expr
            tok: tokenizer.Token
            tok.pos = type.pos
            if .Results not_in allowed_flags {
                tok.text = "_"
            }

            names, _ := slice.create([]^ast.Expr, 1, allocator)
            names[0] = ast.new_from_positions(ast.Ident, tok.pos, end_pos(tok), allocator)
            #partial switch ident in names[0].derived_expr {
            case ^ast.Ident:
                ident.name = tok.text
            case:
                unreachable()
            }

            flags := check_field_flag_prefixes(p, len(list), allowed_flags, eaf.flags)

            field := new_ast_field(names, type, nil, allocator)
            field.docs    = docs
            field.flags   = flags
            field.comment = p.line_comment
            _ = dyn_array.append(&fields, field)
        }
    } else {
        names := convert_to_ident_list(p, list[:], true, allow_poly_names, allocator)
        if len(names) == 0 {
            error(p, p.curr_tok.pos, "empty field declaration")
        }

        set_flags: ast.Field_Flags
        if len(list) > 0 {
            set_flags = list[0].flags
        }
        total_name_count += len(names)
        _ = handle_field(p, &seen_ellipsis, &fields, docs, names, allowed_flags, set_flags, allocator)

        for p.curr_tok.kind != follow && p.curr_tok.kind != .EOF {
            docs = p.lead_comment
            set_flags = parse_field_prefixes(p, allocator)
            names = parse_ident_list(p, allow_poly_names, allocator)

            total_name_count += len(names)
            handle_field(p, &seen_ellipsis, &fields, docs, names, allowed_flags, set_flags, allocator) or_break
        }
    }

    field_list = ast.new_from_positions(ast.Field_List, start_tok.pos, p.curr_tok.pos, allocator)
    field_list.list = fields[:]
    return
}


parse_results :: proc(p: ^Parser, allocator: mem.Allocator) -> (list: ^ast.Field_List, diverging: bool) {
    if !allow_token(p, .Arrow_Right, allocator) {
        return
    }

    if allow_token(p, .Not, allocator) {
        diverging = true
        return
    }

    prev_level := p.expr_level
    defer p.expr_level = prev_level

    if p.curr_tok.kind != .Open_Paren {
        type := parse_type(p, allocator)
        field := new_ast_field(nil, type, nil, allocator)

        list = ast.new_from_positions(ast.Field_List, field.pos, field.end, allocator)
        list.list, _ = slice.create([]^ast.Field, 1, allocator)
        list.list[0] = field
        return
    }

    _ = expect_token(p, .Open_Paren, allocator)
    list, _ = parse_field_list(p, .Close_Paren, ast.Field_Flags_Signature_Results, allocator)
    _ = expect_token_after(p, .Close_Paren, "parameter list", allocator)
    return
}


string_to_calling_convention :: proc(s: string) -> ast.Proc_Calling_Convention {
    if s[0] != '"' && s[0] != '`' {
        return nil
    }
    if len(s) == 2 {
        return nil
    }
    return s
}

parse_proc_tags :: proc(p: ^Parser, allocator: mem.Allocator) -> (tags: ast.Proc_Tags) {
    for p.curr_tok.kind == .Hash {
        _ = expect_token(p, .Hash, allocator)
        ident := expect_token(p, .Ident, allocator)

        switch ident.text {
        case "bounds_check":    tags += {.Bounds_Check}
        case "no_bounds_check": tags += {.No_Bounds_Check}
        case "optional_ok":     tags += {.Optional_Ok}
        case "optional_allocator_error": tags += {.Optional_Allocator_Error}
        case:
        }
    }

    if .Bounds_Check in tags && .No_Bounds_Check in tags {
        p.err(p.curr_tok.pos, "#bounds_check and #no_bounds_check applied to the same procedure type")
    }

    return
}

parse_proc_type :: proc(p: ^Parser, tok: tokenizer.Token, allocator: mem.Allocator) -> ^ast.Proc_Type {
    cc: ast.Proc_Calling_Convention
    if p.curr_tok.kind == .String {
        str := expect_token(p, .String, allocator)
        cc = string_to_calling_convention(str.text)
        if cc == nil {
            error(p, str.pos, "unknown calling convention '%s'", str.text)
        }
    }

    if cc == nil && p.in_foreign_block {
        cc = .Foreign_Block_Default
    }

    _ = expect_token(p, .Open_Paren, allocator)
    p.expr_level += 1
    params, _ := parse_field_list(p, .Close_Paren, ast.Field_Flags_Signature_Params, allocator)
    p.expr_level -= 1
    _ = expect_closing_parentheses_of_field_list(p, allocator)
    results, diverging := parse_results(p, allocator)

    is_generic := false

    loop: for param in params.list {
        if param.type != nil {
            if _, ok := param.type.derived.(^ast.Poly_Type); ok {
                is_generic = true
                break loop
            }
            for name in param.names {
                if _, ok := name.derived.(^ast.Poly_Type); ok {
                    is_generic = true
                    break loop
                }
            }
        }
    }

    end := end_pos(p.prev_tok)
    pt := ast.new_from_positions(ast.Proc_Type, tok.pos, end, allocator)
    pt.tok = tok
    pt.calling_convention = cc
    pt.params = params
    pt.results = results
    pt.diverging = diverging
    pt.generic = is_generic
    return pt
}

parse_inlining_or_tailing_operand :: proc(p: ^Parser, lhs: bool, tok: tokenizer.Token, allocator: mem.Allocator) -> ^ast.Expr {
    expr := parse_unary_expr(p, lhs, allocator)

    pi := ast.Proc_Inlining.None
    pt := ast.Proc_Tailing.None
    #partial switch tok.kind {
    case .Inline:
        pi = .Inline
    case .No_Inline:
        pi = .No_Inline
    case .Ident:
        switch tok.text {
        case "force_inline":
            pi = .Inline
        case "force_no_inline":
            pi = .No_Inline
        case "must_tail":
            pt = .Must_Tail
        }
    }

    if expr != nil {
        #partial switch e in ast.strip_or_return_expr(expr).derived_expr {
        case ^ast.Proc_Lit:
            if e.inlining != .None && e.inlining != pi {
                error(p, expr.pos, "both 'inline' and 'no_inline' cannot be applied to a procedure literal")
            }
            if pt != .None {
                error(p, expr.pos, "'#must_tail' can only be applied to a procedure call, not the procedure literal")
            }

            e.inlining = pi
            e.tailing  = pt
            return expr
        case ^ast.Call_Expr:
            if e.inlining != .None && e.inlining != pi {
                error(p, expr.pos, "both 'inline' and 'no_inline' cannot be applied to a procedure call")
            }
            e.inlining = pi
            e.tailing  = pt
            return expr
        }
    }

    error(p, tok.pos, "'%s' must be followed by a procedure literal or call", tok.text)
    return ast.new_from_pos_and_end_node(ast.Bad_Expr, tok.pos, expr, allocator)
}

parse_operand :: proc(p: ^Parser, lhs: bool, allocator: mem.Allocator) -> ^ast.Expr {
    #partial switch p.curr_tok.kind {
    case .Ident:
        return parse_ident(p, allocator)

    case .Undef:
        tok := expect_token(p, .Undef, allocator)
        undef := ast.new_from_positions(ast.Undef, tok.pos, end_pos(tok), allocator)
        undef.tok = tok.kind
        return undef

    case .Context:
        tok := expect_token(p, .Context, allocator)
        ctx := ast.new_from_positions(ast.Implicit, tok.pos, end_pos(tok), allocator)
        ctx.tok = tok
        return ctx

    case .Integer, .Float, .Imag,
         .Rune, .String:
        tok := advance_token(p, allocator)
        bl := ast.new_from_positions(ast.Basic_Lit, tok.pos, end_pos(tok), allocator)
        bl.tok = tok
        return bl

    case .Open_Brace:
        if !lhs {
            return parse_literal_value(p, nil, allocator)
        }

    case .Open_Paren:
        open := expect_token(p, .Open_Paren, allocator)
        p.expr_level += 1
        expr := parse_expr(p, false, allocator)
        _ = skip_possible_newline(p, allocator)
        p.expr_level -= 1
        close := expect_token(p, .Close_Paren, allocator)

        pe := ast.new_from_positions(ast.Paren_Expr, open.pos, end_pos(close), allocator)
        pe.open  = open.pos
        pe.expr  = expr
        pe.close = close.pos
        return pe

    case .Distinct:
        tok := advance_token(p, allocator)
        type := parse_type(p, allocator)
        dt := ast.new_from_pos_and_end_node(ast.Distinct_Type, tok.pos, type, allocator)
        dt.tok  = tok.kind
        dt.type = type
        return dt

    case .Hash:
        tok := expect_token(p, .Hash, allocator)
        name := expect_token(p, .Ident, allocator)
        switch name.text {
        case "type":
            type := parse_type(p, allocator)
            hp := ast.new_from_pos_and_end_node(ast.Helper_Type, tok.pos, type, allocator)
            hp.tok  = tok.kind
            hp.type = type
            return hp

        case "file", "directory", "line", "procedure", "caller_location":
            bd := ast.new_from_positions(ast.Basic_Directive, tok.pos, end_pos(name), allocator)
            bd.tok  = tok
            bd.name = name.text
            return bd

        case "caller_expression":
            bd := ast.new_from_positions(ast.Basic_Directive, tok.pos, end_pos(name), allocator)
            bd.tok  = tok
            bd.name = name.text

            if peek_token_kind(p, .Open_Paren, 0, allocator) {
                return parse_call_expr(p, bd, allocator)
            }
            return bd

        case "location", "exists", "load", "load_directory", "load_hash", "hash", "assert", "panic", "defined", "config":
            bd := ast.new_from_positions(ast.Basic_Directive, tok.pos, end_pos(name), allocator)
            bd.tok  = tok
            bd.name = name.text
            return parse_call_expr(p, bd, allocator)

        case "soa":
            bd := ast.new_from_positions(ast.Basic_Directive, tok.pos, end_pos(name), allocator)
            bd.tok  = tok
            bd.name = name.text
            original_type := parse_type(p, allocator)
            type := ast.unparen_expr(original_type)
            #partial switch t in type.derived_expr {
            case ^ast.Array_Type:         t.tag = bd
            case ^ast.Dynamic_Array_Type: t.tag = bd
            case ^ast.Pointer_Type:       t.tag = bd
            case:
                error(p, original_type.pos, "expected an array or pointer type after #%s", name.text)
            }
            return original_type

        case "simd":
            bd := ast.new_from_positions(ast.Basic_Directive, tok.pos, end_pos(name), allocator)
            bd.tok  = tok
            bd.name = name.text
            original_type := parse_type(p, allocator)
            type := ast.unparen_expr(original_type)
            #partial switch t in type.derived_expr {
            case ^ast.Array_Type:         t.tag = bd
            case:
                error(p, original_type.pos, "expected an array type after #%s", name.text)
            }
            return original_type

        case "partial":
            tag := ast.new_from_positions(ast.Basic_Directive, tok.pos, end_pos(name), allocator)
            tag.tok = tok
            tag.name = name.text
            original_expr := parse_expr(p, lhs, allocator)
            expr := ast.unparen_expr(original_expr)
            #partial switch t in expr.derived_expr {
            case ^ast.Comp_Lit:
                t.tag = tag
            case ^ast.Array_Type:
                t.tag = tag
                error(p, tok.pos, "#%s has been replaced with #sparse for non-contiguous enumerated array types", name.text)
            case:
                error(p, tok.pos, "expected a compound literal after #%s", name.text)

            }
            return original_expr

        case "sparse":
            tag := ast.new_from_positions(ast.Basic_Directive, tok.pos, end_pos(name), allocator)
            tag.tok = tok
            tag.name = name.text
            original_type := parse_type(p, allocator)
            type := ast.unparen_expr(original_type)
            #partial switch t in type.derived_expr {
            case ^ast.Array_Type:
                t.tag = tag
            case:
                error(p, tok.pos, "expected an enumerated array type after #%s", name.text)

            }
            return original_type

        case "bounds_check", "no_bounds_check":
            operand := parse_expr(p, lhs, allocator)

            switch name.text {
            case "bounds_check":
                operand.state_flags += {.Bounds_Check}
                if .No_Bounds_Check in operand.state_flags {
                    error(p, name.pos, "#bounds_check and #no_bounds_check cannot be applied together")
                }
            case "no_bounds_check":
                operand.state_flags += {.No_Bounds_Check}
                if .Bounds_Check in operand.state_flags {
                    error(p, name.pos, "#bounds_check and #no_bounds_check cannot be applied together")
                }
            case: unimplemented()
            }
            return operand

        case "relative":
            tag := ast.new_from_positions(ast.Basic_Directive, tok.pos, end_pos(name), allocator)
            tag.tok = tok
            tag.name = name.text

            tag_call := parse_call_expr(p, tag, allocator)
            type := parse_type(p, allocator)

            rt := ast.new_from_pos_and_end_node(ast.Relative_Type, tok.pos, type, allocator)
            rt.tag = tag_call
            rt.type = type
            return rt

        case "force_inline", "force_no_inline":
            return parse_inlining_or_tailing_operand(p, lhs, name, allocator)
        case:
            expr := parse_expr(p, lhs, allocator)
            end := expr.pos if expr != nil else end_pos(tok)
            te := ast.new_from_positions(ast.Tag_Expr, tok.pos, end, allocator)
            te.op   = tok
            te.name = name.text
            te.expr = expr
            return te
        }

    case .Inline, .No_Inline:
        tok := advance_token(p, allocator)
        return parse_inlining_or_tailing_operand(p, lhs, tok, allocator)

    case .Proc:
        tok := expect_token(p, .Proc, allocator)

        if p.curr_tok.kind == .Open_Brace {
            open := expect_token(p, .Open_Brace, allocator)

            args: [dynamic]^ast.Expr

            for p.curr_tok.kind != .Close_Brace &&
                p.curr_tok.kind != .EOF {
                elem := parse_expr(p, false, allocator)
                _ = dyn_array.append(&args, elem)

                allow_token(p, .Comma, allocator) or_break
            }

            close := expect_closing_brace_of_field_list(p, allocator)

            if len(args) == 0 {
                error(p, tok.pos, "expected at least 1 argument in procedure group")
            }

            pg := ast.new_from_positions(ast.Proc_Group, tok.pos, end_pos(close), allocator)
            pg.tok   = tok
            pg.open  = open.pos
            pg.args  = args[:]
            pg.close = close.pos
            return pg
        }

        type := parse_proc_type(p, tok, allocator)
        tags: ast.Proc_Tags
        where_token: tokenizer.Token
        where_clauses: []^ast.Expr

        _ = skip_possible_newline_for_literal(p, allocator)

        if p.curr_tok.kind == .Where {
            where_token = expect_token(p, .Where, allocator)
            prev_level := p.expr_level
            p.expr_level = -1
            where_clauses = parse_rhs_expr_list(p, allocator)
            p.expr_level = prev_level
        }
        tags = parse_proc_tags(p, allocator)
        type.tags = tags

        if p.allow_type && p.expr_level < 0 {
            if where_token.kind != .Invalid {
                error(p, where_token.pos, "'where' clauses are not allowed on procedure types")
            }
            return type
        }
        body: ^ast.Stmt

        _ = skip_possible_newline_for_literal(p, allocator)

        if allow_token(p, .Undef, allocator) {
            body = nil
            if where_token.kind != .Invalid {
                error(p, where_token.pos, "'where' clauses are not allowed on procedure literals without a defined body (replaced with ---")
            }
        } else if p.curr_tok.kind == .Open_Brace {
            prev_proc := p.curr_proc
            p.curr_proc = type
            body = parse_body(p, allocator)
            p.curr_proc = prev_proc
        } else if allow_token(p, .Do, allocator) {
            prev_proc := p.curr_proc
            p.curr_proc = type
            body = convert_stmt_to_body(p, parse_stmt(p, allocator), allocator)
            p.curr_proc = prev_proc
            if type.pos.line != body.pos.line {
                error(p, body.pos, "the body of a 'do' must be on the same line as the signature")
            }
        } else {
            return type
        }

        pl := ast.new_from_positions(ast.Proc_Lit, tok.pos, end_pos(p.prev_tok), allocator)
        pl.type = type
        pl.body = body
        pl.tags = tags
        pl.where_token = where_token
        pl.where_clauses = where_clauses
        return pl

    case .Dollar:
        tok := advance_token(p, allocator)
        type := parse_ident(p, allocator)
        end := type.end

        specialization: ^ast.Expr
        if allow_token(p, .Quo, allocator) {
            specialization = parse_type(p, allocator)
            end = specialization.pos
        }
        if is_blank_ident_node(type) {
            error(p, type.pos, "invalid polymorphic type definition with a blank identifier")
        }

        pt := ast.new_from_positions(ast.Poly_Type, tok.pos, end, allocator)
        pt.dollar = tok.pos
        pt.type = type
        pt.specialization = specialization
        return pt

    case .Typeid:
        tok := advance_token(p, allocator)
        ti := ast.new_from_positions(ast.Typeid_Type, tok.pos, end_pos(tok), allocator)
        ti.tok = tok.kind
        ti.specialization = nil
        return ti

    case .Pointer:
        tok := expect_token(p, .Pointer, allocator)
        elem := parse_type(p, allocator)
        ptr := ast.new_from_pos_and_end_node(ast.Pointer_Type, tok.pos, elem, allocator)
        ptr.pointer = tok.pos
        ptr.elem = elem
        return ptr


    case .Open_Bracket:
        open := expect_token(p, .Open_Bracket, allocator)
        count: ^ast.Expr
        #partial switch p.curr_tok.kind {
        case .Pointer:
            tok := expect_token(p, .Pointer, allocator)
            close := expect_token(p, .Close_Bracket, allocator)
            elem := parse_type(p, allocator)
            t := ast.new_from_pos_and_end_node(ast.Multi_Pointer_Type, open.pos, elem, allocator)
            t.open = open.pos
            t.pointer = tok.pos
            t.close = close.pos
            t.elem = elem
            return t
        case .Dynamic:
            tok := expect_token(p, .Dynamic, allocator)
            close := expect_token(p, .Close_Bracket, allocator)
            elem := parse_type(p, allocator)
            da := ast.new_from_pos_and_end_node(ast.Dynamic_Array_Type, open.pos, elem, allocator)
            da.open = open.pos
            da.dynamic_pos = tok.pos
            da.close = close.pos
            da.elem = elem
            return da
        case .Question:
            tok := expect_token(p, .Question, allocator)
            q := ast.new_from_positions(ast.Unary_Expr, tok.pos, end_pos(tok), allocator)
            q.op = tok
            count = q
        case:
            p.expr_level += 1
            count = parse_expr(p, false, allocator)
            p.expr_level -= 1
        case .Close_Bracket:
            // handle below
        }
        close := expect_token(p, .Close_Bracket, allocator)
        elem := parse_type(p, allocator)
        at := ast.new_from_pos_and_end_node(ast.Array_Type, open.pos, elem, allocator)
        at.open  = open.pos
        at.len   = count
        at.close = close.pos
        at.elem  = elem
        return at

    case .Map:
        tok := expect_token(p, .Map, allocator)
        _ = expect_token(p, .Open_Bracket, allocator)
        key := parse_type(p, allocator)
        _ = expect_token(p, .Close_Bracket, allocator)
        value := parse_type(p, allocator)

        mt := ast.new_from_pos_and_end_node(ast.Map_Type, tok.pos, value, allocator)
        mt.tok_pos = tok.pos
        mt.key = key
        mt.value = value
        return mt

    case .Struct:
        tok := expect_token(p, .Struct, allocator)

        poly_params:     ^ast.Field_List
        align:           ^ast.Expr
        min_field_align: ^ast.Expr
        max_field_align: ^ast.Expr
        is_packed:       bool
        is_raw_union:    bool
        is_no_copy:      bool
        is_all_or_none:  bool
        is_simple:       bool
        fields:          ^ast.Field_List
        name_count:      int

        if allow_token(p, .Open_Paren, allocator) {
            param_count: int
            poly_params, param_count = parse_field_list(p, .Close_Paren, ast.Field_Flags_Record_Poly_Params, allocator)
            if param_count == 0 {
                error(p, poly_params.pos, "expected at least 1 polymorphic parameter")
                poly_params = nil
            }
            _ = expect_token_after(p, .Close_Paren, "parameter list", allocator)
        }

        prev_level := p.expr_level
        p.expr_level = -1
        for allow_token(p, .Hash, allocator) {
            tag := expect_token_after(p, .Ident, "#", allocator)
            switch tag.text {
            case "packed":
                if is_packed {
                    error(p, tag.pos, "duplicate struct tag '#%s'", tag.text)
                }
                is_packed = true
            case "all_or_none":
                if is_all_or_none {
                    error(p, tag.pos, "duplicate struct tag '#%s'", tag.text)
                }
                is_all_or_none = true
            case "simple":
                if is_simple {
                    error(p, tag.pos, "duplicate struct tag '#%s'", tag.text)
                }
                is_simple = true
            case "align":
                if align != nil {
                    error(p, tag.pos, "duplicate struct tag '#%s'", tag.text)
                }
                align = parse_expr(p, true, allocator)
            case "field_align":
                if min_field_align != nil {
                    error(p, tag.pos, "duplicate struct tag '#%s'", tag.text)
                }
                warn(p, tag.pos, "#field_align has been deprecated in favour of #min_field_align")
                min_field_align = parse_expr(p, true, allocator)
            case "min_field_align":
                if min_field_align != nil {
                    error(p, tag.pos, "duplicate struct tag '#%s'", tag.text)
                }
                min_field_align = parse_expr(p, true, allocator)
            case "max_field_align":
                if max_field_align != nil {
                    error(p, tag.pos, "duplicate struct tag '#%s'", tag.text)
                }
                max_field_align = parse_expr(p, true, allocator)
            case "raw_union":
                if is_raw_union {
                    error(p, tag.pos, "duplicate struct tag '#%s'", tag.text)
                }
                is_raw_union = true
            case "no_copy":
                if is_no_copy {
                    error(p, tag.pos, "duplicate struct tag '#%s'", tag.text)
                }
                is_no_copy = true
            case:
                error(p, tag.pos, "invalid struct tag '#%s", tag.text)
            }
        }
        p.expr_level = prev_level

        if is_raw_union && is_packed {
            is_packed = false
            error(p, tok.pos, "'#raw_union' cannot also be '#packed")
        }

        if is_raw_union && is_all_or_none {
            is_all_or_none = false
            error(p, tok.pos, "'#raw_union' cannot also be '#all_or_none")
        }

        where_token: tokenizer.Token
        where_clauses: []^ast.Expr

        _ = skip_possible_newline_for_literal(p, allocator)

        if p.curr_tok.kind == .Where {
            where_token = expect_token(p, .Where, allocator)
            where_prev_level := p.expr_level
            p.expr_level = -1
            where_clauses = parse_rhs_expr_list(p, allocator)
            p.expr_level = where_prev_level
        }

        _ = skip_possible_newline_for_literal(p, allocator)
        _ = expect_token(p, .Open_Brace, allocator)
        fields, name_count = parse_field_list(p, .Close_Brace, ast.Field_Flags_Struct, allocator)
        close := expect_closing_brace_of_field_list(p, allocator)

        st := ast.new_from_positions(ast.Struct_Type, tok.pos, end_pos(close), allocator)
        st.poly_params       = poly_params
        st.align             = align
        st.min_field_align   = min_field_align
        st.max_field_align   = max_field_align
        st.is_packed         = is_packed
        st.is_raw_union      = is_raw_union
        st.is_no_copy        = is_no_copy
        st.is_all_or_none    = is_all_or_none
        st.is_simple         = is_simple
        st.fields            = fields
        st.name_count        = name_count
        st.where_token       = where_token
        st.where_clauses     = where_clauses
        return st

    case .Union:
        tok := expect_token(p, .Union, allocator)
        poly_params: ^ast.Field_List
        align:       ^ast.Expr
        is_no_nil:     bool
        is_shared_nil: bool

        if allow_token(p, .Open_Paren, allocator) {
            param_count: int
            poly_params, param_count = parse_field_list(p, .Close_Paren, ast.Field_Flags_Record_Poly_Params, allocator)
            if param_count == 0 {
                error(p, poly_params.pos, "expected at least 1 polymorphic parameter")
                poly_params = nil
            }
            _ = expect_token_after(p, .Close_Paren, "parameter list", allocator)
        }

        prev_level := p.expr_level
        p.expr_level = -1
        for allow_token(p, .Hash, allocator) {
            tag := expect_token_after(p, .Ident, "#", allocator)
            switch tag.text {
            case "align":
                if align != nil {
                    error(p, tag.pos, "duplicate union tag '#%s'", tag.text)
                }
                align = parse_expr(p, true, allocator)
            case "maybe":
                error(p, tag.pos, "#%s functionality has now been merged with standard 'union' functionality", tag.text)
            case "no_nil":
                if is_no_nil {
                    error(p, tag.pos, "duplicate union tag '#%s'", tag.text)
                }
                is_no_nil = true
            case "shared_nil":
                if is_shared_nil {
                    error(p, tag.pos, "duplicate union tag '#%s'", tag.text)
                }
                is_shared_nil = true
            case:
                error(p, tag.pos, "invalid union tag '#%s", tag.text)
            }
        }
        p.expr_level = prev_level

        if is_no_nil && is_shared_nil {
            error(p, p.curr_tok.pos, "#shared_nil and #no_nil cannot be applied together")
        }

        union_kind := ast.Union_Type_Kind.Normal
        switch {
        case is_no_nil:     union_kind = .no_nil
        case is_shared_nil: union_kind = .shared_nil
        }

        where_token: tokenizer.Token
        where_clauses: []^ast.Expr

        _ = skip_possible_newline_for_literal(p, allocator)

        if p.curr_tok.kind == .Where {
            where_token = expect_token(p, .Where, allocator)
            where_prev_level := p.expr_level
            p.expr_level = -1
            where_clauses = parse_rhs_expr_list(p, allocator)
            p.expr_level = where_prev_level
        }


        _ = skip_possible_newline_for_literal(p, allocator)
        _ = expect_token_after(p, .Open_Brace, "union", allocator)

        variants: [dynamic]^ast.Expr
        for p.curr_tok.kind != .Close_Brace && p.curr_tok.kind != .EOF {
            type := parse_type(p, allocator)
            if _, ok := type.derived.(^ast.Bad_Expr); !ok {
                _ = dyn_array.append(&variants, type)
            }
            allow_token(p, .Comma, allocator) or_break
        }

        close := expect_closing_brace_of_field_list(p, allocator)



        ut := ast.new_from_positions(ast.Union_Type, tok.pos, end_pos(close), allocator)
        ut.poly_params   = poly_params
        ut.variants      = variants[:]
        ut.align         = align
        ut.where_token   = where_token
        ut.where_clauses = where_clauses
        ut.kind          = union_kind

        return ut

    case .Enum:
        tok := expect_token(p, .Enum, allocator)
        base_type: ^ast.Expr
        if p.curr_tok.kind != .Open_Brace {
            base_type = parse_type(p, allocator)
        }

        _ = skip_possible_newline_for_literal(p, allocator)
        open := expect_token(p, .Open_Brace, allocator)
        fields := parse_elem_list(p, allocator)
        close := expect_closing_brace_of_field_list(p, allocator)

        et := ast.new_from_positions(ast.Enum_Type, tok.pos, end_pos(close), allocator)
        et.base_type = base_type
        et.open = open.pos
        et.fields = fields
        et.close = close.pos
        return et

    case .Bit_Set:
        tok := expect_token(p, .Bit_Set, allocator)
        open := expect_token(p, .Open_Bracket, allocator)
        elem, underlying: ^ast.Expr

        prev_allow_range := p.allow_range
        p.allow_range = true
        elem = parse_expr(p, false, allocator)
        p.allow_range = prev_allow_range

        if allow_token(p, .Semicolon, allocator) {
            underlying = parse_type(p, allocator)
        }


        close := expect_token(p, .Close_Bracket, allocator)

        bst := ast.new_from_positions(ast.Bit_Set_Type, tok.pos, end_pos(close), allocator)
        bst.tok_pos = tok.pos
        bst.open = open.pos
        bst.elem = elem
        bst.underlying = underlying
        bst.close = close.pos
        return bst
        
    case .Matrix:
        tok := expect_token(p, .Matrix, allocator)
        _ = expect_token(p, .Open_Bracket, allocator)
        row_count := parse_expr(p, false, allocator)
        _ = expect_token(p, .Comma, allocator)
        column_count := parse_expr(p, false, allocator)
        _ = expect_token(p, .Close_Bracket, allocator)
        elem := parse_type(p, allocator)

        mt := ast.new_from_pos_and_end_node(ast.Matrix_Type, tok.pos, elem, allocator)
        mt.tok_pos = tok.pos
        mt.row_count = row_count
        mt.column_count = column_count
        mt.elem = elem
        return mt
    
    case .Bit_Field:
        tok := expect_token(p, .Bit_Field, allocator)

        backing_type := parse_type_or_ident(p, allocator)
        if backing_type == nil {
            token := advance_token(p, allocator)
            error(p, token.pos, "Expected a backing type for a 'bit_field'")
        }

        _ = skip_possible_newline_for_literal(p, allocator)
        open := expect_token_after(p, .Open_Brace, "bit_field", allocator)

        fields: [dynamic]^ast.Bit_Field_Field
        for p.curr_tok.kind != .Close_Brace && p.curr_tok.kind != .EOF {
            docs := p.lead_comment

            name := parse_ident(p, allocator)
            _ = expect_token(p, .Colon, allocator)
            type := parse_type(p, allocator)
            _ = expect_token(p, .Or, allocator)
            bit_size := parse_expr(p, true, allocator)

            tag: tokenizer.Token
            if p.curr_tok.kind == .String {
                tag = expect_token(p, .String, allocator)
            }
            ok := allow_token(p, .Comma, allocator)

            field := ast.new_from_pos_and_end_node(ast.Bit_Field_Field, name.pos, bit_size, allocator)

            field.name     = name
            field.type     = type
            field.bit_size = bit_size
            field.tag      = tag
            field.docs     = docs
            field.comments = p.line_comment

            _ = dyn_array.append(&fields, field)

            if !ok {
                break
            }
        }

        close := expect_closing_brace_of_field_list(p, allocator)

        bf := ast.new_from_positions(ast.Bit_Field_Type, tok.pos, end_pos(close), allocator)

        bf.tok_pos      = tok.pos
        bf.backing_type = backing_type
        bf.open         = open.pos
        bf.fields       = fields[:]
        bf.close        = close.pos
        return bf

    case .Asm:
        tok := expect_token(p, .Asm, allocator)

        param_types: [dynamic]^ast.Expr
        return_type: ^ast.Expr
        if allow_token(p, .Open_Paren, allocator) {
            for p.curr_tok.kind != .Close_Paren && p.curr_tok.kind != .EOF {
                t := parse_type(p, allocator)
                _ = dyn_array.append(&param_types, t)
                if p.curr_tok.kind != .Comma ||
                   p.curr_tok.kind == .EOF {
                    break
                }
                _ = advance_token(p, allocator)
            }
            _ = expect_token(p, .Close_Paren, allocator)

            if allow_token(p, .Arrow_Right, allocator) {
                return_type = parse_type(p, allocator)
            }
        }

        has_side_effects := false
        is_align_stack := false
        dialect := ast.Inline_Asm_Dialect.Default
        for allow_token(p, .Hash, allocator) {
            if p.curr_tok.kind == .Ident {
                name := advance_token(p, allocator)
                switch name.text {
                case "side_effects":
                    if has_side_effects {
                        error(p, tok.pos, "duplicate directive on inline asm expression: '#side_effects'")
                    }
                    has_side_effects = true
                case "align_stack":
                    if is_align_stack {
                        error(p, tok.pos, "duplicate directive on inline asm expression: '#align_stack'")
                    }
                    is_align_stack = true
                case "att":
                    if dialect == .ATT {
                        error(p, tok.pos, "duplicate directive on inline asm expression: '#att'")
                    } else if dialect != .Default {
                        error(p, tok.pos, "conflicting asm dialects")
                    } else {
                        dialect = .ATT
                    }
                case "intel":
                    if dialect == .Intel {
                        error(p, tok.pos, "duplicate directive on inline asm expression: '#intel'")
                    } else if dialect != .Default {
                        error(p, tok.pos, "conflicting asm dialects")
                    } else {
                        dialect = .Intel
                    }
                }

            } else {
                error(p, p.curr_tok.pos, "expected an identifier after hash")
            }
        }

        _ = skip_possible_newline_for_literal(p, allocator)
        open := expect_token(p, .Open_Brace, allocator)
        asm_string := parse_expr(p, false, allocator)
        _ = expect_token(p, .Comma, allocator)
        constraints_string := parse_expr(p, false, allocator)
        _ = allow_token(p, .Comma, allocator)
        close := expect_closing_brace_of_field_list(p, allocator)

        e := ast.new_from_positions(ast.Inline_Asm_Expr, tok.pos, end_pos(close), allocator)
        e.tok                = tok
        e.param_types        = param_types[:]
        e.return_type        = return_type
        e.constraints_string = constraints_string
        e.has_side_effects   = has_side_effects
        e.is_align_stack     = is_align_stack
        e.dialect            = dialect
        e.open               = open.pos
        e.asm_string         = asm_string
        e.close              = close.pos

        return e

    }

    return nil
}

is_literal_type :: proc(expr: ^ast.Expr) -> bool {
    val := ast.unparen_expr(expr)
    if val == nil {
        return false
    }
    #partial switch _ in val.derived_expr {
    case ^ast.Bad_Expr,
        ^ast.Ident,
        ^ast.Selector_Expr,
        ^ast.Array_Type,
        ^ast.Struct_Type,
        ^ast.Union_Type,
        ^ast.Enum_Type,
        ^ast.Dynamic_Array_Type,
        ^ast.Map_Type,
        ^ast.Bit_Set_Type,
        ^ast.Matrix_Type,
        ^ast.Call_Expr,
        ^ast.Bit_Field_Type:
        return true
    }
    return false
}

parse_value :: proc(p: ^Parser, allocator: mem.Allocator) -> ^ast.Expr {
    if p.curr_tok.kind == .Open_Brace {
        return parse_literal_value(p, nil, allocator)
    }
    prev_allow_range := p.allow_range
    defer p.allow_range = prev_allow_range
    p.allow_range = true
    return parse_expr(p, false, allocator)
}

parse_elem_list :: proc(p: ^Parser, allocator: mem.Allocator) -> []^ast.Expr {
    elems: [dynamic]^ast.Expr
    elems.allocator = allocator

    for p.curr_tok.kind != .Close_Brace && p.curr_tok.kind != .EOF {
        elem := parse_value(p, allocator)
        if p.curr_tok.kind == .Eq {
            eq := expect_token(p, .Eq, allocator)
            value := parse_value(p, allocator)

            fv := ast.new_from_pos_and_end_node(ast.Field_Value, elem.pos, value, allocator)
            fv.field = elem
            fv.sep   = eq.pos
            fv.value = value

            elem = fv
        }

        _ = dyn_array.append(&elems, elem)

        allow_token(p, .Comma, allocator) or_break
    }

    return elems[:]
}

parse_literal_value :: proc(p: ^Parser, type: ^ast.Expr, allocator: mem.Allocator) -> ^ast.Comp_Lit {
    elems: []^ast.Expr
    open := expect_token(p, .Open_Brace, allocator)
    p.expr_level += 1
    if p.curr_tok.kind != .Close_Brace {
        elems = parse_elem_list(p, allocator)
    }
    p.expr_level -= 1

    _ = skip_possible_newline(p, allocator)
    close := expect_closing_brace_of_field_list(p, allocator)

    pos := type.pos if type != nil else open.pos
    lit := ast.new_from_positions(ast.Comp_Lit, pos, end_pos(close), allocator)
    lit.type  = type
    lit.open  = open.pos
    lit.elems = elems
    lit.close = close.pos
    return lit
}

parse_call_expr :: proc(p: ^Parser, operand: ^ast.Expr, allocator: mem.Allocator) -> ^ast.Expr {
    args: [dynamic]^ast.Expr

    ellipsis: tokenizer.Token

    p.expr_level += 1
    open := expect_token(p, .Open_Paren, allocator)

    seen_ellipsis := false
    for p.curr_tok.kind != .Close_Paren &&
        p.curr_tok.kind != .EOF {

        if p.curr_tok.kind == .Comma {
            error(p, p.curr_tok.pos, "expected an expression not ,")
        } else if p.curr_tok.kind == .Eq {
            error(p, p.curr_tok.pos, "expected an expression not =")
        }

        prefix_ellipsis := false
        if p.curr_tok.kind == .Ellipsis {
            prefix_ellipsis = true
            ellipsis = expect_token(p, .Ellipsis, allocator)
        }

        arg := parse_expr(p, false, allocator)
        if p.curr_tok.kind == .Eq {
            eq := expect_token(p, .Eq, allocator)

            if prefix_ellipsis {
                error(p, ellipsis.pos, "'..' must be applied to value rather than a field name")
            }

            value := parse_value(p, allocator)
            fv := ast.new_from_pos_and_end_node(ast.Field_Value, arg.pos, value, allocator)
            fv.field = arg
            fv.sep   = eq.pos
            fv.value = value

            arg = fv
        } else if seen_ellipsis {
            error(p, arg.pos, "Positional arguments are not allowed after '..'")
        }

        _ = dyn_array.append(&args, arg)

        if ellipsis.pos.line != 0 {
            seen_ellipsis = true
        }

        allow_token(p, .Comma, allocator) or_break
    }

    close := expect_closing_token_of_field_list(p, .Close_Paren, "argument list", allocator)
    p.expr_level -= 1

    ce := ast.new_from_positions(ast.Call_Expr, operand.pos, end_pos(close), allocator)
    ce.expr     = operand
    ce.open     = open.pos
    ce.args     = args[:]
    ce.ellipsis = ellipsis
    ce.close    = close.pos

    o := ast.unparen_expr(operand)
    if se, ok := o.derived.(^ast.Selector_Expr); ok && se.op.kind == .Arrow_Right {
        sce := ast.new_from_pos_and_end_node(ast.Selector_Call_Expr, ce.pos, ce, allocator)
        sce.expr = o
        sce.call = ce
        return sce
    }

    return ce
}

empty_selector_expr :: proc(tok: tokenizer.Token, operand: ^ast.Expr, allocator: mem.Allocator) -> ^ast.Selector_Expr {
    field := ast.new_from_positions(ast.Ident, tok.pos, end_pos(tok), allocator)
    field.name = ""

    sel := ast.new_from_pos_and_end_node(ast.Selector_Expr, operand.pos, field, allocator)
    sel.expr  = operand
    sel.op = tok
    sel.field = field

    return sel
}

parse_atom_expr :: proc(p: ^Parser, value: ^ast.Expr, lhs: bool, allocator: mem.Allocator) -> (operand: ^ast.Expr) {
    operand = value
    if operand == nil {
        if p.allow_type {
            return nil
        }
        error(p, p.curr_tok.pos, "expected an operand")
        fix_advance_to_next_stmt(p, allocator)
        be := ast.new_from_positions(ast.Bad_Expr, p.curr_tok.pos, end_pos(p.curr_tok), allocator)
        operand = be
    }

    loop := true
    is_lhs := lhs
    for loop {
        #partial switch p.curr_tok.kind {
        case:
            loop = false

        case .Open_Paren:
            operand = parse_call_expr(p, operand, allocator)

        case .Open_Bracket:
            prev_allow_range := p.allow_range
            defer p.allow_range = prev_allow_range
            p.allow_range = false

            indices: [2]^ast.Expr
            interval: tokenizer.Token
            is_slice_op := false

            p.expr_level += 1
            open := expect_token(p, .Open_Bracket, allocator)

            #partial switch p.curr_tok.kind {
            case .Colon, .Ellipsis, .Range_Half, .Range_Full:
                // NOTE(bill): Do not err yet
                break
            case:
                indices[0] = parse_expr(p, false, allocator)
            }

            #partial switch p.curr_tok.kind {
            case .Ellipsis, .Range_Half, .Range_Full:
                error(p, p.curr_tok.pos, "expected a colon, not a range")
                fallthrough
            case .Colon, .Comma/*matrix index*/:
                interval = advance_token(p, allocator)
                is_slice_op = true
                if p.curr_tok.kind != .Close_Bracket && p.curr_tok.kind != .EOF {
                    indices[1] = parse_expr(p, false, allocator)
                }
            }

            close := expect_token(p, .Close_Bracket, allocator)
            p.expr_level -= 1

            if is_slice_op {
                if interval.kind == .Comma {
                    if indices[0] == nil || indices[1] == nil {
                        error(p, p.curr_tok.pos, "matrix index expressions require both row and column indices")
                    }
                    se := ast.new_from_positions(ast.Matrix_Index_Expr, operand.pos, end_pos(close), allocator)
                    se.expr = operand
                    se.open = open.pos
                    se.row_index = indices[0]
                    se.column_index = indices[1]
                    se.close = close.pos

                    operand = se
                } else {
                    se := ast.new_from_positions(ast.Slice_Expr, operand.pos, end_pos(close), allocator)
                    se.expr = operand
                    se.open = open.pos
                    se.low = indices[0]
                    se.interval = interval
                    se.high = indices[1]
                    se.close = close.pos

                    operand = se
                }
            } else {
                ie := ast.new_from_positions(ast.Index_Expr, operand.pos, end_pos(close), allocator)
                ie.expr = operand
                ie.open = open.pos
                ie.index = indices[0]
                ie.close = close.pos

                operand = ie
            }


        case .Period:
            tok := expect_token(p, .Period, allocator)
            #partial switch p.curr_tok.kind {
            case .Ident:
                field := parse_ident(p, allocator)

                sel := ast.new_from_pos_and_end_node(ast.Selector_Expr, operand.pos, field, allocator)
                sel.expr  = operand
                sel.op = tok
                sel.field = field

                operand = sel

            case .Open_Paren:
                open := expect_token(p, .Open_Paren, allocator)
                type := parse_type(p, allocator)
                close := expect_token(p, .Close_Paren, allocator)

                ta := ast.new_from_positions(ast.Type_Assertion, operand.pos, end_pos(close), allocator)
                ta.expr  = operand
                ta.open  = open.pos
                ta.type  = type
                ta.close = close.pos

                operand = ta

            case .Question:
                question := expect_token(p, .Question, allocator)
                type := ast.new_from_positions(ast.Unary_Expr, question.pos, end_pos(question), allocator)
                type.op = question
                type.expr = nil

                ta := ast.new_from_pos_and_end_node(ast.Type_Assertion, operand.pos, type, allocator)
                ta.expr  = operand
                ta.type  = type

                operand = ta

            case:
                error(p, p.curr_tok.pos, "expected a selector")
                operand = empty_selector_expr(tok, operand, allocator)
            }

        case .Arrow_Right:
            tok := expect_token(p, .Arrow_Right, allocator)
            #partial switch p.curr_tok.kind {
            case .Ident:
                field := parse_ident(p, allocator)

                sel := ast.new_from_pos_and_end_node(ast.Selector_Expr, operand.pos, field, allocator)
                sel.expr  = operand
                sel.op = tok
                sel.field = field

                operand = sel
            case:
                error(p, p.curr_tok.pos, "expected a selector")
                operand = empty_selector_expr(tok, operand, allocator)
            }

        case .Pointer:
            op := expect_token(p, .Pointer, allocator)
            deref := ast.new_from_positions(ast.Deref_Expr, operand.pos, end_pos(op), allocator)
            deref.expr = operand
            deref.op   = op

            operand = deref

        case .Or_Return:
            token := expect_token(p, .Or_Return, allocator)
            oe := ast.new_from_positions(ast.Or_Return_Expr, operand.pos, end_pos(token), allocator)
            oe.expr  = operand
            oe.token = token

            operand = oe

        case .Or_Break, .Or_Continue:
            token := advance_token(p, allocator)
            label: ^ast.Ident

            end := end_pos(token)
            if p.curr_tok.kind == .Ident {
                end = end_pos(p.curr_tok)
                label = parse_ident(p, allocator)
            }

            oe := ast.new_from_positions(ast.Or_Branch_Expr, operand.pos, end, allocator)
            oe.expr  = operand
            oe.token = token
            oe.label = label

            operand = oe

        case .Open_Brace:
            if !is_lhs && is_literal_type(operand) && p.expr_level >= 0 {
                operand = parse_literal_value(p, operand, allocator)
            } else {
                loop = false
            }

        case .Increment, .Decrement:
            if !lhs {
                tok := advance_token(p, allocator)
                error(p, tok.pos, "postfix '%s' operator is not supported", tok.text)
            } else {
                loop = false
            }
        }

        is_lhs = false
    }

    return operand

}

parse_expr :: proc(p: ^Parser, lhs: bool, allocator: mem.Allocator) -> ^ast.Expr {
    return parse_binary_expr(p, lhs, 0+1, allocator)
}
parse_unary_expr :: proc(p: ^Parser, lhs: bool, allocator: mem.Allocator) -> ^ast.Expr {
    #partial switch p.curr_tok.kind {
    case .Transmute, .Cast:
        tok := advance_token(p, allocator)
        open := expect_token(p, .Open_Paren, allocator)
        type := parse_type(p, allocator)
        close := expect_token(p, .Close_Paren, allocator)
        expr := parse_unary_expr(p, lhs, allocator)

        tc := ast.new_from_pos_and_end_node(ast.Type_Cast, tok.pos, expr, allocator)
        tc.tok   = tok
        tc.open  = open.pos
        tc.type  = type
        tc.close = close.pos
        tc.expr  = expr
        return tc

    case .Auto_Cast:
        op := advance_token(p, allocator)
        expr := parse_unary_expr(p, lhs, allocator)

        ac := ast.new_from_pos_and_end_node(ast.Auto_Cast, op.pos, expr, allocator)
        ac.op   = op
        ac.expr = expr
        return ac

    case .Add, .Sub,
         .Not, .Xor,
         .And:
        op := advance_token(p, allocator)
        expr := parse_unary_expr(p, lhs, allocator)
        
        ue := ast.new_from_pos_and_end_node(ast.Unary_Expr, op.pos, expr, allocator)
        ue.op   = op
        ue.expr = expr
        return ue

    case .Increment, .Decrement:
        op := advance_token(p, allocator)
        error(p, op.pos, "unary '%s' operator is not supported", op.text)
        expr := parse_unary_expr(p, lhs, allocator)

        ue := ast.new_from_pos_and_end_node(ast.Unary_Expr, op.pos, expr, allocator)
        ue.op   = op
        ue.expr = expr
        return ue

    case .Period:
        op := advance_token(p, allocator)
        field := parse_ident(p, allocator)
        ise := ast.new_from_pos_and_end_node(ast.Implicit_Selector_Expr, op.pos, field, allocator)
        ise.field = field
        return ise

    }
    return parse_atom_expr(p, parse_operand(p, lhs, allocator), lhs, allocator)
}
parse_binary_expr :: proc(p: ^Parser, lhs: bool, prec_in: int, allocator: mem.Allocator) -> ^ast.Expr {
    start_pos := p.curr_tok.pos
    expr := parse_unary_expr(p, lhs, allocator)

    if expr == nil {
        return ast.new_from_positions(ast.Bad_Expr, start_pos, end_pos(p.prev_tok), allocator)
    }

    for prec := token_precedence(p, p.curr_tok.kind); prec >= prec_in; prec -= 1 {
        loop: for {
            op := p.curr_tok
            op_prec := token_precedence(p, op.kind)
            if op_prec != prec {
                break loop
            }

            #partial switch op.kind {
            case .If, .When:
                if p.prev_tok.pos.line < op.pos.line {
                    // NOTE(bill): Check to see if the `if` or `when` is on the same line of the `lhs` condition
                    break loop
                }
            }

            _ = expect_operator(p, allocator)

            #partial switch op.kind {
            case .Question:

                cond := expr
                x := parse_expr(p, lhs, allocator)
                colon := expect_token(p, .Colon, allocator)
                y := parse_expr(p, lhs, allocator)
                te := ast.new_from_positions(ast.Ternary_If_Expr, expr.pos, end_pos(p.prev_tok), allocator)
                te.cond = cond
                te.op1  = op
                te.x    = x
                te.op2  = colon
                te.y    = y

                expr = te
            case .If:
                x := expr
                cond := parse_expr(p, lhs, allocator)
                else_tok := expect_token(p, .Else, allocator)
                y := parse_expr(p, lhs, allocator)
                te := ast.new_from_positions(ast.Ternary_If_Expr, expr.pos, end_pos(p.prev_tok), allocator)
                te.x    = x
                te.op1  = op
                te.cond = cond
                te.op2  = else_tok
                te.y    = y

                expr = te
            case .When:
                x := expr
                cond := parse_expr(p, lhs, allocator)
                _ = skip_possible_newline(p, allocator)
                else_tok := expect_token(p, .Else, allocator)
                y := parse_expr(p, lhs, allocator)
                te := ast.new_from_positions(ast.Ternary_When_Expr, expr.pos, end_pos(p.prev_tok), allocator)
                te.x    = x
                te.op1  = op
                te.cond = cond
                te.op2  = else_tok
                te.y    = y

                expr = te
            case .Or_Else:
                x := expr
                y := parse_expr(p, lhs, allocator)
                oe := ast.new_from_positions(ast.Or_Else_Expr, expr.pos, end_pos(p.prev_tok), allocator)
                oe.x     = x
                oe.token = op
                oe.y     = y

                expr = oe

            case:
                right := parse_binary_expr(p, false, prec+1, allocator)
                if right == nil {
                    error(p, op.pos, "expected expression on the right-hand side of the binary operator")
                }
                be := ast.new_from_positions(ast.Binary_Expr, expr.pos, end_pos(p.prev_tok), allocator)
                be.left  = expr
                be.op    = op
                be.right = right

                expr = be
            }
        }
    }

    return expr
}


parse_expr_list :: proc(p: ^Parser, lhs: bool, allocator: mem.Allocator) -> ([]^ast.Expr) {
    list: [dynamic]^ast.Expr
    list.allocator = allocator
    for {
        expr := parse_expr(p, lhs, allocator)
        _ = dyn_array.append(&list, expr)
        if p.curr_tok.kind != .Comma || p.curr_tok.kind == .EOF {
            break
        }
        _ = advance_token(p, allocator)
    }

    return list[:]
}
parse_lhs_expr_list :: proc(p: ^Parser, allocator: mem.Allocator) -> []^ast.Expr {
    return parse_expr_list(p, true, allocator)
}
parse_rhs_expr_list :: proc(p: ^Parser, allocator: mem.Allocator) -> []^ast.Expr {
    return parse_expr_list(p, false, allocator)
}

parse_simple_stmt :: proc(p: ^Parser, flags: Stmt_Allow_Flags, allocator: mem.Allocator) -> ^ast.Stmt {
    start_tok := p.curr_tok
    docs := p.lead_comment

    lhs := parse_lhs_expr_list(p, allocator)
    op := p.curr_tok
    switch {
    case tokenizer.is_assignment_operator(op.kind):
        // if p.curr_proc == nil {
        //  error(p, p.curr_tok.pos, "simple statements are not allowed at the file scope");
        //  return ast.new_from_pos_and_end_node(ast.Bad_Stmt, start_tok.pos, end_pos(p.curr_tok));
        // }
        _ = advance_token(p, allocator)
        rhs := parse_rhs_expr_list(p, allocator)
        if len(rhs) == 0 {
            error(p, p.curr_tok.pos, "no right-hand side in assignment statement")
            return ast.new_from_positions(ast.Bad_Stmt, start_tok.pos, end_pos(p.curr_tok), allocator)
        }
        stmt := ast.new_from_pos_and_end_node(ast.Assign_Stmt, lhs[0].pos, rhs[len(rhs)-1], allocator)
        stmt.lhs = lhs
        stmt.op = op
        stmt.rhs = rhs
        return stmt

    case op.kind == .In:
        if .In in flags {
            _ = allow_token(p, .In, allocator)
            prev_allow_range := p.allow_range
            p.allow_range = true
            expr := parse_expr(p, false, allocator)
            p.allow_range = prev_allow_range

            rhs, _ := slice.create([]^ast.Expr, 1, allocator)
            rhs[0] = expr

            stmt := ast.new_from_pos_and_end_node(ast.Assign_Stmt, lhs[0].pos, rhs[len(rhs)-1], allocator)
            stmt.lhs = lhs
            stmt.op = op
            stmt.rhs = rhs
            return stmt
        }
    case op.kind == .Colon:
        _ = expect_token_after(p, .Colon, "identifier list", allocator)
        if .Label in flags && len(lhs) == 1 {
            is_partial := false
            is_reverse := false

            partial_token: tokenizer.Token
            if p.curr_tok.kind == .Hash {
                name := peek_token(p, 0, allocator)
                if name.kind == .Ident && name.text == "partial" &&
                   peek_token(p, 1, allocator).kind == .Switch {
                    partial_token = expect_token(p, .Hash, allocator)
                    _ = expect_token(p, .Ident, allocator)
                    is_partial = true
                } else if name.kind == .Ident && name.text == "reverse" &&
                          peek_token(p, 1, allocator).kind == .For {
                    partial_token = expect_token(p, .Hash, allocator)
                    _ = expect_token(p, .Ident, allocator)
                    is_reverse = true
                }
            }

            #partial switch p.curr_tok.kind {
            case .Open_Brace, .If, .For, .Switch:
                label := lhs[0]
                stmt := parse_stmt(p, allocator)

                if stmt != nil {
                    #partial switch n in stmt.derived_stmt {
                    case ^ast.Block_Stmt:       n.label = label
                    case ^ast.If_Stmt:          n.label = label
                    case ^ast.For_Stmt:         n.label = label
                    case ^ast.Switch_Stmt:      n.label = label
                    case ^ast.Type_Switch_Stmt: n.label = label
                    case ^ast.Range_Stmt:       n.label = label
                    }

                    if is_partial {
                        #partial switch n in stmt.derived_stmt {
                        case ^ast.Switch_Stmt:      n.partial = true
                        case ^ast.Type_Switch_Stmt: n.partial = true
                        case:
                            error(p, partial_token.pos, "incorrect use of directive, use '%s: #partial switch'", partial_token.text)
                        }
                    }
                    if is_reverse {
                        #partial switch n in stmt.derived_stmt {
                        case ^ast.Range_Stmt: n.reverse = true
                        case:
                            error(p, partial_token.pos, "incorrect use of directive, use '%s: #reverse for'", partial_token.text)
                        }
                    }
                }

                return stmt
            }
        }
        return parse_value_decl(p, lhs, docs, allocator)
    }

    if len(lhs) > 1 {
        error(p, op.pos, "expected 1 expression, got %d", len(lhs))
        return ast.new_from_positions(ast.Bad_Stmt, start_tok.pos, end_pos(p.curr_tok), allocator)
    }

    #partial switch op.kind {
    case .Increment, .Decrement:
        _ = advance_token(p, allocator)
        error(p, op.pos, "postfix '%s' statement is not supported", op.text)
    }

    es := ast.new_from_pos_and_end_node(ast.Expr_Stmt, lhs[0].pos, lhs[0], allocator)
    es.expr = lhs[0]
    return es
}

parse_value_decl :: proc(p: ^Parser, names: []^ast.Expr, docs: ^ast.Comment_Group, allocator: mem.Allocator) -> ^ast.Decl {
    is_mutable := true

    values: []^ast.Expr
    type := parse_type_or_ident(p, allocator)

    #partial switch p.curr_tok.kind {
    case .Eq, .Colon:
        sep := advance_token(p, allocator)
        is_mutable = sep.kind != .Colon

        values = parse_rhs_expr_list(p, allocator)
        if len(values) > len(names) {
            error(p, p.curr_tok.pos, "too many values on the right-hand side of the declaration")
        } else if len(values) < len(names) && !is_mutable {
            error(p, p.curr_tok.pos, "all constant declarations must be defined")
        } else if len(values) == 0 {
            error(p, p.curr_tok.pos, "expected an expression for this declaration")
        }
    }

    if is_mutable {
        if type == nil && len(values) == 0 {
            error(p, p.curr_tok.pos, "missing variable type or initialization")
            return ast.new_from_positions(ast.Bad_Decl, names[0].pos, end_pos(p.curr_tok), allocator)
        }
    } else {
        if type == nil && len(values) == 0 && len(names) > 0 {
            error(p, p.curr_tok.pos, "missing constant value")
            return ast.new_from_positions(ast.Bad_Decl, names[0].pos, end_pos(p.curr_tok), allocator)
        }
    }

    end := p.prev_tok

    if p.expr_level >= 0 {
        end: ^ast.Expr
        if !is_mutable && len(values) > 0 {
            end = values[len(values)-1]
        }
        if p.curr_tok.kind == .Close_Brace &&
           p.curr_tok.pos.line == p.prev_tok.pos.line {

        } else {
            _ = expect_semicolon(p, end, allocator)
        }
    }

    if p.curr_proc == nil {
        if len(values) > 0 && len(names) != len(values) {
            error(p, values[0].pos, "expected %d expressions on the right-hand side, got %d", len(names), len(values))
        }
    }

    decl := ast.new_from_positions(ast.Value_Decl, names[0].pos, end_pos(end), allocator)
    decl.docs = docs
    decl.names = names
    decl.type = type
    decl.values = values
    decl.is_mutable = is_mutable
    return decl
}

// the default was .Standard
parse_import_decl :: proc(p: ^Parser, kind: Import_Decl_Kind, allocator: mem.Allocator) -> ^ast.Import_Decl {
    docs := p.lead_comment
    tok := expect_token(p, .Import, allocator)

    import_name: tokenizer.Token
    is_using := kind != Import_Decl_Kind.Standard

    #partial switch p.curr_tok.kind {
    case .Ident:
        import_name = advance_token(p, allocator)
    case:
        import_name.pos = p.curr_tok.pos
    }

    path := expect_token_after(p, .String, "import", allocator)

    decl := ast.new_from_positions(ast.Import_Decl, tok.pos, end_pos(path), allocator)
    decl.docs       = docs
    decl.is_using   = is_using
    decl.import_tok = tok
    decl.name       = import_name
    decl.relpath    = path
    decl.fullpath   = path.text

    if p.curr_proc != nil {
        error(p, decl.pos, "import declarations cannot be used within a procedure, it must be done at the file scope")
    } else {
        _ = dyn_array.append(&p.file.imports, decl)
    }
    _ = expect_semicolon(p, decl, allocator)
    decl.comment = p.line_comment

    return decl
}
