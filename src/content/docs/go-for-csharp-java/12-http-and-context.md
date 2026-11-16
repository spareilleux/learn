---
title: "12. HTTP and context"
description: "Exercise an HTTP handler in memory and propagate cooperative cancellation."
sidebar:
  order: 12
---

## Learning objectives

Read an HTTP boundary as a handler contract, test status and JSON without a public service, and identify who owns cancellation.

## HTTP is an adapter around typed behavior

An [http.Handler](https://pkg.go.dev/net/http#Handler) serves a request by writing headers, status and body to a [`ResponseWriter`](https://pkg.go.dev/net/http#ResponseWriter). Our webapi package exposes the study fixture at a GET route through [http.ServeMux](https://pkg.go.dev/net/http#ServeMux). The handler encodes typed records as JSON instead of constructing text by string concatenation. It sets Content-Type before writing the body, because the first write can commit the response headers.

This is a small boundary for learning the protocol shape. The CLI does not call HTTP to use its own domain functions; both boundaries depend on study directly. That prevents needless networking inside a local report. A handler can reuse a core package without becoming the owner of all its business logic. The advanced course develops service lifecycle and production operational concerns separately.

## Test the boundary without an external service

The example creates an [httptest.ResponseRecorder](https://pkg.go.dev/net/http/httptest#ResponseRecorder) and a request, then invokes ServeHTTP directly. No socket is opened and no public endpoint is contacted. The resulting status, headers and body are observable just as they are to handler-level tests. Decode the body into Record values and verify the domain data rather than comparing incidental whitespace in JSON.

The fixture should yield status two hundred and two records. The tests additionally check the media type and an unsupported method. A recorder test does not establish TLS configuration, proxy behavior, wire framing or real client timeouts. Those require different tests. Keeping the claim at the handler boundary makes the evidence precise while still testing real routing, serialization and data composition.

## Context carries a lifetime across calls

A [context.Context](https://pkg.go.dev/context#Context) communicates cancellation and deadlines through a call chain. Use the request's context when work belongs to that request. [context.WithCancel](https://pkg.go.dev/context#WithCancel) returns a child context and a cancellation function; the creator is responsible for calling cancel to release associated resources. Passing a context does not force another operation to stop. The operation must check its error or select on its Done channel.

After the successful handler call, the command cancels its context and calls Count. Count checks cancellation before starting and returns [`context.Canceled`](https://pkg.go.dev/context#Canceled). [`errors.Is`](https://pkg.go.dev/errors#Is) recognizes that result. This is deterministic: cancellation has happened before the call, so the example does not depend on a timing race or a sleep. The handler also checks a canceled request before encoding, and its focused test asserts that no body is written in that case.

## Compare with familiar request lifetimes

[C# CancellationToken](https://learn.microsoft.com/dotnet/api/system.threading.cancellationtoken) provides a useful comparison for cooperative cancellation, but a Go context also carries deadlines and request-scoped values. Do not put ordinary configuration or optional function parameters into context just to avoid explicit arguments. A canceled context should not be reused for an unrelated new operation. Derive a new lifetime from the appropriate parent instead.

Encoding can fail after headers have been committed. Our small handler returns when encoding fails; it is not a production error-reporting or response-buffering policy. Likewise a handler-level cancellation check does not guarantee that no write can race with a later cancellation. Understand the exact observation point. The important standard-course habit is to propagate ownership of the request lifetime and keep domain operations testable without a running service.

## Worked example

Complete source: [`cmd/l12/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l12/main.go).

```go
package main

import (
	"context"
	"encoding/json"
	"errors"
	"example.com/learn/go-for-csharp-java/internal/study"
	"example.com/learn/go-for-csharp-java/internal/webapi"
	"fmt"
	"net/http"
	"net/http/httptest"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	request := httptest.NewRequestWithContext(ctx, http.MethodGet, "/records", nil)
	response := httptest.NewRecorder()
	webapi.Handler().ServeHTTP(response, request)
	var records []study.Record
	if err := json.Unmarshal(response.Body.Bytes(), &records); err != nil {
		panic(err)
	}
	cancel()
	_, err := study.Count(ctx, records)
	fmt.Printf("status=%d records=%d cancelled=%t\n", response.Code, len(records), errors.Is(err, context.Canceled))
}
```

From the repository root:

```sh
cd code/go-for-csharp-java
go run ./cmd/l12
```

**Verified output — Go 1.27.1, Windows/amd64.**

```text
status=200 records=2 cancelled=true
```

## Read, predict, then check

Before executing the program, trace each value from its declaration to the formatted result. Write down which operation owns validation and which operation only transforms already typed data. Then run the checked-in command and compare the complete output, including its final newline, with examples.json. A matching example demonstrates this fixture; the authored tests cover additional contracts. Change one input at a time, explain the consequence, and keep your experiment separate from the published fixture. This makes a surprising result diagnosable without silently changing what the lesson promises.

## Exercises

1. Why does this example need neither a public server nor a port?

<details>
<summary>Solution 1</summary>

ServeHTTP is an ordinary interface call. httptest supplies the request and a ResponseWriter implementation that records status, headers and body in memory. The example exercises routing and encoding directly. It therefore demonstrates the handler contract, while making no claim about sockets, TLS or deployment configuration.

</details>

2. Why cancel before calling Count in the example?

<details>
<summary>Solution 2</summary>

That establishes a deterministic ordering: Count observes an already-canceled context at entry and returns context.Canceled before starting work. A sleep would not prove that ordering reliably. In a live request, cancellation can arrive during work; operations must observe it cooperatively, and callers must handle whichever completion contract the operation documents.

</details>

## Official sources

- [http.Handler](https://pkg.go.dev/net/http#Handler)
- [http.ServeMux](https://pkg.go.dev/net/http#ServeMux)
- [httptest.ResponseRecorder](https://pkg.go.dev/net/http/httptest#ResponseRecorder)
- [context.WithCancel](https://pkg.go.dev/context#WithCancel)

[Next lesson](../13-testing/) · [Journal](../journal/)
