resource "random_pet" "demo" {
}

data "aws_region" "current" {}

resource "aws_lambda_function" "writer" {
  reserved_concurrent_executions = 1

  function_name = "${random_pet.demo.id}-writer"
  role          = aws_iam_role.lambda.arn

  handler = "clj_lambda_datahike.handler"

  s3_bucket        = aws_s3_bucket.lambda.id
  s3_key           = aws_s3_object.lambda.key
  source_code_hash = filebase64sha256("../target/lambda.jar")

  runtime = "java11"

  memory_size = 3008

  timeout = 30

  environment {
    variables = {
      DATAHIKE_S3_BACKEND = aws_s3_bucket.datahike-s3-backend.id
      BACKEND_ROLE = "writer"
    }
  }
}

resource "aws_lambda_function" "reader" {
  function_name = "${random_pet.demo.id}-reader"
  role          = aws_iam_role.lambda.arn

  handler = "clj_lambda_datahike.handler"

  s3_bucket        = aws_s3_bucket.lambda.id
  s3_key           = aws_s3_object.lambda.key
  source_code_hash = filebase64sha256("../target/lambda.jar")

  runtime = "java11"

  memory_size = 3008

  timeout = 30

  environment {
    variables = {
      DATAHIKE_S3_BACKEND = aws_s3_bucket.datahike-s3-backend.id
      BACKEND_ROLE = "reader"
    }
  }
}

resource "aws_lambda_function_url" "writer" {
  function_name      = aws_lambda_function.writer.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_function_url" "reader" {
  function_name      = aws_lambda_function.reader.function_name
  authorization_type = "NONE"
}

resource "aws_iam_role" "lambda" {
  name               = "${random_pet.demo.id}-demo"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "datahike-s3-backend"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:GetObject",
            "s3:DeleteObject*",
            "s3:PutObject*",
          ]
          Effect = "Allow"
          Resource = [
            aws_s3_bucket.datahike-s3-backend.arn,
            "${aws_s3_bucket.datahike-s3-backend.arn}/*"
          ]
        },
        {
          Action = [
            "s3:ListBucket"
          ]
          Effect = "Allow"
          Resource = [
            aws_s3_bucket.datahike-s3-backend.arn,
          ]
        }
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_s3_bucket" "datahike-s3-backend" {
  bucket = "${random_pet.demo.id}-backend"
}

resource "aws_s3_bucket_public_access_block" "datahike-s3-backend" {
  bucket = aws_s3_bucket.datahike-s3-backend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "lambda" {
  bucket = "${random_pet.demo.id}-lambda"
}

resource "aws_s3_bucket_public_access_block" "lambda" {
  bucket = aws_s3_bucket.lambda.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "lambda" {
  bucket = aws_s3_bucket.lambda.id
  key    = "lambda.jar"

  source      = "../target/lambda.jar"
  source_hash = filemd5("../target/lambda.jar")
}
