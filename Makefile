# Makefile for Terraform operations

.PHONY: init init-prod init-dev plan plan-dev apply apply-dev destroy destroy-dev fmt validate clean

# Default AWS profile
PROFILE ?= whos-my-good-boy-infra
# Default environment
ENVIRONMENT ?= prod

# Initialize Terraform for current environment (defaults to prod if not specified)
init:
	terraform init -backend-config="key=$(ENVIRONMENT).tfstate"

# Initialize Terraform for production
init-prod:
	ENVIRONMENT=prod $(MAKE) init

# Initialize Terraform for development
init-dev:
	ENVIRONMENT=dev $(MAKE) init

# Format Terraform files
fmt:
	terraform fmt -recursive

# Validate Terraform configuration
validate: fmt
	terraform validate

# Plan Terraform changes for production
plan: validate
	ENVIRONMENT=prod $(MAKE) init
	terraform plan -var="environment=prod" -var="aws_profile=$(PROFILE)"

# Plan Terraform changes for development
plan-dev: validate
	ENVIRONMENT=dev $(MAKE) init
	terraform plan -var="environment=dev" -var="aws_profile=$(PROFILE)"

# Apply Terraform changes for production
apply: validate
	ENVIRONMENT=prod $(MAKE) init
	terraform apply -var="environment=prod" -var="aws_profile=$(PROFILE)"

# Apply Terraform changes for development
apply-dev: validate
	ENVIRONMENT=dev $(MAKE) init
	terraform apply -var="environment=dev" -var="aws_profile=$(PROFILE)"

# Apply Terraform changes with auto-approve for production
apply-auto: validate
	ENVIRONMENT=prod $(MAKE) init
	terraform apply -auto-approve -var="environment=prod" -var="aws_profile=$(PROFILE)"

# Apply Terraform changes with auto-approve for development
apply-dev-auto: validate
	ENVIRONMENT=dev $(MAKE) init
	terraform apply -auto-approve -var="environment=dev" -var="aws_profile=$(PROFILE)"

# Destroy production infrastructure
destroy:
	ENVIRONMENT=prod $(MAKE) init
	terraform destroy -var="environment=prod" -var="aws_profile=$(PROFILE)"

# Destroy development infrastructure
destroy-dev:
	ENVIRONMENT=dev $(MAKE) init
	terraform destroy -var="environment=dev" -var="aws_profile=$(PROFILE)"

# Clean Terraform files
clean:
	rm -rf .terraform/
	find . -type d -name ".terraform" -exec rm -rf {} +
	find . -name ".terraform.lock.hcl" -delete

# Show outputs
output:
	terraform output

# Login to AWS SSO
login:
	aws sso login --profile $(PROFILE)
