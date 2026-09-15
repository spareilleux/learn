#!/usr/bin/env bash
# Lesson 3: Deployments and ReplicaSets, rolling updates, a failed rollout and a rollback, with the two course APIs.
L=l03
last() { kubectl rollout status -n $L "$1" --timeout="${2:-180s}" 2>&1 | tail -1; }
step ${L}_namespace kubectl create namespace $L

# The C# API, three replicas
step ${L}_apply_csharp kubectl apply -n $L -f l03/csharp-api.yaml
record ${L}_rollout_csharp_watch "kubectl rollout status -n $L deployment/csharp-api --timeout=180s"
step ${L}_rollout_csharp last deployment/csharp-api
step ${L}_get_all kubectl get -n $L deployment,rs,pods -l app=csharp-api
step ${L}_owners kubectl get -n $L rs,pods -l app=csharp-api -o custom-columns=KIND:.kind,NAME:.metadata.name,OWNER:.metadata.ownerReferences[0].kind,OWNER-NAME:.metadata.ownerReferences[0].name

# A rolling update: a new image tag changes the pod template
step ${L}_set_image kubectl set image -n $L deployment/csharp-api api=csharp-api:1.1
step ${L}_annotate kubectl annotate -n $L deployment/csharp-api kubernetes.io/change-cause="image csharp-api:1.1"
record ${L}_rollout_update_watch "kubectl rollout status -n $L deployment/csharp-api --timeout=180s"
step ${L}_rollout_update last deployment/csharp-api
step ${L}_rs_after_update kubectl get -n $L rs -l app=csharp-api
sh_step ${L}_update_events "kubectl get events -n $L --field-selector involvedObject.kind=Deployment,involvedObject.name=csharp-api -o custom-columns=REASON:.reason,MESSAGE:.message --sort-by=.metadata.creationTimestamp"

# A broken update: the tag doesn't exist on the node, and the rollout stops after progressDeadlineSeconds
step ${L}_set_bad_image kubectl set image -n $L deployment/csharp-api api=csharp-api:9.9
step ${L}_annotate_bad kubectl annotate -n $L deployment/csharp-api kubernetes.io/change-cause="image csharp-api:9.9, which doesn't exist"
# How many "Waiting�" lines come before the error depends on timing: keep the last line and the exit code
record ${L}_rollout_bad_watch "kubectl rollout status -n $L deployment/csharp-api --timeout=180s"
sh_step ${L}_rollout_bad "kubectl rollout status -n $L deployment/csharp-api --timeout=180s 2>&1 | tail -1; exit \${PIPESTATUS[0]}"
step ${L}_pods_bad kubectl get -n $L pods -l app=csharp-api --sort-by=.metadata.creationTimestamp
step ${L}_deploy_bad kubectl get -n $L deployment csharp-api
step ${L}_conditions_bad kubectl get -n $L deployment csharp-api -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
step ${L}_history kubectl rollout history -n $L deployment/csharp-api

# Back to the previous revision
step ${L}_undo kubectl rollout undo -n $L deployment/csharp-api
step ${L}_rollout_undo last deployment/csharp-api
step ${L}_history_after_undo kubectl rollout history -n $L deployment/csharp-api
step ${L}_image_after_undo kubectl get -n $L deployment csharp-api -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

# The Spring Boot API
step ${L}_apply_java kubectl apply -n $L -f l03/java-reactor-api.yaml
step ${L}_rollout_java last deployment/java-reactor-api
step ${L}_get_java kubectl get -n $L deployment java-reactor-api

# Exercise 1: back to revision 1 explicitly
step ${L}_ex1_undo_to kubectl rollout undo -n $L deployment/csharp-api --to-revision=1
step ${L}_ex1_rollout last deployment/csharp-api
step ${L}_ex1_image kubectl get -n $L deployment csharp-api -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
step ${L}_ex1_history kubectl rollout history -n $L deployment/csharp-api
# Exercise 2: the same image under another tag still makes a new ReplicaSet
step ${L}_ex2_images kubectl get -n $L rs -l app=csharp-api -o jsonpath='{range .items[*]}{.metadata.name} {.spec.template.spec.containers[0].image} replicas={.spec.replicas} revision={.metadata.annotations.deployment\.kubernetes\.io/revision}{"\n"}{end}'
# Exercise 3: a request that no node can satisfy
step ${L}_ex3_apply kubectl apply -n $L -f l03/too-big.yaml
wait_for 60 "kubectl get events -n $L --field-selector reason=FailedScheduling -o name | grep -q ."
step ${L}_ex3_pods kubectl get -n $L pods -l app=too-big
sh_step ${L}_ex3_events "kubectl get events -n $L --field-selector reason=FailedScheduling -o custom-columns=TYPE:.type,REASON:.reason,MESSAGE:.message --no-headers | sort -u"

step ${L}_cleanup kubectl delete namespace $L --wait=true
