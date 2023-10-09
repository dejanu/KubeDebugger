## Plugins

### Extend `kubectl` functionality

* prefix your script e.g. `kubectl-scriptname`
* add the script dir to path: 
```bash 
export PATH=`pwd`:"$PATH"
```
* check available plugins: `kubectl plugin list`

### Manage plugins

* Plugin index [krew](https://krew.sigs.k8s.io/plugins/)