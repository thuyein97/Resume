provider "aws" {
  region = "us-east-1" # Update to your preferred region
}

# DynamoDB Table
resource "aws_dynamodb_table" "example_table" {
  name         = "ExampleDynamoDBTable"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
  tags = {
    Environment = "dev"
  }
}
resource "aws_dynamodb_table_item" "count" {
  table_name = aws_dynamodb_table.example_table.name
  hash_key   = aws_dynamodb_table.example_table.hash_key
  item       = <<ITEM
{
  "id": {"S": "visitor_count"},
  "visitorCount": {"N": "0"}
}
ITEM
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-dynamodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for DynamoDB Access
resource "aws_iam_policy" "dynamodb_access_policy" {
  name = "DynamoDBAccessPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.example_table.arn
      }
    ]
  })
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_access_policy.arn
}

resource "aws_lambda_function" "example_lambda" {
  filename      = "lambda_function.zip" # Path to your Lambda function code
  function_name = "ExampleLambdaFunction"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler" # Update as per your Lambda function entry point
  runtime       = "python3.12"                     # Update to the runtime of your Lambda function

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.example_table.name
    }
  }

  # Required permissions for Lambda logging
  depends_on = [aws_iam_role_policy_attachment.lambda_policy_attachment]
}

# API Gateway
resource "aws_api_gateway_rest_api" "example_api" {
  name        = "ExampleAPIGateway"
  description = "API Gateway to trigger Lambda function"
}

# API Gateway Resource
resource "aws_api_gateway_resource" "example_resource" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  parent_id   = aws_api_gateway_rest_api.example_api.root_resource_id
  path_part   = "visitors"
}

# API Gateway Method
resource "aws_api_gateway_method" "example_method" {
  rest_api_id   = aws_api_gateway_rest_api.example_api.id
  resource_id   = aws_api_gateway_resource.example_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.example_api.id
  resource_id             = aws_api_gateway_resource.example_resource.id
  http_method             = aws_api_gateway_method.example_method.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.example_lambda.arn}/invocations"
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.example_api.execution_arn}/*/*"
}
resource "aws_api_gateway_method_response" "example" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  resource_id = aws_api_gateway_resource.example_resource.id
  http_method = aws_api_gateway_method.example_method.http_method
  status_code = "200"
}
resource "aws_api_gateway_integration_response" "example" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  resource_id = aws_api_gateway_resource.example_resource.id
  http_method = aws_api_gateway_method.example_method.http_method
  status_code = "200"
  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
  #response_templates = {
  #"application/json" = "{\"statusCode\": 200, \"headers\": {\"Access-Control-Allow-Origin\": \"*\", \"Access-Control-Allow-Methods\": \"GET, POST, OPTIONS\", \"Access-Control-Allow-Headers\": \"*\"}, \"body\": \"$input.path('$.body')\"}"
  #}
}
resource "aws_api_gateway_deployment" "example_deployment" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.example_api.id
}

resource "aws_api_gateway_stage" "example" {
  rest_api_id   = aws_api_gateway_rest_api.example_api.id
  stage_name    = "dev"
  deployment_id = aws_api_gateway_deployment.example_deployment.id
}
output "api-gateway-url" {
  value = aws_api_gateway_deployment.example_deployment.invoke_url
}