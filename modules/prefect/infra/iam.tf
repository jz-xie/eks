data "aws_iam_policy_document" "s3_access" {
  statement {
    sid    = "AllowS3WriteAccess"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_name}",
      "arn:aws:s3:::${local.bucket_name}/*",
    ]
  }
}

data "aws_iam_policy_document" "this" {
  source_policy_documents = [
    data.aws_iam_policy_document.s3_access.json,
  ]
}

resource "aws_iam_policy" "this" {
  name        = "${local.bucket_name}-access"
  description = "Allow Prefect job access s3 storage"
  policy      = data.aws_iam_policy_document.this.json
  tags = {
    project     = var.project
    environment = var.environment
  }
}
