---
title: 2. Pods
description: A pod's lifecycle and conditions, liveness, readiness and startup probes on the C# and Spring Boot APIs, init containers and native sidecars, requests, limits and QoS classes, each shown failing on purpose.
sidebar:
  order: 2
---

Full code: [`code/kubernetes/l02`](https://github.com/spareilleux/learn/tree/main/code/kubernetes/l02), with its commands in [`l02/run.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/run.sh). Every output below comes from a run of that script; [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/check.sh) compares them with [`expected`](https://github.com/spareilleux/learn/tree/main/code/kubernetes/expected).

The commands are shown as the script runs them, in Bash. On Windows, run them in Git Bash or WSL, or in PowerShell without the `| grep`, `| sort` and `| head` filters, which only shorten the output.

A **pod** is the smallest thing Kubernetes schedules: one or more containers that share a network address, can share volumes, and are placed on the same node together. Most pods hold one container, and you rarely create pods by hand; a Deployment does it for you (lesson 3). But every setting that decides whether your application starts, receives traffic and survives lives in the pod template, so this lesson looks at pods alone first.

## The images

This lesson and the next two run the two APIs built in [lesson 4 of the WSL containers course](../../wsl-containers/04-build-an-image/): an ASP.NET Core minimal API and a Spring Boot WebFlux API, both answering `GET /` on port 8080 with a small JSON document. [`images.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/images.sh) builds them from that course's Containerfiles, pulls two helper images, and loads everything into the kind node. On Windows, run it from Git Bash or WSL.

```bash
bash images.sh
```

The manifests use `imagePullPolicy: Never`: the node must already have the image, and Kubernetes never tries a registry. With a registry, you would push the images and leave the default, `IfNotPresent` for a tagged image.

:::caution[kind load docker-image and Docker Desktop]
The usual command, `kind load docker-image csharp-api:1.0`, failed on the author's machine with `ctr: content digest sha256:e86d3659…: not found`. kind imports the image into the node with `ctr images import --all-platforms`, and an image saved from Docker Desktop's containerd image store lists platforms whose layers were never downloaded. This is [kind issue #3795](https://github.com/kubernetes-sigs/kind/issues/3795), listed in kind's [known issues](https://kind.sigs.k8s.io/docs/user/known-issues/). `images.sh` uses the workaround: `docker save --platform linux/amd64` into an archive, then `kind load image-archive`.
:::

## A pod and its lifecycle

[`l02/pod.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/pod.yaml) runs the C# API with resources and two probes, explained in the next sections:

```yaml
# Lesson 2: one pod running the C# API built in the WSL containers course, with requests, limits and two probes.
apiVersion: v1
kind: Pod
metadata:
  name: csharp-api
  labels:
    app: csharp-api
spec:
  containers:
    - name: api
      image: csharp-api:1.0
      # kind loads the image into the node: never try a registry
      imagePullPolicy: Never
      ports:
        - containerPort: 8080
      resources:
        requests:
          cpu: 100m
          memory: 64Mi
        limits:
          memory: 256Mi
      # Send traffic only once GET / answers
      readinessProbe:
        httpGet:
          path: /
          port: 8080
        periodSeconds: 5
      # Restart the container if GET / stops answering
      livenessProbe:
        httpGet:
          path: /
          port: 8080
        periodSeconds: 10
        failureThreshold: 3
```

```text
> kubectl apply -n l02 -f l02/pod.yaml
pod/csharp-api created
> kubectl wait -n l02 --for=condition=Ready pod/csharp-api --timeout=120s
pod/csharp-api condition met
> kubectl get pod -n l02 csharp-api
NAME         READY   STATUS    RESTARTS   AGE
csharp-api   1/1     Running   0          1s
```

`STATUS` summarizes two separate things. The pod's [**phase**](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase) is one of `Pending`, `Running`, `Succeeded`, `Failed` or `Unknown`. The pod's **conditions** say which steps it has passed, and `kubectl wait` waits for one of them:

```text
> kubectl get pod -n l02 csharp-api -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'
PodReadyToStartContainers=True
Initialized=True
Ready=True
ContainersReady=True
PodScheduled=True
```

In the order they happen: the scheduler picked a node (`PodScheduled`), the kubelet created the pod's sandbox and network (`PodReadyToStartContainers`), init containers finished (`Initialized`), every container passed its readiness probe (`ContainersReady`), and so the pod is `Ready`. Only a `Ready` pod receives traffic from a Service.

The container's standard output is its log, as with `docker logs`. ASP.NET Core writes its startup lines:

```text
> kubectl logs -n l02 csharp-api
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://[::]:8080
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
info: Microsoft.Hosting.Lifetime[0]
      Hosting environment: Production
info: Microsoft.Hosting.Lifetime[0]
      Content root path: /app
```

And the events tell what the kubelet did, which is the first place to look when a pod doesn't start:

```text
> kubectl get events -n l02 --field-selector involvedObject.name=csharp-api,type=Normal -o custom-columns=TYPE:.type,REASON:.reason,MESSAGE:.message --sort-by=.metadata.creationTimestamp
TYPE     REASON      MESSAGE
Normal   Scheduled   Successfully assigned l02/csharp-api to learn-k8s-control-plane
Normal   Pulled      Container image "csharp-api:1.0" already present on machine and can be accessed by the pod
Normal   Created     Container created
Normal   Started     Container started
```

On some runs, a `Warning` also appears, with the pod's IP address: `Readiness probe failed: Get "http://10.244.0.44:8080/": dial tcp 10.244.0.44:8080: connect: connection refused`. The command above keeps only `Normal` events for that reason. The first probe went out before Kestrel was listening. It is harmless, and it shows why readiness matters: the process is running, but the application isn't serving yet.

## Three probes

A **probe** is a check that the kubelet runs against a container, over HTTP, TCP, gRPC or a command. [Kubernetes has three kinds](https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/), and they answer three different questions:

| Probe | Question | When it fails | ASP.NET Core | Spring Boot |
|---|---|---|---|---|
| **liveness** | Is the process stuck beyond repair? | the kubelet restarts the container | a health check tagged `live` with [`MapHealthChecks`](https://learn.microsoft.com/aspnet/core/host-and-deploy/health-checks) | `/actuator/health/liveness` |
| **readiness** | Can it take requests now? | the pod is removed from Services, nothing restarts | a check tagged `ready`, including dependencies | `/actuator/health/readiness` |
| **startup** | Has it finished starting? | liveness and readiness wait; after `failureThreshold` failures the container is restarted | | |

Spring Boot's Actuator [exposes both groups](https://docs.spring.io/spring-boot/reference/actuator/endpoints.html#actuator.endpoints.kubernetes-probes) when it runs on Kubernetes. ASP.NET Core leaves the split to you. The two course APIs have neither, so the probes here call `GET /`. That is enough to see the mechanics, but a real liveness endpoint should not check a database: if the database goes down, restarting every pod doesn't bring it back.

### A liveness probe that fails

[`l02/liveness-fail.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/liveness-fail.yaml) probes `/healthz`, a path the API doesn't have, every 2 seconds, and gives up after 2 failures:

```yaml
      livenessProbe:
        httpGet:
          path: /healthz
          port: 8080
        periodSeconds: 2
        failureThreshold: 2
```

```text
> kubectl get pod -n l02 liveness-fail
NAME            READY   STATUS    RESTARTS     AGE
liveness-fail   1/1     Running   1 (2s ago)   6s
> kubectl get events -n l02 --field-selector involvedObject.name=liveness-fail,type=Warning -o custom-columns=TYPE:.type,REASON:.reason,MESSAGE:.message --no-headers | grep -v 'connection refused' | sort -u
Warning   Unhealthy   Liveness probe failed: HTTP probe failed with statuscode: 404
> kubectl get events -n l02 --field-selector involvedObject.name=liveness-fail,reason=Killing -o custom-columns=TYPE:.type,REASON:.reason,MESSAGE:.message --no-headers | sort -u
Normal   Killing   Container api failed liveness probe, will be restarted
```

An HTTP probe succeeds on any status from 200 to 399; the 404 is a failure, with the message built in the kubelet's [`http.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/probe/http/http.go#L147) and recorded as an event by [`prober.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/kubelet/prober/prober.go#L124). The container's previous state is less obvious:

```text
> kubectl get pod -n l02 liveness-fail -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason} {.status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'
Completed 0
```

The kubelet stops a container with `SIGTERM`, and ASP.NET Core handles it as a clean shutdown, so the killed container exited with code 0. A restart count that keeps growing with reason `Completed` is often a liveness probe, not a crash. After a few restarts, the kubelet waits longer and longer before the next one: on the author's cluster, `STATUS` showed `CrashLoopBackOff` from the second restart, 16 seconds after the pod was created.

### A readiness probe that fails

The same mistake on the readiness probe, in [`l02/readiness-fail.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/readiness-fail.yaml), gives a different result:

```text
> kubectl get pod -n l02 readiness-fail
NAME             READY   STATUS    RESTARTS   AGE
readiness-fail   0/1     Running   0          1s
> kubectl get pod -n l02 readiness-fail -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'
PodReadyToStartContainers=True
Initialized=True
Ready=False
ContainersReady=False
PodScheduled=True
> kubectl get events -n l02 --field-selector involvedObject.name=readiness-fail,type=Warning -o custom-columns=TYPE:.type,REASON:.reason,MESSAGE:.message --no-headers | grep -v 'connection refused' | sort -u
Warning   Unhealthy   Readiness probe failed: HTTP probe failed with statuscode: 404
```

`Running`, zero restarts, and never `Ready`. Nothing is broken from the kubelet's point of view; the pod simply never receives traffic. Lesson 4 shows the other side: such a pod is listed in its Service's EndpointSlice, marked not ready.

### A startup probe for the JVM

The Spring Boot API needs a couple of seconds to start. A liveness probe with a short delay would kill it before it answers; a long `initialDelaySeconds` would delay the detection of real failures for the whole life of the pod. A startup probe solves both. [`l02/startup.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/startup.yaml) checks every second, up to 60 times, and the liveness probe starts only after the first success:

```yaml
      startupProbe:
        httpGet:
          path: /
          port: 8080
        periodSeconds: 1
        failureThreshold: 60
      livenessProbe:
        httpGet:
          path: /
          port: 8080
        periodSeconds: 10
```

```text
> kubectl wait -n l02 --for=condition=Ready pod/java-reactor-api --timeout=180s
pod/java-reactor-api condition met
> kubectl get events -n l02 --field-selector involvedObject.name=java-reactor-api -o custom-columns=TYPE:.type,REASON:.reason,COUNT:.count,MESSAGE:.message --sort-by=.metadata.creationTimestamp
TYPE      REASON      COUNT   MESSAGE
Normal    Scheduled   1       Successfully assigned l02/java-reactor-api to learn-k8s-control-plane
Normal    Pulled      1       Container image "java-reactor-api:1.0" already present on machine and can be accessed by the pod
Normal    Created     1       Container created
Normal    Started     1       Container started
Warning   Unhealthy   1       Startup probe failed: Get "http://10.244.0.196:8080/": dial tcp 10.244.0.196:8080: connect: connection refused
```

On this run, the container started at 13:18:36 and the pod was ready at 13:18:38: two seconds, with one failed startup probe that cost nothing. On a busy node, the same JVM can take ten times longer, which is why the budget is 60 seconds and not 3. The timings change from run to run, so `check.sh` records this output without comparing it.

## Init containers and sidecars

**Init containers** run one after the other, each to completion, before the regular containers start: a migration, a configuration file, a wait for a dependency. Since Kubernetes 1.33, where the feature became stable, an init container with `restartPolicy: Always` is a [**native sidecar**](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/) instead: it starts in the init sequence, but keeps running next to the app, and it stops after the app. Log shippers, proxies and certificate refreshers are typical sidecars.

[`l02/init-sidecar.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/init-sidecar.yaml) has both. `setup` writes a configuration file into a shared `emptyDir` volume, `log-shipper` follows a log file, and `app` reads the configuration and appends to the log every second:

```yaml
spec:
  # sh runs as PID 1 and ignores SIGTERM: without this, deleting the pod waits the default 30 s before SIGKILL
  terminationGracePeriodSeconds: 5
  initContainers:
    - name: setup
      image: busybox:1.38.0
      command: ["sh", "-c", "echo 'greeting=hello' > /config/app.conf && echo setup done"]
      volumeMounts:
        - name: config
          mountPath: /config
    - name: log-shipper
      image: busybox:1.38.0
      restartPolicy: Always
      # Follows the file the app writes; a real sidecar would send it somewhere
      command: ["sh", "-c", "touch /logs/app.log && tail -F /logs/app.log"]
      volumeMounts:
        - name: logs
          mountPath: /logs
  containers:
    - name: app
      image: busybox:1.38.0
      command: ["sh", "-c", ". /config/app.conf; i=0; while true; do i=$((i+1)); echo \"$greeting $i\" >> /logs/app.log; sleep 1; done"]
      volumeMounts:
        - name: config
          mountPath: /config
        - name: logs
          mountPath: /logs
  volumes:
    - name: config
      emptyDir: {}
    - name: logs
      emptyDir: {}
```

```text
> kubectl get pod -n l02 init-sidecar
NAME           READY   STATUS    RESTARTS   AGE
init-sidecar   2/2     Running   0          5s
> kubectl get pod -n l02 init-sidecar -o jsonpath='{range .status.initContainerStatuses[*]}{.name}: started={.started} ready={.ready} terminated={.state.terminated.reason}{"\n"}{end}{range .status.containerStatuses[*]}{.name}: started={.started} ready={.ready}{"\n"}{end}'
setup: started=false ready=true terminated=Completed
log-shipper: started=true ready=true terminated=
app: started=true ready=true
> kubectl logs -n l02 init-sidecar -c setup
setup done
> kubectl logs -n l02 init-sidecar -c log-shipper | head -3
hello 1
hello 2
hello 3
```

`READY 2/2` counts the sidecar and the app, not `setup`, which has completed. `-c` picks a container in a multi-container pod. The sidecar saw the first line because it was already running when the app wrote it: that start order is what the native sidecar guarantees, and what an ordinary second container in `containers` doesn't.

## Requests, limits and QoS

Each container can declare, for CPU and memory:

- a **request**: what the scheduler reserves for it on a node. A pod is only placed where the sum of requests fits.
- a **limit**: the most it may use. Above its CPU limit, a container is throttled; above its memory limit, the kernel kills it.

CPU is counted in cores (`100m` is a tenth of a core), memory in bytes (`64Mi`). The first pod requested `100m` and `64Mi` with a `256Mi` memory limit, and no CPU limit: it may use idle CPU on the node, but not more memory than planned. That is a common choice for web APIs; the [resource management page](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) describes the options.

Requests and limits decide the pod's [**QoS class**](https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/), which decides which pods the kubelet evicts first when a node runs out of memory. [`l02/qos.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/qos.yaml) creates one pod of each:

```text
> kubectl get pods -n l02 guaranteed burstable besteffort -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
NAME         QOS
guaranteed   Guaranteed
burstable    Burstable
besteffort   BestEffort
```

The rule, as written in [`qos.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/apis/core/v1/helper/qos/qos.go#L39-L42): a pod is `BestEffort` if no container has any CPU or memory request or limit, `Guaranteed` if every container has CPU and memory requests equal to its limits, and `Burstable` otherwise. `BestEffort` pods go first under memory pressure, `Guaranteed` ones last.

Both runtimes read the limit. .NET sizes its garbage-collected heap from the container's memory limit ([`GCHeapHardLimit`](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector#heap-hard-limit) defaults to 75% of it), and the JVM from `-XX:MaxRAMPercentage`, 25% of the limit by default. A limit copied from another service can starve one and waste memory on the other.

Since Kubernetes 1.35, requests and limits can also be [changed on a running pod](https://kubernetes.io/docs/tasks/configure-pod-container/resize-container-resources/) without restarting it; lesson 9, on scaling, comes back to it.

## A practical case: GA's deployment guide

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) runs on Docker Compose and .NET Aspire, and a [Kubernetes track](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/conductor/tracks/k8s-deployment/index.md) is planned, not started. Its deployment guide already has a [Deployment for the API](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/docs/DEPLOYMENT_GUIDE.md#L152-L195), with a liveness probe on `/health` and a readiness probe on `/ready`, both on port 7001. Compared with the code at the same commit:

- the [API's Dockerfile](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/Apps/ga-server/GaApi/Dockerfile#L31-L33) exposes port 8080, the default of .NET's `aspnet` images, and sets `ASPNETCORE_ENVIRONMENT=Production`;
- the Aspire service defaults map `/health` and `/alive` [only in the Development environment](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/AllProjects.ServiceDefaults/Extensions.cs#L95-L112), the template's choice for security reasons;
- no `/ready` endpoint exists; the API's own health controller answers under `/api/Health`.

As written, the probes would fail against the image: nothing listens on 7001, and even on 8080 the paths return 404. From this lesson, the expected result is a container restarted by its liveness probe and a pod never `Ready`, but I haven't deployed GA to check it (*to verify*). The guide also declares no resources, so the pod would be `BestEffort`. The fix belongs to both sides: map a `live` and a `ready` health endpoint in Production, without the details that the template's warning is about, and point the probes at them on 8080.

## Key takeaways

- A pod is one or more containers placed together; its phase says where it is in its life, its conditions say which steps it has passed, and `Ready` decides whether it gets traffic.
- `kubectl logs`, `kubectl get events` and the container's `lastState` answer most "why doesn't it start" questions.
- Liveness restarts a stuck container, readiness takes a pod out of traffic without restarting it, and startup protects slow starters without weakening the other two.
- A liveness restart of an ASP.NET Core app shows as `Completed`, exit code 0: the app shut down cleanly when asked.
- Init containers run to completion in order; a native sidecar (`restartPolicy: Always`) starts before the app and runs alongside it.
- Requests place pods, limits cap them, and together they set the QoS class that decides eviction order.

## Exercises

**1.** `l02/pod.yaml` is `Burstable`. Write a variant that is `Guaranteed`, apply it, and check its class.

<details>
<summary>Solution</summary>

Requests must equal limits for both CPU and memory, in every container: [`l02/pod-guaranteed.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/pod-guaranteed.yaml).

```yaml
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 100m
          memory: 128Mi
```

```text
> kubectl apply -n l02 -f l02/pod-guaranteed.yaml
pod/csharp-api-guaranteed created
> kubectl get pod -n l02 csharp-api-guaranteed -o jsonpath='{.status.qosClass}{"\n"}'
Guaranteed
```

The price is the CPU limit: under load, this pod is throttled at a tenth of a core even if the node is idle.

</details>

**2.** Give the C# API a memory limit of `8Mi` ([`l02/oom.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/oom.yaml)). What happens, and where do you see it?

<details>
<summary>Solution</summary>

```text
> kubectl apply -n l02 -f l02/oom.yaml
pod/oom created
> kubectl get pod -n l02 oom
NAME   READY   STATUS    RESTARTS     AGE
oom    1/1     Running   1 (2s ago)   2s
> kubectl get pod -n l02 oom -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason} {.status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'
OOMKilled 137
```

The kernel kills the process as soon as it goes over the limit: reason `OOMKilled`, exit code 137 (128 + 9, `SIGKILL`). The kubelet restarts it, and a few seconds later `STATUS` shows `OOMKilled`. `STATUS` changes from second to second, so `lastState` is the reliable place to read.

While preparing this exercise, a limit of `16Mi` looked sufficient at first: the API started and kept running. Then a `kubectl exec` into that container, to read its memory use, pushed it over the limit, and the API was `OOMKilled`. A process started with `kubectl exec` runs inside the container's cgroup and counts against its limit.

</details>

**3.** What does a pod look like when its init container fails? Try [`l02/init-fail.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/init-fail.yaml), whose `setup` container prints an error and exits with code 1.

<details>
<summary>Solution</summary>

```text
> kubectl apply -n l02 -f l02/init-fail.yaml
pod/init-fail created
> kubectl get pod -n l02 init-fail
NAME        READY   STATUS     RESTARTS     AGE
init-fail   0/1     Init:Error   1 (2s ago)   2s
> kubectl get pod -n l02 init-fail -o jsonpath='setup: exit code {.status.initContainerStatuses[0].lastState.terminated.exitCode}{"\n"}app: {.status.containerStatuses[0].state.waiting.reason}{"\n"}'
setup: exit code 1
app: PodInitializing
> kubectl logs -n l02 init-fail -c setup
config server unreachable
```

`Init:Error` means an init container exited with an error; while it runs again, `STATUS` shows `Init:0/1`, zero of one init containers completed. With the pod's default `restartPolicy: Always`, the kubelet retries `setup` with a growing delay, and `app` waits in `PodInitializing` until it succeeds. The init container's own log gives the reason.

</details>

## Sources

- Kubernetes documentation: [Pods](https://kubernetes.io/docs/concepts/workloads/pods/), [Pod lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/), [Liveness, readiness and startup probes](https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/) and [how to configure them](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/), [Init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/), [Sidecar containers](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/), [Resource management for pods and containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/), [Pod quality of service classes](https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/)
- Source code at v1.37.0: [`pkg/probe/http/http.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/probe/http/http.go#L147), [`pkg/kubelet/prober/prober.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/kubelet/prober/prober.go#L124), [`qos.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/apis/core/v1/helper/qos/qos.go#L39-L42)
- [Health checks in ASP.NET Core](https://learn.microsoft.com/aspnet/core/host-and-deploy/health-checks), [Spring Boot Kubernetes probes](https://docs.spring.io/spring-boot/reference/actuator/endpoints.html#actuator.endpoints.kubernetes-probes), [.NET garbage collector configuration](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector)
- kind: [known issues](https://kind.sigs.k8s.io/docs/user/known-issues/), [issue #3795](https://github.com/kubernetes-sigs/kind/issues/3795)
