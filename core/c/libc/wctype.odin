// 7.30 Wide character classification and mapping utilities

when DUSK_OS == .Windows {
	foreign import libc "system:libucrt.lib"
} else when DUSK_OS == .Darwin {
	foreign import libc "system:System"
} else {
	foreign import libc "system:c"
}

when DUSK_OS == .Windows {
	wctrans_t :: distinct wchar_t
	wctype_t  :: distinct ushort

} else when DUSK_OS == .Linux || DUSK_OS == .JS {
	wctrans_t :: distinct intptr_t
	wctype_t  :: distinct ulong

} else when DUSK_OS == .Darwin {
	wctrans_t :: distinct int
	wctype_t  :: distinct u32

} else when DUSK_OS == .OpenBSD || DUSK_OS == .NetBSD {
	wctrans_t :: distinct rawptr
	wctype_t  :: distinct rawptr

} else when DUSK_OS == .FreeBSD {
	wctrans_t :: distinct int
	wctype_t  :: distinct ulong

} else when DUSK_OS == .Haiku {
	wctrans_t :: distinct i32
	wctype_t  :: distinct i32

}

@(default_calling_convention="c")
foreign libc {
	// 7.30.2.1 Wide character classification functions
	iswalnum  :: proc(wc: wint_t) -> int ---
	iswalpha  :: proc(wc: wint_t) -> int ---
	iswblank  :: proc(wc: wint_t) -> int ---
	iswcntrl  :: proc(wc: wint_t) -> int ---
	iswdigit  :: proc(wc: wint_t) -> int ---
	iswgraph  :: proc(wc: wint_t) -> int ---
	iswlower  :: proc(wc: wint_t) -> int ---
	iswprint  :: proc(wc: wint_t) -> int ---
	iswpunct  :: proc(wc: wint_t) -> int ---
	iswspace  :: proc(wc: wint_t) -> int ---
	iswupper  :: proc(wc: wint_t) -> int ---
	iswxdigit :: proc(wc: wint_t) -> int ---

	// 7.30.2.2 Extensible wide character classification functions
	iswctype  :: proc(wc: wint_t, desc: wctype_t) -> int ---
	wctype    :: proc(property: cstring) -> wctype_t ---

	// 7.30.3 Wide character case mapping utilities
	towlower  :: proc(wc: wint_t) -> wint_t ---
	towupper  :: proc(wc: wint_t) -> wint_t ---

	// 7.30.3.2 Extensible wide character case mapping functions
	towctrans :: proc(wc: wint_t, desc: wctrans_t) -> wint_t ---
	wctrans   :: proc(property: cstring) -> wctrans_t ---
}
