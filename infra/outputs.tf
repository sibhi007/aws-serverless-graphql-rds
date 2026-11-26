output "site_url" {
  value = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "graphql_url" {
  value = "https://${aws_cloudfront_distribution.cdn.domain_name}/graphql"
}

output "ecr_repository" {
  value = aws_ecr_repository.graphql.repository_url
}

output "ecs_cluster" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service" {
  value = aws_ecs_service.graphql.name
}

output "frontend_bucket" {
  value = aws_s3_bucket.frontend.id
}

output "cloudfront_id" {
  value = aws_cloudfront_distribution.cdn.id
}

output "github_role_arn" {
  value = aws_iam_role.github_deploy.arn
}