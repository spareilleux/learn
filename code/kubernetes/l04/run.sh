#!/usr/bin/env bash
# Lesson 4: Services (ClusterIP, NodePort, LoadBalancer), DNS, EndpointSlices, Ingress and the Gateway API.
# LoadBalancer, Ingress and Gateway need cloud-provider-kind running next to the cluster (see check.sh).
L=l04
# The APIs report their runtime and OS versions, which differ between machines and image builds
api() { sed -E 's/"runtime":"[^"]*"/"runtime":"<runtime>"/; s/"os":"[^"]*"/"os":"<os>"/'; }
export -f api
in_client() { kubectl exec -n $L client -- "$@"; }
export L

step ${L}_namespace kubectl create namespace $L
sh_step ${L}_apply_apps "kubectl apply -n $L -f l03/csharp-api.yaml -f l03/java-reactor-api.yaml -f l04/client.yaml"
sh_step ${L}_rollout "kubectl rollout status -n $L deployment/csharp-api --timeout=180s | tail -1; kubectl rollout status -n $L deployment/java-reactor-api --timeout=180s | tail -1; kubectl wait -n $L --for=condition=Ready pod/client --timeout=120s"

# ClusterIP: a virtual IP and a DNS name
step ${L}_apply_services kubectl apply -n $L -f l04/services.yaml
step ${L}_get_services kubectl get -n $L services
# kube-proxy needs a moment to program a new Service's rules on the node
wait_for 60 "kubectl exec -n $L client -- curl -s -m 2 http://csharp-api/ | grep -q csharp-api"
wait_for 60 "kubectl exec -n $L client -- curl -s -m 2 http://java-reactor-api/ | grep -q java-reactor-api"
sh_step ${L}_curl_csharp "kubectl exec -n $L client -- curl -s http://csharp-api/ | api; echo"
sh_step ${L}_curl_java "kubectl exec -n $L client -- curl -s http://java-reactor-api/ | api; echo"
sh_step ${L}_curl_fqdn "kubectl exec -n $L client -- curl -s http://csharp-api.$L.svc.cluster.local/ | api; echo"
step ${L}_resolv_conf kubectl exec -n $L client -- cat /etc/resolv.conf
step ${L}_nslookup kubectl exec -n $L client -- nslookup csharp-api.$L.svc.cluster.local.

# EndpointSlices: the pods behind the Service, and their readiness
# EndpointSlice names end with five random characters
sh_step ${L}_endpointslices "kubectl get -n $L endpointslices | sed -E 's/^(csharp-api|java-reactor-api)-[a-z0-9]{5} /\1-<slice> /'"
step ${L}_endpoints_deprecated kubectl get -n $L endpoints csharp-api
step ${L}_apply_unready kubectl apply -n $L -f l04/unready.yaml
wait_for 60 "kubectl get -n $L endpointslices -l kubernetes.io/service-name=csharp-api -o jsonpath='{.items[*].endpoints[*].targetRef.name}' | grep -q csharp-api-unready"
sh_step ${L}_endpoint_conditions "kubectl get -n $L endpointslices -l kubernetes.io/service-name=csharp-api -o jsonpath='{range .items[*].endpoints[*]}{.targetRef.name} ready={.conditions.ready}{\"\n\"}{end}' | sort"
# 30 requests: which pods answer?
sh_step ${L}_spread "kubectl exec -n $L client -- sh -c 'for i in \$(seq 30); do curl -s http://csharp-api/; echo; done' | sed -E 's/.*\"machine\":\"([^\"]*)\".*/\1/' | sort | uniq -c | awk '{ n++; if (\$2 == \"csharp-api-unready\") u = \$1 } END { print n \" pods answered 30 requests; csharp-api-unready answered \" (u + 0) }'"

# NodePort: port 30080 of the node, mapped to localhost:30080 by kind/cluster.yaml
step ${L}_apply_nodeport kubectl apply -n $L -f l04/nodeport.yaml
step ${L}_get_nodeport kubectl get -n $L service csharp-api-nodeport
wait_for 30 "curl -s http://localhost:30080/ | grep -q csharp-api"
sh_step ${L}_curl_nodeport "curl -s http://localhost:30080/ | api; echo"

# LoadBalancer: cloud-provider-kind starts a load balancer container and writes its IP into the Service's status
step ${L}_apply_lb kubectl apply -n $L -f l04/loadbalancer.yaml
wait_for 90 "[ -n \"\$(kubectl get -n $L service java-reactor-api-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')\" ]"
# The node port behind a LoadBalancer Service is chosen at random in 30000-32767
sh_step ${L}_get_lb "kubectl get -n $L service java-reactor-api-lb | sed -E 's#80:[0-9]+/TCP#80:<node-port>/TCP#'"
lb=$(kubectl get -n $L service java-reactor-api-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
wait_for 60 "kubectl exec -n $L client -- curl -s -m 2 http://$lb/ | grep -q java-reactor-api"
sh_step ${L}_curl_lb "kubectl exec -n $L client -- curl -s http://$lb/ | api; echo"
record ${L}_lb_containers "docker ps --filter name=kindccm --format '{{.Names}} {{.Ports}}'"

# Gateway API: one Gateway, one HTTPRoute, routed by host name
step ${L}_apply_gateway kubectl apply -n $L -f l04/gateway.yaml
step ${L}_gateway_programmed kubectl wait -n $L --for=condition=Programmed gateway/web --timeout=120s
step ${L}_get_gateway kubectl get -n $L gateway web
step ${L}_route_status kubectl get -n $L httproute apis -o jsonpath='{range .status.parents[*].conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
gw=$(kubectl get -n $L gateway web -o jsonpath='{.status.addresses[0].value}')
wait_for 60 "kubectl exec -n $L client -- curl -s -m 2 -H 'Host: csharp.example.test' http://$gw/ | grep -q csharp-api"
sh_step ${L}_curl_gateway "for h in csharp.example.test java.example.test; do kubectl exec -n $L client -- curl -s -H \"Host: \$h\" http://$gw/ | api; echo; done"
sh_step ${L}_curl_gateway_unknown "kubectl exec -n $L client -- curl -s -o /dev/null -w '%{http_code} %header{server}\n' -H 'Host: other.example.test' http://$gw/"

# Ingress: cloud-provider-kind translates it into a Gateway and HTTPRoutes of its own
step ${L}_apply_ingress kubectl apply -n $L -f l04/ingress.yaml
wait_for 120 "[ -n \"\$(kubectl get -n $L ingress apis -o jsonpath='{.status.loadBalancer.ingress[0].ip}')\" ]"
step ${L}_get_ingress kubectl get -n $L ingress apis -o custom-columns=NAME:.metadata.name,CLASS:.spec.ingressClassName,HOSTS:.spec.rules[*].host,ADDRESS:.status.loadBalancer.ingress[0].ip
step ${L}_ingress_translated kubectl get -n $L gateways,httproutes
ing=$(kubectl get -n $L ingress apis -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
wait_for 60 "kubectl exec -n $L client -- curl -s -m 2 -H 'Host: java.example.test' http://$ing/ | grep -q java-reactor-api"
sh_step ${L}_curl_ingress "kubectl exec -n $L client -- curl -s -H 'Host: java.example.test' http://$ing/ | api; echo"

# Exercise 1: a headless Service resolves to the ready pods' own addresses
step ${L}_ex1_apply kubectl apply -n $L -f l04/headless.yaml
wait_for 60 "[ \$(kubectl exec -n $L client -- nslookup -type=a csharp-api-headless.$L.svc.cluster.local. 2>/dev/null | grep -c '^Address: ') -eq 3 ]"
step ${L}_ex1_get kubectl get -n $L service csharp-api-headless
# nslookup lists the addresses in any order
record ${L}_ex1_nslookup "kubectl exec -n $L client -- nslookup -type=a csharp-api-headless.$L.svc.cluster.local."
sh_step ${L}_ex1_addresses "kubectl exec -n $L client -- nslookup -type=a csharp-api-headless.$L.svc.cluster.local. | grep '^Address: ' | sort"
sh_step ${L}_ex1_pods "kubectl get -n $L pods -l app=csharp-api -o custom-columns='NAME:.metadata.name,IP:.status.podIP,READY:.status.conditions[?(@.type==\"Ready\")].status' --sort-by=.metadata.name"
# Exercise 2: a selector that matches nothing leaves the Service without endpoints
step ${L}_ex2_apply kubectl apply -n $L -f l04/wrong-selector.yaml
wait_for 30 "kubectl get -n $L endpointslices -l kubernetes.io/service-name=csharp-api-typo -o name | grep -q ."
sh_step ${L}_ex2_endpointslices "kubectl get -n $L endpointslices -l kubernetes.io/service-name=csharp-api-typo | sed -E 's/^csharp-api-typo-[a-z0-9]{5} /csharp-api-typo-<slice> /'"
step ${L}_ex2_curl kubectl exec -n $L client -- curl -sS -m 5 http://csharp-api-typo/
# Exercise 3: the API server's own Service, from another namespace
step ${L}_ex3_get kubectl get -n default service kubernetes
sh_step ${L}_ex3_curl "kubectl exec -n $L client -- curl -sk https://kubernetes.default/version; echo"

step ${L}_cleanup kubectl delete namespace $L --wait=true
