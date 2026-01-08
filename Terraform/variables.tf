variable "aws_region" {
  default = "us-east-1"
}

variable "source_bucket_name" {
  default = "serverless-img-proc-source-bbee8ea1"
}

variable "dest_bucket_name" {
  default = "serverless-img-proc-dest-bbee8ea1"
}

variable "dynamodb_table_name" {
  default = "serverless-img-proc-metadata"
}
