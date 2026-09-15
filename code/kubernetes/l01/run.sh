#!/usr/bin/env bash
# Lesson 1: the cluster's parts, kubectl, and a reconciliation loop seen from outside.
L=l01
step ${L}_version kubectl version
step ${L}_get_nodes kubectl get nodes
step ${L}_kube_system kubectl get pods -n kube-system
step ${L}_static_pods docker exec learn-k8s-control-plane ls /etc/kubernetes/manifests
step ${L}_contexts kubectl config get-contexts
# -v=6 prints each HTTP request kubectl sends to the API server
sh_step ${L}_verbose "kubectl get nodes -v=6 2>&1 | grep round_trippers | sed -E 's/milliseconds=[0-9]+/milliseconds=<ms>/'"
step ${L}_explain kubectl explain pod.spec.restartPolicy
step ${L}_api_resources_apps kubectl api-resources --api-group=apps

# The API server validates without storing anything: unknown fields are rejected
step ${L}_dry_run_invalid kubectl apply --dry-run=server -f l01/hello-invalid.yaml
step ${L}_dry_run kubectl apply --dry-run=server -f l01/hello.yaml

# Each lesson works in its own namespace, deleted at the end with everything in it (events included)
step ${L}_namespace kubectl create namespace $L
step ${L}_apply kubectl apply -n $L -f l01/hello.yaml
# rollout status prints a varying number of "Waiting…" lines first: keep the last one
sh_step ${L}_rollout "kubectl rollout status -n $L deployment/hello --timeout=120s | tail -1"
step ${L}_get_rs_pods kubectl get -n $L rs,pods -l app=hello
# Only the changed lines: the rest of the diff holds temporary paths, timestamps and a uid
sh_step ${L}_diff "kubectl diff -n $L -f l01/hello-3-replicas.yaml | grep -E '^[-+] '"
before=$(kubectl get pods -n $L -l app=hello -o name | sort)
step ${L}_delete_pods kubectl delete pods -n $L -l app=hello --wait=true
sh_step ${L}_rollout_again "kubectl rollout status -n $L deployment/hello --timeout=120s | tail -1"
after=$(kubectl get pods -n $L -l app=hello -o name | sort)
kept=$(comm -12 <(echo "$before") <(echo "$after") | grep -c . )
step ${L}_replaced echo "pods before: $(echo $before | wc -w), after: $(echo $after | wc -w), kept: $kept"
step ${L}_events kubectl get events -n $L --field-selector involvedObject.kind=ReplicaSet -o custom-columns=REASON:.reason,MESSAGE:.message
# Exercise 1: an imperative change, then the file applied again
step ${L}_ex1_scale kubectl scale -n $L deployment/hello --replicas=4
sh_step ${L}_ex1_after_scale "kubectl rollout status -n $L deployment/hello --timeout=120s | tail -1; kubectl get -n $L deployment hello"
step ${L}_ex1_apply kubectl apply -n $L -f l01/hello.yaml
sh_step ${L}_ex1_after_apply "kubectl rollout status -n $L deployment/hello --timeout=120s | tail -1; kubectl get -n $L deployment hello"
# Exercise 2: the command line of the scheduler's static pod
sh_step ${L}_ex2_scheduler "kubectl get pod -n kube-system kube-scheduler-learn-k8s-control-plane -o jsonpath='{.spec.containers[0].image}{\"\n\"}{range .spec.containers[0].command[*]}{@}{\"\n\"}{end}'"
# Exercise 3: a default value, read from the API's own documentation
step ${L}_ex3_explain kubectl explain deployment.spec.strategy.rollingUpdate.maxSurge

step ${L}_cleanup kubectl delete namespace $L --wait=true
