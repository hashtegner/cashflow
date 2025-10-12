output "container_registry_url" {
  value = aws_ecr_repository.cashflow.repository_url
}

output "s3_bucket_name" {
  value = aws_s3_bucket.cashflow.bucket
}
