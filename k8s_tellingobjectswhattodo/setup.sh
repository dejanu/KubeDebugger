#!/usr/bin/env bash

# bash-completion
#source <(kubectl completion bash)
source ~/.kube/kubectl_autocompletion

# add KREW to path
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# add my plugins to path
export PATH="$PATH:../plugins"

# change PS1 to show current context of pwd without absolute path
result=${PWD##*/}          # to assign to a variable
#result=${result:-/}        # to correct for the case where PWD=/
#printf '%s\n' "${PWD##*/}"

export PS1='🔥 ${PWD##*/}: '
