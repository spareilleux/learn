package collection

import (
	"slices"
	"testing"
	"testing/quick"
	"unicode/utf8"
)

func TestMapStops(t *testing.T) {
	calls := 0
	for v := range Map(slices.Values([]int{1, 2, 3}), func(v int) int { calls++; return v * 2 }) {
		if v != 2 {
			t.Fatal(v)
		}
		break
	}
	if calls != 1 {
		t.Fatalf("iterator ignored stop: %d", calls)
	}
}
func TestReverseProperty(t *testing.T) {
	property := func(s string) bool { return !utf8.ValidString(s) || Reverse(Reverse(s)) == s }
	if err := quick.Check(property, nil); err != nil {
		t.Fatal(err)
	}
}
func FuzzReverse(f *testing.F) {
	for _, seed := range []string{"", "abc", "été", "🙂x"} {
		f.Add(seed)
	}
	f.Fuzz(func(t *testing.T, s string) {
		if !utf8.ValidString(s) {
			t.Skip()
		}
		if Reverse(Reverse(s)) != s {
			t.Fatal("involution")
		}
	})
}
