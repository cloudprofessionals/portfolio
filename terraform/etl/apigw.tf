#get arn of the role for cloudwatch
resource "aws_api_gateway_account" "api_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_lambda_role.arn
}

#create rest api resource
resource "aws_api_gateway_rest_api" "api_gateway" {
  name = var.api_gateway_name
  tags = var.tags
}

#create parent resource
resource "aws_api_gateway_resource" "tickets" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "tickets"
}

#create report resource
resource "aws_api_gateway_resource" "report" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_resource.tickets.id
  path_part   = "report"
}

#create get method
resource "aws_api_gateway_method" "getMethod" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.report.id
  http_method   = "GET"
  authorization = "NONE"
  request_validator_id = aws_api_gateway_request_validator.validator.id
  api_key_required = true
  request_parameters = {
    "method.request.querystring.service_start" = true
    "method.request.querystring.service_end" = true
//    "method.request.querystring.page_size" = true
    "method.request.header.x-api-key" = true
  }
}

#enable metrics and logging
resource "aws_api_gateway_method_settings" "api_settings" {
  method_path = "*/*"
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name = aws_api_gateway_stage.api_stage.stage_name
  settings {
    metrics_enabled = true
    data_trace_enabled = true
    logging_level = "INFO"
  }
}

#use lambda as integration
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.report.id
  http_method = aws_api_gateway_method.getMethod.http_method
  credentials = aws_iam_role.api_gateway_lambda_role.arn
  integration_http_method = "POST"
  type  = "AWS_PROXY"
  uri   = aws_lambda_function.tickets.invoke_arn
}

#create api deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.report.id,
      aws_api_gateway_method.getMethod.id,
      aws_api_gateway_integration.lambda.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

#create deployment stage
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name = var.api_stage_name
  depends_on = [
    aws_cloudwatch_log_group.log_group
  ]
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.log_group.arn
    format = "$context.identity.sourceIp,$context.identity.caller,$context.identity.user,$context.requestTime,$context.httpMethod,$context.resourcePath,$context.protocol,$context.status,$context.responseLength,$context.requestId"
  }
}

#create request validator
resource "aws_api_gateway_request_validator" "validator" {
  name      = "request_parameters"
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  validate_request_parameters = true
}

resource "aws_api_gateway_api_key" "api_key" {
  name = var.api_key_name
}

#grant permission to api gateway to call lambda
resource "aws_lambda_permission" "api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tickets.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}

#create cloudwatch log group
resource "aws_cloudwatch_log_group" "log_group" {
  name   = var.cloudwatch_log_group_name
  retention_in_days = 90
  tags = var.tags
}

#create usage plan to enable api key
resource "aws_api_gateway_usage_plan" "api_plan" {
  name = var.api_usage_plan_name
  description = "usage plan for api gateway"

  api_stages {
    api_id = aws_api_gateway_rest_api.api_gateway.id
    stage = aws_api_gateway_stage.api_stage.stage_name
  }

  quota_settings {
    limit = 10000
    offset = 0
    period = "DAY"
  }
}

#create api key
resource "aws_api_gateway_usage_plan_key" "api_key_plan" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api_plan.id
}


#create resource policy to protect your api
//resource "aws_api_gateway_rest_api_policy" "resource_policy" {
//  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
//
//  policy = <<EOF
//{
//    "Version": "2012-10-17",
//    "Statement": [
//        {
//            "Effect": "Allow",
//            "Principal": "*",
//            "Action": "execute-api:Invoke",
//            "Resource": "${aws_api_gateway_rest_api.api_gateway.execution_arn}"
//        },
//        {
//            "Effect": "Deny",
//            "Principal": "*",
//            "Action": "execute-api:Invoke",
//            "Resource": "${aws_api_gateway_rest_api.api_gateway.execution_arn}",
//            "Condition": {
//                "NotIpAddress": {
//                    "aws:SourceIp": [
//                        "91.214.151.131/32"
//                    ]
//                }
//            }
//        }
//    ]
//}
//EOF
//}