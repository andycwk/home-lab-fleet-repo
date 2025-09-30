#!/usr/bin/env bash

function inject_secrets(){
  local -r file="./cluster.yaml.j2"
  local output
  pwd
  pushd ./Kubernetes/India-ARC/bootstrap >>/dev/null
  if [[ ! -f "${file}" ]]; then
      echo "File does not exist" "file=${file}"
      exit 1
  fi

  if ! output=$(op inject --in-file "${file}") || [[ -z "${output}" ]]; then
      popd >>/dev/null
      echo "Failed to render config" "file=${file}"
      exit 1
  fi
  popd >>/dev/null
  echo "${output}"
  echo "${output}" | kubectl apply --server-side --filename - &>/dev/null
}

function main(){
    if ! command -v flux &>/dev/null; then
        echo "Flux CLI was not found, please install https://fluxcd.io/docs/installation/" >>/dev/stderr
        exit 1
    fi

    if ! command -v op &>/dev/null; then
        echo "1Password CLI was not found, please install https://developer.1password.com/docs/cli/get-started/" >>/dev/stderr
        exit 1
    fi

    if ! op whoami --format=json &>/dev/null; then
        echo "Please choose and sign into the correct 1Password account..."
        op signin
    fi

    inject_secrets

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

    # if [ ! $GITHUB_TOKEN ]; then
    #     echo "GITHUB_TOKEN env variable not found, expecting a personal access token with access to this repo" >>/dev/stderr
    #     exit 1
    # fi

    local -r GH_TOKEN=$(op read op://kube-ARC-TI-IN-cluster/GITHUB/password)
    local -r GH_USER=$(op read op://kube-ARC-TI-IN-cluster/GITHUB/username)

    GITHUB_TOKEN=${GH_TOKEN} flux bootstrap github \
    --owner=$GH_USER \
    --repository=home-lab-fleet-repo \
    --branch=main \
    --path=./Kubernetes/India-ARC/flux/ \
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
}

main "$@"
