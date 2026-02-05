# Makefile for Open Horizon Nginx Service
# Supports multi-architecture builds (amd64, arm64)
# Compatible with both Docker and Podman

# Variables
CONTAINER_ENGINE ?= $(shell command -v docker 2>/dev/null || command -v podman 2>/dev/null || echo docker)
DOCKER_REGISTRY ?= docker.io/changeme
SERVICE_NAME = service-nginx
SERVICE_VERSION = 1.0.0
DOCKER_IMAGE_BASE = $(DOCKER_REGISTRY)/$(SERVICE_NAME)

# Get current architecture
ARCH ?= $(shell hzn architecture)

# Open Horizon variables
HZN_ORG_ID ?= $(shell hzn node list 2>/dev/null | jq -r '.organization // empty')
HZN_EXCHANGE_USER_AUTH ?=

# Default value for userInput variable (used for verification)
message ?= Hello from Open Horizon!

# Export variables for horizon/service.definition.json substitution
export DOCKER_IMAGE_BASE
export SERVICE_VERSION
export ARCH
export message

.PHONY: help build build-amd64 build-arm64 build-all-arches push push-amd64 push-arm64 \
        publish-service publish-service-amd64 publish-service-arm64 publish-all-services \
        remove-service remove-service-amd64 remove-service-arm64 \
        publish-pattern publish-deployment-policy remove-deployment-policy publish \
        test test-custom-message stop-test clean check-env verify-service verify-pattern \
        logs shell all

.DEFAULT_GOAL := help

## help: Display this help message
help:
	@echo "Open Horizon Nginx Service - Makefile targets:"
	@echo ""
	@grep -E '^## [a-zA-Z_-]+:' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = "## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$2, $$3}'
	@echo ""
	@echo "Environment Variables:"
	@echo "  CONTAINER_ENGINE       Container engine to use (default: auto-detect docker/podman)"
	@echo "  DOCKER_REGISTRY        Docker registry (default: $(DOCKER_REGISTRY))"
	@echo "  SERVICE_VERSION        Service version (default: 1.0.0)"
	@echo "  HZN_ORG_ID            Open Horizon organization ID"
	@echo "  HZN_EXCHANGE_USER_AUTH Open Horizon credentials"

## check-env: Check required environment variables
check-env:
	@if [ -z "$(HZN_ORG_ID)" ]; then \
		echo "Error: HZN_ORG_ID is not set"; \
		exit 1; \
	fi
	@if [ -z "$(HZN_EXCHANGE_USER_AUTH)" ]; then \
		echo "Error: HZN_EXCHANGE_USER_AUTH is not set"; \
		exit 1; \
	fi
	@echo "Environment check passed"

## build: Build container image for current architecture
build:
	@echo "Building $(SERVICE_NAME):$(SERVICE_VERSION) for $(ARCH) using $(CONTAINER_ENGINE)..."
	$(CONTAINER_ENGINE) build -t $(DOCKER_IMAGE_BASE)_$(ARCH):$(SERVICE_VERSION) .
	$(CONTAINER_ENGINE) tag $(DOCKER_IMAGE_BASE)_$(ARCH):$(SERVICE_VERSION) $(DOCKER_IMAGE_BASE)_$(ARCH):latest
	@echo "Build complete: $(DOCKER_IMAGE_BASE)_$(ARCH):$(SERVICE_VERSION)"

## build-amd64: Build container image for amd64 architecture
build-amd64:
	@echo "Building $(SERVICE_NAME):$(SERVICE_VERSION) for amd64 using $(CONTAINER_ENGINE)..."
	$(CONTAINER_ENGINE) build --platform linux/amd64 -t $(DOCKER_IMAGE_BASE)_amd64:$(SERVICE_VERSION) .
	$(CONTAINER_ENGINE) tag $(DOCKER_IMAGE_BASE)_amd64:$(SERVICE_VERSION) $(DOCKER_IMAGE_BASE)_amd64:latest
	@echo "Build complete: $(DOCKER_IMAGE_BASE)_amd64:$(SERVICE_VERSION)"

## build-arm64: Build container image for arm64 architecture
build-arm64:
	@echo "Building $(SERVICE_NAME):$(SERVICE_VERSION) for arm64 using $(CONTAINER_ENGINE)..."
	$(CONTAINER_ENGINE) build --platform linux/arm64 -t $(DOCKER_IMAGE_BASE)_arm64:$(SERVICE_VERSION) .
	$(CONTAINER_ENGINE) tag $(DOCKER_IMAGE_BASE)_arm64:$(SERVICE_VERSION) $(DOCKER_IMAGE_BASE)_arm64:latest
	@echo "Build complete: $(DOCKER_IMAGE_BASE)_arm64:$(SERVICE_VERSION)"

## build-all-arches: Build container images for all architectures
build-all-arches:
	@echo "Building multi-architecture images using $(CONTAINER_ENGINE)..."
	@if [ "$(CONTAINER_ENGINE)" = "docker" ]; then \
		if ! docker buildx version 2>/dev/null | grep -q multiarch; then \
			echo "Creating buildx builder 'multiarch'..."; \
			docker buildx create --name multiarch --use; \
			docker buildx inspect --bootstrap; \
		fi; \
		docker buildx build --platform linux/amd64,linux/arm64 \
			-t $(DOCKER_IMAGE_BASE)_amd64:$(SERVICE_VERSION) \
			-t $(DOCKER_IMAGE_BASE)_amd64:latest \
			-t $(DOCKER_IMAGE_BASE)_arm64:$(SERVICE_VERSION) \
			-t $(DOCKER_IMAGE_BASE)_arm64:latest \
			--push .; \
	else \
		echo "Building for amd64..."; \
		podman build --no-cache --platform linux/amd64 -t $(DOCKER_IMAGE_BASE)_amd64:$(SERVICE_VERSION) .; \
		podman tag $(DOCKER_IMAGE_BASE)_amd64:$(SERVICE_VERSION) $(DOCKER_IMAGE_BASE)_amd64:latest; \
		echo "Building for arm64..."; \
		podman build --no-cache --platform linux/arm64 -t $(DOCKER_IMAGE_BASE)_arm64:$(SERVICE_VERSION) .; \
		podman tag $(DOCKER_IMAGE_BASE)_arm64:$(SERVICE_VERSION) $(DOCKER_IMAGE_BASE)_arm64:latest; \
		echo "Pushing images..."; \
		podman push $(DOCKER_IMAGE_BASE)_amd64:$(SERVICE_VERSION); \
		podman push $(DOCKER_IMAGE_BASE)_amd64:latest; \
		podman push $(DOCKER_IMAGE_BASE)_arm64:$(SERVICE_VERSION); \
		podman push $(DOCKER_IMAGE_BASE)_arm64:latest; \
	fi
	@echo "Multi-architecture build complete"

## push: Push container image for current architecture
push:
	@echo "Pushing $(DOCKER_IMAGE_BASE)_$(ARCH):$(SERVICE_VERSION) using $(CONTAINER_ENGINE)..."
	$(CONTAINER_ENGINE) push $(DOCKER_IMAGE_BASE)_$(ARCH):$(SERVICE_VERSION)
	$(CONTAINER_ENGINE) push $(DOCKER_IMAGE_BASE)_$(ARCH):latest
	@echo "Push complete"

## push-amd64: Push container image for amd64 architecture
push-amd64:
	@echo "Pushing $(DOCKER_IMAGE_BASE)_amd64:$(SERVICE_VERSION) using $(CONTAINER_ENGINE)..."
	$(CONTAINER_ENGINE) push $(DOCKER_IMAGE_BASE)_amd64:$(SERVICE_VERSION)
	$(CONTAINER_ENGINE) push $(DOCKER_IMAGE_BASE)_amd64:latest
	@echo "Push complete"

## push-arm64: Push container image for arm64 architecture
push-arm64:
	@echo "Pushing $(DOCKER_IMAGE_BASE)_arm64:$(SERVICE_VERSION) using $(CONTAINER_ENGINE)..."
	$(CONTAINER_ENGINE) push $(DOCKER_IMAGE_BASE)_arm64:$(SERVICE_VERSION)
	$(CONTAINER_ENGINE) push $(DOCKER_IMAGE_BASE)_arm64:latest
	@echo "Push complete"

## publish-service: Publish service definition for current architecture
publish-service: check-env
	@echo "=================="
	@echo "PUBLISHING SERVICE"
	@echo "=================="
	@ARCH=$(ARCH) envsubst < horizon/service.definition.json > /tmp/service-$(ARCH).json
	@hzn exchange service publish -O -P --json-file=/tmp/service-$(ARCH).json
	@rm -f /tmp/service-$(ARCH).json
	@echo "Service published: $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)"
	@echo ""

## publish-service-amd64: Publish service definition for amd64
publish-service-amd64: check-env
	@echo "=================="
	@echo "PUBLISHING SERVICE"
	@echo "=================="
	@ARCH=amd64 envsubst < horizon/service.definition.json > /tmp/service-amd64.json
	@hzn exchange service publish -O -P --json-file=/tmp/service-amd64.json
	@rm -f /tmp/service-amd64.json
	@echo "Service published: $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_amd64"
	@echo ""

## publish-service-arm64: Publish service definition for arm64
publish-service-arm64: check-env
	@echo "=================="
	@echo "PUBLISHING SERVICE"
	@echo "=================="
	@ARCH=arm64 envsubst < horizon/service.definition.json > /tmp/service-arm64.json
	@hzn exchange service publish -O -P --json-file=/tmp/service-arm64.json
	@rm -f /tmp/service-arm64.json
	@echo "Service published: $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_arm64"
	@echo ""

## publish-all-services: Publish service definitions for all architectures
publish-all-services: publish-service-amd64 publish-service-arm64
	@echo "All service definitions published"

## remove-service: Remove service definition for current architecture
remove-service: check-env
	@echo "=================="
	@echo "REMOVING SERVICE"
	@echo "=================="
	@hzn exchange service remove -f $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)
	@echo ""

## remove-service-amd64: Remove service definition for amd64
remove-service-amd64: check-env
	@echo "=================="
	@echo "REMOVING SERVICE"
	@echo "=================="
	@hzn exchange service remove -f $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_amd64
	@echo ""

## remove-service-arm64: Remove service definition for arm64
remove-service-arm64: check-env
	@echo "=================="
	@echo "REMOVING SERVICE"
	@echo "=================="
	@hzn exchange service remove -f $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_arm64
	@echo ""

## publish-pattern: Publish deployment pattern
publish-pattern: check-env
	@echo "======================="
	@echo "PUBLISHING PATTERN"
	@echo "======================="
	@hzn exchange pattern publish -f horizon/pattern.json
	@echo "Pattern published: $(HZN_ORG_ID)/pattern-$(SERVICE_NAME)"
	@echo ""

## publish-deployment-policy: Publish deployment policy
publish-deployment-policy: check-env
	@echo "============================"
	@echo "PUBLISHING DEPLOYMENT POLICY"
	@echo "============================"
	@hzn exchange deployment addpolicy -f horizon/service.policy.json $(HZN_ORG_ID)/policy-$(SERVICE_NAME)_$(SERVICE_VERSION)
	@echo "Deployment policy published: $(HZN_ORG_ID)/policy-$(SERVICE_NAME)_$(SERVICE_VERSION)"
	@echo ""

## remove-deployment-policy: Remove deployment policy
remove-deployment-policy: check-env
	@echo "=========================="
	@echo "REMOVING DEPLOYMENT POLICY"
	@echo "=========================="
	@hzn exchange deployment removepolicy -f $(HZN_ORG_ID)/policy-$(SERVICE_NAME)_$(SERVICE_VERSION)
	@echo ""

## publish: Publish service definitions and deployment policy for all architectures
publish: publish-all-services publish-deployment-policy
	@echo "✓ All publishing complete!"
	@echo ""

## test: Run service locally for testing
test:
	@echo "Starting service locally on port 8080 using $(CONTAINER_ENGINE)..."
	@$(CONTAINER_ENGINE) rm -f nginx-test 2>/dev/null || true
	$(CONTAINER_ENGINE) run -d --name nginx-test \
		-p 8080:80 \
		-e MESSAGE="Test message from local container" \
		$(DOCKER_IMAGE_BASE)_$(ARCH):$(SERVICE_VERSION)
	@echo ""
	@echo "Service started. Test with:"
	@echo "  curl http://localhost:8080"
	@echo "  open http://localhost:8080"
	@echo ""
	@echo "View logs with:"
	@echo "  make logs"
	@echo ""
	@echo "Stop with:"
	@echo "  make stop-test"

## test-custom-message: Run service locally with custom message
test-custom-message:
	@echo "Starting service with custom message using $(CONTAINER_ENGINE)..."
	@$(CONTAINER_ENGINE) rm -f nginx-test 2>/dev/null || true
	@read -p "Enter custom message: " msg; \
	$(CONTAINER_ENGINE) run -d --name nginx-test \
		-p 8080:80 \
		-e MESSAGE="$$msg" \
		$(DOCKER_IMAGE_BASE)_$(ARCH):$(SERVICE_VERSION)
	@echo "Service started with custom message"
	@echo "Test at: http://localhost:8080"

## stop-test: Stop local test container
stop-test:
	@echo "Stopping test container..."
	@$(CONTAINER_ENGINE) stop nginx-test 2>/dev/null || true
	@$(CONTAINER_ENGINE) rm nginx-test 2>/dev/null || true
	@echo "Test container stopped"

## clean: Remove local container images
clean:
	@echo "Removing local images using $(CONTAINER_ENGINE)..."
	@$(CONTAINER_ENGINE) rmi $(DOCKER_IMAGE_BASE)_amd64:$(SERVICE_VERSION) 2>/dev/null || true
	@$(CONTAINER_ENGINE) rmi $(DOCKER_IMAGE_BASE)_amd64:latest 2>/dev/null || true
	@$(CONTAINER_ENGINE) rmi $(DOCKER_IMAGE_BASE)_arm64:$(SERVICE_VERSION) 2>/dev/null || true
	@$(CONTAINER_ENGINE) rmi $(DOCKER_IMAGE_BASE)_arm64:latest 2>/dev/null || true
	@echo "Cleanup complete"

## verify-service: Verify service is published in Exchange
verify-service: check-env
	@echo "Verifying service in Exchange..."
	@hzn exchange service list $(HZN_ORG_ID)/$(SERVICE_NAME) | jq .
	@echo ""
	@echo "Service details for amd64:"
	@hzn exchange service list $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_amd64 -l | jq .
	@echo ""
	@echo "Service details for arm64:"
	@hzn exchange service list $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_arm64 -l | jq .

## verify-pattern: Verify pattern is published in Exchange
verify-pattern: check-env
	@echo "Verifying pattern in Exchange..."
	@hzn exchange pattern list $(HZN_ORG_ID)/pattern-$(SERVICE_NAME) | jq .

## dev-verify: Verify service definition locally with hzn dev
dev-verify:
	@echo "Verifying service definition..."
	@export DOCKER_IMAGE_BASE=$(DOCKER_IMAGE_BASE) && \
	 export SERVICE_VERSION=$(SERVICE_VERSION) && \
	 export message="$(message)" && \
	 hzn dev service verify
	@echo "✓ Service definition verified successfully"

## logs: View logs from local test container
logs:
	@$(CONTAINER_ENGINE) logs -f nginx-test

## shell: Open shell in local test container
shell:
	@$(CONTAINER_ENGINE) exec -it nginx-test /bin/bash

## all: Build, push, and publish everything
all: build-all-arches publish-all-services publish-deployment-policy
	@echo ""
	@echo "✓ All tasks complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Register a node with policy: hzn register --policy=horizon/node-policy.json"
	@echo "     Or with pattern: hzn register -p pattern-$(SERVICE_NAME)"
	@echo "  2. Check status: hzn agreement list"
	@echo "  3. Test service: curl http://localhost:8080"

## distclean: Remove all published artifacts and clean local images
distclean: remove-deployment-policy remove-service-amd64 remove-service-arm64 clean
	@echo "✓ Complete cleanup finished"
