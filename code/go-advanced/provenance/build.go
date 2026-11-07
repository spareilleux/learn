package provenance

import "runtime/debug"

func MainModule() (string, bool) {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		return "", false
	}
	return info.Main.Path, true
}
