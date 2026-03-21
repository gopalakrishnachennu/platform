terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "{{ values.awsRegion }}"
}

resource "aws_s3_bucket" "this" {
  bucket = "{{ values.bucketName }}"
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
{{#if values.enableVersioning}}
    status = "Enabled"
{{else}}
    status = "Suspended"
{{/if}}
  }
}

output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}
