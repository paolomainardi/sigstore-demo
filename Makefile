
ifndef DOCKER_TAG
	export DOCKER_TAG=1.0.0
endif

run: docker-build
	docker rm -vf nyancat || true
	docker run -d --name nyancat -p 8080:80 $(REGISTRY):$(DOCKER_TAG)

k8s-0:
	kind create cluster --name cosign-demo

k8s-1: # Install kyverno.
	kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.8.5/install.yaml

k8s-2:
	kubectl apply -f k8s/deployment.yaml
	kubectl apply -f k8s/svc.yaml

k8s-3:
	pkill kubectl || true
	kubectl port-forward svc/nyancat 8080:80 &

docker-build:
	docker build -t $(REGISTRY):$(DOCKER_TAG) .
	docker push $(REGISTRY):$(DOCKER_TAG)

cosign-1:
	cosign sign "$(REGISTRY)":@$(shell crane digest $(REGISTRY):$(DOCKER_TAG))

cosign-2:
	crane ls $(REGISTRY)

cosign-2:
	cosign verify $(REGISTRY):@$(shell crane digest $(REGISTRY):$(DOCKER_TAG))

sbom-1:
	syft ${REGISTRY}:${DOCKER_TAG}

sbom-2:
	syft ${REGISTRY}:${DOCKER_TAG} -o cyclonedx-json > sbom-cyclonedx.json

sbom-3:
	cosign attest --predicate sbom-cyclonedx.json --type cyclonedx $(REGISTRY):$(DOCKER_TAG)

sbom-4:
	crane ls $(REGISTRY)

sbom-5:
	cosign verify-attestation --type cyclonedx $(REGISTRY):$(DOCKER_TAG) > sbom-attestation.json

sbom-6:
	cat sbom-attestation.json  | jq -r .payload | base64 -d | jq -r ".predicate.Data" | jless

