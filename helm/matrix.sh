#! /bin/bash

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl edit deployment metrics-server -n kube-system #TLS update