#!/usr/bin/env bash
# Kubernetes course: validates every manifest of the lessons against the Kubernetes 1.37.0 JSON schemas, without a
# cluster. Runs on Windows, Linux and macOS. The schemas are pinned on a commit of yannh/kubernetes-json-schema, and the
# Gateway API ones on a commit of datreeio/CRDs-catalog.
set -euo pipefail
cd "$(dirname "$0")"
k8s='https://raw.githubusercontent.com/yannh/kubernetes-json-schema/1360e239a56dcf2e5c7f99e61ccbaca1ea07036a/{{.NormalizedKubernetesVersion}}-standalone{{.StrictSuffix}}/{{.ResourceKind}}{{.KindSuffix}}.json'
crds='https://raw.githubusercontent.com/datreeio/CRDs-catalog/ad3b08c5045129d7bb1eeffd8e61719b2c8dd1e2/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
kubeconform -v
# kind/cluster.yaml configures kind itself, not the cluster: it has no schema here
kubeconform -kubernetes-version 1.37.0 -strict -summary -output text \
  -schema-location "$k8s" -schema-location "$crds" \
  $(ls l[0-9][0-9]/*.yaml | grep -v -- -invalid.yaml)
# Files named *-invalid.yaml hold a mistake a lesson shows: each one must fail
for f in l[0-9][0-9]/*-invalid.yaml; do
  if kubeconform -kubernetes-version 1.37.0 -strict -schema-location "$k8s" -schema-location "$crds" "$f"; then
    echo "$f should be invalid"
    exit 1
  fi
done
