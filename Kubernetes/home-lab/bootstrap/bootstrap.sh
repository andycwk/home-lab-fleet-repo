#!/usr/bin/env bash

kubectl apply -k ./bootstrap --validate=false

sops -d ./bootstrap/age-key.sops.yaml |
kubectl apply -f /dev/stdin

kubctl apply -k ../flux/bootstrap