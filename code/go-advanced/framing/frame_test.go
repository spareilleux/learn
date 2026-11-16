package framing

import (
	"bytes"
	"errors"
	"io"
	"net"
	"testing"
	"time"
)

func TestPipeFrames(t *testing.T) {
	reader, writer := net.Pipe()
	defer reader.Close()
	defer writer.Close()
	if err := reader.SetDeadline(time.Now().Add(2 * time.Second)); err != nil {
		t.Fatal(err)
	}
	if err := writer.SetDeadline(time.Now().Add(2 * time.Second)); err != nil {
		t.Fatal(err)
	}
	done := make(chan error, 1)
	go func() {
		defer writer.Close()
		if err := Write(writer, []byte("alpha")); err != nil {
			done <- err
			return
		}
		done <- Write(writer, nil)
	}()
	first, err := Read(reader)
	if err != nil || string(first) != "alpha" {
		t.Fatal(string(first), err)
	}
	empty, err := Read(reader)
	if err != nil || len(empty) != 0 {
		t.Fatal(empty, err)
	}
	if err := <-done; err != nil {
		t.Fatal(err)
	}
	if _, err := Read(reader); err != io.EOF {
		t.Fatal(err)
	}
}
func TestMalformedFrames(t *testing.T) {
	cases := []struct {
		data []byte
		want error
	}{{[]byte{0, 0}, io.ErrUnexpectedEOF}, {[]byte{0, 0, 0, 2, 1}, io.ErrUnexpectedEOF}, {[]byte{0, 0, 4, 1}, ErrTooLarge}}
	for _, tc := range cases {
		if _, err := Read(bytes.NewReader(tc.data)); !errors.Is(err, tc.want) {
			t.Fatalf("%v: %v", tc.data, err)
		}
	}
	if err := Write(io.Discard, make([]byte, MaxFrame+1)); !errors.Is(err, ErrTooLarge) {
		t.Fatal(err)
	}
}

type zeroWriter struct{}

func (zeroWriter) Write([]byte) (int, error) { return 0, nil }
func TestNoProgress(t *testing.T) {
	if err := Write(zeroWriter{}, []byte("a")); !errors.Is(err, io.ErrShortWrite) {
		t.Fatal(err)
	}
}
func FuzzFrames(f *testing.F) {
	f.Add([]byte("abc"))
	f.Add([]byte{})
	f.Fuzz(func(t *testing.T, payload []byte) {
		if len(payload) > MaxFrame {
			t.Skip()
		}
		var b bytes.Buffer
		if err := Write(&b, payload); err != nil {
			t.Fatal(err)
		}
		got, err := Read(&b)
		if err != nil || !bytes.Equal(got, payload) {
			t.Fatalf("round trip: %v", err)
		}
	})
}
