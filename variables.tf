variable "aws_region" {
  description = "AWS region where resources are deployed"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Prefix used for resource names"
  type        = string
  default     = "ecr-ecs-nginx-demo"
}

variable "image_tag" {
  description = "Tag of the docker image (in ECR) that the ECS task should run"
  type        = string
  default     = "latest"
}

variable "github_repo" {
  description = "GitHub repository allowed to assume the CI/CD IAM role, in the form <owner>/<repo>"
  type        = string
  default     = "cervinka92-arch/CHANGE_ME"
}
