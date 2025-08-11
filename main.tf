resource "random_id" "name" {
  byte_length = 8
}

resource "aws_s3_bucket" "bucket1" {
  bucket = "image-recognition-frontend-${random_id.name.hex}"
}
resource "aws_s3_bucket" "bucket2" {
  bucket = "image-recognition-upload-${random_id.name.hex}"
}
resource "aws_s3_bucket_cors_configuration" "name" {
  bucket = aws_s3_bucket.bucket1.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = []
  }

}

resource "aws_iam_role" "lambda_image_recognition_role" {
  name = "lambda-image-recognition-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_image_recognition_policy" {
  name = "lambda-image-recognition-policy"
  role = aws_iam_role.lambda_image_recognition_role.name


  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "arn:aws:s3:::image-recognition-uploads/*"
      },
      {
        Effect = "Allow",
        Action = [
          "rekognition:DetectLabels"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "name" {
  function_name = "imageRecognitionHandler"
  role          = aws_iam_role.lambda_image_recognition_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  architectures = x86_64
  filename = data.archive_file.name.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

}
data "archive_file" "name" {
  type = "zip"
  source_file = "${path.module}/index.js"
  output_path = "${path.module}/lambdat.zip"
  
}

resource "aws_api_gateway_rest_api" "name" {
  name = "Project1"
}
resource "aws_api_gateway_resource" "name" {
  rest_api_id = aws_api_gateway_rest_api.name.id
  parent_id = aws_api_gateway_rest_api.name.root_resource_id
  path_part = "analyze"
  
}
resource "aws_api_gateway_method" "name" {
  rest_api_id = aws_api_gateway_rest_api.name.id
  resource_id = aws_api_gateway_resource.name.id
  http_method="POST"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "name" {
  rest_api_id = aws_api_gateway_method.name.id
  resource_id = aws_api_gateway_resource.name.id
  http_method = aws_api_gateway_method.name.http_method
  integration_http_method = "POST"
  type = 'AWS_PROXY'
  uri=aws_lambda_function.name.invoke_arn
}

resource "aws_api_gateway_method" "option_analyse" {
  rest_api_id=aws_api_gateway_rest_api.name.id
  resource_id=aws_api_gateway_resource.name.id
  http_method="OPTIONS"
  authorization="NONE"
  
}
resource "aws_api_gateway_integration" "name1" {
  rest_api_id=aws_api_gateway_rest_api.name.id
  resource_id=aws_api_gateway_resource.name.id
  http_method=aws_api_gateway_method.option_analyse.http_method
  type="MOCK"
  request_templates={
    "application/json"="{\"statusCode\":200}"
  }
}
resource "aws_api_gateway_method_response" "name" {
  rest_api_id=aws_api_gateway_rest_api.name.id
  resource_id=aws_api_gateway_integration.name.id
  http_method=aws_api_gateway_method.options_analyze.http_method
  status_code="200"
  response_parameters={
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
   response_models = {
    "application/json" = "Empty"
  }
  
}
resource "aws_api_gateway_integration_response" "name"{
  rest_api_id=aws_api_gateway_rest_api.name.id
  resource_id=aws_api_gateway_resource.name.id
   http_method = aws_api_gateway_method.options_analyze.http_method
  status_code = aws_api_gateway_method_response.options_analyze_response.status_code
   response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
 response_templates = {
    "application/json" = ""
  }
}
resource "aws_api_gateway_deployment" "name"{
  depends_on = [ aws_api_gateway_integration.name,aws_api_gateway_integration.name1 ]
  rest_api_id=aws_api_gateway_rest_api.name.id
  stage_name = "project"


}


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
