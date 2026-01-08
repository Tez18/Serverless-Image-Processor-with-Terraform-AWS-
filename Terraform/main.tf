provider "aws" {
  region = var.aws_region
}

# ---------------- S3 Buckets ----------------
resource "aws_s3_bucket" "source_bucket" {
  bucket = var.source_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket" "dest_bucket" {
  bucket = var.dest_bucket_name
  force_destroy = true
}

# ---------------- DynamoDB ----------------
resource "aws_dynamodb_table" "metadata_table" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "image_name"

  attribute {
    name = "image_name"
    type = "S"
  }
}

# ---------------- IAM Role ----------------
resource "aws_iam_role" "lambda_exec_role" {
  name = "serverless-img-proc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = ["s3:GetObject"],
        Resource = "${aws_s3_bucket.source_bucket.arn}/*"
      },
      {
        Effect = "Allow",
        Action = ["s3:PutObject"],
        Resource = "${aws_s3_bucket.dest_bucket.arn}/*"
      },
      {
        Effect = "Allow",
        Action = ["dynamodb:PutItem"],
        Resource = aws_dynamodb_table.metadata_table.arn
      }
    ]
  })
}

# ---------------- Lambda ----------------
resource "aws_lambda_function" "image_processor" {
  function_name = "serverless-img-proc-function"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "processor.lambda_handler"
  timeout       = 15
  memory_size   = 512

  filename         = "lambda/lambda.zip"
  source_code_hash = filebase64sha256("lambda/lambda.zip")

  environment {
    variables = {
      DEST_BUCKET = aws_s3_bucket.dest_bucket.bucket
      TABLE_NAME = aws_dynamodb_table.metadata_table.name
    }
  }
}
