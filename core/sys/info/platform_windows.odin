
import "base:container/slice"
import "base:container/strings"
import sb "base:container/string_buffer"
import "base:unicode/utf16"

import sys "core:sys/windows"

@(private)
_os_version :: proc(res: ^OS_Version, loc := #caller_location) -> (ok: bool) {
    format_windows_product_type :: proc (buf: ^sb.String_Buffer, prod_type: sys.Windows_Product_Type) -> (ok: bool) {
        #partial switch prod_type {
        case .ULTIMATE:
            sb.write(buf, "Ultimate") or_return

        case .HOME_BASIC:
            sb.write(buf, "Home Basic") or_return

        case .HOME_PREMIUM:
            sb.write(buf, "Home Premium") or_return

        case .ENTERPRISE:
            sb.write(buf, "Enterprise") or_return

        case .CORE:
            sb.write(buf, "Home Basic") or_return

        case .HOME_BASIC_N:
            sb.write(buf, "Home Basic N") or_return

        case .EDUCATION:
            sb.write(buf, "Education") or_return

        case .EDUCATION_N:
            sb.write(buf, "Education N") or_return

        case .BUSINESS:
            sb.write(buf, "Business") or_return

        case .STANDARD_SERVER:
            sb.write(buf, "Standard Server") or_return

        case .DATACENTER_SERVER:
            sb.write(buf, "Datacenter") or_return

        case .SMALLBUSINESS_SERVER:
            sb.write(buf, "Windows Small Business Server") or_return

        case .ENTERPRISE_SERVER:
            sb.write(buf, "Enterprise Server") or_return

        case .STARTER:
            sb.write(buf, "Starter") or_return

        case .DATACENTER_SERVER_CORE:
            sb.write(buf, "Datacenter Server Core") or_return

        case .STANDARD_SERVER_CORE:
            sb.write(buf, "Server Standard Core") or_return

        case .ENTERPRISE_SERVER_CORE:
            sb.write(buf, "Enterprise Server Core") or_return

        case .BUSINESS_N:
            sb.write(buf, "Business N") or_return

        case .HOME_SERVER:
            sb.write(buf, "Home Server") or_return

        case .SERVER_FOR_SMALLBUSINESS:
            sb.write(buf, "Windows Server 2008 for Windows Essential Server Solutions") or_return

        case .SMALLBUSINESS_SERVER_PREMIUM:
            sb.write(buf, "Small Business Server Premium") or_return

        case .HOME_PREMIUM_N:
            sb.write(buf, "Home Premium N") or_return

        case .ENTERPRISE_N:
            sb.write(buf, "Enterprise N") or_return

        case .ULTIMATE_N:
            sb.write(buf, "Ultimate N") or_return

        case .HYPERV:
            sb.write(buf, "HyperV") or_return

        case .STARTER_N:
            sb.write(buf, "Starter N") or_return

        case .PROFESSIONAL:
            sb.write(buf, "Professional") or_return

        case .PROFESSIONAL_N:
            sb.write(buf, "Professional N") or_return

        case:
            sb.write(buf, "Unknown Edition") or_return
        }
        return true
    }

    // Grab Windows DisplayVersion (like 20H02)
    format_display_version :: proc (buf: ^sb.String_Buffer) -> (version: string, ok: bool) {
        scratch: [512]u8

        if dv, read_ok := read_reg_string(
            sys.HKEY_LOCAL_MACHINE,
            "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion",
            "DisplayVersion",
            scratch[:],
        ); read_ok {
            sb.write(buf, " (version: ") or_return
            l := buf.len
            sb.write(buf, dv) or_return
            version = string(sb.slice(buf^)[l:][:len(dv)])
            sb.write_byte(buf, ')') or_return
        }
        return version, true
    }

    // Grab build number and UBR
    format_build_number :: proc (buf: ^sb.String_Buffer, major_build: int) -> (ubr: int, ok: bool) {
        if res, read_ok := read_reg_i32(
            sys.HKEY_LOCAL_MACHINE,
            "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion",
            "UBR",
        ); read_ok {
            ubr = int(res)
            sb.write(buf, ", build: ") or_return
            sb.write(buf, sb.from_int(major_build)) or_return
            sb.write_byte(buf, '.') or_return
            sb.write(buf, sb.from_int(ubr)) or_return
        }
        return ubr, true
    }

    /*
    NOTE(Jeroen):
        `GetVersionEx`  will return 6.2 for Windows 10 unless the program is manifested for Windows 10.
        `RtlGetVersion` will return the true version.

        Rather than include the WinDDK, we ask the kernel directly.
        `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion` is for the minor build version (Update Build Release)
    */
    res.platform = .Windows

    osvi: sys.OSVERSIONINFOEXW
    osvi.dwOSVersionInfoSize = sys.ULONG(size_of(osvi))
    if status := sys.RtlGetVersion(&osvi); status != 0 {
        return false
    }

    product_type: sys.Windows_Product_Type
    _ = sys.GetProductInfo(
        osvi.dwMajorVersion,         osvi.dwMinorVersion,
        u32(osvi.wServicePackMajor), u32(osvi.wServicePackMinor),
        &product_type,
    )

    res.os.major     = int(osvi.dwMajorVersion)
    res.os.minor     = int(osvi.dwMinorVersion)
    res.kernel.major = int(osvi.dwMajorVersion)
    res.kernel.minor = int(osvi.dwBuildNumber)

    buf := sb.create(raw_data(res.full.data[:]), len(res.full.data), 0)
    defer res.full.len = buf.len

    sb.write(&buf, "Windows ") or_return

    switch osvi.dwMajorVersion {
    case 10:
        switch osvi.wProductType {
        case 1: // VER_NT_WORKSTATION:
            if osvi.dwBuildNumber < 22000 {
                sb.write(&buf, "10 ") or_return
            } else {
                sb.write(&buf, "11 ") or_return
            }
            format_windows_product_type(&buf, product_type) or_return

        case: // Server or Domain Controller
            switch osvi.dwBuildNumber {
            case 14393:
                sb.write(&buf, "2016 Server") or_return
            case 17763:
                sb.write(&buf, "2019 Server") or_return
            case 20348:
                sb.write(&buf, "2022 Server") or_return
            case:
                sb.write(&buf, "Unknown Server") or_return
            }
        }

    case 6:
        switch osvi.dwMinorVersion {
        case 0:
            switch osvi.wProductType {
            case 1: // VER_NT_WORKSTATION
                sb.write(&buf, "Windows Vista ") or_return
                format_windows_product_type(&buf, product_type) or_return
            case 3:
                sb.write(&buf, "Windows Server 2008") or_return
            }

        case 1:
            switch osvi.wProductType {
            case 1: // VER_NT_WORKSTATION:
                sb.write(&buf, "Windows 7 ") or_return
                format_windows_product_type(&buf, product_type) or_return
            case 3:
                sb.write(&buf, "Windows Server 2008 R2") or_return
            }

        case 2:
            switch osvi.wProductType {
            case 1: // VER_NT_WORKSTATION:
                sb.write(&buf, "Windows 8 ") or_return
                format_windows_product_type(&buf, product_type) or_return
            case 3:
                sb.write(&buf, "Windows Server 2012") or_return
            }

        case 3:
            switch osvi.wProductType {
            case 1: // VER_NT_WORKSTATION:
                sb.write(&buf, "Windows 8.1 ") or_return
                format_windows_product_type(&buf, product_type) or_return
            case 3:
                sb.write(&buf, "Windows Server 2012 R2") or_return
            }
        }

    case 5:
        switch osvi.dwMinorVersion {
        case 0:
            sb.write(&buf, "Windows 2000") or_return
        case 1:
            sb.write(&buf, "Windows XP") or_return
        case 2:
            sb.write(&buf, "Windows Server 2003") or_return
        }
    }

    // Grab DisplayVersion
    res.release = format_display_version(&buf) or_return

    // Grab build number and UBR
    res.kernel.patch = format_build_number(&buf, int(osvi.dwBuildNumber)) or_return

    return true
}

@(private)
_ram_stats :: proc() -> (total_ram, free_ram, total_swap, free_swap: i64, ok: bool) {
    state: sys.MEMORYSTATUSEX

    state.dwLength = sys.DWORD(size_of(state))
    if ok := sys.GlobalMemoryStatusEx(&state); !ok {
        return
    }

    total_ram  = i64(state.ullTotalPhys)
    free_ram   = i64(state.ullAvailPhys)
    total_swap = i64(state.ullTotalPageFil)
    free_swap  = i64(state.ullAvailPageFil)
    ok         = true

    return
}

_iterate_gpus :: proc(it: ^GPU_Iterator, minimum_vram := i64(256 * 1024 * 1024)) -> (gpu: GPU, index: int, ok: bool) {
    GPU_ROOT_KEY :: `SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}`

    defer it.index += 1

    gpu_key: sys.HKEY
    if status := sys.RegOpenKeyExW(
        sys.HKEY_LOCAL_MACHINE,
        GPU_ROOT_KEY,
        0,
        sys.KEY_ENUMERATE_SUB_KEYS,
        &gpu_key,
    ); status != i32(sys.ERROR_SUCCESS) {
        return {}, it.index, false
    }
    defer _ = sys.RegCloseKey(gpu_key)

    buf_wstring: [100]u16
    buf_len := u32(len(buf_wstring))
    buf_key:     [4 * len(buf_wstring)]u8
    buf_leaf:    [100]u8
    leaf:        string

    gpu_loop: {
        defer it._index += 1

        if status := sys.RegEnumKeyW(
            gpu_key,
            auto_cast it._index,
            &buf_wstring[0],
            &buf_len,
        ); status != i32(sys.ERROR_SUCCESS) {
            return {}, it.index, false
        }

        utf16.decode_to_utf8(buf_leaf[:], buf_wstring[:])
        leaf = string(cstring(&buf_leaf[0]))

        // Skip leaves that are not of the form 000x
        if is_integer(leaf) {
            break gpu_loop
        }
    }

    n := slice.copy_from_string(buf_key[:], GPU_ROOT_KEY)
    buf_key[n] = '\\'
    slice.copy_from_string(buf_key[n+1:], leaf)

    key_len := len(GPU_ROOT_KEY) + len(leaf) + 1

    utf16.encode_string(buf_wstring[:], string(buf_key[:key_len]))
    key := cstring16(&buf_wstring[0])

    // Determine if this is a real GPU, or perhaps a screen mirroring or RDP driver
    // Real devices tend to have more than 256 MiB of VRAM
    gpu.vram, _ = read_reg_i64   (sys.HKEY_LOCAL_MACHINE, key, "HardwareInformation.qwMemorySize")
    if gpu.vram < minimum_vram {
        return
    }

    // Real devices tend to have a matching PCI device
    matching,   _ := read_reg_string(sys.HKEY_LOCAL_MACHINE, key, "MatchingDeviceId", it._buffer[:100])
    if !strings.string_has_prefix(matching, "PCI\\VEN") {
        return
    }

    gpu.vendor, _ = read_reg_string(sys.HKEY_LOCAL_MACHINE, key, "ProviderName",  it._buffer[  0:][:100])
    gpu.model,  _ = read_reg_string(sys.HKEY_LOCAL_MACHINE, key, "DriverDesc",    it._buffer[100:][:100])
    gpu.driver, _ = read_reg_string(sys.HKEY_LOCAL_MACHINE, key, "DriverVersion", it._buffer[200:][:100])

    return gpu, it.index, true
}

@(private)
read_reg_string :: proc(hkey: sys.HKEY, subkey, val: cstring16, res_buf: []u8) -> (res: string, ok: bool) {
    if len(subkey) == 0 || len(val) == 0 {
        return
    }

    buf_utf16: [1024]u16

    result_size := sys.DWORD(size_of(buf_utf16))
    status := sys.RegGetValueW(
        hkey,
        subkey,
        val,
        sys.RRF_RT_REG_SZ,
        nil,
        raw_data(buf_utf16[:]),
        &result_size,
    )
    if status != 0 {
        // Couldn't retrieve string
        return
    }

    utf16.decode_to_utf8(res_buf[:result_size], buf_utf16[:])
    res = string(cstring(&res_buf[0]))
    return res, true
}

@(private)
read_reg_i32 :: proc(hkey: sys.HKEY, subkey, val: cstring16) -> (res: i32, ok: bool) {
    if len(subkey) == 0 || len(val) == 0 {
        return
    }

    result_size := sys.DWORD(size_of(i32))
    status := sys.RegGetValueW(
        hkey,
        subkey,
        val,
        sys.RRF_RT_REG_DWORD,
        nil,
        &res,
        &result_size,
    )
    return res, status == 0
}

@(private)
read_reg_i64 :: proc(hkey: sys.HKEY, subkey, val: cstring16) -> (res: i64, ok: bool) {
    if len(subkey) == 0 || len(val) == 0 {
        return
    }

    result_size := sys.DWORD(size_of(i64))
    status := sys.RegGetValueW(
        hkey,
        subkey,
        val,
        sys.RRF_RT_REG_QWORD,
        nil,
        &res,
        &result_size,
    )
    return res, status == 0
}

@(private)
is_integer :: proc(s: string) -> (ok: bool) {
    if s == "" {
        return
    }

    ok = true

    for r in s {
        switch r {
        case '0'..='9': continue
        case: return false
        }
    }
    return
}
