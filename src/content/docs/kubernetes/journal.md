---
title: Journal
description: Dated progress notes for the Kubernetes course — versions chosen, an image load that failed on Docker Desktop, a cluster that woke up with expired tokens, surprises for a C# or Java developer, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Lesson 1 — Architecture and a local cluster
- [x] Lesson 2 — Pods
- [x] Lesson 3 — Deployments
- [x] Lesson 4 — Services and DNS
- [ ] Lesson 5 — Configuration: ConfigMaps and Secrets
- [ ] Lesson 6 — Storage: volumes, PersistentVolumes, StatefulSets
- [ ] Lesson 7 — Jobs, CronJobs and DaemonSets
- [ ] Lesson 8 — Scheduling
- [ ] Lesson 9 — Scaling
- [ ] Lesson 10 — Security
- [ ] Lesson 11 — Packaging: Helm and Kustomize
- [ ] Lesson 12 — Observability and troubleshooting
- [ ] Lesson 13 — Extending Kubernetes: CRDs and operators
- [ ] Lesson 14 — Continuous delivery
- [ ] Lesson 15 — In production: AKS, EKS, GKE

## 2026-09-15 — Lessons 1 to 4

- [kubernetes.io/releases](https://kubernetes.io/releases/) listed 1.37 as the latest minor version, released on 2026-08-26, and `dl.k8s.io/release/stable.txt` still said `v1.37.0` on 2026-09-15. kind 0.33.0's default node image is 1.37.0. Its [release notes](https://github.com/kubernetes-sigs/kind/releases/tag/v0.33.0) start with "defaults to Kubernetes 1.36.1" and, a few lines lower, give the 1.37.0 image as the new default; the image in [`defaults/image.go`](https://github.com/kubernetes-sigs/kind/blob/407a9675e6d9af1200b5f57f9ca52ec6cdacce74/pkg/apis/config/defaults/image.go#L20-L21) settles it. The node runs containerd 2.3.4, CoreDNS 1.14.6 and etcd 3.7.0.
- The machine: Windows 11 with Docker Desktop 4.61.0 (Engine 29.2.1), which uses containerd's image store. The cluster uses its own kubeconfig file through `KUBECONFIG`, so that no command could reach another cluster. Creating it took 58 seconds with the node image already downloaded; running the four lessons with [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/check.sh) takes about three minutes.
- Each lesson runs in its own namespace, deleted at the end. An early version of lesson 1 worked in `default`, and a test Deployment I had forgotten there changed the output of `kubectl get pods`.
- `kubectl rollout status` prints a varying number of `Waiting…` lines, and the first readiness probe of a starting pod sometimes fails with `connection refused`: `check.sh` compares the last line, filters those events, and keeps the raw outputs that vary for the lessons to quote.
- CI: kubeconform validates every manifest on the three OSes with schemas pinned to a commit; the kind job runs on Ubuntu, with kind and `kubectl` downloaded and checked against their SHA-256 checksums.
- Git Bash on Windows turns arguments that start with `/` into Windows paths, which broke `docker exec … ls /etc/kubernetes/manifests`. `MSYS_NO_PATHCONV=1` fixes it, and then `KUBECONFIG` must be written `C:/…`, since the conversion no longer applies to it either.

**The image that wouldn't load.** `kind load docker-image csharp-api:1.0` failed with `ctr: content digest sha256:e86d3659bcca4c720111606875d3c5554678fd22ce255e8c5ed8e4f571d5d6c3: not found`. kind imports images with `ctr images import --all-platforms`, and an image exported from containerd's image store refers to platforms whose layers Docker Desktop never downloaded. It is [kind#3795](https://github.com/kubernetes-sigs/kind/issues/3795), still open; the [known issues](https://kind.sigs.k8s.io/docs/user/known-issues/) page on kind's site describes it, but the docs of the v0.33.0 tag don't yet. [`images.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/images.sh) saves the images for one platform, `docker save --platform linux/amd64`, and loads the archive with `kind load image-archive`.

**The cluster that woke up with expired tokens.** After the machine had slept for about eight hours, lesson 3's first run showed `ReplicaSetCreateError Failed to create new replica set` events, with `Unauthorized` in their messages. My explanation, not verified: the controllers authenticate with service account tokens that expire and are renewed while the cluster runs, and the tokens expired during the sleep before they could be renewed. The errors went away by themselves after a few minutes, and the next run matched `expected/`. On a laptop, give a cluster a moment after a long sleep before believing its errors.

**Surprises:**

- A container killed by its liveness probe shows `lastState` `Completed`, exit code 0: ASP.NET Core handles `SIGTERM` as a normal shutdown. A restart count that keeps growing with no error is worth a look at the probes.
- With a 16 MiB memory limit, the C# API started and kept running; a `kubectl exec` into the container, to read its memory use, pushed the container over its limit, and the API was `OOMKilled`. Processes started by `exec` count against the container's limit. Lesson 2's exercise uses 8 MiB, which fails every time.
- `kubectl rollout undo` warns that it doesn't update the `last-applied-configuration` annotation, which the examples of its documentation page don't show.
- cloud-provider-kind doesn't implement Ingress separately: it translates each Ingress into a Gateway named `kind-ingress-gateway` and one HTTPRoute per host.
- On Windows, cloud-provider-kind's first load balancer published port 80 on the host, so `curl http://localhost/` reached the Java API; the Gateway's load balancer got a random host port. A program already listening on port 80 would have made the first one fail or change; I didn't try.
- The Java API reports the WSL 2 kernel as its OS (`Linux 6.18.40.1-microsoft-standard-WSL2`), and the C# API the image's distribution (`Ubuntu 24.04.5 LTS`): the same question, two different answers.
- `kubectl get endpoints` prints `Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice`.

**GuitarAlchemist.** The ga repository has no Kubernetes manifest files, chart or `k8s` directory (at `3010dc68`). It has a [Kubernetes track](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/conductor/tracks/k8s-deployment/index.md) marked "Future / Not Started", and a [deployment guide](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/docs/DEPLOYMENT_GUIDE.md#L106-L231) with a Kubernetes section. Lesson 2 compares that section's probes with the API's image: port 7001 against 8080, and `/health` and `/ready` against endpoints mapped only in Development, or not at all. The same section runs MongoDB as a Deployment with a PersistentVolumeClaim and the default `RollingUpdate` strategy: with one replica, the defaults allow one extra pod and none unavailable, so an update would create a second MongoDB pod, needing the same volume, before stopping the first one. The track itself says databases need StatefulSets; lesson 6 will come back to it.

**To verify:**

- The Windows `PATH` command of lesson 1, and the macOS tab.
- What GA's deployment guide actually does on a cluster, which I reasoned about without deploying it.
