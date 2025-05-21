# Who's My Good Boy Infrastructure

This repository contains the Terraform configuration for the Who's My Good Boy
infrastructure.

## Project Structure

The infrastructure code has been organized in a modular structure:

```
.
├── environments/
│   ├── prod/                  # Production environment configuration
│   │   ├── main.tf            # Main production configuration
│   │   ├── outputs.tf         # Production environment outputs
│   │   └── variables.tf       # Production environment variables
│   └── dev/                   # Development environment configuration
│       ├── main.tf            # Main development configuration
│       ├── outputs.tf         # Development environment outputs
│       └── variables.tf       # Development environment variables
├── modules/                   # Reusable Terraform modules
│   ├── ecr/                   # ECR repository module
│   ├── ecs/                   # ECS cluster and service module
│   ├── elb/                   # Elastic Load Balancer module
│   ├── iam/                   # IAM roles and policies module
│   ├── s3/                    # S3 bucket module
│   └── vpc/                   # VPC and networking module
├── main.tf                    # Root configuration entry point
├── outputs.tf                 # Root outputs
└── variables.tf               # Root variables
```

## Modules

### VPC Module

- Defines the VPC, subnets, internet gateway, and security groups

### IAM Module

- Defines IAM roles, policies, and groups
- Includes specialized policies for ECR access and user management

### ECR Module

- Defines the ECR repository for the backend application
- Includes lifecycle policies for image management

### ECS Module

- Defines the ECS cluster and services
- Configures the task definition for the backend application

### ELB Module

- Defines the Application Load Balancer
- Configures listeners and target groups

### S3 Module

- Defines the S3 bucket for ML models
- Configures access policies and encryption

## Environments

### Production

- High-availability configuration with 2 instances
- Full resources allocation for production workloads
- Stricter security settings

### Development

- Reduced resources to save costs
- More verbose logging
- Only 1 instance

## Usage

To initialize the Terraform configuration:

```bash
terraform init
```

### Working with Production Environment

To plan the production deployment:

```bash
make plan
# or
terraform plan -var="environment=prod"
```

To apply the production changes:

```bash
make apply
# or
terraform apply -var="environment=prod"
```

To destroy the production environment:

```bash
make destroy
# or
terraform destroy -var="environment=prod"
```

### Working with Development Environment

To plan the development deployment:

```bash
make plan-dev
# or
terraform plan -var="environment=dev"
```

To apply the development changes:

```bash
make apply-dev
# or
terraform apply -var="environment=dev"
```

To destroy the development environment:

```bash
make destroy-dev
# or
terraform destroy -var="environment=dev"
```

## Adding New Resources

To add new resources:

1. Add the resource to the appropriate module
2. Update the module's variables and outputs as needed
3. Update the environment configuration to use the new resource

## Adding New Environments

To add a new environment (e.g., staging):

1. Create a new directory in the `environments` folder
2. Copy the files from an existing environment
3. Update the variables as needed
4. Update the root main.tf to include the new environment
