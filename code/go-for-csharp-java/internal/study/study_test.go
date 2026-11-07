package study

import (
	"context"
	"errors"
	"fmt"
	"io"
	"strings"
	"testing"
	"unicode/utf8"
)

func TestSliceAliasAndClone(t *testing.T) {
	original := Fixture()
	alias := original[:1]
	detached := Clone(alias)
	alias[0].Minutes = 99
	if original[0].Minutes != 99 || detached[0].Minutes != 15 {
		t.Fatalf("original=%v detached=%v", original, detached)
	}
}

func TestRecordCopyAndPointerMethod(t *testing.T) {
	original := Fixture()[0]
	copy := original
	copy.Add(5)
	if original.Minutes != 15 || copy.Minutes != 20 {
		t.Fatal(original, copy)
	}
}

func TestTypedNilInterface(t *testing.T) {
	var pointer *Record
	var named interface{ Label() string } = pointer
	if pointer != nil || named == nil {
		t.Fatal("typed nil lost dynamic type")
	}
}

func TestLoadValidationAndErrorIdentity(t *testing.T) {
	cases := []struct {
		name, input string
		want        Minutes
		invalid     bool
	}{
		{"sample", Sample, 40, false},
		{"empty array", "[]", 0, false},
		{"empty name", `[{"name":"","minutes":1}]`, 0, true},
		{"negative", `[{"name":"go","minutes":-1}]`, 0, true},
		{"null", "null", 0, true},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			records, err := Load(strings.NewReader(tc.input))
			if tc.invalid {
				if !errors.Is(err, ErrInvalid) {
					t.Fatalf("want invalid: %v", err)
				}
				return
			}
			if err != nil || Total(records) != tc.want {
				t.Fatalf("records=%v error=%v", records, err)
			}
		})
	}
}

func TestLoadMalformedAndInvalidUTF8(t *testing.T) {
	for _, input := range []string{"[", Sample + " true", "{}"} {
		if _, err := Load(strings.NewReader(input)); err == nil {
			t.Fatalf("accepted %q", input)
		}
	}
	if _, err := Load(strings.NewReader(string([]byte{0xff}))); !errors.Is(err, ErrInvalid) {
		t.Fatalf("UTF-8: %v", err)
	}
}

type brokenReader struct{}

func (brokenReader) Read([]byte) (int, error) { return 0, io.ErrUnexpectedEOF }

func TestLoadPreservesReadError(t *testing.T) {
	_, err := Load(brokenReader{})
	if !errors.Is(err, io.ErrUnexpectedEOF) {
		t.Fatal(err)
	}
}

func TestUnicodeBytesAndRunes(t *testing.T) {
	name := "café"
	if len(name) != 5 || utf8.RuneCountInString(name) != 4 {
		t.Fatal("byte/rune model changed")
	}
}

func TestSelectBoundaryAndOrder(t *testing.T) {
	records := []Record{{"first", 20}, {"skip", 19}, {"last", 20}}
	selected := Select(records, 20)
	if len(selected) != 2 || selected[0].Name != "first" || selected[1].Name != "last" {
		t.Fatal(selected)
	}
	selected[0].Name = "changed"
	if records[0].Name != "first" {
		t.Fatal("selection aliases the input elements")
	}
}

func TestMapPreservesOrderAndEmpty(t *testing.T) {
	labels := Map(Fixture(), func(r Record) string { return r.Label() })
	if len(labels) != 2 || labels[0] != "types" || labels[1] != "go" {
		t.Fatal(labels)
	}
	if len(Map([]Record(nil), func(r Record) string { return r.Name })) != 0 {
		t.Fatal("empty map")
	}
}

func TestStreamAndCancellation(t *testing.T) {
	count, err := Count(context.Background(), Fixture())
	if err != nil || count != 2 {
		t.Fatalf("count=%d err=%v", count, err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, err := Count(ctx, Fixture()); !errors.Is(err, context.Canceled) {
		t.Fatal(err)
	}
	for range Stream(ctx, nil) {
	}
}

func ExampleTotal() {
	fmt.Println(Total(Fixture()))
	fmt.Println(Total(nil))
	// Output:
	// 40
	// 0
}

func FuzzLoad(f *testing.F) {
	f.Add(Sample)
	f.Add("[]")
	f.Add("null")
	f.Fuzz(func(t *testing.T, input string) {
		records, err := Load(strings.NewReader(input))
		if err != nil {
			return
		}
		for _, record := range records {
			if record.Name == "" || record.Minutes < 0 {
				t.Fatal("invalid accepted record")
			}
		}
	})
}
