// An internal test: same module, so it can call the private parse_release
module deps

fn test_parse_release() {
	r := parse_release('9.5.1')!
	assert r.parts == [9, 5, 1]
}

fn test_parse_release_rejects_letters() {
	parse_release('1.x') or {
		assert err.msg() == 'strconv.atoi: parsing "x": invalid radix 10 character'
		return
	}
	assert false, 'expected an error'
}

fn test_prerelease() ! {
	v := parse_version('1.0.0-beta.24164.1')!
	assert v is Prerelease
	if v is Prerelease {
		assert v.label == 'beta.24164.1'
		assert v.release.parts == [1, 0, 0]
	}
	assert !v.is_stable()
}

fn test_floating() ! {
	for s in ['0.*', '8.*-*'] {
		v := parse_version(s)!
		assert v is Floating, s
	}
}
