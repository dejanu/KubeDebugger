#!/usr/bin/env bash
# Purpose: wrapper for inspecting Requests/Limits for Pods

# read namespaces
printf "\n Available namespaces are:\n $(kubectl get ns -o=custom-columns=NAMESPACES:.metadata.name) \n\t"
printf "\n Please write the name of the namespace for which you want to know the resource status:\n"
read -r nspace

# list all pods from the selected namespace
printf "\n \e[0;32m Pods in ${nspace} namespace: \e[0m \n"
kubectl -n "${nspace}" get po -o=custom-columns=PODs:.metadata.name

# list resources for the selected pod
printf "\n Please write the name of the POD for which you want to know the resource status:\n\n"
read -r ppod
printf "\n \e[0;32m Limits and Requests for selected POD: \e[0m \n"
kubectl -n "${nspace}" get po "${ppod}" -o jsonpath='{.spec.containers[*].resources}' | jq .

# list containers in the selected pod
printf "\n\t\t\t\t \e[0;32m WHY ARE WE SEEING THIS 🤔 \e[0m \n"
read -r answer
if [ "${answer}" == "why" ]; then
    # printf "\e[4mContainers in POD 👇 \e[24m"
    printf "\n\t\t\t\t \e[0;32m Containers in POD 😲: \e[0m"
    kubectl -n "${nspace}" get po "${ppod}" -o jsonpath='{.spec.containers[*].name}'
    printf "\n\t\t\t\t \e[0;32m ------------------- \e[0m \n\n"
else
    printf "\n \e[0;32m Exiting... \e[0m \n"
    exit 1
fi