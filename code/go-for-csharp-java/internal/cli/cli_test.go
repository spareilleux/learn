package cli

import (
	"bytes"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestRunReport(t *testing.T) {
	cases := []struct {
		name          string
		args          []string
		input, output string
		code          int
	}{
		{"sample", nil, "", "types: 15 min\ngo: 25 min\ntotal: 40 min\n", 0},
		{"filter", []string{"-min", "20"}, "", "go: 25 min\ntotal: 25 min\n", 0},
		{"stdin", []string{"-file", "-"}, `[{"name":"review","minutes":10}]`, "review: 10 min\ntotal: 10 min\n", 0},
		{"empty", []string{"-file", "-"}, "[]", "total: 0 min\n", 0},
		{"bad JSON", []string{"-file", "-"}, "{", "", 1},
		{"bad record", []string{"-file", "-"}, `[{"name":"go","minutes":-1}]`, "", 1},
		{"bad flag", []string{"-min", "x"}, "", "", 2},
		{"negative filter", []string{"-min", "-1"}, "", "", 2},
		{"positional", []string{"unexpected"}, "", "", 2},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			var out, errOut bytes.Buffer
			code := Run(tc.args, strings.NewReader(tc.input), &out, &errOut)
			if code != tc.code || out.String() != tc.output {
				t.Fatalf("code=%d out=%q err=%q", code, out.String(), errOut.String())
			}
			if tc.code != 0 && errOut.Len() == 0 {
				t.Fatal("missing diagnostic")
			}
			if tc.code == 0 && errOut.Len() != 0 {
				t.Fatal(errOut.String())
			}
		})
	}
}

func TestRunFile(t *testing.T) {
	filename := filepath.Join(t.TempDir(), "records.json")
	if err := os.WriteFile(filename, []byte(`[{"name":"file","minutes":7}]`), 0600); err != nil {
		t.Fatal(err)
	}
	var out, errOut bytes.Buffer
	if code := Run([]string{"-file", filename}, strings.NewReader(""), &out, &errOut); code != 0 {
		t.Fatalf("code=%d error=%s", code, &errOut)
	}
	if out.String() != "file: 7 min\ntotal: 7 min\n" {
		t.Fatal(out.String())
	}
	out.Reset()
	if code := Run([]string{"-file", filename + ".missing"}, strings.NewReader(""), &out, &errOut); code != 1 || out.Len() != 0 {
		t.Fatalf("missing file code=%d out=%q", code, out.String())
	}
}

type brokenWriter struct{}

func (brokenWriter) Write([]byte) (int, error) { return 0, io.ErrClosedPipe }

func TestRunOutputFailure(t *testing.T) {
	var diagnostic bytes.Buffer
	if code := Run(nil, strings.NewReader(""), brokenWriter{}, &diagnostic); code != 1 {
		t.Fatal(code)
	}
	if !strings.Contains(diagnostic.String(), "output:") {
		t.Fatal(diagnostic.String())
	}
}
