data "aws_caller_identity" "current" {}


provider "aws" {
  region     = "us-east-1"
  access_key = var.awsaccesskey
  secret_key = var.awssecretkey
}

resource "aws_dynamodb_table" "terraform_statelock" {
  name           = var.avtx_dynamodb_table
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}


resource "aws_s3_bucket" "avtx_controller_bucket" {

  bucket = var.avtx_controller_bucket
  acl    = "private"
  force_destroy = true

  versioning {
    enabled = true
  }
        policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${data.aws_caller_identity.current.arn}"
            },
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${var.avtx_controller_bucket}",
                "arn:aws:s3:::${var.avtx_controller_bucket}/*"
            ]
        }
    ]
}
EOF
}
