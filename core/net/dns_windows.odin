#+build windows


/*
    Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
    For other protocols and their features, see subdirectories of this package.
*/

/*
    Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
    Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
    Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
    Copyright 2024 Feoramund       <rune@swevencraft.org>.
    Made available under Odin's license.

    List of contributors:
        Tetralux:        Initial implementation
        Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
        Jeroen van Rijn: Cross platform unification, code style, documentation
        Feoramund:       FreeBSD platform code
*/

import "base:internal"
import "base:mem"
import "base:mem/allocators"
import "base:container/slice"
import "base:container/dyn_array"
import "base:container/strings"

import "core:os"
import "core:strings_tools"
import "core:sync"

import win "core:sys/windows"

/*
    Replaces environment placeholders in `dns_configuration`. Only necessary on Windows.
    Is automatically called, once, by `get_dns_records_*`.
*/
@(private)
_init_dns_configuration :: proc() {
    sync.once_do_without_data(&dns_config_initialized, proc() {
        allocators.TEMP_ALLOCATOR_TEMP_GUARD()
        val := os.replace_environment_placeholders(dns_configuration.hosts_file, allocators.temp_allocator)
        slice.copy_from_string(dns_configuration.hosts_file_buf[:], val)
        dns_configuration.hosts_file = string(dns_configuration.hosts_file_buf[:len(val)])
    })
}

@(private)
_get_dns_records_os :: proc(hostname: string, type: DNS_Record_Type, allocator: mem.Allocator) -> (records: []DNS_Record, err: DNS_Error) {
    options := win.DNS_QUERY_OPTIONS{}
    if strings.string_has_suffix(hostname, ".local") {
        options = {.MULTICAST_ONLY, .MULTICAST_WAIT} // 0x00020500
    }

    host_cstr, _ := strings.cstring_clone_from_string(hostname, allocators.temp_allocator)
    rec: ^win.DNS_RECORD
    res := win.DnsQuery_UTF8(host_cstr, u16(type), options, nil, &rec, nil)

    switch u32(res) {
    case 0:
        // okay
    case win.ERROR_INVALID_NAME:
        return nil, .Invalid_Hostname_Error
    case win.DNS_INFO_NO_RECORDS:
        return
    case:
        return nil, .System_Error
    }
    defer win.DnsRecordListFree(rec, 1) // 1 means that we're freeing a list... because the proc name isn't enough.

    count := 0
    for r := rec; r != nil; r = r.pNext {
        if r.wType != u16(type) {
            // NOTE(tetra): Should never happen, but...
            continue
        }
        count += 1
    }

    recs, _ := dyn_array.create_len_cap([dynamic]DNS_Record, 0, count, allocator)
    if recs == nil {
        return nil, .System_Error // return no results if OOM.
    }

    for r := rec; r != nil; r = r.pNext {
        if r.wType != u16(type) {
            continue // NOTE(tetra): Should never happen, but...
        }

        name_clone, _ := strings.string_clone(string(r.pName), allocator)

        base_record := DNS_Record_Base{
            record_name = name_clone,
            ttl_seconds = r.dwTtl,
        }

        switch DNS_Record_Type(r.wType) {
        case .IP4:
            addr := IP4_Address(transmute([4]u8)r.Data.A)
            record := DNS_Record_IP4{
                base    = base_record,
                address = addr,
            }
            _ = dyn_array.append(&recs, record)

        case .IP6:
            addr := IP6_Address(transmute([8]u16be) r.Data.AAAA)
            record := DNS_Record_IP6{
                base    = base_record,
                address = addr,
            }
            _ = dyn_array.append(&recs, record)

        case .CNAME:
            data_clone, _ := strings.string_clone(string(r.Data.CNAME), allocator)
            record := DNS_Record_CNAME{
                base      = base_record,
                host_name = data_clone,
            }
            _ = dyn_array.append(&recs, record)

        case .TXT:
            n := r.Data.TXT.dwStringCount
            ptr := &r.Data.TXT.pStringArray
            c_strs := slice.from_ptr(ptr, int(n))

            for cstr in c_strs {
                cstr_clone, _ := strings.string_clone(string(cstr), allocator)
                record := DNS_Record_TXT{
                    base  = base_record,
                    value = cstr_clone,
                }
                _ = dyn_array.append(&recs, record)
            }

        case .NS:
            ns_clone, _ := strings.string_clone(string(r.Data.NS), allocator)
            record := DNS_Record_NS{
                base      = base_record,
                host_name = ns_clone,
            }
            _ = dyn_array.append(&recs, record)

        case .MX:
            /*
                TODO(tetra): Order by preference priority? (Prefer hosts with lower preference values.)
                Or maybe not because you're supposed to just use the first one that works
                and which order they're in changes every few calls.
            */

            name_exchange_clone, _ := strings.string_clone(string(r.Data.MX.pNameExchange), allocator)

            record := DNS_Record_MX{
                base       = base_record,
                host_name  = name_exchange_clone,
                preference = int(r.Data.MX.wPreference),
            }
            _ = dyn_array.append(&recs, record)

        case .SRV:
            // NOTE(tetra): Srv record name should be of the form '_servicename._protocol.hostname'
            // The record name is the name of the record.
            // Not to be confused with the _target_ of the record, which is--in combination with the port--what we're looking up
            // by making this request in the first place.

            service_name, protocol_name: string

            s := base_record.record_name
            i := strings_tools.index_byte(s, '.')
            if i > -1 {
                service_name = s[:i]
                s = s[len(service_name) + 1:]
            } else {
                continue
            }

            i  = strings_tools.index_byte(s, '.')
            if i > -1 {
                protocol_name = s[:i]
            } else {
                continue
            }

            name_target_clone, _ := strings.string_clone(string(r.Data.SRV.pNameTarget), allocator)

            _ = dyn_array.append(&recs, DNS_Record_SRV {
                base          = base_record,
                target        = name_target_clone, // The target hostname/address that the service can be found on
                port          = int(r.Data.SRV.wPort),
                service_name  = service_name,
                protocol_name = protocol_name,
                priority      = int(r.Data.SRV.wPriority),
                weight        = int(r.Data.SRV.wWeight),

            })
        }
    }

    records = recs[:]
    return
}
