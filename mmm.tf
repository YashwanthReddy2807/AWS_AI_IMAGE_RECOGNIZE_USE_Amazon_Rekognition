resource "aws_lambda_permission" "name" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.image_recognition_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.name.execution_arn}/*/*"

}
resource "aws_s3_object" "name" {
  bucket       = aws_s3_bucket.bucket1.bucket
  source       = "index.html"
  key          = "index.html"
  content_type = "text/html"

}

resource "aws_s3_bucket_website_configuration" "name" {
  bucket = aws_s3_bucket.bucket1.bucket
  index_document {
    suffix = "index.html"
  }
}
