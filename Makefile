# PostgreSQL Tools Makefile

# Docker image information
IMAGE_REGISTRY = ghcr.io
IMAGE_ORG = ukwhatn
BASE_IMAGE = $(IMAGE_REGISTRY)/$(IMAGE_ORG)/psql-base
MIGRATOR_IMAGE = $(IMAGE_REGISTRY)/$(IMAGE_ORG)/psql-migrator
DUMPER_IMAGE = $(IMAGE_REGISTRY)/$(IMAGE_ORG)/psql-dumper
VERSION ?= $(shell date +%Y%m%d)

.PHONY: install format lint security test build-base build-migrator build-dumper build-all tag-images push-images clean up down

# Development commands
install:
	poetry install --with dev,db,dumper

format:
	ruff format .

lint:
	ruff check .

security:
	bandit -r . && semgrep .

# Docker build commands
build-base:
	docker build -t $(BASE_IMAGE):latest -f docker/base.Dockerfile .

build-migrator: build-base
	docker build -t $(MIGRATOR_IMAGE):latest -f docker/migrator.Dockerfile .

build-dumper: build-base
	docker build -t $(DUMPER_IMAGE):latest -f docker/dumper.Dockerfile .

build-all: build-base build-migrator build-dumper
	@echo "All images built successfully."

# Tag images with version for releases
tag-images: build-all
	docker tag $(BASE_IMAGE):latest $(BASE_IMAGE):$(VERSION)
	docker tag $(MIGRATOR_IMAGE):latest $(MIGRATOR_IMAGE):$(VERSION)
	docker tag $(DUMPER_IMAGE):latest $(DUMPER_IMAGE):$(VERSION)
	@echo "Images tagged with version: $(VERSION)"

# Docker push commands (for GitHub Actions)
push-images: tag-images
	docker push $(BASE_IMAGE):latest
	docker push $(BASE_IMAGE):$(VERSION)
	docker push $(MIGRATOR_IMAGE):latest
	docker push $(MIGRATOR_IMAGE):$(VERSION)
	docker push $(DUMPER_IMAGE):latest
	docker push $(DUMPER_IMAGE):$(VERSION)
	@echo "All images pushed successfully."

# Test command
test:
	@echo "Running tests..."
	# Add test commands here when tests are implemented

# Clean docker images
clean:
	docker rmi $(BASE_IMAGE):latest $(BASE_IMAGE):$(VERSION) $(MIGRATOR_IMAGE):latest $(MIGRATOR_IMAGE):$(VERSION) $(DUMPER_IMAGE):latest $(DUMPER_IMAGE):$(VERSION) || true

# Docker Compose commands for local development
up:
	docker compose up -d

down:
	docker compose down