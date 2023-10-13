
ifndef DOCKER_TAG
	export DOCKER_TAG=1.0.0
endif

##@ Docker

macos-deps:
	brew tap anchore/grype
	brew install kind crane syft cosign grype
	mkdir -p bin/darwin
	curl -Lo bin/darwin/cosign https://github.com/sigstore/cosign/releases/download/v1.13.1/cosign-darwin-arm64
	chmod +x bin/darwin/cosign

linux-deps:
	mkdir -p bin/linux
	curl -Lo bin/linux/cosign https://github.com/sigstore/cosign/releases/download/v1.13.1/cosign-linux-amd64
	chmod +x bin/linux/cosign

clean:
	@kubectx kind-cosign-demo
	kubectl delete -f k8s || true
	kubectl delete -f k8s/policy || true

run: docker-build ## Build the image and run it.
	docker rm -vf nyancat || true
	docker run -d --name nyancat -p 8080:80 $(REGISTRY):$(DOCKER_TAG)

docker-build: ## Build and push the image.
	@echo "Building and pushing: $(REGISTRY):$(DOCKER_TAG)"
	@echo -e ""
	@docker build -t $(REGISTRY):$(DOCKER_TAG) .
	docker push $(REGISTRY):$(DOCKER_TAG)

port-forward:
	kubectl port-forward svc/nyancat 8000:80

list-registry:
	crane ls $(REGISTRY)

##@ Sigstore
cosign-0: ## Scan the registry.
	crane ls $(REGISTRY)

cosign-1: ## Sign the image.
	cosign sign "$(REGISTRY)":@$(shell crane digest $(REGISTRY):$(DOCKER_TAG))

cosign-2: ## Scan the registry.
	crane ls $(REGISTRY)

cosign-3: ## Verify the image.
	cosign verify $(REGISTRY):@$(shell crane digest $(REGISTRY):$(DOCKER_TAG))

cosign-4: ## See the signature.
	cosign verify $(REGISTRY):@$(shell crane digest $(REGISTRY):$(DOCKER_TAG)) | jless

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
	cosign verify-attestation --type cyclonedx $(REGISTRY):$(DOCKER_TAG) > sbom-attestation.json

sbom-6:	## Extract the sbom payload from the attestation.
	cat sbom-attestation.json | jq -r .payload | base64 -d | jq -r ".predicate.Data" | jless

##@ Vulnerability Scanning
vuln-1: ## Scan the image with grype.
	cat sbom-cyclonedx.json | grype

vuln-2:	## Scan the sbom downloaded from the attestation.
	cosign verify-attestation --type cyclonedx $(REGISTRY):$(DOCKER_TAG) | jq -r .payload | base64 -d | jq -r ".predicate.Data" | grype

##@ K8S
k8s-0: ## Create a kind cluster
	@kind create cluster --name cosign-demo || true

k8s-1: ## Install kyverno.
	@kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.8.5/install.yaml || true

k8s-2: ## Apply kyverno policy.
	kubectl apply -f k8s/policy

k8s-3: ## Deploy nyancat.
	kubectl apply -f k8s/deployment.yaml
	kubectl apply -f k8s/svc.yaml

k8s-4: ## Port forward to nyancat.
	pkill kubectl || true
	kubectl port-forward svc/nyancat 8080:80 &

k8s-5: ## Change the dockerfile and push a new tag without signature.
	sed -i 's/IDI2023/PHPDAY/g' src/index.html
	docker build -t $(REGISTRY):1.1.0 .
	docker push $(REGISTRY):1.1.0

k8s-6: ## Scan the registry to see pushed tags, but no signature.
	crane ls $(REGISTRY)

k8s-7: ## Sign release 1.1.0
	cosign sign "$(REGISTRY)":@$(shell crane digest $(REGISTRY):1.1.0)

k8s-8: ## Deploy a kyverno policy to enforce sbom attestation.
	kubectl apply -f k8s/kyverno/policy-check-sbom.yaml

##@ Help
.PHONY: help
help: ## Show this help screen.
	@echo 'Usage: make <OPTIONS> ... <TARGETS>'
	@echo ''
	@echo 'Available targets are:'
	@awk 'BEGIN {FS = ":.*##";} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


# Drupal drubom demo.
drupal-install:
	docker-compose down -v
	docker-compose build
	docker-compose up -d
	./scripts/drupal-install.sh

d-backup-demo-setup:
	COMPOSE_PROJECT_NAME=demo-backup PORT=8081 docker-compose down -v
	COMPOSE_PROJECT_NAME=demo-backup PORT=8081 docker-compose build
	COMPOSE_PROJECT_NAME=demo-backup PORT=8081 docker-compose up -d
	COMPOSE_PROJECT_NAME=demo-backup PORT=8081 ./scripts/drupal-install.sh
	COMPOSE_PROJECT_NAME=demo-backup PORT=8081 docker-compose exec drupal bash -c "composer require drupal/drubom:1.0.x-dev"
	COMPOSE_PROJECT_NAME=demo-backup PORT=8081 docker-compose exec drupal bash -c "drush -y en drubom && drush drubom:generate"

drupal-backup-cli:
	@COMPOSE_PROJECT_NAME=demo-backup PORT=8081 CONTAINER_HOSTNAME=drupalcon-b docker-compose up -d
	@COMPOSE_PROJECT_NAME=demo-backup PORT=8081 CONTAINER_HOSTNAME=drupalcon-b docker-compose exec drupal bash

drupal-stop-all:
	docker-compose down -v
	COMPOSE_PROJECT_NAME=demo-backup PORT=8081 docker-compose down -v

drupal-cli:
	docker-compose exec drupal bash