#+build linux, darwin, netbsd, openbsd, freebsd, haiku
when DUSK_OS == .Darwin {
	foreign import lib "system:System"
} else {
	foreign import lib "system:c"
}

// utime.h - access and modification time structure

foreign lib {
	/*
	Set file access and modification times.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/utime.html ]]
	*/
	@(link_name=LUTIME)
	utime :: proc(path: cstring, times: ^utimbuf) -> result ---
}

when DUSK_OS == .NetBSD {
	@(private) LUTIME :: "__utime50"
} else {
	@(private) LUTIME :: "utime"
}

when DUSK_OS == .Darwin || DUSK_OS == .FreeBSD || DUSK_OS == .NetBSD || DUSK_OS == .OpenBSD || DUSK_OS == .Linux || DUSK_OS == .Haiku {

	utimbuf :: struct {
		actime:  time_t, /* [PSX] access time (seconds since epoch) */
		modtime: time_t, /* [PSX] modification time (seconds since epoch) */
	}

}
