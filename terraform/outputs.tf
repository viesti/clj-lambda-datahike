output "lambda_name" {
  value = aws_lambda_function.demo.function_name
}

output "datahike-s3-backend" {
  value = aws_s3_bucket.datahike-s3-backend.id
}
