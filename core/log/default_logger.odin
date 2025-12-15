package log

import "base:runtime"
import "core:fmt"
import "core:terminal"
import os "core:os/os2"


default_logger: Logger

@(private) global_subtract_stdout_options: Options
@(private) global_subtract_stderr_options: Options


// @(init)
subtract_terminal_options :: proc() {
	// NOTE(Feoramund): While it is technically possible for these streams to
	// be redirected during the runtime of the program, the cost of checking on
	// every single log message is not worth it to support such an
	// uncommonly-used feature.
	if terminal.color_enabled {
		// This is done this way because it's possible that only one of these
		// streams could be redirected to a file.
		if !terminal.is_terminal(os.stdout) {
			global_subtract_stdout_options = { .Terminal_Color }
		}
		if !terminal.is_terminal(os.stderr) {
			global_subtract_stderr_options = { .Terminal_Color }
		}
	} else {
		// Override any terminal coloring.
		global_subtract_stdout_options = { .Terminal_Color }
		global_subtract_stderr_options = { .Terminal_Color }
	}
}


debugf :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(default_logger, .Debug,   fmt_str, ..args, location=location)
}
infof  :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(default_logger, .Info,    fmt_str, ..args, location=location)
}
warnf  :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(default_logger, .Warning, fmt_str, ..args, location=location)
}
errorf :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(default_logger, .Error,   fmt_str, ..args, location=location)
}
fatalf :: proc(fmt_str: string, args: ..any, location := #caller_location) {
	logf(default_logger, .Fatal,   fmt_str, ..args, location=location)
}

debug :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(default_logger, .Debug,   ..args, sep=sep, location=location)
}
info  :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(default_logger, .Info,    ..args, sep=sep, location=location)
}
warn  :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(default_logger, .Warning, ..args, sep=sep, location=location)
}
error :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(default_logger, .Error,   ..args, sep=sep, location=location)
}
fatal :: proc(args: ..any, sep := " ", location := #caller_location) {
	log(default_logger, .Fatal,   ..args, sep=sep, location=location)
}

panic :: proc(args: ..any, location := #caller_location) -> ! {
	log(default_logger, .Fatal, ..args, location=location)
	runtime.panic("log.panic", location)
}
panicf :: proc(fmt_str: string, args: ..any, location := #caller_location) -> ! {
	logf(default_logger, .Fatal, fmt_str, ..args, location=location)
	runtime.panic("log.panicf", location)
}

@(disabled=ODIN_DISABLE_ASSERT)
assert :: proc(condition: bool, message := #caller_expression(condition), loc := #caller_location) {
	if !condition {
		@(cold)
		internal :: proc(message: string, loc: runtime.Source_Code_Location) {
			log(default_logger, .Fatal, message, location=loc)
			runtime.assertion_failure_proc("runtime assertion", message, loc)
		}
		internal(message, loc)
	}
}

@(disabled=ODIN_DISABLE_ASSERT)
assertf :: proc(condition: bool, fmt_str: string, args: ..any, loc := #caller_location) {
	if !condition {
		// NOTE(dragos): We are using the same trick as in builtin.assert
		// to improve performance to make the CPU not
		// execute speculatively, making it about an order of
		// magnitude faster
		@(cold)
		internal :: proc(loc: runtime.Source_Code_Location, fmt_str: string, args: ..any) {
			message := fmt.tprintf(fmt_str, ..args)
			log(default_logger, .Fatal, message, location=loc)
			runtime.assertion_failure_proc("runtime assertion", message, loc)
		}
		internal(loc, fmt_str, ..args)
	}
}

ensure :: proc(condition: bool, message := #caller_expression(condition), loc := #caller_location) {
	if !condition {
		@(cold)
		internal :: proc(message: string, loc: runtime.Source_Code_Location) {
			log(default_logger, .Fatal, message, location=loc)
			runtime.assertion_failure_proc("unsatisfied ensure", message, loc)
		}
		internal(message, loc)
	}
}

ensuref :: proc(condition: bool, fmt_str: string, args: ..any, loc := #caller_location) {
	if !condition {
		@(cold)
		internal :: proc(loc: runtime.Source_Code_Location, fmt_str: string, args: ..any) {
			message := fmt.tprintf(fmt_str, ..args)
			log(default_logger, .Fatal, message, location=loc)
			runtime.assertion_failure_proc("unsatisfied ensure", message, loc)
		}
		internal(loc, fmt_str, ..args)
	}
}
