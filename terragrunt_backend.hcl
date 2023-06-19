generate "terraform_backend" {
  path      = "terraform_backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "bigdata-terraform-states"
    key            = "${get_path_from_repo_root()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "bigdata-terraform-states-locking"
  }
}
EOF
}