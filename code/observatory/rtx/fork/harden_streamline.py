"""Local hardening of NVIDIA-RTX/godot backport/nvidia-pt-dlss-4.6.3 (e1157bf) before any build:
Streamline neither downloads plugins nor loads downloaded ones, and sl.interposer.dll is loaded only
from the executable's own folder, once NVIDIA's embedded signature on it verifies (sl_security.h).
    python harden_streamline.py <godot source dir>"""
import sys

G = sys.argv[1].rstrip('/')


def patch(rel, pairs):
    p = f'{G}/{rel}'
    s = open(p, encoding='utf-8').read()
    for old, new in pairs:
        if new in s:
            continue  # already applied
        assert s.count(old) == 1, (rel, old)
        s = s.replace(old, new)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print('patched', rel)


LOADER = '''#ifdef _WIN32
// Local hardening, not in NVIDIA's fork: sl.interposer.dll only from the executable's own folder,
// and only once NVIDIA's embedded signature on it verifies, as Streamline's programming guide
// advises; a DLL of that name elsewhere on the search path is never loaded. The Vulkan driver
// (rendering_context_driver_vulkan.cpp) loads the interposer through this too.
void *streamline_load_interposer() {
	static HMODULE module = nullptr;
	static bool tried = false;
	if (tried) {
		return module;
	}
	tried = true;
	wchar_t path[MAX_PATH];
	const DWORD n = GetModuleFileNameW(nullptr, path, MAX_PATH);
	if (n == 0 || n >= MAX_PATH) {
		return nullptr;
	}
	wchar_t *slash = wcsrchr(path, L'\\\\');
	const wchar_t *name = L"sl.interposer.dll";
	if (slash == nullptr || size_t(slash + 1 - path) + wcslen(name) >= MAX_PATH) {
		return nullptr;
	}
	wcscpy_s(slash + 1, MAX_PATH - size_t(slash + 1 - path), name);
	if (GetFileAttributesW(path) == INVALID_FILE_ATTRIBUTES) {
		return nullptr;
	}
	if (!sl::security::verifyEmbeddedSignature(path)) {
		ERR_PRINT("Streamline: sl.interposer.dll beside the executable is not signed by NVIDIA; it is not loaded.");
		return nullptr;
	}
	module = LoadLibraryExW(path, nullptr, LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR | LOAD_LIBRARY_SEARCH_SYSTEM32);
	return module;
}
#endif

StreamlineContext &StreamlineContext::get() {'''

patch('drivers/streamline/streamline_context.cpp', [
    ('#ifdef _WIN32\n#include <windows.h>\n#endif\n',
     '#ifdef _WIN32\n#include <windows.h>\n// Local hardening: NVIDIA\'s signature check (streamline_load_interposer below).\n'
     '#include <sl_security.h>\n#pragma comment(lib, "wintrust.lib")\n#pragma comment(lib, "crypt32.lib")\n#endif\n'),
    ('StreamlineContext &StreamlineContext::get() {', LOADER),
    ('\tHMODULE streamline = LoadLibraryA("sl.interposer.dll");',
     '\tHMODULE streamline = (HMODULE)streamline_load_interposer();'),
    ('\tpref.flags = sl::PreferenceFlags::eAllowOTA | sl::PreferenceFlags::eLoadDownloadedPlugins | sl::PreferenceFlags::eDisableCLStateTracking;',
     '\t// Local hardening: no eAllowOTA or eLoadDownloadedPlugins, so Streamline neither downloads plugins\n'
     '\t// nor loads downloaded ones; the signed DLLs beside the executable are all it runs.\n'
     '\tpref.flags = sl::PreferenceFlags::eDisableCLStateTracking;'),
])

patch('drivers/vulkan/rendering_context_driver_vulkan.cpp', [
    ('#if defined(USE_VOLK) && defined(STREAMLINE_ENABLED) && defined(_WIN32)\n#include <windows.h>\n#endif\n',
     '#if defined(USE_VOLK) && defined(STREAMLINE_ENABLED) && defined(_WIN32)\n#include <windows.h>\n'
     'void *streamline_load_interposer(); // drivers/streamline/streamline_context.cpp: signed, beside the executable\n#endif\n'),
    ('\tmodule = LoadLibraryA("sl.interposer.dll");',
     '\tmodule = (HMODULE)streamline_load_interposer();'),
])
