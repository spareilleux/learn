// Package versions, as written in the project files of GuitarAlchemist/ga.
module deps

import strconv

// Release is a version made of numbers only, such as 9.5.1.
pub struct Release {
pub:
	parts []int
}

// Prerelease is a release followed by a label, such as 1.0.0-beta.1.
pub struct Prerelease {
pub:
	release Release
	label   string
}

// Floating is a version with a wildcard, such as 8.*-*, that NuGet resolves at restore time.
pub struct Floating {
pub:
	pattern string
}

// Version is one of the three forms.
pub type Version = Floating | Prerelease | Release

fn parse_release(s string) !Release {
	mut parts := []int{}
	for p in s.split('.') {
		parts << strconv.atoi(p)!
	}
	return Release{parts}
}

// parse_version reads a version, or returns an error when a part isn't a number.
pub fn parse_version(s string) !Version {
	if s.contains('*') {
		return Floating{s}
	}
	if dash := s.index('-') {
		return Prerelease{parse_release(s[..dash])!, s[dash + 1..]}
	}
	return parse_release(s)!
}

// is_stable tells whether a version is a release.
pub fn (v Version) is_stable() bool {
	return v is Release
}
