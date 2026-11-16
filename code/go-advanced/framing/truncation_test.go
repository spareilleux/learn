package framing

import (
	"bytes"
	"errors"
	"io"
	"testing"
)

func TestMissingPayloadIsUnexpectedEOF(t *testing.T) {
	_, err := Read(bytes.NewReader([]byte{0, 0, 0, 2}))
	if !errors.Is(err, io.ErrUnexpectedEOF) {
		t.Fatalf("got %v; want %v", err, io.ErrUnexpectedEOF)
	}
}
