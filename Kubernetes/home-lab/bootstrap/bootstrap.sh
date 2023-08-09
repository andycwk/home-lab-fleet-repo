#!/usr/bin/env bash

kubectl apply -k ./bootstrap --validate=false

for FILE in ./flux/vars/*.sops.yaml; do
    sops -d $FILE |
        kubectl apply -f -
done

kubectl apply -k ./flux/config
