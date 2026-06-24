#+no-instrumentation

Raw_Any :: struct {
    data: rawptr,
    id:   typeid,
}
when !DUSK_NO_RTTI {
    #assert(size_of(Raw_Any) == size_of(any))
}
