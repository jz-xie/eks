output "s3_bucket_arn" {
  value = module.s3.arn
}

output "rds_arn" {
  value = module.rds.cluster_arn
}
