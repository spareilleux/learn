#!/usr/bin/env bash
# Kubernetes course: runs each lesson's commands against the kind cluster learn-k8s and compares the outputs with
# expected/, after normalize() in lib.sh has replaced ages, generated names, IP addresses and ports.
# Create the cluster first: kind create cluster --config kind/cluster.yaml
# bash check.sh [l01 l02 …]  runs some lessons only; UPDATE=1 writes expected/ instead of comparing.
set -uo pipefail
cd "$(dirname "$0")"
K8S_DIR=$(pwd)
. ./lib.sh
echo "kind $(kind version 2>/dev/null), kubectl $(kubectl version --client -o json | grep -m1 gitVersion | tr -d ' ",')"
kubectl config use-context kind-learn-k8s > /dev/null || { echo "no kind-learn-k8s context"; exit 1; }
# Lesson 4 needs cloud-provider-kind (LoadBalancer, Ingress, Gateway API): it runs as a container on kind's network
if ! docker ps --format '{{.Names}}' | grep -qx learn-k8s-cloud-provider; then
  docker run -d --name learn-k8s-cloud-provider --network kind -v /var/run/docker.sock:/var/run/docker.sock \
    registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.11.1@sha256:40e18b9cd9c798cce40d39ff5c099a4f16a36c268d8e1dda469d73955a35e403 > /dev/null
fi
lessons=${*:-$(ls -d l[0-9][0-9] | tr '\n' ' ')}
for l in $lessons; do
  echo "== $l"
  . "$l/run.sh"
done
exit $status
