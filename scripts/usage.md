## Intro
There are two types of resources: CPU (measured in CPU units, `m` which stands for a thousandth of a core) and Memory (measured in bytes),
  the mechanisms through which Kubernetes controls resources such as CPU and Memory are **requests** and **limits**.

Requests and limits are on a per-container basis:

  * requests are what the container is guaranteed to get (Kubernetes will only schedule it on a node that can give it that resource).
  * limits are what the container is allowed to use, and it is restricted to go above limits.

## Scripts usage

Check resources Limits and Requests and QoS for selected Pod :`./pod_resource_inspector.sh`
Sorted view of nodes and pods resource consumption based on a selected resource (cpu/memory) :`./cluster_resource_inspector.sh `
