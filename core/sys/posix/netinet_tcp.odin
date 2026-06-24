#+build linux, darwin, netbsd, openbsd, freebsd
// netinet/tcp.h - definitions for the Internet Transmission Control Protocol (TCP)

when DUSK_OS == .Darwin || DUSK_OS == .FreeBSD || DUSK_OS == .NetBSD || DUSK_OS == .OpenBSD || DUSK_OS == .Linux {

	TCP_NODELAY :: 0x01

}
