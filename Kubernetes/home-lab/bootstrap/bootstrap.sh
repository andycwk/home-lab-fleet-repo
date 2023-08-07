#!/usr/bin/env bash

kubectl apply -k ./bootstrap --validate=false

sops -d ./bootstrap/age-key.sops.yaml |
kubectl apply -f /dev/stdin

sops -d ./bootstrap/gh-ssh-credentials.sops.yaml |
kubectl apply -f /dev/stdin

kubectl apply -k ./flux/bootstrap --validate=false