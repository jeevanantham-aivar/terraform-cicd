terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# Call the ECS module
module "ecs" {
  source = "./modules/ecs"

  app_name         = "html-site"
  ecr_repo_name    = "html-site"
  ecr_repo_url     = "842475164805.dkr.ecr.ap-south-1.amazonaws.com/html-site"
  cluster_name     = "html-cluster"
  container_name   = "html-container"
  subnet_ids       = var.subnet_ids
  security_group_id = var.security_group_id
  vpc_id           = var.vpc_id
  enable_alb       = true
}
