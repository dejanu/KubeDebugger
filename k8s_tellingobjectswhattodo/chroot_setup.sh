#!/usr/bin/env bash

chr=$HOME/jail

mkdir -p $chr/{bin,lib,lib64}
cp -v /usr/bin/{bash,ls} $chr/bin

# check and copy dependecies for each bin in the chroot enc
ldd /bin/{bash,ls}

cp --parents {....}  $HOME/jail

# activate environment
sudo chroot $HOME/jail /bin/bash
