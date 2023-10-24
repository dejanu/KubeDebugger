## Plugins

* Commands that are not normally part of `kubectl` can be added as plugins

### Extend `kubectl` functionality

* prefix your script e.g. `kubectl-scriptname`
* add the script dir to path: 
```bash 
export PATH=`pwd`:"$PATH"
```
* check available plugins: `kubectl plugin list`

### Manage plugins

* Plugin index [krew](https://krew.sigs.k8s.io/plugins/), installation guide [here](https://krew.sigs.k8s.io/docs/user-guide/setup/install/#bash)

### PLugin execution (POSIX)

```mermaid
flowchart LR;

A[kubectl] -->|execve(2) syscall| B(kubectl-foo)
```