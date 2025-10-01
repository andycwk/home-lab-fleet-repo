#!/usr/bin/env bash

function main(){
    validate-CLI
    prepare-cluster
    bootstrap-flux

    echo "==============================================================="
    echo "Cluster bootstrap now complete and in sync with this fleet repo"
    echo "==============================================================="
}

function validate-CLI(){
    echo "======================"
    echo "validating CLI tooling"
    echo "======================"

    if ! command -v flux &>/dev/null; then
        echo "Flux CLI was not found, please install https://fluxcd.io/docs/installation/" >>/dev/stderr
        exit 1
    fi

    if ! command -v op &>/dev/null; then
        echo "1Password CLI was not found, please install https://developer.1password.com/docs/cli/get-started/" >>/dev/stderr
        exit 1
    fi
}

function prepare-cluster(){
    echo "================="
    echo "Preparing cluster"
    echo "================="

    if ! op whoami --format=json &>/dev/null; then
        echo "Please choose and sign into the correct 1Password account..."
        op signin
    fi

    local -r file="./cluster.yaml.j2"
    local output

    pushd ./Kubernetes/India-ARC/bootstrap >>/dev/null
    if [[ ! -f "${file}" ]]; then
        echo "File does not exist" "file=${file}"
        exit 1
    fi

    IDENTITY_B64="$(op read 'op://kube-CI-CD-TI-IN-cluster/deploy-key/private key' | base64 -b0)"
    IDENTITY_PUB_B64="$(op read 'op://kube-CI-CD-TI-IN-cluster/deploy-key/public key' | base64 -b0)"
    export MINIJINJA_CONFIG_FILE=$(pwd)/.minijinja.toml
    
    if ! output=$(IDENTITY_B64="$IDENTITY_B64" IDENTITY_PUB_B64="$IDENTITY_PUB_B64" minijinja-cli "${file}" | op inject) || [[ -z "${output}" ]]; then
        popd >>/dev/null
        echo "Failed to render config" "file=${file}"
        exit 1
    fi
    popd >>/dev/null

    # if ! output=$(op inject --in-file "${file}") || [[ -z "${output}" ]]; then
    #     popd >>/dev/null
    #     echo "Failed to render config" "file=${file}"
    #     exit 1
    # fi
    # popd >>/dev/null

    echo "${output}" | kubectl apply --server-side --filename -
}

function bootstrap-flux(){
    echo "=================="
    echo "Bootstrapping Flux"
    echo "=================="

    local -r GH_TOKEN=$(op read "op://kube-CI-CD-TI-IN-cluster/GITHUB/password")
    local -r GH_USER=$(op read "op://kube-CI-CD-TI-IN-cluster/GITHUB/username")

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
