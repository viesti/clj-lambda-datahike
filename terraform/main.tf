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

  runtime = "java17"

  memory_size = 3008

  timeout = 30

  environment {
    variables = {
      DATAHIKE_S3_BACKEND = aws_s3_bucket.datahike-s3-backend.id
      BACKEND_ROLE = "writer"
    }
  }

  publish = true

  snap_start {
    apply_on = "PublishedVersions"
  }
}

resource "aws_lambda_function" "reader" {
  function_name = "${random_pet.demo.id}-reader"
  role          = aws_iam_role.lambda.arn

  handler = "clj_lambda_datahike.handler"

  s3_bucket        = aws_s3_bucket.lambda.id
  s3_key           = aws_s3_object.lambda.key
  source_code_hash = filebase64sha256("../target/lambda.jar")

  runtime = "java17"

  memory_size = 3008

  timeout = 30

  environment {
    variables = {
      DATAHIKE_S3_BACKEND = aws_s3_bucket.datahike-s3-backend.id
      BACKEND_ROLE = "reader"
    }
  }

  publish = true

  snap_start {
    apply_on = "PublishedVersions"
  }
}

resource "aws_lambda_alias" "writer-latest-checkpoint" {
  name             = "writer-latest-checkpoint"
  description      = "Points to the latest Snapstart checkpoint version"
  function_name    = aws_lambda_function.writer.arn
  function_version = aws_lambda_function.writer.version
}

resource "null_resource" "writer-cleanup-lambda-versions" {
  triggers = {
    lambda_version = aws_lambda_alias.writer-latest-checkpoint.function_version
  }

  provisioner "local-exec" {
    working_dir = ".."
    command = "bb run cleanup-lambda-versions ${aws_lambda_function.writer.function_name} writer-latest-checkpoint"
  }
}

resource "null_resource" "reader-cleanup-lambda-versions" {
  triggers = {
    lambda_version = aws_lambda_alias.reader-latest-checkpoint.function_version
  }

  provisioner "local-exec" {
    working_dir = ".."
    command = "bb run cleanup-lambda-versions ${aws_lambda_function.reader.function_name} reader-latest-checkpoint"
  }
}

resource "aws_lambda_alias" "reader-latest-checkpoint" {
  name             = "reader-latest-checkpoint"
  description      = "Points to the latest Snapstart checkpoint version"
  function_name    = aws_lambda_function.reader.arn
  function_version = aws_lambda_function.reader.version
}

resource "aws_lambda_function_url" "writer" {
  function_name      = aws_lambda_function.writer.function_name
  authorization_type = "NONE"

  qualifier = aws_lambda_alias.writer-latest-checkpoint.name
}

resource "aws_lambda_function_url" "reader" {
  function_name      = aws_lambda_function.reader.function_name
  authorization_type = "NONE"

  qualifier = aws_lambda_alias.reader-latest-checkpoint.name
}

resource "local_file" "writer-url-file" {
  content  = aws_lambda_function_url.writer.function_url
  filename = "${path.module}/writer-url.txt"
}

resource "local_file" "reader-url-file" {
  content  = aws_lambda_function_url.reader.function_url
  filename = "${path.module}/reader-url.txt"
}

resource "local_file" "writer-lambda-name-file" {
  content  = aws_lambda_function.writer.function_name
  filename = "${path.module}/writer-lambda-name.txt"
}

resource "local_file" "reader-lambda-name-file" {
  content  = aws_lambda_function.reader.function_name
  filename = "${path.module}/reader-lambda-name.txt"
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
