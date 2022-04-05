provider "aws" {
    profile = "${var.aws_profile}"
    region = "${var.aws_region}"
}

// Create Dynamodb Layout Table
resource "aws_dynamodb_table" "layout_dynamodb_table" {
    name            = "${var.table_name}"
    billing_mode    = "${var.table_billing_mode}"
    hash_key        = "id"
    attribute {
        name        = "id"
        type        = "S"
    }
    tags = {
        environment = "${var.environment}"
    }
}

// define CRUD Lambda Roles
data "aws_iam_policy_document" "layout_lambda_role_document" {
  statement {
        effect = "Allow"
        sid = ""
        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
        actions = [
            "sts:AssumeRole"
        ]
  }
}

resource "aws_iam_role" "layout_lambda_role" {
    name               = "layout_lambda_role"
    description        = "Layout Lambda Role"
    assume_role_policy = data.aws_iam_policy_document.layout_lambda_role_document.json
}

data "aws_iam_policy_document" "layout_iam_policy_document" {
  statement {
    effect = "Allow"
    actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Scan",
        "dynamodb:UpdateItem",
        "dynamodb:Query"
    ]
    resources = [
      "arn:aws:dynamodb:*:*:*"
    ]
  }
}

resource "aws_iam_policy" "layout_iam_policy" {
    name        = "layout_iam_policy"
    description = "Layout IAM Policy"
    path        = "/"
    policy      = data.aws_iam_policy_document.layout_iam_policy_document.json
}

// define Authorizer Lambda Roles
data "aws_iam_policy_document" "layout_authorizer_iam_policy_document" {
  statement {
    effect = "Allow"
    actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_policy" "layout_authorizer_iam_policy" {
    name        = "layout_authorizer_iam_policy"
    description = "Layout Authorizer IAM Policy"
    path        = "/"
    policy      = data.aws_iam_policy_document.layout_authorizer_iam_policy_document.json
}

// attach roles to service
resource "aws_iam_role_policy_attachment" "layout_iam_role_policy_attachment" {
    role       = aws_iam_role.layout_lambda_role.name
    policy_arn = aws_iam_policy.layout_iam_policy.arn
}

// attach authorizer roles to service
resource "aws_iam_role_policy_attachment" "layout_authorizer_iam_role_policy_attachment" {
    role       = aws_iam_role.layout_lambda_role.name
    policy_arn = aws_iam_policy.layout_authorizer_iam_policy.arn
}

// compress layout service file
data "archive_file" "archive_layout_service" {
    type        = "zip"
    source_file = "${path.module}/src/index.js"
    output_path = "${path.module}/src/layout_service.zip"
}

// compress authorizer layout service file
data "archive_file" "archive_layout_authorizer_service" {
    type        = "zip"
    source_file = "${path.module}/src/authorizer.js"
    output_path = "${path.module}/src/layout_authorizer_service.zip"
}

// provision layout management service
resource "aws_lambda_function" "layout_lambda_function" {
    filename      = "${path.module}/src/layout_service.zip"
    function_name = "layout_lambda_function"
    role          = aws_iam_role.layout_lambda_role.arn
    handler       = "index.handler"
    runtime       = "nodejs14.x"
    architectures = [ "x86_64" ]
    depends_on    = [aws_iam_role_policy_attachment.layout_iam_role_policy_attachment]
}

// provision layout authorizer management service
resource "aws_lambda_function" "layout_authorizer_lambda_function" {
    filename      = "${path.module}/src/layout_authorizer_service.zip"
    function_name = "layout_authorizer_lambda_function"
    role          = aws_iam_role.layout_lambda_role.arn
    handler       = "authorizer.handler"
    runtime       = "nodejs14.x"
    architectures = [ "x86_64" ]
    depends_on    = [aws_iam_role_policy_attachment.layout_authorizer_iam_role_policy_attachment]
}

// create API Gateway Layout
resource "aws_apigatewayv2_api" "layout_api_gateway" {
  name          = "layout_api_gateway"
  description   = "Layout Service API Gateway"
  protocol_type = "HTTP"
}

// define API Gateway Stage
resource "aws_apigatewayv2_stage" "layout_api_stage" {
    api_id      = aws_apigatewayv2_api.layout_api_gateway.id

    name        = "${var.environment}"
    auto_deploy = true

    access_log_settings {
        destination_arn = aws_cloudwatch_log_group.layout_cloudwatch_log_group.arn

        format = jsonencode({
          requestId               = "$context.requestId"
          sourceIp                = "$context.identity.sourceIp"
          requestTime             = "$context.requestTime"
          protocol                = "$context.protocol"
          httpMethod              = "$context.httpMethod"
          resourcePath            = "$context.resourcePath"
          routeKey                = "$context.routeKey"
          status                  = "$context.status"
          responseLength          = "$context.responseLength"
          integrationErrorMessage = "$context.integrationErrorMessage"
          }
        )
    }
}

// define API Gateway Integration Service
resource "aws_apigatewayv2_integration" "layout_api_integration" {
    description            = "Layout Service API Gateway Integration"
    api_id                 = aws_apigatewayv2_api.layout_api_gateway.id
    connection_type        = "INTERNET"
    integration_type       = "AWS_PROXY"
    integration_method     = "POST"
    integration_uri        = aws_lambda_function.layout_lambda_function.invoke_arn
    payload_format_version = "2.0"
    timeout_milliseconds   = 30000
}

// define API Gateway Authorization Service
resource "aws_apigatewayv2_authorizer" "layout_api_authorizer" {
    name                              = "layout_api_authorizer"
    api_id                            = aws_apigatewayv2_api.layout_api_gateway.id
    identity_sources                  = ["$request.header.Authorization"]
    authorizer_type                   = "REQUEST"
    authorizer_uri                    = aws_lambda_function.layout_authorizer_lambda_function.invoke_arn
    authorizer_payload_format_version = "2.0"
    authorizer_result_ttl_in_seconds  = 0
}

// define API Gateway Routes
resource "aws_apigatewayv2_route" "layout_get_api_route" {
    operation_name     = "find"
    api_id             = aws_apigatewayv2_api.layout_api_gateway.id
    route_key          = "GET /layouts"
    target             = "integrations/${aws_apigatewayv2_integration.layout_api_integration.id}"
    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.layout_api_authorizer.id
}

resource "aws_apigatewayv2_route" "layout_get_by_id_api_route" {
    operation_name     = "findById"
    api_id             = aws_apigatewayv2_api.layout_api_gateway.id
    route_key          = "GET /layouts/{id}"
    target             = "integrations/${aws_apigatewayv2_integration.layout_api_integration.id}"
    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.layout_api_authorizer.id
}

resource "aws_apigatewayv2_route" "layout_put_api_route" {
    operation_name     = "save"
    api_id             = aws_apigatewayv2_api.layout_api_gateway.id
    route_key          = "PUT /layouts"
    target             = "integrations/${aws_apigatewayv2_integration.layout_api_integration.id}"
    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.layout_api_authorizer.id
}

resource "aws_apigatewayv2_route" "layout_delete_api_route" {
    operation_name     = "delete"
    api_id             = aws_apigatewayv2_api.layout_api_gateway.id
    route_key          = "DELETE /layouts/{id}"
    target             = "integrations/${aws_apigatewayv2_integration.layout_api_integration.id}"
    authorization_type = "CUSTOM"
    authorizer_id      = aws_apigatewayv2_authorizer.layout_api_authorizer.id
}

// define API Gateway Cloudwatch configuration
resource "aws_cloudwatch_log_group" "layout_cloudwatch_log_group" {
    name              = "/aws/api_gw/${aws_apigatewayv2_api.layout_api_gateway.name}"
    retention_in_days = 30
}

// define API Gateway Lambda Permissions
resource "aws_lambda_permission" "layout_lambda_permission" {
    statement_id  = "AllowExecutionFromAPIGateway"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.layout_lambda_function.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.layout_api_gateway.execution_arn}/*/*"
}

// define API Gateway Authorizer Lambda Permissions
resource "aws_lambda_permission" "layout_authorizer_lambda_permission" {
    statement_id  = "AllowExecutionFromAPIGateway"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.layout_authorizer_lambda_function.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.layout_api_gateway.execution_arn}/*/*"
}

// create a custom domain attacged to API Gateway
resource "aws_apigatewayv2_domain_name" "layout_domain_name" {
    domain_name = "${var.domain_name}"

    domain_name_configuration {
        certificate_arn = "${var.domain_arn_certificate}"
        endpoint_type   = "REGIONAL"
        security_policy = "TLS_1_2"
    }
}

resource "aws_apigatewayv2_api_mapping" "layout_api_mapping" {
    api_id          = aws_apigatewayv2_api.layout_api_gateway.id
    stage           = aws_apigatewayv2_stage.layout_api_stage.id
    domain_name     = aws_apigatewayv2_domain_name.layout_domain_name.id
    api_mapping_key = "${var.environment}"
}
