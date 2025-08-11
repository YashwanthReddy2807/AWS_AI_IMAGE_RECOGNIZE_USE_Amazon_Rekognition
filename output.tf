output "name" {
  value = aws_s3_bucket.bucket1.id
}
output "name2" {
  value = aws_s3_bucket.bucket2.id
}
output "api_invoke_url" {
  description = "Invoke URL for the API"
  value       = "${aws_api_gateway_deployment.image_api_deployment.invoke_url}/analyze"
}
output "name3" {
  value = aws_s3_bucket_website_configuration.name.website_endpoint
}
