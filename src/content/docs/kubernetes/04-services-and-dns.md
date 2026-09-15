---
title: 4. Services and DNS
description: A stable name and address in front of the C# and Spring Boot pods with ClusterIP, NodePort and LoadBalancer Services, cluster DNS, EndpointSlices and readiness, then one entry point for both with the Gateway API and with Ingress.
sidebar:
  order: 4
---

Full code: [`code/kubernetes/l04`](https://github.com/spareilleux/learn/tree/main/code/kubernetes/l04), with its commands in [`l04/run.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/run.sh). As in lessons 2 and 3, the commands are shown as run in Bash.

Every pod has its own IP address, and every pod is temporary. In lesson 3, each update replaced the three C# pods with new ones, new names and new addresses. A client can't keep a list of them. A **Service** is the stable part: a name, a virtual IP address that doesn't change for the Service's lifetime, and a label selector that decides, at every moment, which pods receive the traffic.

## Setup

The lesson reuses lesson 3's two Deployments, and adds a pod to send requests from inside the cluster:

```yaml
# Lesson 4: a pod to send requests from inside the cluster. curl's image would run curl and exit: sleep instead.
apiVersion: v1
kind: Pod
metadata:
  name: client
spec:
  terminationGracePeriodSeconds: 0
  containers:
    - name: curl
      image: curlimages/curl:8.22.0
      command: ["sleep", "infinity"]
```

```text
> kubectl create namespace l04
namespace/l04 created
> kubectl apply -n l04 -f l03/csharp-api.yaml -f l03/java-reactor-api.yaml -f l04/client.yaml
deployment.apps/csharp-api created
deployment.apps/java-reactor-api created
pod/client created
```

## ClusterIP

[`l04/services.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/services.yaml) puts a Service in front of each Deployment:

```yaml
# Lesson 4: a stable name and virtual IP in front of each Deployment of lesson 3.
apiVersion: v1
kind: Service
metadata:
  name: csharp-api
spec:
  # ClusterIP is the default: reachable from inside the cluster only
  type: ClusterIP
  selector:
    app: csharp-api
  ports:
    - name: http
      port: 80
      targetPort: http
---
apiVersion: v1
kind: Service
metadata:
  name: java-reactor-api
spec:
  selector:
    app: java-reactor-api
  ports:
    - name: http
      port: 80
      targetPort: http
```

`port` is what clients call; `targetPort: http` is the pods' port named `http` in lesson 3, 8080. Naming the port in the pod template lets the application change its port without touching the Service.

```text
> kubectl apply -n l04 -f l04/services.yaml
service/csharp-api created
service/java-reactor-api created
> kubectl get -n l04 services
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
csharp-api         ClusterIP   10.96.34.184   <none>        80/TCP    0s
java-reactor-api   ClusterIP   10.96.210.58   <none>        80/TCP    0s
> kubectl exec -n l04 client -- curl -s http://csharp-api/
{"app":"csharp-api","runtime":"<runtime>","os":"<os>","machine":"csharp-api-55b7fbb748-dn79k"}
> kubectl exec -n l04 client -- curl -s http://java-reactor-api/
{"app":"java-reactor-api","runtime":"<runtime>","os":"<os>","machine":"java-reactor-api-64bd9f4b94-xkbjc"}
```

[`kubectl exec`](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_exec/) runs `curl` inside the `client` pod, as `docker exec` would. The `machine` field is the pod's host name, which is its name: the Service chose one of the pods.

The script replaces the runtime and OS, which depend on the image build, with placeholders. On the author's machine, the C# API reported `".NET 10.0.12"` and `"Ubuntu 24.04.5 LTS"`, the distribution of its base image, and the Java API `"Java 25.0.4+7-LTS"` and `"Linux 6.18.40.1-microsoft-standard-WSL2"`: Java's `os.name` and `os.version` describe the kernel, which is Docker Desktop's WSL 2 kernel, shared by every container.

A ClusterIP is reachable only from inside the cluster. No process listens on it: on each node, [kube-proxy](https://kubernetes.io/docs/reference/networking/virtual-ips/) programs the kernel to rewrite packets sent to the Service's address and port towards one of the pods. On kind, kube-proxy uses iptables; its log says `"Using iptables Proxier"`. A new Service takes a moment to be programmed, which is why the script waits for the first `curl` to answer.

## DNS

The name `csharp-api` was resolved by the cluster's DNS, [CoreDNS](https://coredns.io/), which creates a record for every Service. Its full name includes the namespace:

```text
> kubectl exec -n l04 client -- curl -s http://csharp-api.l04.svc.cluster.local/
{"app":"csharp-api","runtime":"<runtime>","os":"<os>","machine":"csharp-api-55b7fbb748-9rj4s"}
> kubectl exec -n l04 client -- cat /etc/resolv.conf
search l04.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
> kubectl exec -n l04 client -- nslookup csharp-api.l04.svc.cluster.local.
Server:		10.96.0.10
Address:	10.96.0.10:53


Name:	csharp-api.l04.svc.cluster.local
Address: 10.96.34.184

```

The kubelet writes each pod's `/etc/resolv.conf`:

- `nameserver 10.96.0.10` is the ClusterIP of the `kube-dns` Service in `kube-system`, in front of the CoreDNS pods of lesson 1.
- `search` lets a short name work: `csharp-api` is tried as `csharp-api.l04.svc.cluster.local` first. From another namespace, `csharp-api.l04` is enough.
- `ndots:5` means that a name with fewer than five dots goes through the search list before being tried as is. `api.github.com` has two, so a pod first asks for `api.github.com.l04.svc.cluster.local` and two other names that don't exist. A trailing dot, as in the `nslookup` above, marks a name as complete and skips the list.

The [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) page lists the records; [Debugging DNS resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/) is the page to open when names don't resolve.

## EndpointSlices: which pods, and are they ready?

The Service's selector is evaluated by the EndpointSlice controller, which writes the matching pods' addresses into [**EndpointSlices**](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/). kube-proxy reads those, not the pods.

```text
> kubectl get -n l04 endpointslices
NAME                     ADDRESSTYPE   PORTS   ENDPOINTS                                AGE
csharp-api-<slice>         IPv4          8080    10.244.0.241,10.244.0.239,10.244.0.240   3s
java-reactor-api-<slice>   IPv4          8080    10.244.0.243,10.244.0.244                3s
> kubectl get -n l04 endpoints csharp-api
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME         ENDPOINTS                                               AGE
csharp-api   10.244.0.239:8080,10.244.0.240:8080,10.244.0.241:8080   3s
```

Each slice name ends with five random characters, replaced here by `<slice>`. The older **Endpoints** object still exists, and kubectl warns: it held every address of a Service in one object, which didn't scale to thousands of pods, and has been [deprecated since 1.33](https://kubernetes.io/blog/2025/04/24/endpoints-deprecation/). Tutorials that still use `kubectl get endpoints` work, for now.

Readiness, from lesson 2, matters here. [`l04/unready.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/unready.yaml) adds a fourth pod with the label `app: csharp-api` and a readiness probe that always fails:

```text
> kubectl apply -n l04 -f l04/unready.yaml
pod/csharp-api-unready created
> kubectl get -n l04 endpointslices -l kubernetes.io/service-name=csharp-api -o jsonpath='{range .items[*].endpoints[*]}{.targetRef.name} ready={.conditions.ready}{"\n"}{end}' | sort
csharp-api-55b7fbb748-9rj4s ready=true
csharp-api-55b7fbb748-dn79k ready=true
csharp-api-55b7fbb748-zw7ph ready=true
csharp-api-unready ready=false
```

The selector matches it, so the slice lists it, marked `ready=false`. Thirty requests show that kube-proxy skips it:

```text
> kubectl exec -n l04 client -- sh -c 'for i in $(seq 30); do curl -s http://csharp-api/; echo; done' | …
3 pods answered 30 requests; csharp-api-unready answered 0
```

(The part after `|` counts the `machine` values; the full command is in `run.sh`.) This is also a trap: a Service selects **any** pod with its labels, including one from another Deployment, or one started by hand for debugging. Readiness protected the clients this time.

## NodePort

A **NodePort** Service also opens a port, from 30000 to 32767, on every node. [`l04/nodeport.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/nodeport.yaml) asks for 30080, which [`kind/cluster.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/kind/cluster.yaml) maps to `127.0.0.1:30080` on your machine with [`extraPortMappings`](https://kind.sigs.k8s.io/docs/user/configuration/#extra-port-mappings):

```yaml
spec:
  type: NodePort
  selector:
    app: csharp-api
  ports:
    - name: http
      port: 80
      targetPort: http
      nodePort: 30080
```

```text
> kubectl apply -n l04 -f l04/nodeport.yaml
service/csharp-api-nodeport created
> kubectl get -n l04 service csharp-api-nodeport
NAME                  TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
csharp-api-nodeport   NodePort   10.96.80.124   <none>        80:30080/TCP   1s
> curl -s http://localhost:30080/
{"app":"csharp-api","runtime":"<runtime>","os":"<os>","machine":"csharp-api-55b7fbb748-dn79k"}
```

The last `curl` runs on your machine, not in the cluster: on Windows, `curl.exe` in PowerShell. A NodePort Service is also a ClusterIP Service. It is the simplest way in, but the clients have to know node addresses and an unusual port; kind's port mapping must be declared when the cluster is created.

## LoadBalancer

A **LoadBalancer** Service asks the infrastructure for an external load balancer: on AKS, EKS or GKE, the cloud provider's controller creates one and writes its address into the Service. kind has no cloud, so the course runs [cloud-provider-kind](https://github.com/kubernetes-sigs/cloud-provider-kind) v0.11.1, which plays that role with one [Envoy](https://www.envoyproxy.io/) container per load balancer. [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/check.sh) starts it as a container on kind's Docker network, with access to Docker's socket to create those containers:

```bash
docker run -d --name learn-k8s-cloud-provider --network kind -v /var/run/docker.sock:/var/run/docker.sock \
  registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.11.1@sha256:40e18b9cd9c798cce40d39ff5c099a4f16a36c268d8e1dda469d73955a35e403
```

In Git Bash, set `MSYS_NO_PATHCONV=1` first, as `check.sh` does, or Git Bash rewrites `/var/run/docker.sock` into a Windows path; `/var/run/docker.sock` is the socket's path inside Docker Desktop's VM, not on Windows. Access to the Docker socket means control of Docker: run only an image you trust, pinned by digest as here.

```yaml
# Lesson 4: a LoadBalancer Service. In a cloud, the provider creates a load balancer; on kind, cloud-provider-kind does.
apiVersion: v1
kind: Service
metadata:
  name: java-reactor-api-lb
spec:
  type: LoadBalancer
  selector:
    app: java-reactor-api
  ports:
    - name: http
      port: 80
      targetPort: http
```

```text
> kubectl apply -n l04 -f l04/loadbalancer.yaml
service/java-reactor-api-lb created
> kubectl get -n l04 service java-reactor-api-lb
NAME                  TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
java-reactor-api-lb   LoadBalancer   10.96.155.58   172.23.0.4    80:<node-port>/TCP   1s
> kubectl exec -n l04 client -- curl -s http://172.23.0.4/
{"app":"java-reactor-api","runtime":"<runtime>","os":"<os>","machine":"java-reactor-api-64bd9f4b94-g8wnk"}
> docker ps --filter name=kindccm --format '{{.Names}} {{.Ports}}'
kindccm-86739d9686d6 0.0.0.0:80->80/tcp, 0.0.0.0:52142->10000/tcp, [::]:52142->10000/tcp
```

`EXTERNAL-IP` is the Envoy container's address on the `kind` network. A LoadBalancer Service is also a NodePort Service, on a port chosen at random, and so a ClusterIP Service: each type adds a way in.

On Linux, that address is reachable from the host. On Windows and macOS, Docker runs in a VM and it isn't: from Windows, `curl` to `172.23.0.4` timed out. cloud-provider-kind's [README](https://github.com/kubernetes-sigs/cloud-provider-kind/blob/4c9c37ce120814f597129ff708ab68bc0da4d147/README.md#L371-L385) describes the workaround it applies there, publishing the load balancer's port on the host. On the author's machine, the first load balancer got port 80 itself, as `docker ps` shows, and `curl http://localhost/` from Windows answered; the Gateway below got a random host port instead. Before relying on either, check `docker ps`, and note that port 80 on your machine may already be taken.

## One entry point: the Gateway API

With two APIs, two load balancers mean two addresses, and in a cloud, two bills. An HTTP router can send both host names to the right Service from one address. Kubernetes has two APIs for that. The newer one, the [**Gateway API**](https://gateway-api.sigs.k8s.io/), splits the job in three objects:

| Object | Who writes it | What it says |
|---|---|---|
| **GatewayClass** | the platform, with its controller | which implementation, like a StorageClass |
| **Gateway** | the cluster operator | an entry point: addresses, ports, protocols, TLS certificates |
| **HTTPRoute** | the application team | which requests go to which Service |

The Gateway API is not built into Kubernetes: its objects are [custom resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) (lesson 13) installed from its releases. cloud-provider-kind installed version 1.5.0 of the standard channel, and created a GatewayClass and an IngressClass:

```text
> kubectl get gatewayclass,ingressclass
NAME                                                         CONTROLLER                            ACCEPTED   AGE
gatewayclass.gateway.networking.k8s.io/cloud-provider-kind   kind.sigs.k8s.io/gateway-controller   True       32m

NAME                                                           CONTROLLER                            PARAMETERS   AGE
ingressclass.networking.k8s.io/cloud-provider-kind (default)   kind.sigs.k8s.io/ingress-controller   <none>       32m
```

[`l04/gateway.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/gateway.yaml) declares one Gateway and one route with a rule per host:

```yaml
# Lesson 4: one entry point for both APIs with the Gateway API, routed by host name.
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web
spec:
  # The class provided by cloud-provider-kind; a cloud or a gateway controller provides its own
  gatewayClassName: cloud-provider-kind
  listeners:
    - name: http
      protocol: HTTP
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: apis
spec:
  parentRefs:
    - name: web
  rules:
    - matches:
        - headers:
            - name: Host
              value: csharp.example.test
      backendRefs:
        - name: csharp-api
          port: 80
    - matches:
        - headers:
            - name: Host
              value: java.example.test
      backendRefs:
        - name: java-reactor-api
          port: 80
```

```text
> kubectl apply -n l04 -f l04/gateway.yaml
gateway.gateway.networking.k8s.io/web created
httproute.gateway.networking.k8s.io/apis created
> kubectl wait -n l04 --for=condition=Programmed gateway/web --timeout=120s
gateway.gateway.networking.k8s.io/web condition met
> kubectl get -n l04 gateway web
NAME   CLASS                 ADDRESS      PROGRAMMED   AGE
web    cloud-provider-kind   172.23.0.5   True         1s
> kubectl get -n l04 httproute apis -o jsonpath='{range .status.parents[*].conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
Accepted=True Accepted
ResolvedRefs=True ResolvedRefs
```

The statuses are the first thing to read when a route doesn't work: `Programmed` says the Gateway's controller has configured the proxy, `Accepted` that the Gateway took the route, and `ResolvedRefs` that the Services it names exist. Then one address serves both APIs:

```text
> kubectl exec -n l04 client -- curl -s -H "Host: csharp.example.test" http://172.23.0.5/
{"app":"csharp-api","runtime":"<runtime>","os":"<os>","machine":"csharp-api-55b7fbb748-zw7ph"}
> kubectl exec -n l04 client -- curl -s -H "Host: java.example.test" http://172.23.0.5/
{"app":"java-reactor-api","runtime":"<runtime>","os":"<os>","machine":"java-reactor-api-64bd9f4b94-g8wnk"}
> kubectl exec -n l04 client -- curl -s -o /dev/null -w '%{http_code} %header{server}\n' -H 'Host: other.example.test' http://172.23.0.5/
404 envoy
```

`-H "Host: …"` stands in for DNS records that would point both names at the Gateway. A host that no rule matches gets a 404 from Envoy itself, without reaching any pod.

## Ingress

[**Ingress**](https://kubernetes.io/docs/concepts/services-networking/ingress/) is the older API for the same job, one object with host and path rules. It is stable and still supported, but frozen: new features go to the Gateway API. Its most common controller, ingress-nginx, [was retired in March 2026](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/), and you will still meet it in existing clusters. [`l04/ingress.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/ingress.yaml):

```yaml
# Lesson 4: the older API for the same job as the Gateway. Without ingressClassName, the default IngressClass applies:
# on kind, the one cloud-provider-kind creates.
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: apis
spec:
  rules:
    - host: csharp.example.test
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: csharp-api
                port:
                  name: http
    - host: java.example.test
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: java-reactor-api
                port:
                  name: http
```

```text
> kubectl apply -n l04 -f l04/ingress.yaml
ingress.networking.k8s.io/apis created
> kubectl get -n l04 ingress apis -o custom-columns=NAME:.metadata.name,CLASS:.spec.ingressClassName,HOSTS:.spec.rules[*].host,ADDRESS:.status.loadBalancer.ingress[0].ip
NAME   CLASS                 HOSTS                                   ADDRESS
apis   cloud-provider-kind   csharp.example.test,java.example.test   172.23.0.6
> kubectl get -n l04 gateways,httproutes
NAME                                                     CLASS                 ADDRESS      PROGRAMMED   AGE
gateway.gateway.networking.k8s.io/kind-ingress-gateway   cloud-provider-kind   172.23.0.6   True         2s
gateway.gateway.networking.k8s.io/web                    cloud-provider-kind   172.23.0.5   True         4s

NAME                                                  HOSTNAMES                 AGE
httproute.gateway.networking.k8s.io/apis                                        4s
httproute.gateway.networking.k8s.io/apis-57edfef398   ["java.example.test"]     2s
httproute.gateway.networking.k8s.io/apis-f45dc871d2   ["csharp.example.test"]   2s
> kubectl exec -n l04 client -- curl -s -H 'Host: java.example.test' http://172.23.0.6/
{"app":"java-reactor-api","runtime":"<runtime>","os":"<os>","machine":"java-reactor-api-64bd9f4b94-xkbjc"}
```

The class was filled in by the default IngressClass. cloud-provider-kind doesn't implement Ingress separately: it translates the Ingress into a Gateway of its own, `kind-ingress-gateway`, and one HTTPRoute per host. Those routes use the route's `hostnames` field, the usual way to route by host, where `apis` matched the `Host` header in its rules. The translation is a fair summary of the relationship between the two APIs, and the [ingress2gateway](https://github.com/kubernetes-sigs/ingress2gateway) tool does the same for migrations.

## Which one?

| Need | Use |
|---|---|
| Pods calling each other inside the cluster | ClusterIP, by DNS name |
| A quick look from your machine | `kubectl port-forward`, or a NodePort on a local cluster |
| One TCP or UDP service exposed outside | LoadBalancer |
| HTTP routing by host or path, TLS, several services behind one address | Gateway API (Ingress in existing clusters) |

```text
> kubectl delete namespace l04 --wait=true
namespace "l04" deleted
```

## Key takeaways

- A Service gives pods a stable name and virtual IP, and chooses them by label at every moment; its `targetPort` can name the pods' port.
- CoreDNS resolves `name`, `name.namespace` and `name.namespace.svc.cluster.local`; `ndots:5` makes external names go through the search list first.
- EndpointSlices list the pods behind a Service with their readiness, and kube-proxy sends traffic only to ready ones; the Endpoints API is deprecated.
- NodePort adds a port on every node, and LoadBalancer adds an external address from the infrastructure; on kind, cloud-provider-kind provides it, and on Windows and macOS the address is reached through a port published on the host.
- The Gateway API splits routing into GatewayClass, Gateway and HTTPRoute, and reports each step in their statuses; Ingress does the same job in one frozen API.

## Exercises

**1.** A Service with `clusterIP: None` is **headless**. Create one for the C# API ([`l04/headless.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/headless.yaml)) while `csharp-api-unready` is running, and resolve its name. What do you get, and what is missing?

<details>
<summary>Solution</summary>

```text
> kubectl apply -n l04 -f l04/headless.yaml
service/csharp-api-headless created
> kubectl get -n l04 service csharp-api-headless
NAME                  TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
csharp-api-headless   ClusterIP   None         <none>        80/TCP    1s
> kubectl exec -n l04 client -- nslookup -type=a csharp-api-headless.l04.svc.cluster.local.
Server:		10.96.0.10
Address:	10.96.0.10:53

Name:	csharp-api-headless.l04.svc.cluster.local
Address: 10.244.0.241
Name:	csharp-api-headless.l04.svc.cluster.local
Address: 10.244.0.239
Name:	csharp-api-headless.l04.svc.cluster.local
Address: 10.244.0.240

> kubectl get -n l04 pods -l app=csharp-api -o custom-columns='NAME:.metadata.name,IP:.status.podIP,READY:.status.conditions[?(@.type=="Ready")].status' --sort-by=.metadata.name
NAME                          IP             READY
csharp-api-55b7fbb748-9rj4s   10.244.0.239   True
csharp-api-55b7fbb748-dn79k   10.244.0.241   True
csharp-api-55b7fbb748-zw7ph   10.244.0.240   True
csharp-api-unready            10.244.0.245   False
```

No virtual IP: the name resolves to the addresses of the ready pods themselves, and the client picks one. The unready pod's `10.244.0.245` is missing. [Headless Services](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) serve clients that want to see every instance, such as a database driver or a gRPC client balancing on its own, and give StatefulSet pods a stable DNS name each (lesson 6).

</details>

**2.** [`l04/wrong-selector.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/wrong-selector.yaml) has a typo in its selector: `app: csharp_api`. How does it fail, and how would you find the cause?

<details>
<summary>Solution</summary>

```text
> kubectl apply -n l04 -f l04/wrong-selector.yaml
service/csharp-api-typo created
> kubectl exec -n l04 client -- curl -sS -m 5 http://csharp-api-typo/
curl: (7) Failed to connect to csharp-api-typo:80 after 0 ms: Could not connect to server
command terminated with exit code 7
> kubectl get -n l04 endpointslices -l kubernetes.io/service-name=csharp-api-typo
NAME                    ADDRESSTYPE   PORTS     ENDPOINTS   AGE
csharp-api-typo-<slice>   IPv4          <unset>   <unset>     1s
```

The Service is created without complaint, its name resolves, and the connection is refused at once: kube-proxy rejects traffic to a Service without endpoints. An EndpointSlice with no endpoints is the sign. Compare the selector with the pods' labels, `kubectl get pods --show-labels`. The same symptom appears when every matching pod is unready.

</details>

**3.** Every cluster has a Service named `kubernetes` in the `default` namespace. What is behind it? Call it from the `client` pod, in `l04`.

<details>
<summary>Solution</summary>

```text
> kubectl get -n default service kubernetes
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   9h
> kubectl exec -n l04 client -- curl -sk https://kubernetes.default/version
{
  "major": "1",
  "minor": "37",
  "emulationMajor": "1",
  "emulationMinor": "37",
  "minCompatibilityMajor": "1",
  "minCompatibilityMinor": "36",
  "gitVersion": "v1.37.0",
  "gitCommit": "f54c212e3a2f75d674b717a9b29052b20b60aefc",
  "gitTreeState": "clean",
  "buildDate": "2026-08-26T10:44:25Z",
  "goVersion": "go1.26.6",
  "compiler": "gc",
  "platform": "linux/amd64"
}
```

The API server. `kubernetes.default` is a name in another namespace, completed by the search list. `/version` is readable without credentials; `-k` skips the certificate check, which a real client does with the cluster's CA certificate, mounted by default in every pod with its service account token. This is how controllers and operators running in pods reach the API (lesson 10 gives them permissions).

</details>

## Sources

- Kubernetes documentation: [Service](https://kubernetes.io/docs/concepts/services-networking/service/), [Virtual IPs and service proxies](https://kubernetes.io/docs/reference/networking/virtual-ips/), [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/), [Debugging DNS resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/), [EndpointSlices](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/), [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/), [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/)
- Kubernetes blog: [Endpoints deprecation](https://kubernetes.io/blog/2025/04/24/endpoints-deprecation/), [Ingress NGINX retirement](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)
- [Gateway API](https://gateway-api.sigs.k8s.io/), [ingress2gateway](https://github.com/kubernetes-sigs/ingress2gateway)
- kind: [LoadBalancer](https://kind.sigs.k8s.io/docs/user/loadbalancer/), [Ingress](https://kind.sigs.k8s.io/docs/user/ingress/), [extra port mappings](https://kind.sigs.k8s.io/docs/user/configuration/#extra-port-mappings); [cloud-provider-kind README at v0.11.1](https://github.com/kubernetes-sigs/cloud-provider-kind/blob/4c9c37ce120814f597129ff708ab68bc0da4d147/README.md)
