#!/usr/bin/env bash

#############################################################
# Purpose: wrapper for inspecting Requests/Limits for Pods ##
# @dejanualex                                              ##
#############################################################

## set grep color to yellow or green
# export GREP_COLORS='ms=01;33'
export GREP_COLORS='ms=01;32'

# Options for inspecting resource usage
echo -e "\n Please select desired resource to inspect:\n 1. CPU[millicores] \n 2. Memory[bytes] \n\n"
read -r option
# if option is 1 set resource variable to CPU
if [ "${option}" == "1" ]; then
    resource="cpu"
# if option is 2, set resource variable to CPU
elif [ "${option}" == "2" ]; then
    resource="memory"
else
    echo -e "\e[0;31m Please select a valid option \e[0m"
    exit 1
fi

### NODE LEVEL
echo -e "\n Sorted NODES by "${resource}" :\n $(kubectl top node --sort-by="${resource}") \n"

# get node names $(kubectl get nodes -o=custom-columns=NODES:.metadata.name)
# highlight node in list: kubectl top node --sort-by="${resource}" | egrep --color "${node}|

# check current usage at the Node level and display the Pods running on the selected Node
printf "\n Please write the name of the node for which you want to know the resource status:\n"
read -r node
printf "\e[0;32m Pods running on node "${node}" \e[0m \n"
kubectl get po -A --field-selector spec.nodeName="${node}"

### NAMESPACE LEVEL
# read namespace and pod name
printf "\n Available namespaces are:\n $(kubectl get ns -o=custom-columns=NAMESPACES:.metadata.name) \n\t"
printf "\n Please write the name of the namespace for which you want to know the resource status:\n\n"
read -r nspace

# most resource expensive PODS
printf "\n \e[0;32m Most ${resource}  expensive PODS in ${nspace} namespace: \e[0m \n\n"
kubectl top po -n "${nspace}" --sort-by="${resource}"
# most resource expensive CONTAINERS
printf "\n \e[0;32m Most ${resource} expensive CONTAINERS in ${nspace} namespace: \e[0m \n\n"
kubectl top po -n "${nspace}" --containers=true --sort-by="${resource}"

### POD LEVEL
printf "\n Please select a POD from namespace:\n $(kubectl -n "${nspace}" get po -o=custom-columns=POD:.metadata.name) \e[0m \n\n"
read -r ppod
## check Limits and Requests for Containers in Pod and current usage
printf "\n \e[0;32m Containers in POD:\e[0m"
kubectl -n "${nspace}" get po "${ppod}" -o jsonpath='{.spec.containers[*].name}'
printf "\n \e[0;32m Limits and Request per CONTAINER:\e[0m \n"
kubectl -n "${nspace}" get po "${ppod}" -o jsonpath='{.spec.containers[*].resources}'|jq .
printf "\n \e[0;32m Current resource usage:\e[0m \n"
kubectl -n "${nspace}" top po "${ppod}" --containers