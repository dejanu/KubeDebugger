#!/usr/bin/env bash

kubectl delete po nakedpod
kubectl delete svc webapp-svc
kubectl delete deploy webapp  
