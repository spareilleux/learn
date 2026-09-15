---
title: Journal
description: Dated progress notes for the RabbitMQ course — versions chosen, the broker that crashed before it started, surprises for a C# or Java developer, mistakes, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Lesson 1 — Getting started
- [x] Lesson 2 — Topology: exchanges, bindings and queues
- [x] Lesson 3 — Clients in C#, Java and Spring AMQP
- [x] Lesson 4 — Reliability: acknowledgements, prefetch, confirms
- [ ] Lesson 5 — Queue types: classic, quorum and streams
- [ ] Lesson 6 — Errors: dead lettering, TTL, retries and delayed messages
- [ ] Lesson 7 — Patterns: work queues, publish/subscribe, RPC, competing consumers, outbox
- [ ] Lesson 8 — Clustering and high availability
- [ ] Lesson 9 — Security: virtual hosts, users, permissions, TLS
- [ ] Lesson 10 — Observability: Prometheus, Grafana, alarms, flow control
- [ ] Lesson 11 — Performance and sizing
- [ ] Lesson 12 — Other protocols: streams, MQTT, AMQP 1.0; RabbitMQ and Kafka
- [ ] Lesson 13 — Operations: upgrades, definitions, Kubernetes

## 2026-09-15 — Lessons 1 to 4

- The [release information](https://www.rabbitmq.com/release-information) page listed 4.3.5 as the latest release on 2026-09-15, and Docker Hub's `rabbitmq:4.3.5-management` tag was built on 2026-09-10. The image runs Erlang/OTP 27.3.4.17. The clients are the latest on NuGet and Maven Central that day: RabbitMQ.Client 7.2.2 and amqp-client 5.35.0. Spring Boot 4.1.1 manages amqp-client 5.30.0 and Spring AMQP 4.1.1; the course's parent POM raises the client to 5.35.0 with the `rabbit-amqp-client.version` property, so both Java programs use the same client.
- The code is one C# project with one command per example ([`csharp`](https://github.com/spareilleux/learn/tree/main/code/rabbitmq/csharp)) and a Maven build with two modules, a shaded JAR for the Java client and a Spring Boot JAR ([`java`](https://github.com/spareilleux/learn/tree/main/code/rabbitmq/java)). [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/check.sh) runs 36 steps against a fresh broker, including `rabbitmqctl` and `rabbitmq-diagnostics` commands and a broker restart, and compares each output with `expected/`. I ran it twice in a row on fresh containers on Windows with the same results.
- CI: GitHub-hosted Windows and macOS runners have no Docker, so the workflow builds the clients there and runs everything against a RabbitMQ service container on Linux only.
- To get deterministic output from a broker, the programs avoid timing: they read queues with `basic.get` after publishing, stop consumers after a known count, and name no server-generated consumer tags. Two examples still wait a little: 300 ms after a simulated crash, so that the prefetch window is filled, and 500 ms to check that a consumer receives no fourth message.
- None of the GuitarAlchemist repositories uses RabbitMQ in its code (ga at `dc2e74cb`, ix at `ed5e998`, tars at `54487423`). The only configuration I found is a [generated Docker Compose file in tars](https://github.com/GuitarAlchemist/tars/blob/54487423b5b6e8d4849571e1b3d710f4e99d6f60/.tars/projects/create_a_distributed_microservices_architecture_with_api_gateway/docker-compose.yml#L44-L62): it runs `rabbitmq:3.12-management`, a series no longer on the supported list, with a data volume but no `hostname`, so a recreated container would start under a new node name and not find its data, and it hard-codes the credentials `admin`/`admin123`. Its health check, `rabbitmq-diagnostics ping` as root, is the pattern that crashed my broker, although a 30-second interval makes the race unlikely.

**The broker that stopped before it started.** My first `broker.sh` waited for the broker by running `docker exec rabbitmq rabbitmq-diagnostics check_port_connectivity` every second. The container died within two seconds with `Error when reading /var/lib/rabbitmq/.erlang.cookie: eacces`. The CLI, running as root, created the Erlang cookie before the node did; the node, running as `rabbitmq`, couldn't read it. I reproduced it with a single `docker exec` right after `docker run`, and `ls -la` showed the file owned by `root`. Running the container with `--user rabbitmq` fixed it, with a health check every second. It is [docker-library/rabbitmq#695](https://github.com/docker-library/rabbitmq/issues/695), closed without a comment in 2024; the image's documentation doesn't mention it. Lesson 1 tells the story.

**Surprises:**

- RabbitMQ 4.3.5 refuses a queue declared with `durable: false` unless it is exclusive: `541 INTERNAL_ERROR - Feature transient_nonexcl_queues is deprecated`, a connection error. Every older tutorial that declares `durable: false` fails on this version.
- That error text ends with `To...`: AMQP reply texts are short strings of at most 255 bytes, and the deprecation warning is longer.
- An unroutable message published without `mandatory` is confirmed. A publisher confirm says the broker is done with the message, not that a queue has it.
- With confirm tracking, RabbitMQ.Client 7 throws `PublishReturnException` for a returned message; the Java client reports the same publish as confirmed and calls the `ReturnListener` just before.
- `redelivered` depends on the prefetch window: with no limit, messages a crashed consumer never looked at come back with `redelivered=True`.
- Spring AMQP's Jackson converter writes the Java class name, `dev.learn.rabbitmq.spring.OrdersApplication$Order`, in a `__TypeId__` header, and ignores its absence when the listener's parameter type is concrete.
- Right after a broker started, `curl "…/api/queues/%2F/hello?columns=name,messages,consumers"` returned only `{"name":"hello"}`. In another run, six seconds after publishing, the same request returned `{"consumers":0,"messages":2,"name":"hello"}`. The management plugin collects queue statistics periodically, so the HTTP API lags a few seconds behind `rabbitmqctl`. The exact interval on 4.3.5 is *to verify*.
- With nothing listening on port 5672 on Windows, the .NET client took 4.3 seconds to report `BrokerUnreachableException`, the Java client 165 milliseconds. A fraction of a second after `docker rm -f`, Docker Desktop still accepted the TCP connection and the .NET client reported `connection.start was never received` instead.

**Things I got wrong first:**

- Git Bash converted `/var/lib/rabbitmq/` in `docker exec rabbitmq ls /var/lib/rabbitmq/` into a Windows path under `C:/Program Files/Git`. `MSYS_NO_PATHCONV=1` stops it; `check.sh` sets it for commands run in the container. Setting it for the whole script broke Maven's launcher script instead.
- The Spring Boot parent POM configures the Maven Shade plugin with its own transformers, and Maven merged my `ManifestResourceTransformer` into one of them: "Cannot find 'resource' in class ManifestResourceTransformer". `combine.self="override"` on `<transformers>` fixed it.
- The first version of the queue dumps printed each message's routing key before its body. Headers and fanout messages have an empty or meaningless key, and the output had double spaces; the dumps now print bodies, and the topic examples use the routing key as the body.
- My first push was refused: the GitHub token no longer had the `workflow` scope, needed to create a file under `.github/workflows`. The code went first; the workflow waits for the scope, so until then CI doesn't run these programs.

## Open questions

- The `wslc` and Podman commands of lesson 1, and the Linux and macOS commands, are *to verify*; CI runs the image on Linux.
- Automatic connection recovery in both clients after a broker restart: *to verify* with a program, probably in lesson 8.
- What an exception thrown from a RabbitMQ.Client 7 `ReceivedAsync` handler does to the delivery, and the conversion error of a Spring listener with an interface parameter and no `__TypeId__`: *to verify* in lesson 6.
- `deprecated_features.permit.transient_nonexcl_queues = true` to allow non-durable queues again on 4.3.5: *to verify*.
- Where the 4.3 seconds of the .NET client's refused connection go on Windows: *to verify*.
- Throughput of persistent versus transient messages, and of per-message versus batched confirms: *to verify* in lesson 11.
