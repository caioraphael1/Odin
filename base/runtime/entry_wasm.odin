#+private
#+build wasm32, wasm64p32
#+no-instrumentation
package runtime

import "base:intrinsics"

when !ODIN_TEST && !ODIN_NO_ENTRY_POINT {
    when ODIN_OS == .Orca {
        @(linkage="strong", require, export)
        oc_on_init :: proc "c" () {
            context = {}
            intrinsics.__entry_point()
        }
        @(linkage="strong", require, export)
        oc_on_terminate :: proc "c" () {
        }
    } else {
        @(link_name="_start", linkage="strong", require, export)
        _start :: proc "c" () {
            context = {}

            when ODIN_OS == .WASI {
                _wasi_setup_args()
            }
            intrinsics.__entry_point()
        }
        @(link_name="_end", linkage="strong", require, export)
        _end :: proc "c" () {
        }
    }
}
