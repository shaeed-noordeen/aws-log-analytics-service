# Makefile for the Log Analytics Service

.PHONY: all lint test build push tf-init tf-plan tf-apply smoke

all: lint test build

lint:
	@echo "Linting..."
	# Add linting commands here

test:
	@echo "Running tests..."
	# Add test commands here

build:
	@echo "Building Docker image..."
	# Add Docker build command here

push:
	@echo "Pushing Docker image to ECR..."
	# Add Docker push command here

tf-init:
	@echo "Initializing Terraform..."
	# Add terraform init command here

tf-plan:
	@echo "Planning Terraform changes..."
	# Add terraform plan command here

tf-apply:
	@echo "Applying Terraform changes..."
	# Add terraform apply command here

smoke:
	@echo "Running smoke tests..."
	# Add smoke test commands here