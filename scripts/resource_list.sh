#!/usr/bin/env bash

# Usage: ./resource_list.sh <namespace>
# Purpose: list resources for all containers in ns

nspace=$1
for pod in $(kubectl -n "${nspace}" get po -oname); do
    kubectl -n $nspace get $pod -o=jsonpath='{range .spec.containers[*]}{"Container: "}{.name}{"\nCPU Request: "}{.resources.requests.cpu}{"\nMemory Request: "}{.resources.requests.memory}{"\nCPU Limit: "}{.resources.limits.cpu}{"\nMemory Limit: "}{.resources.limits.memory}{"\n\n"}{end}'
done