#+build js
package runtime

init_default_context_for_js: Context
// @@init
@(private="file")
init_default_context :: proc() {
    init_default_context_for_js = {}
}

@(export)
@(link_name="default_context_ptr")
default_context_ptr :: proc() -> ^Context {
	return &init_default_context_for_js
}

