## Plugins

* Commands that are not normally part of `kubectl` can be added as plugins

### Extend `kubectl` functionality

* prefix your script e.g. `kubectl-scriptname` and make it executable `chmod +x kubectl-scriptname`
* add the script dir to path: 
```bash 
export PATH=`pwd`:"$PATH"
```
* check available plugins:
```bash
# list local plugins
kubectl plugin list

# list plugins from krew index
kubectl krew list
```

* Install a plugin:
```bash
kubeclt crew install tree
# check the ownership relationship between objects
kubeclt tree <object>
```

### Manage plugins

* Plugin index [krew](https://krew.sigs.k8s.io/plugins/), installation guide [here](https://krew.sigs.k8s.io/docs/user-guide/setup/install/#bash)

### Plugin execution (POSIX)

```mermaid
graph LR;
A[kubectl] -->|execve(2) syscall| B(kubectl-foo)
```