output "cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_frontend_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "ecr_backend_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
