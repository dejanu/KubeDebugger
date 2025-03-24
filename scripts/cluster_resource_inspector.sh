#!/usr/bin/env bash

##############################################################
# Purpose: wrapper for inspecting cluster resource usage    ##
#  Node and Namespace level                                 ##
# author: @dejanualex                                       ##
##############################################################

## set grep color to yellow or green
# export GREP_COLORS='ms=01;33'
export GREP_COLORS='ms=01;32'

printf "\e[0;32mCapacity:\e[0m total amount of resources \n"
printf "\e[0;32mReserved:\e[0m resources reserved for kubelet, container-runtime, system daemons \n"
printf "\e[0;32mAllocatable:\e[0m (Capacity - Reserved) \n"
printf "\e[0;32mRequested (Allocated):\e[0m amount of resources requested by pods \n"
printf "\e[0;33mAVAILABLE = (CAPACITY - RESERVED) - REQUESTED\e[0m \n"
echo -e "----------------------------------------------------- \n"

printf "\e[0;32mAllocatable\e[0m resources for each node: \n"
kubectl get nodes -o custom-columns="NAME:.metadata.name,ALLOCATABLE_CPU:.status.allocatable.cpu,ALLOCATABLE_MEM:.status.allocatable.memory"
echo -e "----------------------------------------------------- \n"

printf "\e[0;32mRequested\e[0m resources for each node: \n"
for node in $(kubectl get nodes -o custom-columns="NAME:.metadata.name" | tail -n +2); do
  printf "Node: \e[0;33m%s\e[0m \n" "${node}"
  kubectl describe node "${node}" | grep -A 5 -E "Allocated resources"
  echo -e "----------------------------------------------------- \n"
done

# Options for inspecting resource usage
echo -e "Select desired resource to inspect:\n 1. CPU[millicores] \n 2. Memory[bytes] \n\n"
read -r option
if [ "${option}" == "1" ]; then
    resource="cpu"
elif [ "${option}" == "2" ]; then
    resource="memory"
else
    echo -e "\e[0;31m Please select a valid option: cpu or mem \e[0m"
    exit 1
fi

### NODE LEVEL
printf "\e[0;32mSorted NODES by %s consumption:\e[0m \n" "${resource}"
kubectl top node --sort-by="${resource}"

# check current usage at the Node level and display the Pods running on the selected Node
printf "Write the name of the node for which you want to know the resource status: \t"
read -r node
# kubectl top node --sort-by="${resource}" | egrep --color "${node}"
echo -e "----------------------------------------------------- \n"
printf "\e[0;32mPods running on node %s:\e[0m \n" "${node}"
kubectl get po -A --field-selector spec.nodeName="${node}" -o custom-columns="NAMESPACE:.metadata.namespace,POD:.metadata.name"

## NAMESPACE LEVEL
echo -e "----------------------------------------------------- \n"
printf "Do you want to inspect the resource usage at the NAMESPACE level? [y/n] \n"
read -r response
if [ "${response}" == "n" ]; then
    exit 0
elif [ "${response}" == "y" ]; then
    printf "Available namespaces are:\n $(kubectl get ns -o=custom-columns=NAMESPACES:.metadata.name) \n"
    printf "Please write the name of the namespace for which you want to know the resource status: \t"
    read -r nspace

    # most resource expensive PODS and CONTAINERS
    printf "\e[0;32mMost %s expensive PODS running in %s:\e[0m \n\n" "${resource}" "${nspace}"
    kubectl -n "${nspace}" top po --sort-by="${resource}"

    printf "\e[0;32mMost %s expensive CONTAINERS running on %s:\e[0m \n" "${resource}" "${nspace}"
    kubectl -n "${nspace}" top po --containers=true --sort-by="${resource}"
fi