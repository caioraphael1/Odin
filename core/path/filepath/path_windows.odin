
import "core:os"

SEPARATOR :: '\\'
SEPARATOR_STRING :: `\`
LIST_SEPARATOR :: ';'

is_UNC :: proc(path: string) -> bool {
    return len(os.volume_name(path)) > 2
}
