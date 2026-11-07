package framing

import (
	"encoding/binary"
	"errors"
	"io"
)

const MaxFrame = 1024

var ErrTooLarge = errors.New("frame too large")

func Write(w io.Writer, payload []byte) error {
	if len(payload) > MaxFrame {
		return ErrTooLarge
	}
	var header [4]byte
	binary.BigEndian.PutUint32(header[:], uint32(len(payload)))
	if err := writeAll(w, header[:]); err != nil {
		return err
	}
	return writeAll(w, payload)
}
func writeAll(w io.Writer, data []byte) error {
	for len(data) > 0 {
		n, err := w.Write(data)
		if n < 0 || n > len(data) {
			return io.ErrShortWrite
		}
		data = data[n:]
		if err != nil {
			return err
		}
		if n == 0 {
			return io.ErrShortWrite
		}
	}
	return nil
}
func Read(r io.Reader) ([]byte, error) {
	var header [4]byte
	if _, err := io.ReadFull(r, header[:]); err != nil {
		return nil, err
	}
	size := binary.BigEndian.Uint32(header[:])
	if size > MaxFrame {
		return nil, ErrTooLarge
	}
	data := make([]byte, int(size))
	_, err := io.ReadFull(r, data)
	if err == io.EOF {
		err = io.ErrUnexpectedEOF
	}
	return data, err
}
