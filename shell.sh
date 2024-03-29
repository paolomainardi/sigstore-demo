#!/usr/bin/env sh
export OS=$(uname -s | tr '[:upper:]' '[:lower:]')
export ASCIINEMA_REC=true
export REGISTRY=ghcr.io/paolomainardi/sigstore-demo
export IMAGE=ghcr.io/paolomainardi/sigstore-demo
export DOCKER_TAG=1.0.0
export COSIGN_EXPERIMENTAL=1
export GRYPE_DB_AUTO_UPDATE=0
export GRYPE_CHECK_FOR_APP_UPDATE=0
export SYFT_CHECK_FOR_APP_UPDATE=0
export SHELL=$(which bash)
export PATH=$(pwd)/bin/${OS}:$PATH
kubectx kind-cosign-demo
clear
kubectx kind-cosign-demo
bash -c "source <(cosign completion bash)"
bash -i
