---
title: "8. Production HTTP boundaries"
description: "Define HTTP resource budgets and test malformed requests without an external service."
sidebar:
  order: 8
---

## Learning objective

Define HTTP resource budgets and test malformed requests without an external service.

## Mechanics and mental models

The [net/http](https://pkg.go.dev/net/http) package gives a working server with little code, but its defaults are not a production resource policy. Our Server constructor specifies finite header, read, write and idle timeouts plus a header byte limit. The handler separately limits the body using MaxBytesReader and gives admitted work a one second context. These are different budgets. A handler deadline does not by itself impose a socket read deadline, and a header timeout does not cap request body size.

The boundary accepts POST to /jobs, decodes one JSON value, rejects unknown fields and checks that the next decode sees end of input. Without the second decode, a valid object followed by another document could be silently accepted. Oversized bodies map to 413; malformed input to 400; wrong methods to 405 with Allow; a closed or full worker service to 503. The bounded example deliberately sums small integers; it is not a durable job queue or an authentication design. Caller identity and persistence would require explicit separate contracts.

[httptest](https://pkg.go.dev/net/http/httptest) supports both in-process recorder tests and a real loopback server. Recorder tests isolate request mapping; the integration test adds actual client and transport behavior with a finite client timeout. Close response bodies so connections and resources can be reused. The command uses the recorder to keep its output deterministic and does not listen on a public port. A real application should construct a server explicitly and coordinate its shutdown with the worker service.

C# middleware and Java servlet filters are familiar adapter layers, but Go handlers are ordinary values implementing an interface. Avoid treating a default global handler registry as an implicit dependency container. Pass the service explicitly into API. Once response headers have been written, a later failure cannot replace the status already sent. Production observability should record write failures and request identity according to a defined privacy policy; this small adapter simply returns after an encoder failure. Likewise, finite timeouts are essential budgets, not proof that every client disconnect aborts arithmetic immediately.

## Worked runnable example

The executable belongs to the independent module `example.com/learn/go-advanced`. Its command is a small caller of reusable packages rather than the only location of the behavior. Read the package file first, then follow its calls from the command. The complete checked-in files appear below so imports, error paths and cleanup remain visible. No hidden notebook state or external service is required. Commands use the same working directory and syntax on Windows, Linux/WSL and macOS once Go is on PATH.

### Reusable source

[httpapi/api.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/httpapi/api.go)

```go
package httpapi

import (
	"context"
	"encoding/json"
	"errors"
	"example.com/learn/go-advanced/domain"
	"example.com/learn/go-advanced/jobs"
	"io"
	"net/http"
	"time"
)

const MaxBody = 256

type API struct{ Service *jobs.Service }

func (a API) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/jobs" {
		http.NotFound(w, r)
		return
	}
	if r.Method != http.MethodPost {
		w.Header().Set("Allow", http.MethodPost)
		http.Error(w, "method", http.StatusMethodNotAllowed)
		return
	}
	ctx, cancel := context.WithTimeout(r.Context(), time.Second)
	defer cancel()
	r.Body = http.MaxBytesReader(w, r.Body, MaxBody)
	defer r.Body.Close()
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	var input struct {
		Name   string `json:"name"`
		Values []int  `json:"values"`
	}
	if err := decoder.Decode(&input); err != nil {
		var large *http.MaxBytesError
		if errors.As(err, &large) {
			http.Error(w, "body", http.StatusRequestEntityTooLarge)
		} else {
			http.Error(w, "json", http.StatusBadRequest)
		}
		return
	}
	if err := decoder.Decode(new(any)); err != io.EOF {
		var large *http.MaxBytesError
		if errors.As(err, &large) {
			http.Error(w, "body", http.StatusRequestEntityTooLarge)
		} else {
			http.Error(w, "trailing", http.StatusBadRequest)
		}
		return
	}
	job, err := domain.NewJob(input.Name, input.Values)
	if err != nil {
		http.Error(w, "job", http.StatusBadRequest)
		return
	}
	reply, err := a.Service.Submit(ctx, job)
	if err != nil {
		status := http.StatusServiceUnavailable
		if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
			status = http.StatusRequestTimeout
		}
		http.Error(w, "unavailable", status)
		return
	}
	select {
	case result := <-reply:
		if result.Err != nil {
			http.Error(w, "cancelled", http.StatusRequestTimeout)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(w).Encode(struct {
			Total int `json:"total"`
		}{result.Total}); err != nil {
			return
		}
	case <-ctx.Done():
		http.Error(w, "deadline", http.StatusGatewayTimeout)
	}
}

func Server(address string, handler http.Handler) *http.Server {
	return &http.Server{Addr: address, Handler: handler, ReadHeaderTimeout: 2 * time.Second, ReadTimeout: 3 * time.Second, WriteTimeout: 3 * time.Second, IdleTimeout: 30 * time.Second, MaxHeaderBytes: 8192}
}
```

[cmd/l08/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l08/main.go)

```go
package main

import (
	"context"
	"example.com/learn/go-advanced/httpapi"
	"example.com/learn/go-advanced/jobs"
	"fmt"
	"net/http/httptest"
	"strings"
)

func main() {
	service := jobs.New(1)
	defer service.Drain(context.Background())
	request := httptest.NewRequest("POST", "/jobs", strings.NewReader(`{"name":"sum","values":[2,3]}`))
	response := httptest.NewRecorder()
	httpapi.API{Service: service}.ServeHTTP(response, request)
	fmt.Println(response.Code)
	fmt.Print(response.Body.String())
}
```

Run from the repository root:

```sh
cd code/go-advanced
go run ./cmd/l08
```

### Expected output contract

```text
200
{"total":5}
```

## Read the contract before changing the code

Before running, predict the result and identify the operation that makes each value observable. Follow the input from its caller, through every copy or reference, to its final consumer. Distinguish the value returned by a function from the lifetime of any work that function starts. When an error is possible, identify who owns the decision to stop, retry or translate it. A printed success value is only one part of that contract: rejected inputs and termination must remain understandable too.

The source listing is deliberately complete. Keep it beside the corresponding test file while studying, and name the exact assertion that would fail if the behavior changed. If your proposed change only alters an internal arrangement, those observable assertions should continue to hold. If it changes a public boundary, describe the changed guarantee before editing. This habit transfers well from C# and Java while leaving Go's ownership and synchronization rules explicit.

## Verification and scope

The shown text output is the executable example's expected-output contract, stored in `examples.json`. Replay it before treating it as an observation on your own machine. Tests are authored in the same module and root verification records their actual execution separately. Passing examples do not establish every operating system, production workload or learner outcome. Diagnostic, profile and benchmark commands describe experiments unless the journal contains a measured result. Keep version, source revision and command together when recording new evidence; an observation without its conditions is difficult to reproduce.

## Exercises

1. Why decode a second time after a successful object?

<details>
<summary>Complete solution</summary>

The boundary promises exactly one JSON document. A second decode must return io.EOF; another object or invalid trailing bytes violates that promise. The local cases exercise concatenated objects explicitly.

</details>

2. Can a one second request context replace MaxBytesReader and server timeouts?

<details>
<summary>Complete solution</summary>

No. Each controls a different resource: accepted work lifetime, bytes read, and connection operations. Keep all budgets explicit and test body rejection and cancelled request handling independently.

</details>

## Primary sources

- [net/http](https://pkg.go.dev/net/http)
- [httptest](https://pkg.go.dev/net/http/httptest)

[Next lesson](../09-streaming-and-framing/) · [Learning journal](../journal/)
