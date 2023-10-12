#!/usr/bin/env sh
export ASCIINEMA_REC=true
export REGISTRY=ghcr.io/paolomainardi/idi2023-sigstore-demo
export IMAGE=ghcr.io/paolomainardi/idi2023-sigstore-demo
export DOCKER_TAG=1.0.0
export COSIGN_EXPERIMENTAL=1
export SHELL=$(which bash)
export GRYPE_DB_AUTO_UPDATE=false
kubectx kind-cosign-demo
clear
kubectx kind-cosign-demo
bash -c "source <(cosign completion bash)"
bash -i
