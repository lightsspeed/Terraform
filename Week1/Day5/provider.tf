terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "akhileshisdevopsengg" {
  bucket        = "akhileshisdevopsengg"
  force_destroy = true # Explicitly set


  tags = {
    Name        = "akhileshisdevopsengg"
    Environment = "production"
  }
}

resource "aws_s3_bucket_versioning" "versioning_akhileshisdevopsengg" {
  bucket = aws_s3_bucket.akhileshisdevopsengg.id
  versioning_configuration {
    status = "Enabled"
  }
}
