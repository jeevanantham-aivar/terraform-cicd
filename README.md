# Terraform ECS with ALB Infrastructure

This Terraform project provisions a complete AWS infrastructure for deploying containerized applications using Amazon ECS (Elastic Container Service) with Fargate and an Application Load Balancer (ALB).

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Application   │    │   Application   │
│   Load Balancer │    │   Load Balancer │    │   Load Balancer │
│   (ALB)         │    │   (ALB)         │    │   (ALB)         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   ECS Service   │
                    │   (Fargate)     │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │   ECR Repository│
                    │   (Docker Images)│
                    └─────────────────┘
```

## 📁 Project Structure

```
terraform-ecs/
├── main.tf                 # Root module configuration
├── variables.tf            # Root level variables
├── outputs.tf              # Root level outputs
├── terraform.tfvars        # Variable values (not committed)
├── terraform.tfvars.example # Example variable values
├── .gitignore              # Git ignore rules
├── README.md               # This file
└── modules/
    └── ecs/
        ├── main.tf         # ECS module resources
        ├── variables.tf    # ECS module variables
        └── outputs.tf      # ECS module outputs
```

## 🧩 Modules

### ECS Module (`modules/ecs/`)

The ECS module is the core component that manages all AWS resources required for running containerized applications.

#### **Resources Created:**

1. **Amazon ECR Repository**
   - Stores Docker images
   - Enables image scanning on push
   - Supports force deletion for cleanup

2. **ECS Cluster**
   - Fargate-compatible cluster
   - Container Insights enabled
   - Proper tagging for resource management

3. **IAM Role & Policy**
   - Task execution role for ECS
   - Attached to AmazonECSTaskExecutionRolePolicy
   - Enables ECS to pull images and write logs

4. **CloudWatch Log Group**
   - Centralized logging for containers
   - 7-day retention policy
   - Structured log format

5. **ECS Task Definition**
   - Fargate-compatible configuration
   - 256 CPU units, 512MB memory
   - Port 80 container mapping
   - CloudWatch logging integration

6. **ECS Service**
   - Fargate launch type
   - Public subnet deployment
   - Auto-scaling ready (desired_count = 1)

7. **Application Load Balancer (ALB)**
   - Public-facing load balancer
   - HTTP listener on port 80
   - Health checks configured
   - Target group with IP target type

8. **ALB Target Group**
   - IP target type (Fargate compatible)
   - Health check path: `/`
   - Healthy threshold: 2, Unhealthy: 3
   - 30-second interval, 5-second timeout

9. **ALB Listener**
   - HTTP listener on port 80
   - Forwards traffic to target group
   - Default action configuration

#### **Key Features:**
- **Fargate Compatible**: Uses serverless compute
- **Public Access**: ALB provides public DNS endpoint
- **Health Monitoring**: Automatic health checks
- **Logging**: CloudWatch integration
- **Security**: IAM roles and security groups
- **Modularity**: Reusable across environments

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- Docker images ready for deployment

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd terraform-ecs
```

### 2. Configure Variables

Copy the example variables file and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your actual values:

```hcl
# Network Configuration
subnet_ids = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
security_group_id = "sg-xxxxxxxxx"
vpc_id = "vpc-xxxxxxxxx"
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Apply the Configuration

```bash
terraform apply
```

### 6. Access Your Application

After successful deployment, get the ALB DNS name:

```bash
terraform output alb_dns_name
```

Access your application at: `http://<alb-dns-name>`

## 📋 Configuration

### Root Variables (`variables.tf`)

| Variable | Type | Description | Required |
|----------|------|-------------|----------|
| `subnet_ids` | `list(string)` | List of public subnet IDs | Yes |
| `security_group_id` | `string` | Security group ID for ECS | Yes |
| `vpc_id` | `string` | VPC ID for ALB and target group | Yes |

### ECS Module Variables (`modules/ecs/variables.tf`)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `app_name` | `string` | - | Application name |
| `ecr_repo_name` | `string` | - | ECR repository name |
| `ecr_repo_url` | `string` | - | ECR repository URL |
| `cluster_name` | `string` | - | ECS cluster name |
| `container_name` | `string` | - | Container name |
| `enable_alb` | `bool` | `true` | Enable ALB creation |
| `container_port` | `number` | `80` | Container port |
| `health_check_path` | `string` | `/` | Health check path |
| `health_check_healthy_threshold` | `number` | `2` | Healthy threshold |
| `health_check_unhealthy_threshold` | `number` | `3` | Unhealthy threshold |

### Outputs

| Output | Description |
|--------|-------------|
| `ecr_repo_url` | ECR repository URL |
| `ecs_cluster_name` | ECS cluster name |
| `ecs_service_name` | ECS service name |
| `alb_dns_name` | ALB DNS name for public access |
| `alb_arn` | ALB ARN |
| `target_group_arn` | Target group ARN |

## 🔧 Customization

### Disable ALB

To deploy without ALB (direct ECS service):

```hcl
module "ecs" {
  # ... other parameters
  enable_alb = false
}
```

### Custom Health Checks

```hcl
module "ecs" {
  # ... other parameters
  health_check_path = "/health"
  health_check_healthy_threshold = 3
  health_check_interval = 60
}
```

### Custom Resource Allocation

Modify the task definition in `modules/ecs/main.tf`:

```hcl
resource "aws_ecs_task_definition" "app" {
  # ... other configuration
  cpu    = 512    # 0.5 vCPU
  memory = 1024   # 1GB RAM
}
```

## 🐳 Docker Image Deployment

### 1. Build and Push to ECR

```bash
# Get ECR login token
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $(terraform output -raw ecr_repo_url)

# Build image
docker build -t html-site .

# Tag image
docker tag html-site:latest $(terraform output -raw ecr_repo_url):latest

# Push image
docker push $(terraform output -raw ecr_repo_url):latest
```

### 2. Update ECS Service

```bash
# Force new deployment
aws ecs update-service --cluster html-cluster --service html-site-service --force-new-deployment
```

## 🔒 Security Considerations

- **State Files**: Never commit `.tfstate` files (handled by `.gitignore`)
- **Variables**: Keep sensitive data in `terraform.tfvars` (not committed)
- **IAM Roles**: Minimal required permissions for ECS task execution
- **Security Groups**: Configure appropriate inbound/outbound rules
- **ALB Security**: Consider HTTPS listener for production

## 🧪 Testing

### Validate Configuration

```bash
terraform validate
```

### Plan Changes

```bash
terraform plan -var-file="terraform.tfvars"
```

### Test Health Checks

```bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)

# Test health endpoint
curl -f http://$ALB_DNS/health
```

## 🗑️ Cleanup

### Destroy Infrastructure

```bash
terraform destroy
```

### Clean ECR Repository

```bash
# List images
aws ecr describe-images --repository-name html-site

# Delete images
aws ecr batch-delete-image --repository-name html-site --image-ids imageTag=latest
```

## 📚 Additional Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [AWS ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Note**: This infrastructure is designed for development and staging environments. For production use, consider additional security measures, monitoring, and backup strategies. 