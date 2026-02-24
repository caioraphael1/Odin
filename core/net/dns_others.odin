#+build !windows
#+build !linux
#+build !darwin
#+build !freebsd
#+build !netbsd
#+build !openbsd


@(private)
_get_dns_records_os :: proc(hostname: string, type: DNS_Record_Type, allocator: mem.Allocator) -> (records: []DNS_Record, err: DNS_Error) {
	return
}
