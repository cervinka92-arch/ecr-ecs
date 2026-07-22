output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_url" {
  description = "HTTP URL for the nginx application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecr_repository_url" {
  description = "URI of the ECR repository the pipeline pushes images to"
  value       = aws_ecr_repository.app.repository_url
}

output "github_actions_role_arn" {
  description = "IAM role ARN GitHub Actions assumes via OIDC (set as AWS_ROLE_ARN repo variable)"
  value       = aws_iam_role.github_actions.arn
}
