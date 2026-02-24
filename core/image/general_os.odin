#+build !js

import "core:os"


load_from_file :: proc(filename: string, options := Options{}, allocator: mem.Allocator) -> (img: ^Image, err: Error) {
	data, data_err := os.read_entire_file_from_path(filename, allocator)
	defer _ = delete(data, allocator)
	if data_err == nil {
		return load_from_bytes(data, options, allocator)
	} else {
		return nil, .Unable_To_Read_File
	}
}

which_file :: proc(path: string) -> Which_File_Type {
	f, err := os.open(path)
	if err != nil {
		return .Unknown
	}
	header: [128]byte
	os.read(f, header[:])
	file_type := which_bytes(header[:])
	os.close(f)
	return file_type
}
