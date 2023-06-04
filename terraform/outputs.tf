output "writer_lambda_name" {
  value = aws_lambda_function.writer.function_name
}

output "reader_lambda_name" {
  value = aws_lambda_function.reader.function_name
}

output "datahike-s3-backend" {
  value = aws_s3_bucket.datahike-s3-backend.id
}

output "write_url" {
  value = aws_lambda_function_url.writer.function_url
}

output "read_url" {
  value = aws_lambda_function_url.reader.function_url
}
