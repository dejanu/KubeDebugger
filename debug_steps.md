## Debuging containers in PODs

### Standard way:

* To get a SHELL in the container:
```bash
# CONTAINER_NAME is optional if the Pod contains a single container
# short version for flags: -it, --stdin=false: Pass stdin to the container / --tty=false: Stdin is a TTY
kubectl exec --stdin --tty POD_NAME -c CONTAINER_NAME -- /bin/bash
```
* To Exec a binary from the container:
```bash
# run a individual command in the container
kubect exec POD_NAME -- ls
```
    
⚠️ if the specific binary was not baked into the container's image, most probably you'll get:

```
    error: Internal error occurred: error executing command in container: failed to exec in container: failed to start exec "58984e616235...": OCI runtime exec failed: exec failed: unable to start container process: exec: "BINARY": executable file not found in $PATH: unknown
```

---

### Fancy way

* If you don't have the desired binaries or shell in the container, you can add a **debugging container**:

```bash
# starting a debug contaiener based on a image that has bash
kubectl debug pods/POD_NAME --image IMAGE_NAME -it --target CONTAINER_NAME -- bash
```