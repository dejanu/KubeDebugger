#!/usr/bin/env bash

##################################################################################################
# This script is used to inspect the resource status of a pod in a given namespace.              #
# The script lists all the pods in the selected namespace and their QOS class.                   #
##################################################################################################

export GREP_COLORS='ms=01;32'

# read namespaces
printf "\n Available namespaces are:\n $(kubectl get ns -o=custom-columns=NAMESPACES:.metadata.name) \n\t"
printf "\n Please write the name of the namespace for which you want to know the resource status:\n"
read -r nspace

# list all pods and QOS for the selected namespace
printf "\n \e[0;32m Pods in ${nspace} namespace: \e[0m \n"
for pod in $(kubectl -n "${nspace}" get po -o=name); do
    qos=$(kubectl -n "${nspace}" get "${pod}" -o jsonpath='{.status.qosClass}')
    # if qos is BestEffort print No else yes
    if [ "${qos}" == "BestEffort" ]; then
        printf "\n  ${pod} --> QoS class: ${qos} 🔥 \n"
    else
        printf "\n  ${pod} --> QoS class: ${qos} \n"
    fi
done

# read stding and print message awaiting user input
printf "\n Press ANY key to continue: \n"

read -r answer
printf "\n   QoS  Guaranteed:\e[0;32m Every Container in the Pod must have a limit and a request. For every container LIMIT = REQUEST \e[0m \n"
printf "\n   QoS  Burstable:\e[0;32m  At least one Container in the Pod has a Memory or CPU request or limit. \e[0m \n"
printf "\n   QoS 🔥BestEffort:\e[0;32m Containers in the Pod must not have any Memory or CPU limits or requests \e[0m \n"
echo "---------------------------------------------------------------------------------------------------------------------"
printf "\n   ⚠️ The kubelet prefers to evict BestEffort pods if the node comes under resource pressure. \n"
echo "---------------------------------------------------------------------------------------------------------------------"

# list resources values and usage for the selected pod
printf "\n Please write the name of the POD for which you want to know the resource status:\n\n"
read -r ppod
printf "\n \e[0;32m Containers in \e[0m "${ppod}" \e[0;32m with limits and Requests: \e[0m \n"
kubectl -n "${nspace}" get po "${ppod}" -o jsonpath='{.spec.containers[*].name}'
kubectl -n "${nspace}" get po "${ppod}" -o jsonpath='{.spec.containers[*].resources}' | jq .
printf "\n \e[0;32m Container usage for in \e[0m "${ppod}" POD: \e[0m \n"
kubectl -n "${nspace}" top po "${ppod}" --containers=true

# # list containers in the selected pod
# printf "\n\t\t\t\t \e[0;32m WHY ARE WE SEEING THIS 🤔 ... why \e[0m \n"
# read -r answer
# if [ "${answer}" == "why" ]; then
#     # printf "\e[4mContainers in POD 👇 \e[24m"
#     printf "\n\t\t\t\t \e[0;32m Containers in POD 😲: \e[0m"
#     kubectl -n "${nspace}" get po "${ppod}" -o jsonpath='{.spec.containers[*].name}'
#     printf "\n\t\t\t\t \e[0;32m ------------------- \e[0m \n\n"
# else
#     printf "\n \e[0;32m Exiting... \e[0m \n"
#     exit 1
# fi