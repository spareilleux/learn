#!/usr/bin/env bash
# Lesson 2: a pod's lifecycle, its three kinds of probes, init and sidecar containers, and QoS classes.
L=l02
step ${L}_namespace kubectl create namespace $L

# A pod, its conditions, its logs and its events
step ${L}_apply_pod kubectl apply -n $L -f l02/pod.yaml
step ${L}_wait_ready kubectl wait -n $L --for=condition=Ready pod/csharp-api --timeout=120s
step ${L}_get_pod kubectl get pod -n $L csharp-api
step ${L}_conditions kubectl get pod -n $L csharp-api -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'
step ${L}_qos kubectl get pod -n $L csharp-api -o jsonpath='{.status.qosClass}{"\n"}'
step ${L}_logs kubectl logs -n $L csharp-api
# A readiness probe sent before Kestrel listens fails with "connection refused": whether it happens depends on timing
sh_step ${L}_events "kubectl get events -n $L --field-selector involvedObject.name=csharp-api,type=Normal -o custom-columns=TYPE:.type,REASON:.reason,MESSAGE:.message --sort-by=.metadata.creationTimestamp"

# Liveness probe on a missing path: the kubelet restarts the container
step ${L}_apply_liveness kubectl apply -n $L -f l02/liveness-fail.yaml
wait_for 120 "[ \$(kubectl get pod -n $L liveness-fail -o jsonpath='{.status.containerStatuses[0].restartCount}') -ge 1 ]"
sh_step ${L}_liveness_restarted "echo restartCount at least 1: \$([ \$(kubectl get pod -n $L liveness-fail -o jsonpath='{.status.containerStatuses[0].restartCount}') -ge 1 ] && echo yes || echo no)"
# The kubelet stops the container with SIGTERM: ASP.NET Core shuts down cleanly, so the restart looks like a normal exit
step ${L}_liveness_last_state kubectl get pod -n $L liveness-fail -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason} {.status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'
record ${L}_liveness_get "kubectl get pod -n $L liveness-fail"
sh_step ${L}_liveness_events "kubectl get events -n $L --field-selector involvedObject.name=liveness-fail,type=Warning -o custom-columns=TYPE:.type,REASON:.reason,MESSAGE:.message --no-headers | grep -v 'connection refused' | sort -u; kubectl get events -n $L --field-selector involvedObject.name=liveness-fail,reason=Killing -o custom-columns=TYPE:.type,REASON:.reason,MESSAGE:.message --no-headers | sort -u"

# Readiness probe on a missing path: Running, never Ready, never restarted
step ${L}_apply_readiness kubectl apply -n $L -f l02/readiness-fail.yaml
wait_for 120 "kubectl get events -n $L --field-selector involvedObject.name=readiness-fail,reason=Unhealthy -o name | grep -q ."
step ${L}_readiness_get kubectl get pod -n $L readiness-fail
step ${L}_readiness_conditions kubectl get pod -n $L readiness-fail -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'
sh_step ${L}_readiness_events "kubectl get events -n $L --field-selector involvedObject.name=readiness-fail,type=Warning -o custom-columns=TYPE:.type,REASON:.reason,MESSAGE:.message --no-headers | grep -v 'connection refused' | sort -u"

# Startup probe: the Spring Boot API is given time to start before liveness checks begin
step ${L}_apply_startup kubectl apply -n $L -f l02/startup.yaml
step ${L}_startup_ready kubectl wait -n $L --for=condition=Ready pod/java-reactor-api --timeout=180s
step ${L}_startup_get kubectl get pod -n $L java-reactor-api
record ${L}_startup_events "kubectl get events -n $L --field-selector involvedObject.name=java-reactor-api -o custom-columns=TYPE:.type,REASON:.reason,COUNT:.count,MESSAGE:.message --sort-by=.metadata.creationTimestamp; kubectl get pod -n $L java-reactor-api -o jsonpath='started {.status.containerStatuses[0].state.running.startedAt}, ready {.status.conditions[?(@.type==\"Ready\")].lastTransitionTime}{\"\n\"}'"

# Init container, then a native sidecar next to the app
step ${L}_apply_init_sidecar kubectl apply -n $L -f l02/init-sidecar.yaml
step ${L}_init_sidecar_ready kubectl wait -n $L --for=condition=Ready pod/init-sidecar --timeout=120s
wait_for 30 "[ \$(kubectl logs -n $L init-sidecar -c log-shipper | wc -l) -ge 3 ]"
step ${L}_init_sidecar_get kubectl get pod -n $L init-sidecar
step ${L}_init_sidecar_statuses kubectl get pod -n $L init-sidecar -o jsonpath='{range .status.initContainerStatuses[*]}{.name}: started={.started} ready={.ready} terminated={.state.terminated.reason}{"\n"}{end}{range .status.containerStatuses[*]}{.name}: started={.started} ready={.ready}{"\n"}{end}'
step ${L}_setup_logs kubectl logs -n $L init-sidecar -c setup
sh_step ${L}_sidecar_logs "kubectl logs -n $L init-sidecar -c log-shipper | head -3"

# QoS classes
step ${L}_apply_qos kubectl apply -n $L -f l02/qos.yaml
step ${L}_qos_classes kubectl get pods -n $L guaranteed burstable besteffort -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass

# Exercise 1: the Guaranteed class
step ${L}_ex1_apply kubectl apply -n $L -f l02/pod-guaranteed.yaml
step ${L}_ex1_qos kubectl get pod -n $L csharp-api-guaranteed -o jsonpath='{.status.qosClass}{"\n"}'
# Exercise 2: a memory limit too small
step ${L}_ex2_apply kubectl apply -n $L -f l02/oom.yaml
wait_for 60 "kubectl get pod -n $L oom -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}' | grep -q OOMKilled"
step ${L}_ex2_last_state kubectl get pod -n $L oom -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason} {.status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'
record ${L}_ex2_get "kubectl get pod -n $L oom"
# Exercise 3: a failing init container
step ${L}_ex3_apply kubectl apply -n $L -f l02/init-fail.yaml
wait_for 60 "[ \$(kubectl get pod -n $L init-fail -o jsonpath='{.status.initContainerStatuses[0].restartCount}') -ge 1 ]"
step ${L}_ex3_statuses kubectl get pod -n $L init-fail -o jsonpath='setup: exit code {.status.initContainerStatuses[0].lastState.terminated.exitCode}{"\n"}app: {.status.containerStatuses[0].state.waiting.reason}{"\n"}'
step ${L}_ex3_logs kubectl logs -n $L init-fail -c setup
record ${L}_ex3_get "kubectl get pod -n $L init-fail"

step ${L}_cleanup kubectl delete namespace $L --wait=true
