variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project prefix for all AWS resources"
  type        = string
  default     = "graphql-serverless"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "graphqlapp"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "dbadmin"
}

variable "alert_email" {
  description = "Where CloudWatch alarms are emailed"
  type        = string
}

variable "github_repo" {
  description = "owner/repo that may deploy, e.g. sibhi007/aws-serverless-graphql-rds"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag the ECS task starts with"
  type        = string
  default     = "bootstrap"
}