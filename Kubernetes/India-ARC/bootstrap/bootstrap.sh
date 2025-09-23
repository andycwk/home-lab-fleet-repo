#!/usr/bin/env bash

if ! command -v flux &>/dev/null; then
    echo "Flux CLI was not found, please install https://fluxcd.io/docs/installation/" >>/dev/stderr
    exit 1
fi

# sealedSecretCrt=eHubTaroDevSealedSecret.crt
# sealedSecretKey=~/.ssh/eHubTaroDevSealedSecret.key
# if [ ! -f $sealedSecretCrt ]; then
#     echo "flux-system sealed secret public key not found, please ensure you have $sealedSecretCrt" >>/dev/stderr
#     exit 1
# fi
# if [ ! -f $sealedSecretKey ]; then
#     echo "flux-system sealed secret private key not found, please ensure you have $sealedSecretKey" >>/dev/stderr
#     exit 1
# fi

if [ ! $GITHUB_TOKEN ]; then
    echo "GITHUB_TOKEN env variable not found, expecting a personal access token with access to this repo" >>/dev/stderr
    exit 1
fi

secret=~/.ssh/flux-system_home-labx.yaml
if [ ! -f $secret ]; then
    echo "flux-system secret not found, please ensure you have $secret" >>/dev/stderr
    echo "... will bootstrap with new deployment keys" >> /dev/stderr
else
    echo "existing flux-system secret found.. Sending to cluster"
    kubectl apply -k ./flux/config >>/dev/null
    kubectl apply -f $secret >>/dev/null
fi

flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=home-lab-fleet-repo \
  --branch=main \
  --path=./Kubernetes/India-ARC/flux/flux-system \
  --personal

# flux bootstrap github \
#     --components-extra=image-reflector-controller,image-automation-controller \
#     --owner=TI-eHub \
#     --read-write-key=true \
#     --hostname=gh.texmo.com \
#     --repository=fleet-infra \
#     --branch=main \
#     --path=./clusters/taro-dev

# flux bootstrap github \
#     --components-extra=image-reflector-controller,image-automation-controller \
#     --owner=TI-eHub \
#     --read-write-key=true \
#     --hostname=gh.texmo.com \
#     --repository=fleet-infra \
#     --branch=main \
#     --path=./clusters/taro-dev