variable "subnet_ids" {
  description = "List of subnet IDs for ECS service"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ECS service"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for ALB and target group"
  type        = string
}
