#!/usr/bin/env bash

kubectl apply -k ./bootstrap --validate=false
echo "================="
echo "applied bootstrap"
echo "================="

for FILE in ./flux/vars/*.sops.yaml; do
    sops -d $FILE |
        kubectl apply -f -
done
echo "============"
echo "applied sops"
echo "============"

kubectl apply -k ./flux/config
echo "============"
echo "applied Flux"
echo "============"