---
title: "9. Streaming and framing"
description: "Implement a bounded binary frame protocol that survives partial reads and writes."
sidebar:
  order: 9
---

## Learning objective

Implement a bounded binary frame protocol that survives partial reads and writes.

## Mechanics and mental models

The [io](https://pkg.go.dev/io) interfaces describe streams, not message delivery. A single Read can return fewer bytes than requested without indicating that the peer has sent its whole message. A TCP write is not preserved as a matching TCP read. The same issue appears with file buffering and compression wrappers. Define a framing protocol before interpreting a byte stream as application messages. This course uses a four byte unsigned big endian length followed by that many payload bytes.

The [encoding/binary](https://pkg.go.dev/encoding/binary) package reads and writes the header representation explicitly, so host endianness does not leak into the protocol. Read uses io.ReadFull for header and payload. It validates the length against MaxFrame before allocating, rejecting a hostile advertised size early. Zero length is a valid empty message. End of stream before a new header differs from truncation during a header or payload: callers can treat a clean EOF as an orderly peer close while treating unexpected EOF as a damaged frame.

Write checks the same bound, writes the complete header and then the payload. Its helper loops over partial writes, returns the writer's error, and rejects a zero progress write. Without the zero progress check, a broken writer could make an infinite loop. An error after some bytes does not mean nothing was transmitted. Automatic retry on the same connection may concatenate a new header onto a damaged partial frame. Reconcile protocol state or close the stream before deciding whether an application operation can safely be retried.

C# and Java stream APIs also permit partial reads; familiar buffered convenience methods do not turn a connection into a message bus. The [net.Pipe](https://pkg.go.dev/net#Pipe) test runs two endpoints without an external server, exchanges two frames and verifies the closing EOF. Its deadlines are failure bounds, not synchronization sleeps. Malformed header, oversized length and truncated payload tests specify failure behavior. A fuzz seed round trip checks arbitrary bounded payloads. Authentication, compression negotiation and durable delivery are deliberately outside this small wire contract.

## Worked runnable example

The executable belongs to the independent module `example.com/learn/go-advanced`. Its command is a small caller of reusable packages rather than the only location of the behavior. Read the package file first, then follow its calls from the command. The complete checked-in files appear below so imports, error paths and cleanup remain visible. No hidden notebook state or external service is required. Commands use the same working directory and syntax on Windows, Linux/WSL and macOS once Go is on PATH.

### Reusable source

[framing/frame.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/framing/frame.go)

```go
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
	return data, err
}
```

[cmd/l09/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l09/main.go)

```go
package main

import (
	"bytes"
	"example.com/learn/go-advanced/framing"
	"fmt"
)

func main() {
	var wire bytes.Buffer
	if err := framing.Write(&wire, []byte("Go")); err != nil {
		panic(err)
	}
	payload, err := framing.Read(&wire)
	if err != nil {
		panic(err)
	}
	fmt.Println(string(payload))
}
```

Run from the repository root:

```sh
cd code/go-advanced
go run ./cmd/l09
```

### Expected output contract

```text
Go
```

## Read the contract before changing the code

Before running, predict the result and identify the operation that makes each value observable. Follow the input from its caller, through every copy or reference, to its final consumer. Distinguish the value returned by a function from the lifetime of any work that function starts. When an error is possible, identify who owns the decision to stop, retry or translate it. A printed success value is only one part of that contract: rejected inputs and termination must remain understandable too.

The source listing is deliberately complete. Keep it beside the corresponding test file while studying, and name the exact assertion that would fail if the behavior changed. If your proposed change only alters an internal arrangement, those observable assertions should continue to hold. If it changes a public boundary, describe the changed guarantee before editing. This habit transfers well from C# and Java while leaving Go's ownership and synchronization rules explicit.

## Verification and scope

The shown text output is the executable example's expected-output contract, stored in `examples.json`. Replay it before treating it as an observation on your own machine. Tests are authored in the same module and root verification records their actual execution separately. Passing examples do not establish every operating system, production workload or learner outcome. Diagnostic, profile and benchmark commands describe experiments unless the journal contains a measured result. Keep version, source revision and command together when recording new evidence; an observation without its conditions is difficult to reproduce.

## Exercises

1. Where must the length limit be checked?

<details>
<summary>Complete solution</summary>

Immediately after parsing the fixed header and before allocating payload storage. Checking after allocation permits the oversized request to consume memory before rejection. Read and Write must agree on the same bound.

</details>

2. May a caller blindly retry a partially failed frame write?

<details>
<summary>Complete solution</summary>

No. Some bytes may already be on the wire and the peer may have acted. Close or reconcile the stream, then use an application identity and delivery contract if retries are needed. Framing alone provides no exactly-once guarantee.

</details>

## Primary sources

- [io](https://pkg.go.dev/io)
- [encoding/binary](https://pkg.go.dev/encoding/binary)
- [net.Pipe](https://pkg.go.dev/net#Pipe)

[Next lesson](../10-race-fuzz-and-property-tests/) · [Learning journal](../journal/)
