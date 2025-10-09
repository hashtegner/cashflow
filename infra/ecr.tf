resource "aws_ecr_repository" "cashflow" {
  name = "cashflow"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "container_registry_url" {
  value = aws_ecr_repository.cashflow.repository_url
}