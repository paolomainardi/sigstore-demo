
ifndef DOCKER_TAG
	export DOCKER_TAG=1.0.0
endif

##@ Docker
run: docker-build ## Build the image and run it.
	docker rm -vf nyancat || true
	docker run -d --name nyancat -p 8080:80 $(REGISTRY):$(DOCKER_TAG)

docker-build: ## Build the image.
	docker build -t $(REGISTRY):$(DOCKER_TAG) .
	docker push $(REGISTRY):$(DOCKER_TAG)

##@ K8S
k8s-0: ## Create a kind cluster
	kind create cluster --name cosign-demo

k8s-1: ## Install kyverno.
	kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.8.5/install.yaml

k8s-2: ## Deploy nyancat.
	kubectl apply -f k8s/deployment.yaml
	kubectl apply -f k8s/svc.yaml

k8s-3: ## Port forward to nyancat.
	pkill kubectl || true
	kubectl port-forward svc/nyancat 8080:80 &

##@ Sigstore
cosign-1: ## Sign the image.
	cosign sign "$(REGISTRY)":@$(shell crane digest $(REGISTRY):$(DOCKER_TAG))

cosign-2: ## Scan the registry.
	crane ls $(REGISTRY)

cosign-3: ## Verify the image.
	cosign verify $(REGISTRY):@$(shell crane digest $(REGISTRY):$(DOCKER_TAG))

##@ SBOM

sbom-1: ## Generate SBOM.
	syft ${REGISTRY}:${DOCKER_TAG}

sbom-2: ## Save SBOM in CycloneDX format.
	syft ${REGISTRY}:${DOCKER_TAG} -o cyclonedx-json > sbom-cyclonedx.json

sbom-3: ## Sign SBOM.
	cosign attest --predicate sbom-cyclonedx.json --type cyclonedx $(REGISTRY):$(DOCKER_TAG)

sbom-4: ## Scan the registry.
	crane ls $(REGISTRY)

sbom-5: ## Verify sbom attestation and download the SBOM file.
	cosign verify-attestation --type cyclonedx $(REGISTRY):$(DOCKER_TAG) > sbom-verify-attestation.json

sbom-6:	## Open the sbom dowloaded from the registry.
	cat sbom-verify-attestation  | jq -r .payload | base64 -d | jq -r ".predicate.Data" | jless

##@ Vulnerability Scanning
vuln-1: ## Scan the image with grype.
	cat sbom-cyclonedx.json | grype

vuln-2:	## Scan the sbom downloaded from the attestation.
	cat sbom-verify-attestation  | jq -r .payload | base64 -d | jq -r ".predicate.Data" | grype

##@ Help
.PHONY: help
help: ## Show this help screen.
	@echo 'Usage: make <OPTIONS> ... <TARGETS>'
	@echo ''
	@echo 'Available targets are:'
	@awk 'BEGIN {FS = ":.*##";} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
